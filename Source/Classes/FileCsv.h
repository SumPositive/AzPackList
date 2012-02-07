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
@property (nonatomic, assign, readonly) BOOL			didEncryption;
//@property (nonatomic, strong) NSMutableArray			*errorMsgs;

- (id)init;

//Private//- (BOOL)zSavePrivate:(E1 *)Pe1  toMutableString:(NSMutableString *)PzCsv;
- (NSString *)zSave:(E1 *)Pe1 toMutableString:(NSMutableString *)PzCsv  crypt:(BOOL)bCrypt;
- (NSString *)zSaveTmpFile:(E1 *)Pe1  crypt:(BOOL)bCrypt;
- (NSString *)zSavePasteboard:(E1 *)Pe1  crypt:(BOOL)bCrypt;

//Private//- (E1 *)e1LoadPrivate:(NSString *)PzCsv  withSave:(BOOL)PbSave;
- (E1 *)e1Load:(NSString *)PzCsv  withSave:(BOOL)PbSave;
- (NSString *)zLoadTmpFile;
- (NSString *)zLoadPasteboard;
- (NSString *)zLoadURL:(NSURL*)Url;


@end
