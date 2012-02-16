//
//  GoogleService.m
//  AzPackList5
//
//  Created by Sum Positive on 12/02/11.
//  Copyright (c) 2012 Azukid. All rights reserved.
//

#import "Global.h"
#import "AppDelegate.h"
#import "SFHFKeychainUtils.h"
#import "EntityRelation.h"
#import "GData.h"
#import "GDataDocs.h"
#import "GDataPhotos.h"
#import "GoogleService.h"



@implementation GoogleService

#pragma mark - Login Test
+ (void)loginID:(NSString*)googleID  withPW:(NSString*)googlePW  isSetting:(BOOL)isSetting
{
	NSLog(@"GoogleService: loginID :-----------------------");
	if ([googleID length]<=0 OR [googlePW length]<=0) {
		if (isSetting) alertBox(NSLocalizedString(@"Google Login NG", nil), nil, @"OK");
		return;
	}
	
	// Documentsに専用コレクションを作成する
	GDataServiceGoogleDocs *docService = [[GDataServiceGoogleDocs alloc] init];
	[docService setUserCredentialsWithUsername:googleID password:googlePW];
	
	// ログインテスト　成功すればPWを登録する
	NSURL *docsUrl = [GDataServiceGoogleDocs docsFeedURL];
	[docService fetchFeedWithURL: docsUrl
			completionHandler:^(GDataServiceTicket *ticket, GDataFeedBase *feed, NSError *error) {
				if (error) {
					// 失敗
					NSLog(@"GoogleService(100) Failed '%@'\n", error.localizedDescription);
					if (isSetting) alertBox(NSLocalizedString(@"Google Login NG", nil), nil, @"OK");
				} else {
					// 成功
					if (isSetting) {
						// PW KeyChainに保存する
						NSError *error; // nilを渡すと異常終了するので注意
						[SFHFKeychainUtils storeUsername:GS_KC_LoginPassword
											 andPassword: googlePW
										  forServiceName:GS_KC_ServiceName 
										  updateExisting:YES error:&error];
						alertBox(NSLocalizedString(@"Google Login OK", nil), NSLocalizedString(@"Google Login OK msg",nil), @"OK");
					}
				}
			}];
}


#pragma mark - Document
// Google Documents
static	GDataServiceGoogleDocs		*sDocService = nil;
static	NSURL										*sDocUploadUrl = nil;

+ (GDataServiceGoogleDocs *)docService
{
	if (sDocService) {
		return sDocService;
	}
	// NEW
	sDocService = [[GDataServiceGoogleDocs alloc] init];
	// Login
	NSError *error;
	NSString *username = [SFHFKeychainUtils getPasswordForUsername:GS_KC_LoginName
													andServiceName:GS_KC_ServiceName error:&error];
	NSString *password = [SFHFKeychainUtils getPasswordForUsername:GS_KC_LoginPassword
													andServiceName:GS_KC_ServiceName error:&error];
	[sDocService setUserCredentialsWithUsername:username password:password];
	NSLog(@"GDataServiceGoogleDocs: NEW sDocService=%@", [sDocService description]);
	return sDocService;
}

