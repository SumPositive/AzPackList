//
//  FileCsv.h
//  AzPacking
//
//  Created by 松山 和正 on 10/03/01.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class E1;

@interface FileCsv : NSObject 

@property (nonatomic, strong, readonly) NSString					*tmpPathFile;
@property (nonatomic, strong, readonly) NSMutableArray		*errorMsgs;

- (id)init;

- (NSString *)zSave:(E1 *)Pe1  toTmpFile:(BOOL)bTmpFile;  //NO:PasteBoardへ書き出す
- (NSString *)zSave:(E1 *)Pe1 toMutableString:(NSMutableString *)PzCsv;

- (NSString *)zLoadURL:(NSURL*)Url;
- (NSString *)zLoadFromTmpFile:(BOOL)bTmpFile;  //NO:PasteBoardから読み込む
- (E1 *)zLoad:(NSString *)PzCsv  withSave:(BOOL)PbSave;


@end
