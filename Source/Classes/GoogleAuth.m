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
#define PHOTO_ALBUM				@"PackList Photo"

@implementation GoogleAuth

static GTMOAuth2Authentication		*staticAuth;

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
// 使用できるscopeの一覧			http://code.google.com/intl/ja/apis/gdata/faq.html#AuthScopes
// Documents List Data API　scope			https://docs.google.com/feeds/
// Picasa Web Albums Data API scope		http://picasaweb.google.com/data/
//-----------------------------------------------------------------------------

+ (GDataServiceGoogleDocs *)serviceDocs
{
	static GDataServiceGoogleDocs *staticDocs = nil;
	if (staticDocs==nil) {
		if (staticAuth==nil) {
			staticAuth = [GTMOAuth2ViewControllerTouch 
						  authForGoogleFromKeychainForName: AUTH_KEYCHAIN
						  clientID: AUTH_CLIENT_ID
						  clientSecret: AUTH_CLIENT_SECRET];
		}
		NSLog(@"GoogleAuth: staticAuth=%@", staticAuth);
		if (staticAuth) {
			staticDocs = [[GDataServiceGoogleDocs alloc] init];
			[staticDocs setAuthorizer: staticAuth];
		} else {
			NSLog(@"GoogleAuth: serviceDocs: No Auth  staticAuth=nil");
		}
	}
	return staticDocs;
}

+ (GDataServiceGooglePhotos *)servicePhotos
{
	static GDataServiceGooglePhotos *staticPhotos = nil;
	if (staticPhotos==nil) {
		if (staticAuth==nil) {
			staticAuth = [GTMOAuth2ViewControllerTouch 
						  authForGoogleFromKeychainForName: AUTH_KEYCHAIN
						  clientID: AUTH_CLIENT_ID
						  clientSecret: AUTH_CLIENT_SECRET];
		}
		NSLog(@"GoogleAuth: staticAuth=%@", staticAuth);
		if (staticAuth) {
			staticPhotos = [[GDataServiceGooglePhotos alloc] init];
			[staticPhotos setAuthorizer: staticAuth];
		} else {
			NSLog(@"GoogleAuth: staticPhotos: No Auth  staticAuth=nil");
		}
	}
	return staticPhotos;
}

/*
+ (void)makeFolder:(NSString *)folderName  uploadFile:(NSString *)filePath
{
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
																			 if (filePath) {
																				 [GoogleAuth uploadFile:filePath];
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
									// フォルダを追加する
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
																													if (filePath) {
																														[GoogleAuth uploadPackList:filePath];
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
*/

+ (void)uploadPackList:(NSString *)filePath  withName:(NSString *)name
{
/*	if (staticUpdateUrlPackList==nil) {
		// フォルダが無いので、フォルダを作ってからアップロードする
		[GoogleAuth makeFolder:FOLDER_PACKLIST uploadFile:filePath];
		return;
	}*/
	
	GDataEntryDocBase *newEntry = [GDataEntryStandardDoc documentEntry];
	
	[newEntry setTitleWithString:name];
	[newEntry setDocumentDescription:NSLocalizedString(@"Google PackList Description", nil)];
	
	NSFileHandle *fhand = [NSFileHandle fileHandleForReadingAtPath:filePath];
	if (fhand==nil) {
		return;
	}
	[newEntry setUploadFileHandle:fhand];
	[newEntry setUploadMIMEType:@"text/csv"];
	[newEntry setUploadSlug:@"PackList"];
	NSLog(@"GoogleAuth: uploadPackList: newEntry='%@'", newEntry);
	
	NSURL *uploadURL = [GDataServiceGoogleDocs  docsUploadURL];

	GDataServiceGoogleDocs *service = [GoogleAuth serviceDocs];
	if (service==nil) {
		return;
	}
	// 開始
	[service fetchEntryByInsertingEntry: newEntry
								forFeedURL: uploadURL   //staticUpdateUrlPackList 
								  completionHandler:^(GDataServiceTicket *ticket, GDataEntryBase *entry, NSError *error) {
									  if (error) {
										  // 失敗
										  NSLog(@"GoogleAuth: uploadPackList: Failed '%@'", error.localizedDescription);
									  } else {
										  // 成功
										  GDataEntryContent *ec = [entry content];
										  NSLog(@"GoogleAuth: uploadPackList: URL [ec sourceURI]=[%@]", [ec sourceURI]);	//NSString
									  }
								  }];
}

