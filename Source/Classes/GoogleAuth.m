//
//  GoogleAuth.m
//  AzPackList5
//
//  Created by Sum Positive on 12/02/14.
//  Copyright (c) 2012 Azukid. All rights reserved.
//

#import "Global.h"
#import "GoogleAuth.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GData.h"
#import "GDataDocs.h"


#define AUTH_SCOPE					@"https://docs.google.com/feeds/"
#define AUTH_CLIENT_ID			@"27136904860.apps.googleusercontent.com" 
#define AUTH_CLIENT_SECRET	@"dnvbn1az5x6DtxCEi7BuAPQD" 
#define AUTH_KEYCHAIN			@"OAuth2PackList"
#define FOLDER_PACKLIST		@"PackList"
#define FOLDER_PHOTO			@"PackList Photo"

@implementation GoogleAuth
{

}

static GTMOAuth2Authentication		*staticAuth;
static NSURL										*staticUpdateUrlPackList;
static NSURL										*staticUpdateUrlPhoto;

#pragma make - GTMOAuth2
//-----------------------------------------------------------------------------
// Google API  OAuth2  アプリ登録
// https://code.google.com/apis/console/   packlist@azukid.com
// Product name:	PackList
// Google account:	packlist@azukid.com ＜＜このメアドはGoogleにより公開される。
// Client ID for installed applications
// Client ID:	27136904860.apps.googleusercontent.com
// Client secret:	dnvbn1az5x6DtxCEi7BuAPQD
// Redirect URIs:	urn:ietf:wg:oauth:2.0:oob
//                         http://localhost
//-----------------------------------------------------------------------------
// Google Toolbox for Mac - OAuth 2 Controllers
// http://code.google.com/p/gtm-oauth2/wiki/Introduction#Adding_the_Controllers_to_Your_Project
//-----------------------------------------------------------------------------
// 使用できるscopeの一覧
// http://code.google.com/intl/ja/apis/gdata/faq.html#AuthScopes
//-----------------------------------------------------------------------------

+ (GDataServiceGoogleDocs *)serviceDocs
{
	static GDataServiceGoogleDocs *staticDocs = nil;
	if (staticDocs==nil) {
		staticDocs = [[GDataServiceGoogleDocs alloc] init];
	}
	return staticDocs;
}

