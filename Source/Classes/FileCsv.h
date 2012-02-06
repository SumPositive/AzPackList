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

@property (nonatomic, strong, readonly) NSString		*tmpPathFile;
@property (nonatomic, strong) NSMutableArray			*errorMsgs;

- (id)init;

//Private//- (BOOL)zSavePrivate:(E1 *)Pe1  toMutableString:(NSMutableString *)PzCsv;
- (BOOL)zSave:(E1 *)Pe1 toMutableString:(NSMutableString *)PzCsv  crypt:(BOOL)bCrypt;
- (BOOL)zSaveTmpFile:(E1 *)Pe1  crypt:(BOOL)bCrypt;
- (BOOL)zSavePasteboard:(E1 *)Pe1  crypt:(BOOL)bCrypt;

//- (E1 *)zLoadPrivate:(NSString *)PzCsv  withSave:(BOOL)PbSave;
- (E1 *)zLoad:(NSString *)PzCsv  withSave:(BOOL)PbSave;
- (BOOL)zLoadTmpFile;
- (BOOL)zLoadPasteboard;
- (BOOL)zLoadURL:(NSURL*)Url;


@end
