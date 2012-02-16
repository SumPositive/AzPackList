//
//  GoogleService.h
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
#import "Elements.h"

// KeyChain Name リリース後、変更禁止
#define GS_KC_ServiceName					@"PackListGSKC"
#define GS_KC_LoginName						@"GS_KC_LoginName"
#define GS_KC_LoginPassword					@"GS_KC_LoginPassword"

#define GS_DOC_FOLDER_NAME				@"PackList"
#define GS_PHOTO_ALBUM_NAME			@"PackList"
#define GS_PHOTO_UUID_PREFIX				@"PackList:"	//この後にUUIDが続く。 setPhotoDescriptionWithString:でセット


@interface GoogleService : NSObject

+ (void)loginID:(NSString*)googleID  withPW:(NSString*)googlePW  isSetting:(BOOL)isSetting;

// Document
+ (void)docUploadFile:(NSString*)pathLocal  withName:(NSString*)name;
+ (void)docDownloadFile:(NSString*)pathLocal;

// Photo <Picasa>
+ (void)photoUploadE3:(E3*)e3target;
+ (void)photoDownloadE3:(E3*)e3target  imageView:(UIImageView*)imageView;

@end

