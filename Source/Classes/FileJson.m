//
//  FileJson.m
//  AzPackList
//
//  Created by 松山 和正 on 10/03/01.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Global.h"
#import "AppDelegate.h"
#import "Elements.h"
#import "EntityRelation.h"
#import "FileJson.h"
#import "FileCsv.h"
#import <DropboxSDK/JSON.h>


@implementation FileJson
{
	NSManagedObject		*ownObject_;
}
@synthesize tmpPathFile = tmpPathFile_;
@synthesize errorMsgs = errorMsgs_;


- (void)errorMsg:(NSString*)msg
{
	if (errorMsgs_==nil) {
		errorMsgs_ = [NSMutableArray new];
	}
	[errorMsgs_ addObject:msg];
}


#pragma mark - Lifecycle

- (id)init
{
	self = [super init];
    if (self) {
        // Custom initialization
		// 一時ファイルパス
		// <Application_Home>/Library/Caches/　　＜＜iCloudバックアップされない
		//NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
		//NSString *dir = [paths objectAtIndex:0];
		
		// <Application_Home>/tmp/ 　＜＜iCloudバックアップされない、iOSから消される場合あり
		NSString *tempDir = NSTemporaryDirectory();
		tmpPathFile_ = [tempDir stringByAppendingPathComponent:@"PackListTmp.azp"];
		NSLog(@"FileJson: init: tempPath_ = '%@'", tmpPathFile_);
		if (tmpPathFile_==nil) {
			[self errorMsg:@"NG tmp path"];
		}
    }
    return self;
}

- (void)dealloc
{
	//if (tmpPathFile_) {	// 一時ファイルを削除する
	//	[[NSFileManager defaultManager] removeItemAtPath:tmpPathFile_ error:nil];		
	//}
}

#pragma mark - JSON - Dictionary converter
#define TYPE_NSDate		@"#date#"		//特殊型Key// 日付

// JSON変換できるようにするため、NSManagedObject を NSDictionary に変換する。 ＜＜関連（リレーション）対応
- (NSDictionary*)dictionaryFromObject:(NSManagedObject*)mobj
{
	// 配下から自身がリレーションれたとき無限ループしないための処理　＜＜ これでは、配下内の無限ループまでは回避できない
	if (ownObject_==mobj) {
		// 自身がリレーションされた！　ループ発生 ＜＜禁止！
		return nil;
	}
	// OK 配下からリレーションされたときに備えて自身を記録
	ownObject_ = mobj;
	
	NSArray* attributes = [[[mobj entity] attributesByName] allKeys];
    //関連（リレーション）対応
	NSArray* relationships = [[[mobj entity] relationshipsByName] allKeys];
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity: [attributes count] + [relationships count] + 1];
	//NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity: [attributes count] + 1];
	
    //[dict setObject:[[mobj class] description] forKey:@"class"]; ＜＜ "NSManagedObject" になる
    [dict setObject:[[mobj entity] name] forKey:@"#class"];
	
	// 属性
    for (NSString* attrKey in attributes) {
        NSObject* value = [mobj valueForKey:attrKey];
		NSLog(@"*** attrKey=%@  value=%@", attrKey, value);
		
        if ([value isKindOfClass:[NSDate class]]) {		// JSON未定義型に対応するため
			NSDate *dt = (NSDate*)value;
			// NSDate ---> NSString
			// utcFromDate: デフォルトタイムゾーンのNSDate型 を UTC協定世界時 文字列 "2010-12-31T00:00:00" にする
			// Key に Prefix: TYPE_NSDate を付ける
			[dict setObject:utcFromDate(dt) forKey:[TYPE_NSDate stringByAppendingString:attrKey]];
		}
		else if (attrKey && value) {
            [dict setObject:value forKey:attrKey];
        }
    }
	
    //関連（リレーション）対応
	for (NSString* relationKey in relationships) {	// 配下を再帰的にdict化する
		if ([relationKey isEqualToString:@"childs"]) {
			NSObject* value = [mobj valueForKey:relationKey];
			NSLog(@"***** relationKey=%@  value=%@", relationKey, value);
			
			if ([value isKindOfClass:[NSSet class]]) {
				// 対多
				NSLog(@"*****対多***");
				// The core data set holds a collection of managed objects
				NSSet* relatedObjects = (NSSet*) value;
				// Our set holds a collection of dictionaries
				//NG//NSMutableSet* dictSet = [NSMutableSet setWithCapacity:[relatedObjects count]];
				//NG// SBJsonは、NSSetに対応していないため、Arrayにした。
				NSMutableArray *dicArray = [NSMutableArray new];
				for (NSManagedObject* obj in relatedObjects) {
					NSLog(@"*****対多*** obj=%@", obj);
					if (obj != mobj) { // 自身で無いならば
						NSDictionary *dic = [self dictionaryFromObject:obj];	// 再帰コール
						if (dic) {
							//[dictSet addObject:dic];
							[dicArray addObject:dic];
						}
					}
				}
				//[dict setObject:dictSet forKey:relationKey];
				[dict setObject:dicArray forKey:relationKey];
			}
			else if ([value isKindOfClass:[NSManagedObject class]]) {
				// 対1
				NSManagedObject* obj = (NSManagedObject*) value;
				NSLog(@"*****対1*** obj=%@", obj);
				if (obj != mobj) { // 自身で無いならば
					NSDictionary *dic = [self dictionaryFromObject:obj];	// 再帰コール
					if (dic) {
						[dict setObject:dic forKey:relationKey];
					}
				}
			}
		}
	}
    return dict;
}


