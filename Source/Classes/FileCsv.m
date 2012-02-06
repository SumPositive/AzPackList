//
//  FileCsv.m
//  AzPacking
//
//  Created by 松山 和正 on 10/03/01.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SFHFKeychainUtils.h"
#import "NSDataAddition.h"	// Crypt
#import "Global.h"
#import "AppDelegate.h"
#import "Elements.h"
#import "EntityRelation.h"
#import "FileCsv.h"



@implementation FileCsv
@synthesize tmpPathFile = tmpPathFile_;
@synthesize errorMsgs = errorMsgs_;


// string ⇒ csv : 文字列中にあるCSV予約文字を取り除くか置き換えてCSV保存できるようにする
static NSString *strToCsv( NSString *inStr ) {
	if ([inStr length]) {
		// 文字列中の禁止文字を置き換えてCSV保存できるようにする
		return  [inStr stringByReplacingOccurrencesOfString:@"\"" withString:@"'"];  // ["]-->>[']
	}
	return @"";
}

// csv ⇒ string : CSVから取得した文字列の前後にある["]ダブルクォーテーションを取り除く（無ければ何もしない）
static NSString *csvToStr( NSString *inCsv ) {
	if ([inCsv length]) {
		return  [inCsv stringByReplacingOccurrencesOfString:@"\"" withString:@""];  // 両端の["]を取り除く
	}
	return @"";
}


- (void)errorMsg:(NSString*)msg
{
	if (errorMsgs_) {		// ここで生成しない。親から受け取る
		[errorMsgs_ addObject:msg];
	}
}

// CSV形式　　["]で囲まれた文字列に限り、その中に[,]と[改行]を使用可能。
//           書き込み(SAVE)時に文字列中の["]は[']に置き換えられる。


#pragma mark - Lifecycle