+ (void)docFolderUploadFile:(NSString*)pathLocal  withName:(NSString*)name
{	// 専用コレクションを見つけるか、新規追加し、その位置を sDocUploadUrl にセットする
	// Documentsに専用コレクションを作成する
	GDataServiceGoogleDocs *docService = [self docService];
	//[docService setUserCredentialsWithUsername:googleID password:googlePW];
	
	NSURL *docsUrl = [GDataServiceGoogleDocs docsFeedURL];
	[docService fetchFeedWithURL: docsUrl
			   completionHandler:^(GDataServiceTicket *ticket, GDataFeedBase *feed, NSError *error) {
				   if (error) {
					   // 失敗
					   NSLog(@"GoogleService(100) Failed '%@'\n", error.localizedDescription);
					   return;
				   } else {
					   // 成功
					   BOOL bNew = YES;
					   for (GDataEntryFolderDoc *folder in [feed entries]) {
						   if ([[[folder title] contentStringValue] isEqualToString:GS_DOC_FOLDER_NAME]) {
							   // 既存コレクションあり
							   NSURL *folderUrl = [[folder feedLink] URL];
							   if (folderUrl) {
								   [docService fetchFeedWithURL: folderUrl
											  completionHandler:^(GDataServiceTicket *ticket, GDataFeedBase *feed, NSError *error) {
												  if (error) {
													  NSLog(@"GoogleService(200) fetchFeedWithURL Failed '%@'\n", error.localizedDescription);
													  return;
												  } else {
													  sDocUploadUrl = [[feed uploadLink] URL];
													  NSLog(@"GoogleService(300) OK sDocUploadUrl=[%@]\n", sDocUploadUrl); 
												  }
											  }];
							   }
							   bNew = NO;
							   break;
						   }
					   }
					   if (bNew) {
						   // コレクションなし、追加する
						   NSURL *postLink =  [[feed postLink] URL];
						   GDataEntryFolderDoc *newFolder = [GDataEntryFolderDoc documentEntry];
						   [newFolder setTitleWithString:GS_DOC_FOLDER_NAME];
						   
						   // 開始
						   [docService fetchEntryByInsertingEntry: newFolder
													   forFeedURL: postLink 
												completionHandler:^(GDataServiceTicket *ticket, GDataEntryBase *entry, NSError *error) {
													if (error) {
														// 失敗
														NSLog(@"GoogleService(400) NEW Folder Failed '%@'\n", error.localizedDescription);
														return;
													} else {
														// 成功
														GDataEntryFolderDoc *folder = (GDataEntryFolderDoc *)entry;
														NSURL *folderUrl = [[folder feedLink] URL];
														if (folderUrl) {
															[docService fetchFeedWithURL: folderUrl
																				completionHandler:^(GDataServiceTicket *ticket, GDataFeedBase *feed, NSError *error) {
																					if (error) {
																						NSLog(@"GoogleService(500) NEW Folder fetchFeedWithURL Failed '%@'\n", error.localizedDescription);
																						return;
																					} else {
																						sDocUploadUrl = [[feed uploadLink] URL];
																						NSLog(@"GoogleService(600) NEW Folder OK sDocUploadUrl=[%@]\n", sDocUploadUrl); 
																					}
																				}];
														}
													}
												}];
					   }
				   }
			   }];
}

+ (void)docUploadFile:(NSString*)pathLocal  withName:(NSString*)name
{
	
}

+ (void)docDownloadFile:(NSString*)pathLocal
{
	
}


#pragma mark - Photo <Picasa>
// Google Photo <Picasa>
static	GDataServiceGooglePhotos	*sPhotoService = nil;
static	NSURL										*sPhotoUploadUrl = nil;

+ (GDataServiceGooglePhotos *)photoService
{
	if (sPhotoService) {
		return sPhotoService;
	}
	// NEW
	sPhotoService = [[GDataServiceGooglePhotos alloc] init];
	// Login
	NSError *error;
	NSString *username = [SFHFKeychainUtils getPasswordForUsername:GS_KC_LoginName
													andServiceName:GS_KC_ServiceName error:&error];
	NSString *password = [SFHFKeychainUtils getPasswordForUsername:GS_KC_LoginPassword
													andServiceName:GS_KC_ServiceName error:&error];
	[sPhotoService setUserCredentialsWithUsername:username password:password];
	NSLog(@"GDataServiceGooglePhotos: NEW sPhotoService=%@", [sPhotoService description]);
	return sPhotoService;
}

