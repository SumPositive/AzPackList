//
//  FileCsv.h
//  AzPacking
//
//  Created by 松山 和正 on 10/03/01.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class E1;

@interface FileCsv : NSObject {
	//--------------------------retain
	//--------------------------assign
}

// クラスメソッド（グローバル関数）
+ (NSString *)zSave:(E1 *)Pe1 
	toLocalFileName:(NSString *)PzFname;

+ (NSString *)zSave:(E1 *)Pe1
	toMutableString:(NSMutableString *)PzCsv;


+ (NSString *)zLoad:(NSString *)PzFname;
+ (NSString *)zLoadURL:(NSURL*)Url;
+ (NSString *)zLoadPath:(NSString *)PzFillPath;

+ (E1 *)zLoad:(NSString *)PzCsv
	 withSave:(BOOL)PbSave
		error:(NSError **)err;

@end
