//
//  AzPackCsv.m
//  AzPacking
//
//  Created by 松山 和正 on 10/01/28.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Global.h"
#import "Elements.h"
#import "AzPackCsv.h"

@implementation AzPackCsv
@synthesize PmanagedObjectContext, Pe1selected, Pe1rows;


- (void)dealloc 
{
	[Pe1selected release];
	[PmanagedObjectContext release];
	[super dealloc];
}

- (id)initWithManagedObject:(NSManagedObjectContext *)mobj 
				 E1selected:(E1 *)e1obj 
					 E1rows:(NSInteger)e1rows
{
	if (self = [super init]) {
		PmanagedObjectContext = [mobj retain];
		Pe1selected = [e1obj retain];
		Pe1rows = e1rows;
	}
	
	NSString *err;
	if (Pe1selected == nil && 0 <= Pe1rows) {
		// READ
		err = [self csvRead];
	}
	else if (Pe1selected != nill && Pe1rows < 0) {
		// WRITE
		err = [self csvWrite];
	}
	return self;
}


// csvWrite:
- (NSString *)writeStr:(NSString *)inStr {
	if ([inStr length]) {
		return [inStr stringByReplacingOccurrencesOfString:@"\""  withString:@"'"];  // ["]-->>[']
	}
	return @"";
}

