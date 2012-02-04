//
//  FileJson.h
//  AzPackList
//
//  Created by 松山 和正 on 10/03/01.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class E1;

@interface FileJson : NSObject 

@property (nonatomic, strong, readonly) NSString					*tmpPathFile;
@property (nonatomic, strong, readonly) NSMutableArray		*errorMsgs;

- (id)init;
- (BOOL)writingE1:(E1 *)Pe1;
- (E1*)readingE1;

@end
