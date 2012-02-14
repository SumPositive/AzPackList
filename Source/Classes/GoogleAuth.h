//
//  GoogleAuth.h
//  AzPackList5
//
//  Created by Sum Positive on 12/02/14.
//  Copyright (c) 2012 Azukid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Elements.h"


@interface GoogleAuth : NSObject

+ (void)uploadFile:(NSString *)pathFile;
+ (UIViewController *)viewControllerOAuth2:(id)delegate;
+ (BOOL)isAuthorized;
+ (void)request:(NSMutableURLRequest *)request;

@end