+ (void)makeFolder:(NSString *)folderName  uploadFile:(NSString *)pathFile
{
	//[staticDocs setAuthToken:[staticAuth tokenType]];
	
	NSURL *feedURL = [GDataServiceGoogleDocs  docsFeedURL];
	NSLog(@"GoogleAuth: makeFolder: feedURL='%@'", feedURL);
	
	[[GoogleAuth serviceDocs] fetchFeedWithURL:feedURL
						completionHandler:^(GDataServiceTicket *ticket, GDataFeedBase *feed, NSError *error) {
							NSLog(@"GoogleAuth: makeFolder: feed='%@'\n", feed);
							if (error) {
								// 失敗
								NSLog(@"GoogleAuth: makeFolder: Failed '%@'\n", error.localizedDescription);
								//if (isSetting) alertBox(NSLocalizedString(@"Picasa login NG", nil), nil, @"OK");
							} else {
								// 成功
								//alertBox(NSLocalizedString(@"Picasa login OK", nil), NSLocalizedString(@"Picasa login OK msg",nil), @"OK");
								// 専用フォルダ捕捉、無ければ作成する
								BOOL bNew = YES;
								// FOLDER_PACKLIST
								for (GDataEntryFolderDoc *folder in [feed entries]) 
								{
									if ([[[folder title] contentStringValue] isEqualToString:folderName]) 
									{
										NSURL *feedURL = [[folder feedLink] URL];
										if (feedURL) 
										{
											[[GoogleAuth serviceDocs] fetchFeedWithURL:feedURL
																	 completionHandler:^(GDataServiceTicket *ticket, GDataFeedBase *feed, NSError *error) {
																		 if (error) {
																			 NSLog(@"GoogleAuth: makeFolder: fetchFeedWithURL Failed '%@'\n", error.localizedDescription);
																		 } else {
																			 staticUpdateUrlPackList = [[feed uploadLink] URL];
																			 NSLog(@"GoogleAuth: makeFolder: OK staticUpdateUrlPackList=[%@]\n", staticUpdateUrlPackList); 
																			 if (pathFile) {
																				 [GoogleAuth uploadFile:pathFile];
																			 }
																		 }
																	 }];
										}
										bNew = NO;
										break;
									}
								}
								if (bNew) {
									NSLog(@"GoogleAuth: makeFolder: NEW '%@'", folderName);
									// アルバムを追加する
									NSURL *postLink =  [[feed postLink] URL];
									GDataEntryFolderDoc *newFolder = [GDataEntryFolderDoc documentEntry];
									[newFolder setTitleWithString:folderName];
									[newFolder setDocumentDescription:NSLocalizedString(@"Google Folder Description", nil)];
									//[newFolder setAccess:kGDataPhotoAccessPrivate];  //or kGDataPhotoAccessPublic
									// 開始
									[[GoogleAuth serviceDocs] fetchEntryByInsertingEntry:newFolder
																			  forFeedURL:postLink 
																	   completionHandler:^(GDataServiceTicket *ticket, GDataEntryBase *entry, NSError *error) {
																		   if (error) {
																			   // 失敗
																			   NSLog(@"GoogleAuth: makeFolder: NEW fetchFeedWithURL Failed '%@'\n", error.localizedDescription);
																		   } else {
																			   // 成功
																			   //NSLog(@"AZPicasa: init: New Album OK ticket=[%@]\n  entry=[%@]\n", ticket, entry);
																			   GDataEntryFolderDoc *newFolder = (GDataEntryFolderDoc*)entry;
																			   //NSLog(@"AZPicasa: init: New Album OK [album GPhotoID]=[%@]\n", [album GPhotoID]); 
																			   NSURL *feedURL = [[newFolder feedLink] URL];
																			   if (feedURL) {
																				   [[GoogleAuth serviceDocs] fetchFeedWithURL:feedURL
																											completionHandler:^(GDataServiceTicket *ticket, GDataFeedBase *feed, NSError *error) {
																												if (error) {
																													NSLog(@"GoogleAuth: makeFolder: NEW fetchFeedWithURL Failed '%@'\n", error.localizedDescription);
																												} else {
																													staticUpdateUrlPackList = [[feed uploadLink] URL];
																													NSLog(@"GoogleAuth: makeFolder: NEW OK staticUpdateUrlPackList=[%@]\n", staticUpdateUrlPackList); 
																													if (pathFile) {
																														[GoogleAuth uploadFile:pathFile];
																													}
																												}
																											}];
																			   }
																		   }
																	   }];
								}
							}
						}];
}

+ (void)uploadFile:(NSString *)pathFile
{
	if (staticUpdateUrlPackList==nil) {
		[GoogleAuth makeFolder:FOLDER_PACKLIST uploadFile:pathFile];
		return;
	}
	
	GDataEntryStandardDoc *newDoc = [GDataEntryStandardDoc documentEntry];
	
	[newDoc setTitleWithString:[pathFile pathExtension]];
	[newDoc setDocumentDescription:NSLocalizedString(@"Google PackList Description", nil)];
	
	NSFileHandle *fhand = [NSFileHandle fileHandleForReadingAtPath:pathFile];
	if (fhand==nil) {
		return;
	}
	[newDoc setUploadFileHandle:fhand];
	[newDoc setUploadMIMEType:@"text/csv"];
	[newDoc setUploadSlug:@"PackList"];
	NSLog(@"GoogleAuth: uploadFile: newDoc='%@'", newDoc);
	
	// 開始
	[[GoogleAuth serviceDocs] fetchEntryByInsertingEntry:newDoc
								forFeedURL:staticUpdateUrlPackList 
								  completionHandler:^(GDataServiceTicket *ticket, GDataEntryBase *entry, NSError *error) {
									  if (error) {
										  // 失敗
										  NSLog(@"GoogleAuth: uploadFile: Failed '%@'", error.localizedDescription);
									  } else {
										  // 成功
										  GDataEntryContent *ec = [entry content];
										  NSLog(@"GoogleAuth: uploadFile: URL [ec sourceURI]=[%@]", [ec sourceURI]);	//NSString
									  }
								  }];
}