// JSON変換した NSDictionary から NSManagedObject を生成する。
- (NSManagedObject*)objectFromDictionary:(NSDictionary*)dict  forMoc:(NSManagedObjectContext*)moc
{
    NSString* class = [dict objectForKey:@"#class"];
	if (class==nil) {
		[self errorMsg:@"#class Nothing"];
		return nil;
	}
    NSManagedObject* newObject = [NSEntityDescription insertNewObjectForEntityForName:class inManagedObjectContext:moc];
	if (newObject==nil) {
		[self errorMsg:@"newObject Insert error"];
		return nil;
	}

    for (NSString* key in dict) 
	{
        NSObject* value = [dict objectForKey:key];
		NSLog(@"key=%@,  value=%@", key, value);
		if (value==nil) {
			continue;
		}
		
		if ([key hasPrefix:@"#"]) {	// JSON未定義型に対応するため
			if ([key isEqualToString:@"#class"]) {
				continue;
			}
			else if ([key hasPrefix:TYPE_NSDate]) {
				// UTC日付文字列 ---> NSDate
				NSString *str = (NSString*)value;
				// dateFromUTC: UTC協定世界時 文字列 "2010-12-31T00:00:00" を デフォルトタイムゾーンのNSDate型にする
				// Prefix: TYPE_NSDate を取り除いてKeyにする
				[newObject setValue:dateFromUTC(str) forKey: [key substringFromIndex:[TYPE_NSDate length]]];
			}
			else {
				[self errorMsg:@"NG #type"];
				assert(NO);	// 未定義の型
			}
		}
        else if ([value isKindOfClass:[NSDictionary class]]) {
			// 対1　関連（リレーション）対応
			NSDictionary *dic = (NSDictionary*)value;
			// 子 生成
			NSManagedObject* child = [self objectFromDictionary:dic forMoc:moc];	// 再帰コール
			// 子 関連付け
			[newObject setValue:child forKey:key];
		}
		//else if ([value isKindOfClass:[NSSet class]]) {
		//NG// SBJsonは、NSSetに対応していないため、Arrayにした。
		else if ([value isKindOfClass:[NSArray class]]) {
			// 対多　関連（リレーション）非対応
			//NSSet* relatedDictionarys = (NSSet*)value;
			NSArray *relatedDictionarys = (NSArray*)value;
			NSMutableSet* childObjects = [newObject mutableSetValueForKey:key]; // Mocなので、NSSet
			for (NSDictionary* relatedDic in relatedDictionarys) {
				// 子 生成
				NSManagedObject* child = [self objectFromDictionary:relatedDic forMoc:moc];	// 再帰コール
				// 子 関連付け
				[childObjects addObject:child];
			}
			[newObject setValue:childObjects forKey:key];
		}
		else {  
			// エンティティ
			[newObject setValue:value forKey:key];
		}
	}
	return newObject;
}


#pragma mark - Writing
#define FILE_HEADER_ID_JSON		@"AzPackList,UTF-8,JSON,Copyright(C)2012,Azukid"		// 読み込み時の判定に使用