- (id)init
{
	self = [super init];
    if (self) {
        // Custom initialization
		// 一時ファイルパス
		// <Application_Home>/tmp/ 　＜＜iCloudバックアップされない、iOSから消される場合あり
		NSString *tempDir = NSTemporaryDirectory();
		tmpPathFile_ = [tempDir stringByAppendingPathComponent:@"PackListTmp.azp"];
		NSLog(@"FileCsv: init: tempPath_ = '%@'", tmpPathFile_);
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


#pragma mark - Saveing

- (BOOL)zSavePrivate:(E1 *)Pe1 toMutableString:(NSMutableString *)PzCsv
{	// Private
	assert(PzCsv);
	NSSortDescriptor *key1 = [[NSSortDescriptor alloc] initWithKey:@"row" ascending:YES];
	NSArray *sortRow = [[NSArray alloc] initWithObjects:key1, nil];  
	NSString *str;
	
	@try {
		//----------------------------------------------------------------------------Header
		//OLD str = GD_CSV_HEADER_ID  @",CSV,UTF-8,Copyright,(C)2011,Azukid,,,\n";
		//[1.1.0]これまでLoad時には、GD_CSV_HEADER_ID だけ比較チェックしている。
		//[1.1.0],CSV,の次に,4,を追加。 4 は、xcdatamodel 4 を示している。　　近未来JSON対応すれば、,CSV,⇒,JSON, とする。
		str = GD_CSV_HEADER_ID  @",UTF-8,CSV,5,,,Copyright,(C)2012,Azukid,,\n";
		[PzCsv appendString:str];
		
		//----------------------------------------------------------------------------Body
		
		//----------------------------------------------------------------------------[Begin]
		str = @"Begin,,,,,,,,\n";
		[PzCsv appendString:str];
		
		//----------------------------------------------------------------------------E1 [Plan]
		//[1.0]  ,"name","note",
		str = [NSString stringWithFormat:@",\"%@\",\"%@\",\n", strToCsv(Pe1.name), strToCsv(Pe1.note)];
		AzLOG(@"E1> %@", str);
		[PzCsv appendString:str];
		
		//------------------------------------------------------------------------------E2 [Index]
		//[1.0] , ,"name","note",
		NSMutableArray *e2list = [[NSMutableArray alloc] initWithArray:[Pe1.childs allObjects]];
		[e2list sortUsingDescriptors:sortRow];	// .row 昇順にCSV書き出す
		for (E2 *e2node in e2list) {
			str = [NSString stringWithFormat:@",,\"%@\",\"%@\",\n", strToCsv(e2node.name), strToCsv(e2node.note)];
			AzLOG(@"E2> %@", str);
			[PzCsv appendString:str];
			
			//----------------------------------------------------------------------------E3 [Goods]
			//[1.0] ,,,"name","note",stock,need,weight,
			//[1.1] ,,,"name","note",stock,need,weight,"shopKeyword","shopNote",
			NSMutableArray *e3list = [[NSMutableArray alloc] initWithArray:[e2node.childs allObjects]];
			[e3list sortUsingDescriptors:sortRow];	// .row 昇順にCSV書き出す
			for (E3 *e3node in e3list) {
				if ((-1) < [e3node.need integerValue]) { //(-1)Add専用ノードを除外する
					str = [NSString stringWithFormat:@",,,\"%@\",\"%@\",%ld,%ld,%ld,\"%@\",\"%@\",\n", 
						   strToCsv(e3node.name),
						   strToCsv(e3node.note),
						   [e3node.stock longValue], 
						   [e3node.need longValue], 
						   [e3node.weight longValue],
						   strToCsv(e3node.shopKeyword),
						   strToCsv(e3node.shopNote)   ];
					AzLOG(@"E3> %@", str);
					[PzCsv appendString:str];
				}
			}
			//[e3list release];
			e3list = nil;
		}
		// release
		//[e2list release];
		e2list = nil;
		
		//----------------------------------------------------------------------------[End]
		str = @"End,,,,,,,,\n";
		AzLOG(@"End> %@", str);
		[PzCsv appendString:str];
		// Compleat!
		return YES;
	}
	@catch(id error) {
		[self errorMsg:@"zSave:NG catch"];
	}
	@catch (NSException *errEx) {
		NSString *msg = [NSString stringWithFormat:@"zSave: NSException: %@: %@", [errEx name], [errEx reason]];
		[self errorMsg:msg];
	}
	@finally {
		//
	}
	return NO;
}

// Pe1 から PzCsv 生成する
// crypt = NO; 公開アップするとき暗号化しないため
- (BOOL)zSave:(E1 *)Pe1 toMutableString:(NSMutableString *)PzCsv  crypt:(BOOL)bCrypt
{
	@autoreleasepool {
		if ([self zSavePrivate:Pe1 toMutableString:PzCsv]==NO) {
			return NO;
		}
	}
	//----------------------------------------------------------------------------Crypt 暗号化
	if (bCrypt) {
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		if ([userDefaults boolForKey:UD_OptCrypt]) {
			// KeyChainから保存しているパスワードを取得する
			NSError *error; // nilを渡すと異常終了するので注意
			NSString *secKey = [SFHFKeychainUtils getPasswordForUsername:UD_OptCrypt
														  andServiceName:GD_PRODUCTNAME error:&error];
			if (2 < [secKey length]) {
				// 暗号化
				NSData *plain = [PzCsv dataUsingEncoding:NSUTF8StringEncoding];	//--> NSData
				NSData *data = [plain AES256EncryptWithKey:secKey];	//--> AES256
				//NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
				NSString *str = [data stringEncodedWithBase64];	// NSData --> NSString(Base64)
				NSLog(@"FileCsv: zSave: Crypt: Base64 str=%@", str);
				[PzCsv setString:CRYPT_HEADER];	// Crypt Header を先頭へ追加
				[PzCsv appendString:str];
			}
			else {
				[self errorMsg:NSLocalizedString(@"PackListCrypt NoKey",nil)];
				return NO;
			}
		}
	}
	return YES;
}

- (BOOL)zSaveTmpFile:(E1 *)Pe1  crypt:(BOOL)bCrypt
{
	if (tmpPathFile_==nil) {
		[self errorMsg:@"tmpPathFile_=nil"];
		return NO;
	}
	
	NSMutableString *zCsv = [NSMutableString new];
	// Pe1 ---> zCsv
	if ([self zSave:Pe1 toMutableString:zCsv crypt:bCrypt]==NO) {
		return NO;
	}
	// UTF-8 出力ファイルをCREATE
	[[NSFileManager defaultManager] createFileAtPath:tmpPathFile_ contents:nil attributes:nil];
	// UTF-8 出力ファイルをOPEN
	NSFileHandle *output = [NSFileHandle fileHandleForWritingAtPath:tmpPathFile_];
	if (output==nil) {
		[self errorMsg:NSLocalizedString(@"File error",nil)];
		return NO;
	}
	
	@try {
		// UTF8 エンコーディングしてファイルへ書き出す
		[output writeData:[zCsv dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
		return YES;
	}
	@catch(id error) {
		[self errorMsg:NSLocalizedString(@"File error",nil)];
	}
	@catch (NSException *errEx) {
		NSString *msg = [NSString stringWithFormat:@"zSaveTmpFile: NSException: %@: %@", [errEx name], [errEx reason]];
		[self errorMsg:msg];
	}
	@finally {
		[output closeFile];
	}
	return NO;
}

- (BOOL)zSavePasteboard:(E1 *)Pe1  crypt:(BOOL)bCrypt
{
	NSMutableString *zCsv = [NSMutableString new];
	// Pe1 ---> zCsv
	if ([self zSave:Pe1 toMutableString:zCsv crypt:bCrypt]==NO) {
		return NO;
	}

	@try {
		// PasteBoard出力
		[UIPasteboard generalPasteboard].string = zCsv;  // 共有領域にコピーされる
		return YES;
	}
	@catch(id error) {
		[self errorMsg:NSLocalizedString(@"File error",nil)];
	}
	@catch (NSException *errEx) {
		NSString *msg = [NSString stringWithFormat:@"zSavePasteboard: NSException: %@: %@", [errEx name], [errEx reason]];
		[self errorMsg:msg];
	}
	@finally {
		//
	}
	return NO;
}


#pragma mark - Loading

static unsigned long csvLineOffset = 0;
// zBoard の位置 csvLineOffset から1行分をCSV区切りで分割して aStrings にセットする。
static long csvLineSplit(NSString *zBoard, NSMutableArray *aStrings)
{
	//
	BOOL bDQSection = NO; // YES:["]ダブルクォーテーションで囲まれた文字列区間
	NSString *z1 = nil; // 1文字
	NSString *str;
	unsigned long uiEnd = [zBoard length];
	unsigned long uiStart = csvLineOffset; // 行の開始位置
	long lSplitCount = -1; // (>0)分割して得られた項目数　(0)空白行　(-1)EOF　(-2)ERROR
	// 全クリア
	[aStrings removeAllObjects]; 
	// 1文字づつチェックしながら1行を切り出す
	while (1) 
	{
//if (csvLineOffset==2234) {
//	AzLOG(@"2234");
//}
		if (csvLineOffset < uiEnd) {
			//if (z1) [z1 release];
			z1 = [zBoard substringWithRange:NSMakeRange(csvLineOffset++, 1)];
			//AzLOG(@"z1 retainCount = %d", [z1 retainCount]);
		} else {
			// zBoard 終端処理
			if (uiStart < csvLineOffset) {
				str = [zBoard substringWithRange:NSMakeRange(uiStart, csvLineOffset - uiStart)];
				[aStrings addObject:str]; //[str release];
				lSplitCount++;
				uiStart = uiEnd; //完了
			}
			break; //完了
		}

		//if ([z1 length] != 1) {
		//	AzLOG(@"Break1");
		//	break;	// 終端
		//}
		
		// ["]文字列区間にある[改行]や[,]を無視するための処理
		if ([z1 isEqualToString:@"\""]) {
			if (bDQSection) {
				// 末尾の["]を除いて抜き出す
				str = [zBoard substringWithRange:NSMakeRange(uiStart, csvLineOffset-1-uiStart)];
				[aStrings addObject:str]; //[str release];
				lSplitCount++;
				// [,]or[改行]まで飛ぶ　＜＜万一、末尾の["]と[,]or[改行]の間に文字があった場合に備えて。
				while (1) {
					//if (z1) [z1 release];
					z1 = [zBoard substringWithRange:NSMakeRange(csvLineOffset++, 1)];
					if ([z1 isEqualToString:@","]) {
						break; // 次の項目へ
					} else if ([z1 isEqualToString:@"\n"]) {
						csvLineOffset--; // [改行]位置に戻し、次で行末であることを判定させる
						break;
					}
				}
				uiStart = csvLineOffset;
			} else {
				// 先頭の["]を除く
				uiStart = csvLineOffset; // 最初の["]を除いた次の文字を先頭とする
			}
			bDQSection = !bDQSection; // ["]区間判定　トグルになる
		}
		else if (!bDQSection) {
			// 文字列区間でないところ
			if ([z1 isEqualToString:@","]) {
				// [,]があれば区切りである
				str = [zBoard substringWithRange:NSMakeRange(uiStart, csvLineOffset-1-uiStart)];
				[aStrings addObject:str]; //[str release];
				lSplitCount++;
				uiStart = csvLineOffset;
			}
			else if ([z1 isEqualToString:@"\n"]) {
				// [改行]があれば行末と判断する　　[0.5.3]不具合："Begin"行に[,]が無いため読めなかった。
				str = [zBoard substringWithRange:NSMakeRange(uiStart, csvLineOffset-1-uiStart)];
				[aStrings addObject:str]; //[str release];
				lSplitCount++;
				uiStart = csvLineOffset;
				break; // 行末につき1行抜き出し完了
			}
		} 
	}

	//if (z1) [z1 release];
	
	if (0 <= lSplitCount) lSplitCount++; // 最初(-1)だから(0)以上ならば(+1)して要素数に変換する。

	for (int i = [aStrings count]; i < 10; i++) { // 10 ＜＜最大項目数！項目を増設したとき要注意！
		[aStrings addObject:@""]; //補助項目が無くて[改行]で終わった場合でも最大項目を保持しておく。読み出したときエラーにならないように。
	}

#ifdef xxxDEBUG
	for (int i = 0; i < [aStrings count]; i++) {
		AzLOG(@"csvLineSplit[%d]=[%@]", i, [aStrings objectAtIndex:i]);
	}
	AzLOG(@"csvLineSplit()=%d", lSplitCount);
#endif

	return lSplitCount;
}

- (E1 *)zLoadPrivate:(NSString *)PzCsv  withSave:(BOOL)PbSave // NO=共有プラン詳細表示時、SAVEせずにRollBackするために使用。
{
	NSManagedObjectContext *moc = [EntityRelation getMoc];
	NSInteger iErrLine = 0;
	E1 *e1node = nil;
	E2 *e2node = nil;
	NSInteger e2row = 0;  // CSV読み込み順に連番付与する
	NSInteger e3row = 0;
	NSMutableArray *aSplit = [NSMutableArray new];  // @finallyにて [aSplit release]
	csvLineOffset = 0;
	@try {
		iErrLine = 0;
		//----------------------------------------------------------------------[HEADER]
		iErrLine++;
		//[1.0]"AzPacking,CSV,UTF-8,Copyright,(C)2011,Azukid,,,\n";
		//[1.1]"AzPacking,UTF-8,CSV,4,,,Copyright,(C)2011,Azukid,,\n"
		while (1) { 
			iErrLine++;
			if (csvLineSplit(PzCsv, aSplit) < 0 OR 10 < iErrLine) { // 10行以内に無ければ中断
				@throw NSLocalizedString(@"Err CsvHeaderNG",nil);
			}
			if ([[aSplit objectAtIndex:0] isEqualToString:GD_CSV_HEADER_ID]) {
				break; // OK
			} 
		}
		
		//----------------------------------------------------------------------[Begin]
		//[1.0] "Begin,"
		while (1) { 
			iErrLine++;
			if (csvLineSplit(PzCsv, aSplit) < 0 OR 10 < iErrLine) { // 10行以内に無ければ中断
				@throw NSLocalizedString(@"Err CsvHeaderNG",nil);
			}
			if ([[aSplit objectAtIndex:0] isEqualToString:@"Begin"]) {
				break; // OK
			} 
		}
		
		//----------------------------------------------------------------------[Plan]
		//[1.0] " ,name,note,"
		//[1.0] "0,   1,   2,"
		while (1) { 
			iErrLine++;
			if (csvLineSplit(PzCsv, aSplit) < 0 OR 10 < iErrLine) { // 10行以内に無ければ中断
				@throw NSLocalizedString(@"Err CsvHeaderNG",nil);
			}
			if ([[aSplit objectAtIndex:0] isEqualToString:@""] && ![[aSplit objectAtIndex:1] isEqualToString:@""]) {
				break; // OK                                      ↑notです！
			} 
		}
		//-----------------------------------------------E1.row の最大値を求める
		NSInteger maxRow = [EntityRelation E1_maxRow];
		//-----------------------------------------------E1
		// ContextにE1ノードを追加する　ERROR発生すれば、RollBackしている
		e1node = [NSEntityDescription insertNewObjectForEntityForName:@"E1" inManagedObjectContext:moc];
		//-----------------------------------------------
		e1node.row  = [NSNumber numberWithInteger:1 + maxRow];
		e1node.name = [aSplit objectAtIndex:1];  //csvToStr([aSplit objectAtIndex:1]);
		e1node.note = [aSplit objectAtIndex:2];
		//-----------------------------------------------
		e2row = 0;
		e2node = nil;
		
		while (1) 
		{
			iErrLine++;
			//if (csvLineSplit(PzCsv, aSplit) < 0) {
			//	//[0.5.3]空白行に対応：行末やエラー発生時に中断
			//	@throw NSLocalizedString(@"Err CsvHeaderNG",nil);
			//}
			// [0.7.3] "End,,,," が無いケースに対応
			long lCount = csvLineSplit(PzCsv, aSplit);
			if (lCount == -1) {	// EOF
				break;
			}
			else if	(lCount < -1) {	// ERROR
				@throw NSLocalizedString(@"Err CsvHeaderNG",nil);
			}
			//lCount==0 : 空白行
			
			//----------------------------------------------------------------------[Group] E2
			//[1.0] " , ,name,note,"
			//[1.0] "0,1,   2,   3,"
			else if ([[aSplit objectAtIndex:0] isEqualToString:@""] 
					 && [[aSplit objectAtIndex:1] isEqualToString:@""] 
					 && ![[aSplit objectAtIndex:2] isEqualToString:@""]) // 最後だけ ! NOT
			{
				// トリム（両端のスペース除去）　＜＜Load時に zNameで検索するから厳密にする＞＞
				NSString *zName = [[aSplit objectAtIndex:2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				if (![zName isEqualToString:@""])
				{ // zNameが有効
					e2node = [NSEntityDescription insertNewObjectForEntityForName:@"E2" inManagedObjectContext:moc];
					//-----------------------------------------------
					e2node.row		= [NSNumber numberWithInteger:e2row++];
					e2node.name		= zName; // csvToStr()後にトリム済み
					e2node.note		= [aSplit objectAtIndex:3];
					//-----------------------------------------------
					[e1node addChildsObject:e2node];
					e3row = 0;
				}
			} 
			//--------------------------------------------------------------------------------[Item] E3
			//[1.0] [  ,  ,   ,"name","note",stock,need,weight,]
			//[1.0] [0,1,2,          3,         4,       5,      6,         7,]
			//[1.1] [  ,  ,   ,"name","note",stock,need,weight,"shopKeyword","shopNote",]
			//[1.1] [0,1,2,          3,         4,       5,      6,         7,                       8,                 9,]
			else if (e2node
					 && [[aSplit objectAtIndex:0] isEqualToString:@""] 
					 && [[aSplit objectAtIndex:1] isEqualToString:@""] 
					 && [[aSplit objectAtIndex:2] isEqualToString:@""]) // 3桁ともヌル
			{
				NSString *zName = [[aSplit objectAtIndex:3] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				if (![zName isEqualToString:@""]) 
				{ // zNameが有効
					E3 *e3node = [NSEntityDescription insertNewObjectForEntityForName:@"E3" inManagedObjectContext:moc];
					e3node.row		= [NSNumber numberWithInteger:e3row++];
					e3node.name				= zName;
					e3node.note				= [aSplit objectAtIndex:4];
					//-----------------------------------------------E3:冗長計算処理
					NSInteger iStock	= [[aSplit objectAtIndex:5] integerValue];
					NSInteger iNeed		= [[aSplit objectAtIndex:6] integerValue];
					NSInteger iWeight	= [[aSplit objectAtIndex:7] integerValue];
					e3node.stock		= [NSNumber numberWithInteger:iStock];
					e3node.need			= [NSNumber numberWithInteger:iNeed];
					e3node.weight		= [NSNumber numberWithInteger:iWeight];
					e3node.weightStk	= [NSNumber numberWithInteger:(iWeight * iStock)];
					e3node.weightNed	= [NSNumber numberWithInteger:(iWeight * iNeed)];
					e3node.lack			= [NSNumber numberWithInteger:(iNeed - iStock)];
					e3node.weightLack	= [NSNumber numberWithInteger:((iNeed - iStock) * iWeight)];
					//-----------------------------------------------
					if (0 < iNeed)
						e3node.noGray = [NSNumber numberWithInteger:1];
					else
						e3node.noGray = [NSNumber numberWithInteger:0];
					//-----------------------------------------------
					if (0 < iNeed && iStock < iNeed)
						e3node.noCheck = [NSNumber numberWithInteger:1];
					else
						e3node.noCheck = [NSNumber numberWithInteger:0];
					//-----------------------------------------------
					[e2node addChildsObject:e3node];
					//-----------------------------------------------
					//[1.1]
					if (8 < [aSplit count]) {
						e3node.shopKeyword	= [aSplit objectAtIndex:8];
					}
					if (9 < [aSplit count]) {
						e3node.shopNote		= [aSplit objectAtIndex:9];
					}
				}
			} 
			//--------------------------------------------------------------------------------[End]
			// "End,"
			else if (![[aSplit objectAtIndex:0] isEqualToString:@""]) // [0]がヌルで無い場合全て
			{
				break; // LOOP OUT
			}
		} //while(1)
		
		if (e1node) {
			for (e2node in e1node.childs) {
				// E2 sum属性　＜高速化＞ 親sum保持させる
				[e2node setValue:[e2node valueForKeyPath:@"childs.@sum.noGray"] forKey:@"sumNoGray"];
				[e2node setValue:[e2node valueForKeyPath:@"childs.@sum.noCheck"] forKey:@"sumNoCheck"];
				[e2node setValue:[e2node valueForKeyPath:@"childs.@sum.weightStk"] forKey:@"sumWeightStk"];
				[e2node setValue:[e2node valueForKeyPath:@"childs.@sum.weightNed"] forKey:@"sumWeightNed"];
			}
			
			// E1 sum属性　＜高速化＞ 親sum保持させる
			[e1node setValue:[e1node valueForKeyPath:@"childs.@sum.sumNoGray"] forKey:@"sumNoGray"];
			[e1node setValue:[e1node valueForKeyPath:@"childs.@sum.sumNoCheck"] forKey:@"sumNoCheck"];
			[e1node setValue:[e1node valueForKeyPath:@"childs.@sum.sumWeightStk"] forKey:@"sumWeightStk"];
			[e1node setValue:[e1node valueForKeyPath:@"childs.@sum.sumWeightNed"] forKey:@"sumWeightNed"];
			
			if (PbSave) {
				// 保存する
				NSError *err = nil;
				if (![moc save:&err]) {
					// 保存失敗
					NSString *msg = [NSString stringWithFormat:@"Moc save error: %@", [err localizedDescription]];
					NSLog(@"Unresolved error %@", msg);
					@throw msg;
				}
			}
			return e1node; // OK
		}
		else {
			// Endが無い ＆ [Plan]も無い
			@throw @"No End";
		}
	} //@try
	@catch (NSString *errMsg) {
		[self errorMsg:errMsg];
		if (e1node) {
			[moc rollback];
			//rollbackで十分//[moc deleteObject:e1node]; // insertNewObjectForEntityForNameしたEntityを削除する
			e1node = nil;
		}
	}
	@catch (NSException *errEx) {
		NSString *msg = [NSString stringWithFormat:@"zLoad: NSException: %@: %@", [errEx name], [errEx reason]];
		[self errorMsg:msg];
		if (e1node) {
			[moc rollback];
			//rollbackで十分//[moc deleteObject:e1node]; // insertNewObjectForEntityForNameしたEntityを削除する
			e1node = nil;
		}
	}
	//@finally {
	//	[aSplit release];
	//}	
	return nil; // NG
}

- (E1 *)zLoad:(NSString *)PzCsv  withSave:(BOOL)PbSave // NO=共有プラン詳細表示時、SAVEせずにRollBackするために使用。
{
	//--------------------------------------------------------------------------------Crypt Headerチェック
	if ([PzCsv hasPrefix:CRYPT_HEADER]) {
		// PzCsv から CRYPT_HEADER を取り除く
		PzCsv = [PzCsv substringFromIndex:[CRYPT_HEADER length]];
		//----------------------------------------------------------------------------Crypt 復号化
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		if ([userDefaults boolForKey:UD_OptCrypt]) {
			// KeyChainから保存しているパスワードを取得する
			NSError *error; // nilを渡すと異常終了するので注意
			NSString *secKey = [SFHFKeychainUtils getPasswordForUsername:UD_OptCrypt
														  andServiceName:GD_PRODUCTNAME error:&error];
			if (2 < [secKey length]) {
				// 復号
				NSData *data = [NSData dataWithBase64String:PzCsv];	// NSString(Base64) --> NSData
				NSData *plain = [data AES256DecryptWithKey:secKey];	// 復号化
				 PzCsv = [[NSString alloc] initWithData:plain encoding:NSUTF8StringEncoding]; //-->NSString
				NSLog(@"FileCsv: zLoad: Crypt PzCsv=%@", PzCsv);
			} else {
				[self errorMsg:NSLocalizedString(@"PackListCrypt NoKey",nil)];
				return nil;
			}
		} else {
			[self errorMsg:NSLocalizedString(@"PackListCrypt NoKey",nil)];
			return nil;
		}
		// 復号後のヘッダーチェック
		if ([PzCsv hasPrefix:GD_CSV_HEADER_ID]==NO) {
			[self errorMsg:NSLocalizedString(@"PackListCrypt NoDecrypted",nil)];
			return nil;
		}
	}
	//--------------------------------------------------------------------------------CSV 読み込み
	@autoreleasepool {
		return [self zLoadPrivate:PzCsv withSave:PbSave];
	}
	return nil;
}

// Mail添付ファイルを読み込むため
- (BOOL)zLoadURL:(NSURL*)Url
{
	NSError *err = nil;
	NSString *zCsv = [NSString stringWithContentsOfURL:Url encoding:NSUTF8StringEncoding error:&err];
	if (err) {
		[self errorMsg:[err localizedDescription]];
		return NO;
	}
	//NSLog(@"zCsv=%@", zCsv);
	E1 *e1add = nil;
	if (zCsv) {
		e1add = [self zLoad:zCsv  withSave:YES];
	}
	if (e1add) return YES;
	return NO;
}

//- (NSString *)zLoadPath:(NSString *)PzFillPath  //==nil:PasteBoardから読み込む
- (BOOL)zLoadTmpFile
{
	if (tmpPathFile_==nil) {
		[self errorMsg:@"tmpPathFile_=nil"];
		return NO;
	}

	NSString *zCsv = nil;
	// input OPEN
	NSFileHandle *csvHandle = [NSFileHandle fileHandleForReadingAtPath:tmpPathFile_];
	if (csvHandle==nil) {
		[self errorMsg:@"zLoadTmpFile:NG Read open"];
		return NO;
	}
	// バイナリファイル対策：先頭で強制判定
	@try {
		[csvHandle seekToFileOffset:0];
		NSData *data = [csvHandle readDataOfLength:[GD_CSV_HEADER_ID length]*3];
		if ([data length] != [GD_CSV_HEADER_ID length]*3) {
			[self errorMsg:@"zLoadTmpFile:NG Header length"];
			return NO;
		}
		NSString *csvStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		if (![csvStr hasPrefix:GD_CSV_HEADER_ID]) {	// Plain Header
			if (![csvStr hasPrefix:CRYPT_HEADER]) {		// Crypt Header
				// 先頭部分が一致しない
				[self errorMsg:@"zLoadTmpFile:NG Header ID"];
				return NO;
			}
		}
		// 先頭へ戻す
		[csvHandle seekToFileOffset:0];
		data = [csvHandle readDataToEndOfFile];  // ファイルの終わりまでデータを読んで返す
		zCsv = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		E1 *e1add = nil;
		if (zCsv) {
			e1add = [self zLoad:zCsv   withSave:YES];
		}
		if (e1add) return YES;
		return NO;
	}
	@catch(id error) {
		[self errorMsg:NSLocalizedString(@"File error",nil)];
	}
	@catch (NSException *errEx) {
		NSString *msg = [NSString stringWithFormat:@"zLoadTmpFile: NSException: %@: %@", [errEx name], [errEx reason]];
		[self errorMsg:msg];
	}
	@finally {
		[csvHandle closeFile];
	}
	return NO;
}

- (BOOL)zLoadPasteboard
{
	NSString *zCsv = nil;
	if ([[UIPasteboard generalPasteboard].string length] < 15) {
		[self errorMsg:NSLocalizedString(@"Pasteboard is empty",nil)];
		return NO;
	}
	// PasteBoard からペーストする
	zCsv = [[NSString alloc] initWithString:[UIPasteboard generalPasteboard].string];  // 共有領域
	
	E1 *e1add = nil;
	if (zCsv) {
		e1add = [self zLoad:zCsv   withSave:YES];
	}
	if (e1add) return YES;
	return NO;
}


@end