static NSURL	*staticPhotoAlbumUrl = nil;
+ (void)uploadPhotoAlbum:(E3 *)e3node
{
	GDataServiceGooglePhotos *service = [GoogleAuth servicePhotos];
	if (service==nil) {
		return;
	}
	
	
	NSString *username = [staticAuth userEmail];
	if ([username hasSuffix:@"@gmail.com"]) {
		username = [username stringByReplacingOccurrencesOfString:@"@gmail.com" withString:@""];
	}
	// get the URL for the user  ユーザの全アルバム取得
	NSURL *userURL = [GDataServiceGooglePhotos  photoFeedURLForUserID:username
					   albumID:nil albumName:nil photoID:nil  kind:@"album"  access:nil];
	NSLog(@"GoogleAuth: uploadPhotoAlbum: userURL='%@'", userURL);
	
	// Picasa Web Albums Data API  scope:  http://picasaweb.google.com/data/
	//[staticAuth setScope:@"http://picasaweb.google.com/data/"];
	//[service setAuthorizer:staticAuth];
	[service setAuthSubToken:@"http://picasaweb.google.com/data/"];

	[service fetchFeedWithURL: userURL
						completionHandler:^(GDataServiceTicket *ticket, GDataFeedBase *feed, NSError *error) {
							NSLog(@"GoogleAuth: uploadPhotoAlbum: feed='%@'\n", feed);
							if (error) {
								// 失敗
								NSLog(@"GoogleAuth: uploadPhotoAlbum: Failed '%@'\n", error.localizedDescription);
							} else {
								// 成功
								BOOL bNew = YES;
								for (GDataEntryPhotoAlbum *album in [feed entries]) {
									if ([[[album title] contentStringValue] isEqualToString:PHOTO_ALBUM]) {
										NSURL *feedURL = [[album feedLink] URL];
										if (feedURL) {
											[service fetchFeedWithURL:feedURL
																completionHandler:^(GDataServiceTicket *ticket, GDataFeedBase *feed, NSError *error) {
																	if (error) {
																		NSLog(@"GoogleAuth: uploadPhotoAlbum: fetchFeedWithURL Failed '%@'\n", error.localizedDescription);
																	} else {
																		staticPhotoAlbumUrl = [[feed uploadLink] URL];
																		NSLog(@"GoogleAuth: uploadPhotoAlbum: OK staticPhotoUploadUrl=[%@]\n", staticPhotoAlbumUrl); 
																		[GoogleAuth uploadPhoto:e3node];
																	}
																}];
										}
										bNew = NO;
										break;
									}
								}
								if (bNew) {
									NSLog(@"GoogleAuth: uploadPhotoAlbum: No Album");
									// アルバムを追加する
									NSURL *postLink =  [[feed postLink] URL];
									GDataEntryPhotoAlbum *newAlbum = [GDataEntryPhotoAlbum albumEntry];
									[newAlbum setTitleWithString:PHOTO_ALBUM];
									[newAlbum setPhotoDescriptionWithString:NSLocalizedString(@"Picasa Album Description", nil)];
									[newAlbum setAccess:kGDataPhotoAccessPrivate];  //or kGDataPhotoAccessPublic
									// 開始
									[service fetchEntryByInsertingEntry: newAlbum
															 forFeedURL: postLink 
																  completionHandler:^(GDataServiceTicket *ticket, GDataEntryBase *entry, NSError *error) {
																	  if (error) {
																		  // 失敗
																		  NSLog(@"GoogleAuth: uploadPhotoAlbum: New Album Failed '%@'\n", error.localizedDescription);
																	  } else {
																		  // 成功
																		  //NSLog(@"AZPicasa: init: New Album OK ticket=[%@]\n  entry=[%@]\n", ticket, entry);
																		  GDataEntryPhotoAlbum *album = (GDataEntryPhotoAlbum*)entry;
																		  //NSLog(@"AZPicasa: init: New Album OK [album GPhotoID]=[%@]\n", [album GPhotoID]); 
																		  NSURL *feedURL = [[album feedLink] URL];
																		  if (feedURL) {
																			  [service fetchFeedWithURL: feedURL
																								  completionHandler:^(GDataServiceTicket *ticket, GDataFeedBase *feed, NSError *error) {
																									  if (error) {
																										  NSLog(@"GoogleAuth: uploadPhotoAlbum: New Album fetchFeedWithURL Failed '%@'\n", error.localizedDescription);
																									  } else {
																										  staticPhotoAlbumUrl = [[feed uploadLink] URL];
																										  NSLog(@"GoogleAuth: uploadPhotoAlbum: New Album OK staticPhotoUploadUrl=[%@]\n", staticPhotoAlbumUrl); 
																										  [GoogleAuth uploadPhoto:e3node];
																									  }
																								  }];
																		  }
																	  }
																  }];
								}
							}
						}];
}