- (BOOL)writingE1:(E1 *)Pe1 
{
	if (tmpPathFile_==nil  OR  Pe1==nil) {
		[self errorMsg:@"writingE1: init error"];
		return NO;
	}
	NSDictionary *dic = [self dictionaryFromObject:Pe1];
	NSLog(@"FileJson: writing: dic=%@", dic);
	if (dic==nil) {
		[self errorMsg:@"writingE1:NG dictionaryFromObject"];
		return NO;
	}
	
	SBJsonWriter *jsonWriter = [[SBJsonWriter alloc] init];
#ifdef DEBUGxxx
	jsonWriter.humanReadable = YES;
	jsonWriter.sortKeys = YES;
#endif
	NSString *jsonStr = [jsonWriter stringWithObject:dic];
	NSLog(@"FileJson: writing: jsonStr=%@  error=%@", jsonStr, jsonWriter.errorTrace);
	if (jsonStr==nil) {
		[self errorMsg:@"writingE1:NG jsonWriter"];
		return NO;
	}

	NSLog(@"FileJson: writing: tmpPathFile_='%@'", tmpPathFile_);
	// 一時出力ファイルをCREATE
	[[NSFileManager defaultManager] createFileAtPath:tmpPathFile_ contents:nil attributes:nil];
	// 一時出力ファイルを WRITE OPEN
	NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:tmpPathFile_];
	if (fileHandle==nil) {
		[self errorMsg:@"writingE1:NG Write open"];
		return NO;
	}

	@try {
		//----------------------------------------------------------------------------------------Header CSV
		//str = GD_CSV_HEADER_ID  @",CSV,UTF-8,Copyright,(C)2011,Azukid,,,\n";
		//[1.1.0]これまでLoad時には、GD_CSV_HEADER_ID だけ比較チェックしている。
		//[1.1.0],CSV,の次に,4,を追加。 4 は、xcdatamodel 4 を示している。　　近未来JSON対応すれば、,CSV,⇒,JSON, とする。
		NSString *str = FILE_HEADER_ID_JSON;
		// UTF8 エンコーディングしてファイルへ書き出す
		[fileHandle writeData:[str dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
		
		/*			// 暗号化
		 NSData *jsonData = 
		 
		 // バイナリファイルへ書き出す
		 [output writeData:jsonStr];*/
		
		//----------------------------------------------------------------------------------------Body JSON
		// UTF8 エンコーディングしてファイルへ書き出す
		[fileHandle writeData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
	}
	@catch(id error) {
		[self errorMsg:@"writingE1:NG catch"];
	}
	@catch (NSException *errEx) {
		NSString *msg = [NSString stringWithFormat:@"writingE1: NSException: %@: %@", [errEx name], [errEx reason]];
		[self errorMsg:msg];
	}
	@finally {	// 途中 error や return で抜けても必ず通る。
		[fileHandle closeFile];
	}
	return YES;
	
	// PasteBoard出力
	//[UIPasteboard generalPasteboard].string = zCsv;  // 共有領域にコピーされる
}


#pragma mark - Reading

- (E1*)readingE1
{
	if (tmpPathFile_==nil) {
		[self errorMsg:@"readingE1: tmpPathFile_=nil"];
		return nil;
	}
	
	// 一時ファイルを READ OPEN
	NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:tmpPathFile_];
	if (fileHandle==nil) {
		[self errorMsg:@"readingE1:NG Read open"];
		return nil;
	}
	
	@try {
		[fileHandle seekToFileOffset:0];
		NSData *data = [fileHandle readDataOfLength:[FILE_HEADER_ID_JSON length]];
		if ([data length] != [FILE_HEADER_ID_JSON length]) {
			//@finally//[fileHandle closeFile];
			[self errorMsg:@"readingE1:NG Header length"];
			return nil;
		}
		NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		NSLog(@"FileJson: readingE1: Header=%@", str);
		if (![str isEqualToString:FILE_HEADER_ID_JSON]) { 
			// 一致しない
			//@finally//[fileHandle closeFile];
			//------------------------------------------------------CSV対応
			if ([str hasPrefix:GD_CSV_HEADER_ID]) {		// 初期CSV形式の可能性あり
				// 最初から全文字列を読み込む
				[fileHandle seekToFileOffset:0];
				data = [fileHandle readDataToEndOfFile];  // ファイルの終わりまでデータを読んで返す
				str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
				if (str) {
					FileCsv *fcsv = [[FileCsv alloc] init];
					E1 *e1 = [fcsv zLoad:str  withSave:YES];
					if (e1==nil) {
						NSString *msg = [NSString stringWithFormat:@"readingE1: FileCsv: err=%@", fcsv.errorMsgs];
						[self errorMsg:msg];
					}
					return e1;
				}
			}
			[self errorMsg:@"readingE1:NG Header error"];
			return nil;
		}
		// 引き続きJSON文字列を読み込む
		data = [fileHandle readDataToEndOfFile];  // ファイルの終わりまでデータを読んで返す
		str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		
		// JSON --> Dictionary
		SBJsonParser *jsonParser = [[SBJsonParser alloc] init];
		NSDictionary *dic = [jsonParser objectWithString:str];
		NSLog(@"FileJson: readingE1: dic=%@", dic);
		if (dic==nil) {
			[self errorMsg:@"readingE1:NG jsonParser"];
			return nil;
		}
		// Dictionary --> Moc
		E1 *e1 = (E1*)[self objectFromDictionary:dic forMoc:[EntityRelation getMoc]];
		NSLog(@"FileJson: readingE1: e1=%@", e1);
		if (e1==nil) {
			[self errorMsg:@"readingE1:NG objectFromDictionary"];
			return nil;
		}
		NSInteger maxRow = [EntityRelation E1_maxRow];	//E1.row の最大値を求める
		e1.row = [NSNumber numberWithInteger:1 + maxRow];
		[EntityRelation commit];
		// OK
		return e1;
	}
	@catch(id error) {
		[self errorMsg:@"readingE1:NG catch"];
		return nil;
	}
	@catch (NSException *errEx) {
		NSString *msg = [NSString stringWithFormat:@"readingE1: NSException: %@: %@", [errEx name], [errEx reason]];
		[self errorMsg:msg];
	}
	@finally {	// 途中 error や return で抜けても必ず通る。
		[fileHandle closeFile];
	}
}


@end
