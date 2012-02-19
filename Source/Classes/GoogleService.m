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
#import "FileCsv.h"
#import "GoogleService.h"

#import "NSDataAddition.h"


@implementation GoogleService

#pragma mark - Alert Indicator
static UIAlertView  *staticAlert = nil;
static UIActivityIndicatorView  *staticAlertIndicator = nil;
static UIProgressView *staticAlertProgress = nil;
+ (void)alertIndicatorOn:(NSString*)zTitle
{
	if (staticAlert==nil) {
		staticAlert = [[UIAlertView alloc] initWithTitle:@"" message:@"\n\n" delegate:self 
									   cancelButtonTitle:NSLocalizedString(@"Cancel", nil) 
									   otherButtonTitles:nil];
		// Progress
		staticAlertProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
		[staticAlert addSubview:staticAlertProgress];
		// Indicator
		staticAlertIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		staticAlertIndicator.frame = CGRectMake(0, 0, 50, 50);
		[staticAlert addSubview:staticAlertIndicator];
	}
	[staticAlert setTitle:zTitle];
	[staticAlert show];
	[staticAlertProgress setFrame:CGRectMake(10, staticAlert.frame.size.height-110, staticAlert.bounds.size.width-20, 20)];
	[staticAlertProgress setProgress:0.0];
	[staticAlertProgress setHidden:YES];
	[staticAlertIndicator setFrame:CGRectMake((staticAlert.bounds.size.width-50)/2, staticAlert.frame.size.height-130, 50, 50)];
	[staticAlertIndicator startAnimating];
}
+ (void)alertIndicatorOff
{
	[staticAlertIndicator stopAnimating];
	[staticAlert dismissWithClickedButtonIndex:staticAlert.cancelButtonIndex animated:YES];
}