+ (UIViewController *)viewControllerOAuth2:(id)delegate
{
/*中止したときなど、直前の許可を残す
	if (staticAuth) {
		// 完全にユーザーの許可を破棄する場合
		//　キーチェーンエントリを削除する
		//[GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:AUTH_KEYCHAIN];
		// トークンを取り消すようにGoogleのサーバに依頼する
		//[GTMOAuth2ViewControllerTouch revokeTokenForGoogleAuthentication:mAuthentication];	
		staticAuth = nil;
	}*/
	
    GTMOAuth2ViewControllerTouch *viewController;
    viewController = [[GTMOAuth2ViewControllerTouch alloc]
					  initWithScope: AUTH_SCOPE
					  clientID: AUTH_CLIENT_ID
					  clientSecret: AUTH_CLIENT_SECRET
					  keychainItemName: AUTH_KEYCHAIN
					  completionHandler:
					  ^(GTMOAuth2ViewControllerTouch *viewController, GTMOAuth2Authentication *auth, NSError *error) {
						  if (error != nil) {
							  // 認証に失敗したときの処理
							  NSLog(@"googleOAuth2: Failed '%@'\n", error.localizedDescription);
							  //alertBox(NSLocalizedString(@"Google Auth NG", nil), nil, @"OK");
							  // CANCEL
							  alertBox(NSLocalizedString(@"Google Auth Cancel", nil), nil, @"OK");
						  } 
						  else {
							  // 認証に成功したときの処理
							  staticAuth = auth;
							  alertBox(NSLocalizedString(@"Google Auth OK", nil), NSLocalizedString(@"Google Auth OK msg",nil), @"OK");
							  // 以後、request: からリクエストできる
						  }
						  //[viewController dismissModalViewControllerAnimated:YES];		// 自身で閉じる
						  [viewController.parentViewController.navigationController popViewControllerAnimated:YES];
						  if ([delegate respondsToSelector:@selector(viewWillAppear:)]) {
							  [delegate viewWillAppear:NO];
						  }
						  [GoogleAuth makeFolder];
						  return;
					  }];
	//呼び出し元で開ける
	//[self presentModalViewController:viewController animated:YES];	// 開ける
	return viewController;
}

+ (void)delateAuthorize
{	// 完全にユーザーの許可を破棄する
	//　キーチェーンエントリを削除する
	[GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:AUTH_KEYCHAIN];
	// トークンを取り消すようにGoogleのサーバに依頼する
	[GTMOAuth2ViewControllerTouch revokeTokenForGoogleAuthentication:staticAuth];	
	staticAuth = nil;
}

+ (BOOL)isAuthorized
{
	return [staticAuth canAuthorize];
	//return (staticAuth != nil);
}

+ (void)request:(NSMutableURLRequest *)request
{
	if (staticAuth==nil) {
		staticAuth = [GTMOAuth2ViewControllerTouch 
										 authForGoogleFromKeychainForName: AUTH_KEYCHAIN
										 clientID: AUTH_CLIENT_ID
										 clientSecret: AUTH_CLIENT_SECRET];
	}
	if ([staticAuth canAuthorize]) {
		[staticAuth authorizeRequest: request
						completionHandler:^(NSError *error) {
			if (error) {
				// error
			} else {
				// OK the request has been authorized
			}
		}];
	} else {
		// 未認証
		staticAuth = nil;
		alertBox(NSLocalizedString(@"GTMOAuth2 Disable", nil), 
				 NSLocalizedString(@"GTMOAuth2 Disable msg",nil), @"OK");
	}
}

@end
