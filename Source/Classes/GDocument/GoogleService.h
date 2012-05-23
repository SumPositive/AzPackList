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
#import "GData.h"
#import "GDataDocs.h"
#import "GDataPhotos.h"


// KeyChain Name リリース後、変更禁止
#define GS_KC_ServiceName					@"PackListGSKC"
#define GS_KC_LoginName						@"GS_KC_LoginName"
#define GS_KC_LoginPassword					@"GS_KC_LoginPassword"

#define GS_DOC_FOLDER_NAME				@"PackList"
#define GS_PHOTO_ALBUM_NAME			@"PackList"
#define GS_PHOTO_UUID_PREFIX				@"PackList:"	//この後にUUIDが続く。 setPhotoDescriptionWithString:でセット


@interface GoogleService : NSObject <UIAlertViewDelegate>

+ (void)alertIndicatorOn:(NSString*)zTitle;
+ (void)alertIndicatorOff;

+ (void)loginID:(NSString*)googleID  withPW:(NSString*)googlePW  isSetting:(BOOL)isSetting;

// Document
+ (void)docServiceClear;	//Login IDを変更したときにクリアするため
+ (GDataServiceGoogleDocs *)docService;
+ (void)docUploadErrorNo:(NSInteger)errNo  description:(NSString*)description;
+ (void)docUploadE1:(E1 *)e1node  title:(NSString*)title  crypt:(BOOL)crypt;
+ (void)docDownloadErrorNo:(NSInteger)errNo  description:(NSString*)description;
+ (void)docDownloadEntry:(GDataEntryDocBase *)docEntry;

// Photo <Picasa>
+ (GDataServiceGooglePhotos *)photoService;
+ (void)photoServiceClear;	//Login IDを変更したときにクリアするため
+ (void)photoUploadE3:(E3*)e3target;
+ (void)photoDownloadE3:(E3*)e3target  errorLabel:(UILabel*)errorLabel;

@end