+ (void)uploadPhoto:(E3 *)e3node
{
	assert(e3node);
	if (e3node==nil && e3node.photoData==nil) {
		NSLog(@"GoogleAuth: uploadPhoto: No photoData");
		return;
	}
	
	if (staticPhotoAlbumUrl==nil) {
		// Picasa Album["PackList Photo"] の中へアップロードする
		[GoogleAuth uploadPhotoAlbum:(E3 *)e3node];
		return;
	}
	
	GDataServiceGooglePhotos *service = [GoogleAuth servicePhotos];
	if (service==nil) {
		return;
	}
	
	// Picasaへアップロードする
	GDataEntryPhoto *newEntry = [GDataEntryPhoto photoEntry];
	
	if (0 < [e3node.name length]) {
		[newEntry setTitleWithString: e3node.name];
	} else {
		[newEntry setTitleWithString: @"No Name"];
	}
	[newEntry setPhotoDescriptionWithString:NSLocalizedString(@"Picasa Photo Description", nil)];
	
	if ([e3node.photoUrl hasPrefix:PHOTO_URL_UUID_PRIFIX]) {
		[newEntry setETag:e3node.photoUrl];  //UUID
	}
	[newEntry setUploadData:e3node.photoData];
	[newEntry setUploadMIMEType:@"image/jpeg"];
	[newEntry setUploadSlug:@"PackList"];
	NSLog(@"GoogleAuth: uploadPhoto: newEntry='%@'", newEntry);
	
	assert(staticPhotoAlbumUrl);
	// 開始
	[service fetchEntryByInsertingEntry: newEntry
											  forFeedURL: staticPhotoAlbumUrl
									   completionHandler:^(GDataServiceTicket *ticket, GDataEntryBase *entry, NSError *error) {
										   if (error) {
											   // 失敗
											   NSLog(@"GoogleAuth: uploadPhoto: Failed '%@'", error.localizedDescription);
										   } else {
											   // 成功
											   GDataEntryContent *ec = [entry content];
											   NSLog(@"GoogleAuth: uploadPhoto: URL [ec sourceURI]=[%@]", [ec sourceURI]);	//NSString
											   /*** ETag = UUID とする。
												// e3target を更新する
											   e3node.photoUrl = [NSString stringWithString:[ec sourceURI]];
											   NSError *error;
											   if (![e3node.managedObjectContext save:&error]) {
												   NSLog(@"GoogleAuth: uploadPhoto: MOC error %@, %@", error, [error userInfo]);
												   assert(NO); //DEBUGでは落とす
											   }*/ 
										   }
									   }];
}

+ (void)downloadPhotoE3:(E3 *)e3node  imageView:(UIImageView *)imageView
{
	assert(e3node);
	if (e3node==nil  OR  e3node.photoUrl==nil) {
		NSLog(@"GoogleAuth: downloadPhotoE3: No photoUrl");
		return;
	}
	if (e3node.photoData) {
		NSLog(@"GoogleAuth: downloadPhotoE3: exist photoData");
		return;
	}
	
	UIActivityIndicatorView *actInd = nil;
	if (imageView) {
		actInd = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		actInd.frame = imageView.bounds;
		[imageView addSubview:actInd];
		[actInd startAnimating];
	}
	
	GDataServiceGooglePhotos *service = [GoogleAuth servicePhotos];
	
	NSMutableURLRequest *request;
	if ([e3node.photoUrl hasPrefix:PHOTO_URL_UUID_PRIFIX]) {
		request = [service requestForURL:nil ETag:e3node.photoUrl  httpMethod:nil];
	} else {
		request = [service requestForURL:[NSURL URLWithString: e3node.photoUrl]  ETag:nil   httpMethod:nil];
	}
	
	// fetch the request
	GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithRequest:request];

	// http logs are easier to read when fetchers have comments
	[fetcher setCommentWithFormat:@"downloading %@", e3node.name];
	
	[fetcher beginFetchWithCompletionHandler:^(NSData *data, NSError *error) {
		if (error) {
			NSLog(@"GoogleAuth: downloadPhotoE3: beginFetchWithCompletionHandler Failed '%@'\n", error.localizedDescription);
		} else {
			NSLog(@"GoogleAuth: downloadPhotoE3: beginFetchWithCompletionHandler OK");
			// e3target を更新する　＜＜他の変更が無く、これだけ更新するので、即保存する
			e3node.photoData = [NSData dataWithData:data];
			// URL
			//e3node.photoUrl = 
			NSError *error;
			if (![e3node.managedObjectContext save:&error]) {
				NSLog(@"GoogleAuth: downloadPhotoE3: MOC error %@, %@", error, [error userInfo]);
				assert(NO); //DEBUGでは落とす
			} 
			if (imageView) {
				imageView.image = [UIImage imageWithData:data];
			}
		}
		// END
		if (imageView) {
			imageView.backgroundColor = [UIColor clearColor];
			[actInd stopAnimating];
			[actInd removeFromSuperview];
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
			//			  [GoogleAuth makeFolder:FOLDER_PACKLIST uploadFile:nil];
			//			  [GoogleAuth makeFolder:FOLDER_PHOTO uploadFile:nil];
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