+ (void)photoAlbumUploadE3:(E3*)e3target
{	// 専用アルバムを見つけるか、新規追加し、その位置を sPhotoUploadUrl にセットする
	NSLog(@"GoogleService: photoAlbumUploadE3 :-----------------------");
	GDataServiceGooglePhotos *photoService = [self photoService];
	//[photoService setUserCredentialsWithUsername:googleID password:googlePW];
	
	// get the URL for the user
	if ([photoService username]==nil) {
		NSLog(@"\t username=nil  NoLogin");
		return;
	}
	//NSURL *photosUrl = [GDataServiceGooglePhotos photoContactsFeedURLForUserID: [photoService username]];
	NSURL *photosUrl = [GDataServiceGooglePhotos
						photoFeedURLForUserID: [photoService username]
						albumID:nil	albumName:nil  photoID:nil
						kind:@"album" 
						access:nil];
	NSLog(@"\t photosUrl='%@'", photosUrl);
	
	[photoService fetchFeedWithURL: photosUrl
				 completionHandler:^(GDataServiceTicket *ticket, GDataFeedBase *feed, NSError *error) {
					 if (error) {
						 // 失敗
						 NSLog(@"\t Failed '%@'\n", error.localizedDescription);
						 return;
					 } else {
						 // 成功
						 for (GDataEntryPhotoAlbum *album in [feed entries]) {
							 if ([[[album title] contentStringValue] isEqualToString:GS_PHOTO_ALBUM_NAME]) {
								 NSURL *albumUrl = [[album feedLink] URL];
								 if (albumUrl) {
									 [photoService fetchFeedWithURL: albumUrl
												  completionHandler:^(GDataServiceTicket *ticket, GDataFeedBase *feed, NSError *error) {
													  if (error) {
														  NSLog(@"\t Failed '%@'", error.localizedDescription);
													  } else {
														  sPhotoUploadUrl = [[feed uploadLink] URL];
														  NSLog(@"\t Album Find sPhotoUploadUrl=[%@]", sPhotoUploadUrl); 
														  // 専用アルバムへ写真を保存する
														  [self photoUploadE3:e3target];
													  }
												  }];
								 }
								 return;
							 }
						 }
						 // アルバムを追加する
						 NSLog(@"\t Album NEW"); 
						 NSURL *postLink =  [[feed postLink] URL];
						 GDataEntryPhotoAlbum *newAlbum = [GDataEntryPhotoAlbum albumEntry];
						 [newAlbum setTitleWithString: GS_PHOTO_ALBUM_NAME];
						 [newAlbum setPhotoDescriptionWithString:NSLocalizedString(@"Picasa Album Description", nil)];
						 [newAlbum setAccess:kGDataPhotoAccessPrivate];  //or kGDataPhotoAccessPublic
						 // 開始
						 [photoService fetchEntryByInsertingEntry: newAlbum 
													   forFeedURL: postLink 
												completionHandler:^(GDataServiceTicket *ticket, GDataEntryBase *entry, NSError *error) {
													if (error) {
														// 失敗
														NSLog(@"\t Album NEW Failed '%@'\n", error.localizedDescription);
													} else {
														// 成功
														GDataEntryPhotoAlbum *album = (GDataEntryPhotoAlbum*)entry;
														NSURL *albumUrl = [[album feedLink] URL];
														if (albumUrl) {
															[photoService fetchFeedWithURL: albumUrl
																		 completionHandler:^(GDataServiceTicket *ticket, GDataFeedBase *feed, NSError *error) {
																			 if (error) {
																				 NSLog(@"\t Album NEW Failed '%@'\n", error.localizedDescription);
																			 } else {
																				 sPhotoUploadUrl = [[feed uploadLink] URL];
																				 NSLog(@"\t Album NEW sPhotoUploadUrl=[%@]", sPhotoUploadUrl); 
																				 // 専用アルバムへ写真を保存する
																				 [self photoUploadE3:e3target];
																			 }
																		 }];
														}
													}
												}];
					 }
				 }];
}

