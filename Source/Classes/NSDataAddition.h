//
//  NSDataAddition.h
//  AzPackList5
//
//  Created by Sum Positive on 12/02/05.
//  Copyright (c) 2012 Azukid. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NSString; 

@interface NSData (Additions)

- (NSData *)AES256EncryptWithKey:(NSString *)key;
- (NSData *)AES256DecryptWithKey:(NSString *)key;
//- (NSString *)newStringInBase64FromData;

// Base64にエンコードした文字列を生成する
- (NSString *)stringEncodedWithBase64;
// Base64文字列をデコードし、NSDataオブジェクトを生成する(NSStringより)
+ (NSData *)dataWithBase64String:(NSString *)pstrBase64;

@end