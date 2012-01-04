//
//  FileCsv.m
//  AzPacking
//
//  Created by 松山 和正 on 10/03/01.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Global.h"
#import "AppDelegate.h"
#import "Elements.h"
#import "EntityRelation.h"
#import "FileCsv.h"


@implementation FileCsv

// CSV形式　　["]で囲まれた文字列に限り、その中に[,]と[改行]を使用可能。
//           書き込み(SAVE)時に文字列中の["]は[']に置き換えられる。

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


+ (NSString *)zSave:(E1 *)Pe1 
	toLocalFileName:(NSString *)PzFname //==nil:PasteBoardへ書き出す
{
	@autoreleasepool {
		NSMutableString *zCsv = [NSMutableString new];
		NSString *err = [FileCsv zSave:Pe1 toMutableString:zCsv];
		if (err == nil) {
			if (PzFname) { // ファイル出力
				NSString *home_dir = NSHomeDirectory();
				NSString *doc_dir = [home_dir stringByAppendingPathComponent:@"tmp"];
				NSString *csvPath = [doc_dir stringByAppendingPathComponent:PzFname]; //GD_CSVFILENAME or GD_CSVFILENAME4
				// UTF-8 出力ファイルをCREATE
				[[NSFileManager defaultManager] createFileAtPath:csvPath contents:nil attributes:nil];
				// UTF-8 出力ファイルをOPEN
				NSFileHandle *output = [NSFileHandle fileHandleForWritingAtPath:csvPath];
				if (output) {
					@try {
						// UTF8 エンコーディングしてファイルへ書き出す
						[output writeData:[zCsv dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
					}
					@catch(id error) {
						// File size too small.
						err = NSLocalizedString(@"File error",nil);
					}
					@finally {
						[output closeFile];
					}
				} else {
					err = NSLocalizedString(@"File error",nil);
				}
			} else {
				// PasteBoard出力
				[UIPasteboard generalPasteboard].string = zCsv;  // 共有領域にコピーされる
			}
		}
		//[zCsv release];
		return err;
	}
}

+ (NSString *)zSave:(E1 *)Pe1 
	toMutableString:(NSMutableString *)PzCsv
{
	@autoreleasepool {
		NSParameterAssert(PzCsv);
		NSString *zErrMsg = NSLocalizedString(@"File write error",nil);
		
		// E2, E3 Sort  "row"
		NSSortDescriptor *key1 = [[NSSortDescriptor alloc] initWithKey:@"row" ascending:YES];
		NSArray *sortRow = [[NSArray alloc] initWithObjects:key1, nil];  
		//[key1 release];
		//	NSMutableString *zBoard = [NSMutableString new];
		// 以上 @finally にて release
		NSString *str;
		
		@try {
			//----------------------------------------------------------------------------Header
			//str = GD_PRODUCTNAME  @",CSV,UTF-8,Copyright,(C)2011,Azukid,,,\n";
			//[1.1.0]これまでLoad時には、GD_PRODUCTNAME だけ比較チェックしている。
			//[1.1.0],CSV,の次に,4,を追加。 4 は、xcdatamodel 4 を示している。　　近未来JSON対応すれば、,CSV,⇒,JSON, とする。
			str = GD_PRODUCTNAME  @",UTF-8,CSV,4,,,Copyright,(C)2011,Azukid,,\n";
			[PzCsv appendString:str];
			
			//----------------------------------------------------------------------------Structure
			
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
			zErrMsg = nil;  // Compleat!
		}
		@catch (NSException *errEx) {
			NSString *name = [errEx name];
			AzLOG(@"Err: %@ : %@\n", name, [errEx reason]);
			if ([name isEqualToString:NSRangeException])
				NSLog(@"Exception was caught successfully.\n");
			else
				[errEx raise];
		}
		@finally {
			// release
			//[sortRow release];
		}
		return zErrMsg;
	}
}


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

+ (NSString *)zLoadURL:(NSURL*)Url
{
	NSError *err = nil;
	//NSString *zCsv = [[NSString alloc] initWithContentsOfURL:Url encoding:NSUTF8StringEncoding error:&err];
	NSString *zCsv = [NSString stringWithContentsOfURL:Url encoding:NSUTF8StringEncoding error:&err];
	if (err) {
		return [err localizedDescription];
	}
	//NSLog(@"zCsv=%@", zCsv);
	E1 *e1add = nil;
	if (zCsv) {
		e1add = [FileCsv zLoad:zCsv
					  withSave:YES
						 error:&err];
	}
	//[zCsv release];
	if (e1add==nil) return @"No Data";
	return [err localizedDescription];
}

// Pe1 を生成し、Pe1.row をセットしてから呼び出すこと。
// <HOME/tmp/PzFname>
+ (NSString *)zLoad:(NSString *)PzFname  //==nil:PasteBoardから読み込む
{
	NSString *doc_dir = [NSHomeDirectory() stringByAppendingPathComponent:@"tmp"]; // @"Documents"];
	NSString *zFullPath = [doc_dir stringByAppendingPathComponent:PzFname];  //GD_CSVFILENAME or GD_CSVFILENAME4	
	return [FileCsv zLoadPath:zFullPath];
}

+ (NSString *)zLoadPath:(NSString *)PzFillPath  //==nil:PasteBoardから読み込む
{
	@autoreleasepool {
		NSString *zCsv = nil;
		
		if (PzFillPath) {
			// input OPEN
			NSFileHandle *csvHandle = [NSFileHandle fileHandleForReadingAtPath:PzFillPath];
			// バイナリファイル対策：先頭で強制判定
			if (csvHandle) {
				@try {
					[csvHandle seekToFileOffset:0];
					NSData *data = [csvHandle readDataOfLength:[GD_PRODUCTNAME length]*3];
					if ([data length] != [GD_PRODUCTNAME length]*3) {
						[csvHandle closeFile];
						// File size too small.
						//[methodPool release];
						return NSLocalizedString(@"File error",nil);
					}
					NSString *csvStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
					if (![csvStr hasPrefix:GD_PRODUCTNAME]) { 
						// 先頭部分が一致しない
						//[csvStr release];
						[csvHandle closeFile];
						//[methodPool release];
						return [NSString stringWithFormat:NSLocalizedString(@"This is not a %@ file",nil), GD_CSVFILENAME4];
					}
					//[csvStr release];
					// 先頭へ戻す
					[csvHandle seekToFileOffset:0];
					data = [csvHandle readDataToEndOfFile];  // ファイルの終わりまでデータを読んで返す
					zCsv = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
				}
				@catch(id error) {
					//[methodPool release];
					return NSLocalizedString(@"File error",nil);
				}
				@finally {
					[csvHandle closeFile];
				}
			} else {
				//[methodPool release];
				return NSLocalizedString(@"No File",nil);
			}
		}
		else if (5 < [[UIPasteboard generalPasteboard].string length]) {
			// PasteBoard からペーストする
			zCsv = [[NSString alloc] initWithString:[UIPasteboard generalPasteboard].string];  // 共有領域
		}
		else {
			//[methodPool release];
			return NSLocalizedString(@"Pasteboard is empty",nil);
		}
		
		//NSString *err = @"No Data";
		NSError *err = nil;
		E1 *e1add = nil;
		if (zCsv) {
			e1add = [FileCsv zLoad:zCsv
						  withSave:YES
							 error:&err];
		}
		//[zCsv release];
		if (e1add==nil) return @"No Data";
		return [err localizedDescription];
	}
}

+ (E1 *)zLoad:(NSString *)PzCsv
	 withSave:(BOOL)PbSave		// NO=共有プラン詳細表示時、SAVEせずにRollBackするために使用。
		error:(NSError **)Perror;
{
	@autoreleasepool {
		NSManagedObjectContext *moc = managedObjectContext();
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
			//[1.0]"AzPacking,CSV,UTF-8,Copyright,(C)2011,Azukid,,,\n";
			//[1.1]"AzPacking,UTF-8,CSV,4,,,Copyright,(C)2011,Azukid,,\n"
			while (1) { 
				iErrLine++;
				if (csvLineSplit(PzCsv, aSplit) < 0 OR 10 < iErrLine) { // 10行以内に無ければ中断
					@throw NSLocalizedString(@"Err CsvHeaderNG",nil);
				}
				if ([[aSplit objectAtIndex:0] isEqualToString:GD_PRODUCTNAME]) {
					break; // OK
				} 
			}
			/***** 近未来予定
			 if ([[aSplit objectAtIndex:2] isEqualToString:@"JSON"]) {
			 // JSON 対応
			 }
			 int iModelVersion = [[aSplit objectAtIndex:3] intValue];
			 *****/
			
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
			
			if (*Perror==nil && e1node) {
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
						if (e1node) {
							[moc rollback];
							//rollbackで十分//[moc deleteObject:e1node]; // insertNewObjectForEntityForNameしたEntityを削除する
							e1node = nil;
						}
						AzLOG(@"Unresolved error %@, %@", err, [err userInfo]);
						//if (!(*PpzErr)) *PpzErr = NSLocalizedString(@"CoreData failed to save.", @"CoreData 保存失費");
						if (!(*Perror)) {
							NSDictionary *dic = [[NSDictionary alloc] initWithObjectsAndKeys:
												 NSLocalizedString(@"CoreData failed to save.",nil), @"NSLocalizedDescriptionKey", nil];
							*Perror = [NSError errorWithDomain:NSCocoaErrorDomain code:1000 userInfo:dic];
							//[dic release];
						}
					}
					else {
						// 保存成功
					}
				}
			}
			else {
				// Endが無い ＆ [Plan]も無い
				if (e1node) {
					[moc rollback];
					//rollbackで十分//[moc deleteObject:e1node]; // insertNewObjectForEntityForNameしたEntityを削除する
					e1node = nil;
				}
				//if (!(*PpzErr)) *PpzErr = NSLocalizedString(@"No file content.", @"CSV内容なし");
				if (!(*Perror)) {
					NSDictionary *dic = [[NSDictionary alloc] initWithObjectsAndKeys:
										 NSLocalizedString(@"No file content.",nil), @"NSLocalizedDescriptionKey", nil];
					*Perror = [NSError errorWithDomain:NSCocoaErrorDomain code:1000 userInfo:dic];
					//[dic release];
				}
			}
		} //@try
		@catch (NSException *errEx) {
			if (e1node) {
				[moc rollback];
				//rollbackで十分//[moc deleteObject:e1node]; // insertNewObjectForEntityForNameしたEntityを削除する
				e1node = nil;
			}
			if (!(*Perror)) {
				//*PpzErr = NSLocalizedString(@"File read error",nil);
				NSDictionary *dic = [[NSDictionary alloc] initWithObjectsAndKeys:
									 NSLocalizedString(@"File read error",nil), @"NSLocalizedDescriptionKey", nil];
				*Perror = [NSError errorWithDomain:NSCocoaErrorDomain code:1000 userInfo:dic];
				//[dic release];
			}
			NSString *name = [errEx name];
			AzLOG(@"◆ %@ : %@\n", name, [errEx reason]);
			if ([name isEqualToString:NSRangeException]) {
				AzLOG(@"Exception was caught successfully.\n");
			} else {
				[errEx raise];
			}
		}
		@catch (NSString *errMsg) {
			if (e1node) {
				[moc rollback];
				//rollbackで十分//[moc deleteObject:e1node]; // insertNewObjectForEntityForNameしたEntityを削除する
				e1node = nil;
			}
			//*PpzErr = [NSString stringWithFormat:@"FileCsv (%ld) %@", iErrLine, errMsg];
			if (!(*Perror)) {
				NSDictionary *dic = [[NSDictionary alloc] initWithObjectsAndKeys:
									 [NSString stringWithFormat:@"FileCsv (%ld) %@", iErrLine, errMsg], @"NSLocalizedDescriptionKey", nil];
				*Perror = [NSError errorWithDomain:NSCocoaErrorDomain code:1000 userInfo:dic];
				//[dic release];
			}
		}
		@finally {
			//[aSplit release];
		}	
		return e1node; // moc(Entity)インスタンス
	}
}


@end