static GDataServiceTicket *staticActiveTicket = nil; // docのみ ＜＜photoは全てバック処理なので中断不要
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex==alertView.cancelButtonIndex) {
		if (staticActiveTicket) {
			[staticActiveTicket cancelTicket];
			staticActiveTicket = nil;
		}
		[GoogleService alertIndicatorOff];
	}
}


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
	staticActiveTicket = [docService fetchFeedWithURL: docsUrl
			completionHandler:^(GDataServiceTicket *ticket, GDataFeedBase *feed, NSError *error) {
				staticActiveTicket = nil;
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

+ (void)docUploadErrorNo:(NSInteger)errNo  description:(NSString*)description
{
	NSString *msg = [NSString stringWithFormat:@"%@ (%ld)\n", 
					 NSLocalizedString(@"Google DocUpload NG msg", nil), (long)errNo];
	if (description) {
		msg = [msg stringByAppendingString:description];
	}
	[GoogleService alertIndicatorOff];
	alertBox(NSLocalizedString(@"Google DocUpload NG", nil), msg, @"OK");
}

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

+ (void)docFolderUploadE1:(E1 *)e1node  title:(NSString*)title  crypt:(BOOL)crypt
{	// 専用コレクションを見つけるか、新規追加し、その位置を sDocUploadUrl にセットする
	// Documentsに専用コレクションを作成する
	GDataServiceGoogleDocs *docService = [self docService];
	//[docService setUserCredentialsWithUsername:googleID password:googlePW];
	
	
	NSURL *docsUrl = [GDataServiceGoogleDocs docsFeedURL];
	// PackListフォルダ（コレクション）一覧を取得する
	GDataQueryDocs *query = [GDataQueryDocs documentQueryWithFeedURL:docsUrl];
	[query setMaxResults:10];					// 一度に取得する件数
	[query setShouldShowFolders:YES];	// フォルダを表示するか
	[query setFullTextQueryString:GS_DOC_FOLDER_NAME];	 // この文字列が含まれるものを抽出する（ OR '|' 連記可能）
	
	staticActiveTicket = [docService fetchFeedWithQuery:query
				  completionHandler:^(GDataServiceTicket *ticket, GDataFeedBase *feed, NSError *error) {
					  staticActiveTicket = nil;
				   if (error) {
					   // 失敗
					   [self docUploadErrorNo:100 description:error.localizedDescription];
					   return;
				   } else {
					   // 成功
					   for (GDataEntryFolderDoc *folder in [feed entries]) {
						   NSLog(@"***[[folder title] contentStringValue]=%@", [[folder title] contentStringValue]);
						   if ([[[folder title] contentStringValue] isEqualToString:GS_DOC_FOLDER_NAME]) { // 完全一致
							   // 既存フォルダあり
							   //NSLog(@"***[[folder selfLink] URL]=%@\n", [[folder selfLink] URL]);
							   //NSURL *folderUrl = [[folder selfLink] URL];   //[[folder feedLink] URL];
							   NSURL *folderFeedURL = [[folder content] sourceURL];
							   NSLog(@"***folderFeedURL=%@\n", folderFeedURL);
							   if (folderFeedURL) {
								   staticActiveTicket = [docService fetchFeedWithURL: folderFeedURL
												completionHandler:^(GDataServiceTicket *ticket, GDataFeedBase *feed, NSError *error) {
													staticActiveTicket = nil;
													if (error) {
														[self docUploadErrorNo:200 description:error.localizedDescription];
													} else {
														sDocUploadUrl = [[feed postLink] URL];
														NSLog(@"\t Album Find sDocUploadUrl=[%@]", sDocUploadUrl); 
														[self docUploadE1:e1node  title:title  crypt:crypt]; // 改めてアップ開始する
													}
													return;
												}];
								   return;
							   }
						   }
					   }
					   // フォルダなし、追加する
					   NSURL *postLink =  [[feed postLink] URL];
					   GDataEntryFolderDoc *newFolder = [GDataEntryFolderDoc documentEntry];
					   [newFolder setTitleWithString:GS_DOC_FOLDER_NAME];
					   // 開始
					   staticActiveTicket = [docService fetchEntryByInsertingEntry: newFolder
												   forFeedURL: postLink 
											completionHandler:^(GDataServiceTicket *ticket, GDataEntryBase *entry, NSError *error) {
												staticActiveTicket = nil;
												if (error) {
													// 失敗
													[self docUploadErrorNo:300 description:error.localizedDescription];
												} else {
													// 成功
													NSLog(@"***entry=%@", entry);
													GDataEntryFolderDoc *folder = (GDataEntryFolderDoc *)entry;
													//NSURL *folderUrl = [[folder selfLink] URL];   //[[folder feedLink] URL];
													NSURL *folderFeedURL = [[folder content] sourceURL];
													NSLog(@"***folderFeedURL=%@\n", folderFeedURL);
													if (folderFeedURL) {
														staticActiveTicket = [docService fetchFeedWithURL: folderFeedURL
																   completionHandler:^(GDataServiceTicket *ticket, GDataFeedBase *feed, NSError *error) {
																	   staticActiveTicket = nil;
																	   if (error) {
																		   [self docUploadErrorNo:400 description:error.localizedDescription];
																	   } else {
																		   sDocUploadUrl = [[feed postLink] URL];
																		   NSLog(@"\t Album Find sDocUploadUrl=[%@]", sDocUploadUrl); 
																		   [self docUploadE1:e1node  title:title  crypt:crypt]; // 改めてアップ開始する
																	   }
																	   return;
																   }];
													}
												}
											}];
				   }
			   }];
}

//+ (void)docUploadFile:(NSString*)pathLocal  withName:(NSString*)name
+ (void)docUploadE1:(E1 *)e1node  title:(NSString*)title  crypt:(BOOL)crypt
{
	NSLog(@"GoogleService: docUploadE1 :-----------------------");
	assert(e1node);
	if (e1node==nil) {
		[self docUploadErrorNo:500 description:@"No E1"];
		return;
	}
	
	[GoogleService alertIndicatorOn:NSLocalizedString(@"Google Uploading", nil)];
	[staticAlertProgress setHidden:NO];
	
	// フォルダを追加する
	@synchronized(self)	// 連続したとき、フォルダが重複作成されないようにするため。
	{
		if (sDocUploadUrl==nil) {	// フォルダの所在不明のとき
			[self docFolderUploadE1:e1node  title:title  crypt:crypt]; // 専用フォルダを追加してから、ここに戻って写真を追加する
			return;
		}
	}
	// [+0.1]Folder make  (+0.1)CSV生成  [+0.7]Upload  (+0.1)Folder move
	[staticAlertProgress setProgress: 0.1];
	
	// タイトル名に拡張子(GD_EXTENSION)を付ける
	title = [title stringByDeletingPathExtension]; // 拡張子を外す
	if ([title length]<1) title = @"PackList";
	title = [title stringByAppendingPathExtension:GD_EXTENSION]; // 拡張子を付ける azp

	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(queue, ^{		// 非同期マルチスレッド処理
		// ファイルへ書き出す
		FileCsv *fcsv = [[FileCsv alloc] init];
		NSString *zErr = [fcsv zSaveTmpFile:e1node  crypt:crypt];
		
		dispatch_async(dispatch_get_main_queue(), ^{	// 終了後の処理
			if (zErr) {
				[GoogleService docUploadErrorNo:600 description:zErr];
				return;
			}
			
			// [+0.1)Folder make  (+0.1]CSV生成  [+0.7]Upload  (+0.1)Folder move
			[staticAlertProgress setProgress: 0.2];

			// Upload開始
			NSFileHandle *uploadFileHandle = [NSFileHandle fileHandleForReadingAtPath:fcsv.tmpPathFile];
			if (!uploadFileHandle) {
				NSLog(@"G> Cannot read file.  tmpPathFile=%@", fcsv.tmpPathFile);
				[self docUploadErrorNo:700 description:@"Cannot read CSV"];
				return;
			}
			
			GDataEntryDocBase *newDoc = [GDataEntryStandardDoc documentEntry];

			[newDoc setTitleWithString: title];
			[newDoc setUploadSlug: e1node.name];
			[newDoc setDocumentDescription: e1node.note];
			[newDoc setUploadFileHandle:uploadFileHandle];
			
			if (crypt) {
				[newDoc setUploadMIMEType:@"text/plain"];	//GDataEntryStandardDoc
			} else {
				[newDoc setUploadMIMEType:@"text/csv"];	//GDataEntryStandardDoc
			}
			NSLog(@"G> newDoc='%@'", newDoc);
			
			// 先ずルートにアップロードする
			NSURL *uploadURL = [GDataServiceGoogleDocs docsUploadURL];
			staticActiveTicket = [[self docService] 
								  fetchEntryByInsertingEntry: newDoc
								  forFeedURL: uploadURL
								  completionHandler:^(GDataServiceTicket *ticket, GDataEntryBase *entry, NSError *error) 
								  {
									  staticActiveTicket = nil;
									  if (error) {
										  [self docUploadErrorNo:800 description:error.localizedDescription];
									  } else {
										  // ルートへのアップ成功
										  // 次にフォルダへ挿入する
										  staticActiveTicket = [[self docService] 
																fetchEntryByInsertingEntry: entry
																forFeedURL: sDocUploadUrl
																completionHandler:^(GDataServiceTicket *ticket, GDataEntryBase *entry, NSError *error) 		  
																{
																	staticActiveTicket = nil;
																	if (error) {
																		// 失敗
																		if (error.code==404) {	// 404 data:No album found.
																			alertBox(NSLocalizedString(@"Google NoFolder", nil), 
																					 NSLocalizedString(@"Google NoFolder msg", nil), @"OK");
																			sDocUploadUrl = nil;  // 改めてフォルダ追加させるため
																		} else {
																			[self docUploadErrorNo:900 description:error.localizedDescription];
																		}
																	} else {
																		// 成功
																		GDataEntryContent *ec = [entry content];
																		NSLog(@"G> OK [ec sourceURI]=[%@]", [ec sourceURI]);	//NSString
																		[GoogleService alertIndicatorOff];
																		alertBox(NSLocalizedString(@"Google DocUpload OK", nil), nil, @"OK");
																	}
																}];
										  // Progress:フォルダ移動
										  [staticActiveTicket setUploadProgressHandler:^(GDataServiceTicketBase *ticket,
																						 unsigned long long numberOfBytesRead, unsigned long long dataLength) {
											  if (0 < dataLength) {
												  // (+0.1)Folder make  (+0.1)CSV生成  (+0.7)Upload  [+0.1]Folder move
												  [staticAlertProgress setProgress: 0.9 + 0.1*(numberOfBytesRead/dataLength)];
											  }
										  }];
									  }
								  }];
			// Progress: アップロード
			[staticActiveTicket setUploadProgressHandler:^(GDataServiceTicketBase *ticket,
														   unsigned long long numberOfBytesRead, unsigned long long dataLength) {
				if (0 < dataLength) {
					// (+0.1)Folder make  (+0.1)CSV生成  [+0.7]Upload  (+0.1)Folder move
					[staticAlertProgress setProgress: 0.2 + 0.7*(numberOfBytesRead/dataLength)];
				}
			}];
		});
	});
}


+ (void)docDownloadErrorNo:(NSInteger)errNo  description:(NSString*)description
{
	NSString *msg = [NSString stringWithFormat:@"%@ (%ld)\n", 
					 NSLocalizedString(@"Google DocDownload NG msg", nil), (long)errNo];
	if (description) {
		msg = [msg stringByAppendingString:description];
	}
	[GoogleService alertIndicatorOff];
	alertBox(NSLocalizedString(@"Google DocDownload NG", nil), msg, @"OK");
}


+ (void)docDownload_E1fromData:(NSData *)data
{	// Private
	FileCsv *fcsv = [[FileCsv alloc] init];
	NSString *savePath = fcsv.tmpPathFile;
	
	NSError *error = nil;
	BOOL didWrite = [data writeToFile:savePath  options:NSAtomicWrite  error:&error];
	if (!didWrite) {
		NSLog(@"Error saving file: %@", error);
		[GoogleService docDownloadErrorNo:200 description:error.localizedDescription];
	}
	else {
		// ダウンロード成功
		dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		dispatch_async(queue, ^{
			// CSV読み込み
			NSString *zErr = [fcsv zLoadTmpFile];  //tmpPathFile-->E1へ読み込む
			
			dispatch_async(dispatch_get_main_queue(), ^{
				if (zErr) {
					// CSV読み込み失敗
					[GoogleService docDownloadErrorNo:300 description:zErr];
				}
				else {
					// 成功
					alertBox(NSLocalizedString(@"Download successful",nil), NSLocalizedString(@"Added Plan",nil), @"OK");
				}
				[GoogleService alertIndicatorOff];
			});
		});
	}
}

+ (void)docDownload_FromEntry:(GDataEntryBase *)entry
			exportFormat:(NSString *)exportFormat
			 authService:(GDataServiceGoogle *)service 
{	// Private
	NSURL *exportURL = [[entry content] sourceURL];
	if (exportURL==nil) {
		[GoogleService docDownloadErrorNo:100 description:@"exportURL"];
	} 
	else {
		// we'll use GDataQuery as a convenient way to append the exportFormat
		// parameter of the docs export API to the content src URL
		GDataQuery *query = [GDataQuery queryWithFeedURL:exportURL];
		[query addCustomParameterWithName:@"exportFormat" value:exportFormat];
		NSURL *downloadURL = [query URL];
		NSLog(@"downloadURL=%@", [downloadURL absoluteString]);
		// read the document's contents asynchronously from the network
		NSURLRequest *request = [service requestForURL:downloadURL  ETag:nil httpMethod:nil];
		GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithRequest:request];
		//[fetcher setUserData:savePath];
		[fetcher beginFetchWithCompletionHandler:^(NSData *data, NSError *error) {
			if (error) {
				[GoogleService docDownloadErrorNo:100 description:error.localizedDescription];
			} else {
				[self docDownload_E1fromData:data];
			}
		}];
	}
}

+ (void)docDownloadEntry:(GDataEntryDocBase *)docEntry		//toPathFile:(NSString *)pathFile
{
	NSLog(@"GoogleService: docDownloadEntry :-----------------------");
	// Download開始
	[GoogleService alertIndicatorOn:NSLocalizedString(@"Google Downloading", nil)];
	
	BOOL isSpreadsheet = [docEntry isKindOfClass:[GDataEntrySpreadsheetDoc class]];
	if (!isSpreadsheet) {
		// in a revision entry, we've add a property above indicating if this is a spreadsheet revision
		isSpreadsheet = [[docEntry propertyForKey:@"is spreadsheet"] boolValue];
	}
	
	GDataServiceGoogleDocs *docService = [self docService];
	if (isSpreadsheet) {
		GDataServiceGoogleSpreadsheet *spreadsheetService = [[GDataServiceGoogleSpreadsheet alloc] init];
		[spreadsheetService setUserAgent:[docService userAgent]];
		[spreadsheetService setUserCredentialsWithUsername:[docService username]  password:[docService password]];

		GDataServiceTicket *ticket = [spreadsheetService authenticateWithDelegate:self
									  didAuthenticateSelector:@selector(spreadsheetTicket:authenticatedWithError:)];

		[ticket setProperty:docEntry forKey:@"docEntry"];
		//[ticket setProperty:pathFile forKey:@"savePath"];
	}
	else {
		[self docDownload_FromEntry:docEntry  exportFormat:@"txt"  authService:docService];
	}
}

+ (void)spreadsheetTicket:(GDataServiceTicket *)ticket  authenticatedWithError:(NSError *)error 
{
	if (error) {
		NSLog(@"Spreadsheet authentication error: %@", error);
		[GoogleService docDownloadErrorNo:300 description:error.localizedDescription];
	}
	else {
		GDataEntrySpreadsheetDoc *docEntry = [ticket propertyForKey:@"docEntry"];
		//NSString *savePath = [ticket propertyForKey:@"savePath"];
		[self docDownload_FromEntry:docEntry	exportFormat:@"csv" authService:[ticket service]];
	}
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
	
	//staticActiveTicket =  ＜＜photoは全てバック処理なので中断不要
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
									 return;
								 }
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
	// 暗号化 実験
	//NG//Not an image. [newPhoto setPhotoData: [e3target.photoData AES256EncryptWithKey:@"test"]];
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
		}
		else {
			NSLog(@"G> OK");
			// e3target を更新する　＜＜他の変更が無く、これだけ更新するので、即保存する
			// 暗号化 実験
			//NG// e3target.photoData = [data AES256DecryptWithKey:@"test"];
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