//////////////////////////////////////////////////////////////////////////////////
- (NSString *)csvWrite  // managedObjectContext から Local File へ書き出す
{
	NSString *zErrMsg = NSLocalizedString(@"File write error", @"内部障害:ファイル書き込み失敗");
	NSString *home_dir = NSHomeDirectory();
	NSString *doc_dir = [home_dir stringByAppendingPathComponent:@"Documents"];
	NSString *csvPath = [doc_dir stringByAppendingPathComponent:GD_CSVFILENAME]; // ローカルファイル名
	
	// 出力するファイルをCREATE
	[[NSFileManager defaultManager] createFileAtPath:csvPath contents:nil attributes:nil];
	// 出力するファイルをOPEN
	NSFileHandle *output = [NSFileHandle fileHandleForWritingAtPath:csvPath];
	
	NSMutableString *mstr = [[NSMutableString alloc] initWithCapacity:512];
	//	NSString *z1;  // NSString型で nil のとき @"" に置き換えるために使用
	//	NSString *z2;
	//	NSString *z3;
	
	// Order By [.row] 昇順に書き出すため　＜＜NSManagedObjectContextは順不同である＞＞
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"row" ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:&sortDescriptor count:1];
	
	// ループ
	@try {
		NSString *str;
		NSStringEncoding enc = NSUTF8StringEncoding; //(NSStringEncoding)[NSString availableStringEncodings];
		
		//----------------------------------------------------------------------------Header
		str = GD_PRODUCTNAME  @",CSV,UTF-8,Copyright,(C)2010,Azukid.com,,,\n";
		[output writeData:[str dataUsingEncoding:enc allowLossyConversion:YES]];
		
		// NSUTF8StringEncoding    NSASCIIStringEncoding   availableStringEncodings
		//dat =[str1 dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]; 
		
		//----------------------------------------------------------------------------Structure
		str = @"Structure,,,,,,,,\n";
		[output writeData:[str dataUsingEncoding:enc allowLossyConversion:YES]];
		
		str = @"[Plan],name,note,,,,,,\n";
		[output writeData:[str dataUsingEncoding:enc allowLossyConversion:YES]];
		
		// str = @"[Group],,row,name,note,,,,,\n";
		str = @"[Group],,name,note,,,,,\n";  // rowは自動連番付与する
		[output writeData:[str dataUsingEncoding:enc allowLossyConversion:YES]];
		
		//str = @"[Item],,,row,name,spec,stock,required,weight,note\n";
		str = @"[Item],,,name,spec,stock,required,weight,note\n";  // rowは自動連番付与する
		[output writeData:[str dataUsingEncoding:enc allowLossyConversion:YES]];
		
		str = @"Begin,,,,,,,,\n";
		[output writeData:[str dataUsingEncoding:enc allowLossyConversion:YES]];
		
		//----------------------------------------------------------------------------E1 [Plan]
		// [Plan] ,name,note,,,,,,
		//		if ([self.e1selected.name length]) z1 = self.e1selected.name;	else z1 = @"";
		//		if ([self.e1selected.note length]) z2 = self.e1selected.note;	else z2 = @"";
		//		[z1 replaceOccurrencesOfString: @"\""  withString: @"'"];
		//		[mstr setString:@""];
		//		[mstr appendFormat:@",\"%@\",\"%@\",\n", [self writeStr:self.e1selected.name],
		//												 [self writeStr:self.e1selected.note]];
		//		AzLOG(@"E1> %@", mstr);
		//		[output writeData:[mstr dataUsingEncoding:enc allowLossyConversion:YES]];
		
		str = [NSString stringWithFormat:@",\"%@\",\"%@\",\n", 
			   [self writeStr:self.Pe1selected.name],
			   [self writeStr:self.Pe1selected.note]];
		AzLOG(@"E1> %@", str);
		[output writeData:[str dataUsingEncoding:enc allowLossyConversion:YES]];
		
		//------------------------------------------------------------------------------E2 [Group]
		NSMutableArray *e2list = [[NSMutableArray alloc] initWithArray:[self.Pe1selected.childs allObjects]];
		[e2list sortUsingDescriptors:sortDescriptors];	// .row 昇順にCSV書き出す
		for (E2 *e2obj in e2list) {
			
			// [Group] ,,name,note,,,,,
			//			if ([e2obj.name length]) z1 = e2obj.name;	else z1 = @"";
			//			if ([e2obj.note length]) z2 = e2obj.note;	else z2 = @"";
			[mstr setString:@""];
			[mstr appendFormat:@",,\"%@\",\"%@\",\n",	[self writeStr:e2obj.name], 
			 [self writeStr:e2obj.note]];
			AzLOG(@"E2> %@", mstr);
			[output writeData:[mstr dataUsingEncoding:enc allowLossyConversion:YES]];
			
			//----------------------------------------------------------------------------E3 [Item]
			NSMutableArray *e3list = [[NSMutableArray alloc] initWithArray:[e2obj.childs allObjects]];
			[e3list sortUsingDescriptors:sortDescriptors];	// .row 昇順にCSV書き出す
			for (E3 *e3obj in e3list) {
				
				// [Item] ,,,name,spec,stock,required,weight,note
				//				if ([e3obj.name length]) z1 = e3obj.name;	else z1 = @"";
				//				if ([e3obj.spec length]) z2 = e3obj.spec;	else z2 = @"";
				//				if ([e3obj.note length]) z3 = e3obj.note;	else z3 = @"";
				[mstr setString:@""];
				[mstr appendFormat:@",,,\"%@\",\"%@\",%ld,%ld,%ld,\"%@\",\n", 
				 [self writeStr:e3obj.name], 
				 [self writeStr:e3obj.spec], 
				 [e3obj.stock longValue], 
				 [e3obj.required longValue], 
				 [e3obj.weight longValue], 
				 [self writeStr:e3obj.note]];
				AzLOG(@"E3> %@", mstr);
				[output writeData:[mstr dataUsingEncoding:enc allowLossyConversion:YES]];
			}
			[e3list release];
		}
		// release
		[e2list release];
		//----------------------------------------------------------------------------End
		str = @"End,,,,,,,,\n";
		AzLOG(@"End> %@", str);
		[output writeData:[str dataUsingEncoding:enc allowLossyConversion:YES]];
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
        // CLOSE
		[output closeFile];
		// release
		[sortDescriptor release];
		[sortDescriptors release];
		[mstr release];
	}
	return zErrMsg;
}

// csvRead:muStrucに従って文字列項目を取得する（文字列マーク["]があれば除外する  シングル[']は許可）
- (NSString *)csvString:(NSMutableArray *)muStruc csvLine:(NSArray *)arLine csvCol:(NSString *)zColName {
	NSInteger ui = [muStruc indexOfObject:zColName];
	if (ui != NSNotFound) {
		NSString *zz = [arLine objectAtIndex:ui];
		if ([zz hasPrefix:@"\""]) // 先頭文字が["]ならば先頭と末尾の["]を除外する
			return  [zz substringWithRange:NSMakeRange(1,[zz length]-2)]; // 両端除外
		else 
			return zz;
	}
	return nil;
}

// csvRead:muStrucに従って数値項目を取得する
- (NSNumber *)csvNumber:(NSMutableArray *)muStruc csvLine:(NSArray *)arLine csvCol:(NSString *)zColName {
	NSInteger ui = [muStruc indexOfObject:zColName];
	if (ui != NSNotFound) {
		NSString *zz = [arLine objectAtIndex:ui];
		return [NSNumber numberWithInteger:[zz integerValue]];
	}
	return nil;
}

