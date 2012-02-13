//
//  AZGoogle.h
//  AzPackList5
//
//  Created by Sum Positive on 12/02/13.
//  Copyright (c) 2012 Azukid. All rights reserved.
//
/* -----------------------------------------------------------------------------------------------
 * GData API ライブラリの組み込み手順 参照URL:
 * http://hoishing.wordpress.com/2011/08/23/gdata-objective-c-client-setup-in-xcode-4/
 * -----------------------------------------------------------------------------------------------
 */

#import <Foundation/Foundation.h>
#import "Elements.h"

#define AZG_PICASA
#define AZG_DOCUMENT
//#define AZG_SPREADSHEET
//#define AZG_CALENDER


@interface AZGoogle : NSObject

// Login
- (void)loginID:(NSString*)googleID  withPW:(NSString*)googlePW  isSetting:(BOOL)isSetting;
- (id)init;

#ifdef AZG_PICASA
- (void)picasaUploadE3:(E3*)e3target;
- (void)picasaDownloadE3:(E3*)e3target  imageView:(UIImageView*)imageView;
#endif

#ifdef AZG_DOCUMENT
- (void)docUploadE3:(E3*)e3target;
#endif

@end
