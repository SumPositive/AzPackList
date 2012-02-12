//
//  AZPicasa.h
//  AzPackList5
//
//  Created by Sum Positive on 12/02/11.
//  Copyright (c) 2012 Azukid. All rights reserved.
//
/* -----------------------------------------------------------------------------------------------
 * GData API ライブラリの組み込み手順 参照URL:
 * http://hoishing.wordpress.com/2011/08/23/gdata-objective-c-client-setup-in-xcode-4/
 * -----------------------------------------------------------------------------------------------
 */

#import <Foundation/Foundation.h>
#import "GData.h"
#import "GDataPhotos.h"

@class E3;
@interface AZPicasa : NSObject

- (void)loginID:(NSString*)googleID  withPW:(NSString*)googlePW  isSetting:(BOOL)isSetting;
- (id)init;
- (void)uploadE3:(E3*)e3target;
- (void)downloadE3:(E3*)e3target  imageView:(UIImageView*)imageView;

@end