//////////////////////////////////////////////////////////////////////////////////
- (NSString *)csvRead   // iPack から managedObjectContext へ読み込む
{
	NSString *zErrMsg = nil;
	NSString *home_dir = NSHomeDirectory();
	NSString *doc_dir = [home_dir stringByAppendingPathComponent:@"Documents"];
	NSString *csvPath = [doc_dir stringByAppendingPathComponent:GD_CSVFILENAME];		
	
	unsigned long ulStart = 0;
	unsigned long ulEnd = 0;
	NSData *one;
	NSData *data;
	NSInteger iSection = 0;
	E1 *e1obj;
	E2 *e2obj;
	E3 *e3obj;
	NSInteger e2row = 0;  // CSV読み込み順に連番付与する
	NSInteger e3row = 0;
	BOOL bManagedObjectContextSave = NO;  // YES=CoreData Saveする
	BOOL bDQSection = NO;
	NSData *dDQ = [@"\"" dataUsingEncoding:NSUTF8StringEncoding]; // ["]ダブルクォーテーション
	
	// 以下、release 必要
	unsigned char uChar[1];
	uChar[0] = 0x0a; // LF(0x0a)
	NSData *dLF = [[NSData alloc] initWithBytes:uChar length:1];
	uChar[0] = 0x0d; // CR(0x0d)
	NSData *dCR = [[NSData alloc] initWithBytes:uChar length:1];
	
	NSMutableArray *maE1struc = [[NSMutableArray alloc] initWithCapacity:256];
	NSMutableArray *maE2struc = [[NSMutableArray alloc] initWithCapacity:256];
	NSMutableArray *maE3struc = [[NSMutableArray alloc] initWithCapacity:256];
	
	
	// input OPEN
	NSFileHandle *input = [NSFileHandle fileHandleForReadingAtPath:csvPath];
	@try {
		while (1) {
			bDQSection = NO; // Reset
			// 1行を切り出す
			while (one = [input readDataOfLength:1]) { 
				if ([one length] <= 0) {
					AzLOG(@"Break1");
					break;	// ファイル終端
				}
				// ["]文字列区間にあるCRやLFは無視するための処理
				if ([one isEqualToData:dDQ]) bDQSection = !bDQSection; // ["]区間判定　トグルになる
				// 文字列区間でないところに、CRやLFがあれば行末と判断する
				if (!bDQSection && ([one isEqualToData:dLF] || [one isEqualToData:dCR])) break; // 行末
			}
			
			ulEnd = [input offsetInFile]; // [LF]または[CR]の次の位置を示す
			if (ulEnd <= ulStart) {
				AzLOG(@"Break2");
				break;	// ファイル終端
			}
			if ([one length] <= 0) ulEnd++; // ファイル末尾対策  ＜＜これが無いと "End"の[d]が欠ける＞＞
			
			// [CRLF] [LFCR] 対応のため、次の1バイトを調べてCRまたはLFならば終端を1バイト進める
			one = [input readDataOfLength:1]; // 次の1バイトを先取りしておく 「次の読み込みの開始位置をセットする」ために使用
			
			// 最初に見つかった[CR]または[LF]の直前までを切り出して文字列にする
			[input seekToFileOffset:ulStart]; 
			data = [input readDataOfLength:(ulEnd - ulStart - 1)];  // 1行分読み込み
			NSString *csvStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			
			NSString *csvSplit = [csvStr stringByAppendingString:@",,,"];
			AzLOG(@"%@", csvSplit);
			// さらに、切り出した文字列をCSV区切りで配列に切り出す
			NSArray *csvArray = [csvSplit componentsSeparatedByString:@","];
			AzLOG(@"(%@,%@,%@)", [csvArray objectAtIndex:0], [csvArray objectAtIndex:1], [csvArray objectAtIndex:2]);
			
			// 次の読み込みの開始位置をセットする
			// 次の1バイトが[CR]または[LF]ならば、さらに1バイト進める
			if ([one isEqualToData:dLF] || [one isEqualToData:dCR]) ulEnd++; // 終端を1バイト進める
			// LOOPの最後で開始位置をセットしている。
			
			//============================================================================CoreData Set
			
			if (iSection==0 && [[csvArray objectAtIndex:0] isEqualToString:GD_PRODUCTNAME]
				&& [[csvArray objectAtIndex:1] isEqualToString:@"CSV"]) {
				// GD_PRODUCTNAME  @",CSV,UTF-8,Copyright,(C)2010,Azukid.com,,,\n";
				iSection = 1;
			}
			else if (iSection==0) {
				// 1行目が GD_PRODUCTNAME,CSV, で無かったとき
				if (!zErrMsg) zErrMsg = NSLocalizedString(@"Different file formats.", @"CSV形式が違います");
				break;
			}
			else if (iSection==1 && [[csvArray objectAtIndex:0] isEqualToString:@"Structure"]) {
				iSection = 2;
			}
			else if (iSection==2 && [[csvArray objectAtIndex:0] isEqualToString:@"[Plan]"]) {
				[maE1struc setArray:csvArray];
			}
			else if (iSection==2 && [[csvArray objectAtIndex:0] isEqualToString:@"[Group]"]) {
				[maE2struc setArray:csvArray];
			}
			else if (iSection==2 && [[csvArray objectAtIndex:0] isEqualToString:@"[Item]"]) {
				[maE3struc setArray:csvArray];
			}
			else if (iSection==2 && [[csvArray objectAtIndex:0] isEqualToString:@"Begin"]) {
				iSection = 3;
			}
			else if (iSection==3 && [[csvArray objectAtIndex:0] isEqualToString:@""]
					 && ![[csvArray objectAtIndex:1] isEqualToString:@""]) {  // 最後は、NOTです！ E2との違い
				// [Plan],name,note,,,,,,
				//-----------------------------------------------E1
				// ContextにE1ノードを追加する　E1edit内でCANCELならば削除している
				e1obj = (E1 *)[NSEntityDescription insertNewObjectForEntityForName:@"E1" 
															inManagedObjectContext:self.PmanagedObjectContext];
				//-----------------------------------------------Numbers
				e1obj.row  = [NSNumber numberWithInteger:self.Pe1rows];  // 親からもらった値
				self.Pe1rows++;  // 連続Downloadに対応するため。
				//-----------------------------------------------Strings
				e1obj.name = [self csvString:maE1struc csvLine:csvArray csvCol:@"name"];
				e1obj.note = [self csvString:maE1struc csvLine:csvArray csvCol:@"note"];
				//-----------------------------------------------
				iSection = 4;
				e2row = 0;
				bManagedObjectContextSave = YES;  // 少なくとも[Plan]名があれば保存するため
			}
			else if (4<=iSection && [[csvArray objectAtIndex:0] isEqualToString:@""] 
					 && [[csvArray objectAtIndex:1] isEqualToString:@""]
					 && ![[csvArray objectAtIndex:2] isEqualToString:@""]) {  // 最後は、NOTです！ E3との違い
				// [Group],,name,note,,,,,
				//-----------------------------------------------E2
				e2obj = (E2 *)[NSEntityDescription insertNewObjectForEntityForName:@"E2" 
															inManagedObjectContext:self.PmanagedObjectContext];
				e2obj.row = [NSNumber numberWithInteger:e2row++];  //[self csvNumber:maE2struc csvLine:csvArray csvCol:@"row"];
				//-----------------------------------------------Strings
				e2obj.name = [self csvString:maE2struc csvLine:csvArray csvCol:@"name"];
				e2obj.note = [self csvString:maE2struc csvLine:csvArray csvCol:@"note"];
				//-----------------------------------------------
				[e1obj addChildsObject:e2obj];
				iSection = 5;
				e3row = 0;
			}
			else if (iSection==5 && [[csvArray objectAtIndex:0] isEqualToString:@""] 
					 && [[csvArray objectAtIndex:1] isEqualToString:@""]
					 && [[csvArray objectAtIndex:2] isEqualToString:@""]) {
				// [Item],,,name,spec,stock,required,weight,note
				//-----------------------------------------------E3
				e3obj = (E3 *)[NSEntityDescription insertNewObjectForEntityForName:@"E3" 
															inManagedObjectContext:self.PmanagedObjectContext];
				e3obj.row = [NSNumber numberWithInteger:e3row++];  // [self csvNumber:maE3struc csvLine:csvArray csvCol:@"row"];
				//-----------------------------------------------Numbers
				e3obj.stock = [self csvNumber:maE3struc csvLine:csvArray csvCol:@"stock"];
				e3obj.required = [self csvNumber:maE3struc csvLine:csvArray csvCol:@"required"];
				e3obj.weight = [self csvNumber:maE3struc csvLine:csvArray csvCol:@"weight"];
				//-----------------------------------------------Strings
				e3obj.name = [self csvString:maE3struc csvLine:csvArray csvCol:@"name"];
				e3obj.spec = [self csvString:maE3struc csvLine:csvArray csvCol:@"spec"];
				e3obj.note = [self csvString:maE3struc csvLine:csvArray csvCol:@"note"];
				//-----------------------------------------------E3:冗長計算処理
				NSInteger iStock = [e3obj.stock intValue];
				NSInteger iRequired = [e3obj.required intValue];
				NSInteger iWeight = [e3obj.weight intValue];
				e3obj.weightStk = [NSNumber numberWithInteger:(iWeight * iStock)];
				e3obj.weightReq = [NSNumber numberWithInteger:(iWeight * iRequired)];
				e3obj.lack = [NSNumber numberWithInteger:(iRequired - iStock)];
				e3obj.weightLack = [NSNumber numberWithInteger:((iRequired - iStock) * iWeight)];
				//-----------------------------------------------
				if (0 < iRequired)
					e3obj.noGray = [NSNumber numberWithInteger:1];
				else
					e3obj.noGray = [NSNumber numberWithInteger:0];
				//-----------------------------------------------
				if (0 < iRequired && iStock < iRequired)
					e3obj.noCheck = [NSNumber numberWithInteger:1];
				else
					e3obj.noCheck = [NSNumber numberWithInteger:0];
				//-----------------------------------------------
				[e2obj addChildsObject:e3obj];
				//iSection = 5;
			}
			else if (3<=iSection && [[csvArray objectAtIndex:0] isEqualToString:@"End"]) {
				// 保存する
				bManagedObjectContextSave = YES;
				break; // LOOP OUT
			}
			AzLOG(@"iSection=%d", iSection);
			//============================================================================CoreData Set
			[csvStr release];	// 行毎に生成＆破棄
			if ([one length] <= 0) {
				AzLOG(@"Break3");
				break; // LOOP OUT
			}
			ulStart = ulEnd;
			[input seekToFileOffset:ulStart]; // 次の開始位置にセット
		} // LOOP END
		
		if (e1obj) {
			for (e2obj in e1obj.childs) {
				// E2 sum属性　＜高速化＞ 親sum保持させる
				[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.noGray"] forKey:@"sumNoGray"];
				[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.noCheck"] forKey:@"sumNoCheck"];
				[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.weightStk"] forKey:@"sumWeightStk"];
				[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.weightReq"] forKey:@"sumWeightReq"];
			}
			
			// E1 sum属性　＜高速化＞ 親sum保持させる
			[e1obj setValue:[e1obj valueForKeyPath:@"childs.@sum.sumNoGray"] forKey:@"sumNoGray"];
			[e1obj setValue:[e1obj valueForKeyPath:@"childs.@sum.sumNoCheck"] forKey:@"sumNoCheck"];
			[e1obj setValue:[e1obj valueForKeyPath:@"childs.@sum.sumWeightStk"] forKey:@"sumWeightStk"];
			[e1obj setValue:[e1obj valueForKeyPath:@"childs.@sum.sumWeightReq"] forKey:@"sumWeightReq"];
		}
		
		if (bManagedObjectContextSave) {
			// 保存する
			NSError *err = nil;
			if (![self.PmanagedObjectContext save:&err]) {
				// 保存失敗
				AzLOG(@"Unresolved error %@, %@", err, [err userInfo]);
				if (!zErrMsg) zErrMsg = NSLocalizedString(@"CoreData failed to save.", @"CoreData 保存失費");
			}
			else {
				// 保存成功
				//self.selectedRow++;  // 次の "Begin" から新たなPlanがはじまるのに対応
				//zErrMsg = nil; // Compleat!
			}
		}
		else {
			// Endが無い ＆ [Plan]も無い
			if (!zErrMsg) zErrMsg = NSLocalizedString(@"No file content.", @"CSV内容なし");
		}
	} 
	@catch (NSException *errEx) {
		if (!zErrMsg) zErrMsg = NSLocalizedString(@"File read error", @"CSV読み込み失敗");
		NSString *name = [errEx name];
		AzLOG(@"◆ %@ : %@\n", name, [errEx reason]);
		if ([name isEqualToString:NSRangeException]) {
			AzLOG(@"Exception was caught successfully.\n");
		} else {
			[errEx raise];
		}
	}
	@finally {
		// CLOSE
        [input closeFile];
		// release
		[maE3struc release];
		[maE2struc release];
		[maE1struc release];
		[dCR release];
		[dLF release];
	}	
	return zErrMsg;
}

@end
