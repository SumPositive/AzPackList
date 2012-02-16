//
//  GoogleAPI.h
//  AzPackList5
//
//  Created by Sum Positive on 12/02/14.
//  Copyright (c) 2012 Azukid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Elements.h"


@interface GoogleAPI : NSObject

+ (void)uploadPackList:(NSString *)filePath  withName:(NSString *)name;
+ (void)uploadPhoto:(E3 *)e3node;

+ (void)downloadPhotoE3:(E3 *)e3node  imageView:(UIImageView *)imageView;

+ (UIViewController *)viewControllerOAuth2:(id)delegate;
+ (BOOL)isAuthorized;
+ (void)request:(NSMutableURLRequest *)request;

@end