+ (void)photoUploadE3:(E3*)e3target
{
	NSLog(@"GoogleService: photoUploadE3 :-----------------------");
	assert(e3target);
	if (e3target==nil && e3target.photoData==nil) {
		NSLog(@"G> No photoData");
		return;
	}
	if ([e3target.photoUrl hasPrefix:@"http"]) {
		NSLog(@"G> Exist photoUrl=%@", e3target.photoUrl);
		return;
	}

	// 写真を追加する
	@synchronized(self)	// 連続したとき、アルバムが重複作成されないようにするため。
	{
		if (sPhotoUploadUrl==nil) {
			[self photoAlbumUploadE3:e3target]; // アルバムを追加してから、ここに戻って写真を追加する
			return;
		}
	}

	GDataEntryPhoto *newPhoto = [GDataEntryPhoto photoEntry];
	if (0 < [e3target.name length]) {
		[newPhoto setTitleWithString: e3target.name];
	} else {
		[newPhoto setTitleWithString: @"Goods"];
	}
	
	[newPhoto setPhotoDescriptionWithString:e3target.photoUrl]; // "PackList:" & UUID
	
	// attach the photo data
	assert(e3target.photoData);
	[newPhoto setPhotoData: e3target.photoData];
	[newPhoto setPhotoMIMEType:@"image/jpeg"];
	
	// the slug is just the upload file's filename
	[newPhoto setUploadSlug: @"PackList"];
	NSLog(@"G> newPhoto='%@'", newPhoto);
	
	// 開始
	[[self photoService] fetchEntryByInsertingEntry: newPhoto
								  forFeedURL: sPhotoUploadUrl
								  completionHandler:^(GDataServiceTicket *ticket, GDataEntryBase *entry, NSError *error) {
									  if (error) {
										  // 失敗
										  NSLog(@"G> Failed '%@'", error.localizedDescription);
										  if (error.code==404) {	// 404 data:No album found.
											  alertBox(NSLocalizedString(@"Google NoAlbum", nil), 
													   NSLocalizedString(@"Google NoAlbum msg", nil), @"OK");
											  sPhotoUploadUrl = nil;  // 改めてアルバム追加させるため
										  }
									  } else {
										  // 成功
										  GDataEntryContent *ec = [entry content];
										  NSLog(@"G> OK [ec sourceURI]=[%@]", [ec sourceURI]);	//NSString
										  // e3target を更新する
										  e3target.photoUrl = [NSString stringWithString:[ec sourceURI]];
										  NSError *error;
										  if (![e3target.managedObjectContext save:&error]) {
											  NSLog(@"G> MOC save error %@, %@", error, [error userInfo]);
											  assert(NO); //DEBUGでは落とす
										  } 
										  AppDelegate *ad = (AppDelegate *)[[UIApplication sharedApplication] delegate];
										  ad.app_UpdateSave = NO; //保存済み
									  }
								  }];
}


+ (void)photoDownloadE3:(E3*)e3target  imageView:(UIImageView*)imageView
{
	NSLog(@"GoogleService: photoDownloadE3 :-----------------------");
	assert(e3target);
	if (e3target==nil && e3target.photoUrl==nil) {
		NSLog(@"G> No photoUrl");
		return;
	}
	if (e3target.photoData) {
		NSLog(@"G> Exist photoData");
		return;
	}

	GDataServiceGooglePhotos *service = [self photoService];
	NSMutableURLRequest *request;
	if ([e3target.photoUrl  hasPrefix:GS_PHOTO_UUID_PREFIX]) {
		// Description を検索する
		// "/feed/subtitle"
		return;  // 検索方法が解らないので実装保留
	} else {
		request = [service requestForURL:[NSURL URLWithString: e3target.photoUrl]  ETag:nil   httpMethod:nil];
	}
	// fetch the request
	GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithRequest:request];
	[fetcher setAuthorizer:[service authorizer]];
	
	// http logs are easier to read when fetchers have comments
	[fetcher setCommentWithFormat:@"downloading %@", e3target.name];
	
	UIActivityIndicatorView *actInd = nil;
	if (imageView) {
		actInd = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		actInd.frame = imageView.bounds;
		[imageView addSubview:actInd];
		[actInd startAnimating];
	}
	
	[fetcher beginFetchWithCompletionHandler:^(NSData *data, NSError *error) {
		if (error) {
			NSLog(@"G> Failed '%@'\n", error.localizedDescription);
			// error.code=404 data:No photo found.
			// Picasaにアップされたはずだが、ダウンロードできなかったことを示すアイコンを表示する
			e3target.photoData = UIImagePNGRepresentation([UIImage imageNamed:@"Icon64-DownloadNG"]);
		}
		else {
			NSLog(@"G> OK");
			// e3target を更新する　＜＜他の変更が無く、これだけ更新するので、即保存する
			e3target.photoData = [NSData dataWithData:data];
			NSError *error;
			if (![e3target.managedObjectContext save:&error]) {
				NSLog(@"G> MOC save error %@, %@", error, [error userInfo]);
				assert(NO); //DEBUGでは落とす
			} 
			AppDelegate *ad = (AppDelegate *)[[UIApplication sharedApplication] delegate];
			ad.app_UpdateSave = NO; //保存済み
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


@end
