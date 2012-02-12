//
//  AZPicasa.m
//  AzPackList5
//
//  Created by Sum Positive on 12/02/11.
//  Copyright (c) 2012 Azukid. All rights reserved.
//

#import "Global.h"
#import "AppDelegate.h"
#import "SFHFKeychainUtils.h"
#import "Elements.h"
#import "EntityRelation.h"
#import "AZPicasa.h"

#define ALBUM_NAME		@"PackList Photo"

/*
NSString *uuidString()
{
	CFUUIDRef uuidObj = CFUUIDCreate(nil);	//create a new UUID
	NSString *uuid = (__bridge_transfer NSString *)CFUUIDCreateString(nil, uuidObj);
	CFRelease(uuidObj);
	return uuid;
}
*/

@implementation AZPicasa
{
	AppDelegate							*appDelegate_;
	GDataServiceGooglePhotos	*photoService_;
	NSURL										*uploadUrl_;
}


- (GDataServiceGooglePhotos *)photoService
{
	if (photoService_) {
		return photoService_;
	}
	// NEW
	photoService_ = [[GDataServiceGooglePhotos alloc] init];
	//[photoService_ setUserCredentialsWithUsername:@"azpacking@gmail.com"   password:@"enjiSmei"];
	return photoService_;
}

- (void)loginID:(NSString*)googleID  withPW:(NSString*)googlePW  isSetting:(BOOL)isSetting
{
	if ([googleID length]<=0 OR [googlePW length]<=0) {
		if (isSetting) alertBox(NSLocalizedString(@"Picasa login NG", nil), nil, @"OK");
		return;
	}
	
	GDataServiceGooglePhotos *service = [self photoService];
	[service setUserCredentialsWithUsername:googleID password:googlePW];

	// get the URL for the user
	NSURL *userURL = [GDataServiceGooglePhotos
					  photoFeedURLForUserID:@"azpacking" albumID:nil
					  albumName:nil photoID:nil kind:@"album" access:nil];
	NSLog(@"AZPicasa: init: userURL='%@'", userURL);
	
	[[self photoService] fetchFeedWithURL:userURL
			completionHandler:^(GDataServiceTicket *ticket, GDataFeedBase *feed, NSError *error) {
				NSLog(@"AZPicasa: init: feed='%@'\n", feed);
				if (error) {
					// 失敗
					NSLog(@"AZPicasa: init: Failed '%@'\n", error.localizedDescription);
					if (isSetting) alertBox(NSLocalizedString(@"Picasa login NG", nil), nil, @"OK");
				} else {
					// 成功
					if (isSetting) {
						// PW KeyChainに保存する
						NSError *error; // nilを渡すと異常終了するので注意
						[SFHFKeychainUtils storeUsername:GD_PicasaPW
											 andPassword: googlePW
										  forServiceName:GD_PRODUCTNAME 
										  updateExisting:YES error:&error];
						alertBox(NSLocalizedString(@"Picasa login OK", nil), NSLocalizedString(@"Picasa login OK msg",nil), @"OK");
					}
					BOOL bNew = YES;
					for (GDataEntryPhotoAlbum *album in [feed entries]) {
						//NSLog(@"AZPicasa: init: album.title=[%@]  GPhotoID=[%@]", [album title], [album GPhotoID]);
						if ([[[album title] contentStringValue] isEqualToString:ALBUM_NAME]) {
							NSURL *feedURL = [[album feedLink] URL];
							if (feedURL) {
								[[self photoService] fetchFeedWithURL:feedURL
													completionHandler:^(GDataServiceTicket *ticket, GDataFeedBase *feed, NSError *error) {
														if (error) {
															NSLog(@"AZPicasa: init: fetchFeedWithURL Failed '%@'\n", error.localizedDescription);
														} else {
															uploadUrl_ = [[feed uploadLink] URL];
															NSLog(@"AZPicasa: init: OK uploadUrl_=[%@]\n", uploadUrl_); 
														}
													}];
							}
							bNew = NO;
							break;
						}
					}
					if (bNew) {
						NSLog(@"AZPicasa: init: No Album");
						// アルバムを追加する
						NSURL *postLink =  [[feed postLink] URL];
						GDataEntryPhotoAlbum *newAlbum = [GDataEntryPhotoAlbum albumEntry];
						[newAlbum setTitleWithString:ALBUM_NAME];
						[newAlbum setPhotoDescriptionWithString:NSLocalizedString(@"Picasa Album Description", nil)];
						[newAlbum setAccess:kGDataPhotoAccessPrivate];  //or kGDataPhotoAccessPublic
						// 開始
						[[self photoService] fetchEntryByInsertingEntry:newAlbum forFeedURL:postLink 
													  completionHandler:^(GDataServiceTicket *ticket, GDataEntryBase *entry, NSError *error) {
														  if (error) {
															  // 失敗
															  NSLog(@"AZPicasa: init: New Album Failed '%@'\n", error.localizedDescription);
														  } else {
															  // 成功
															  //NSLog(@"AZPicasa: init: New Album OK ticket=[%@]\n  entry=[%@]\n", ticket, entry);
															  GDataEntryPhotoAlbum *album = (GDataEntryPhotoAlbum*)entry;
															  //NSLog(@"AZPicasa: init: New Album OK [album GPhotoID]=[%@]\n", [album GPhotoID]); 
															  NSURL *feedURL = [[album feedLink] URL];
															  if (feedURL) {
																  [[self photoService] fetchFeedWithURL:feedURL
																					  completionHandler:^(GDataServiceTicket *ticket, GDataFeedBase *feed, NSError *error) {
																						  if (error) {
																							  NSLog(@"AZPicasa: init: New Album fetchFeedWithURL Failed '%@'\n", error.localizedDescription);
																						  } else {
																							  uploadUrl_ = [[feed uploadLink] URL];
																							  NSLog(@"AZPicasa: init: New Album OK uploadUrl_=[%@]\n", uploadUrl_); 
																						  }
																					  }];
															  }
														  }
													  }];
					}
				}
			}];
}

- (id)init
{	// 専用アルバムが無ければ追加する
    self = [super init];
    if (self==nil) return nil;
	
	appDelegate_ = (AppDelegate *)[[UIApplication sharedApplication] delegate];

	NSError *error;
	NSString *uid = [SFHFKeychainUtils getPasswordForUsername:GD_PicasaID
											   andServiceName:GD_PRODUCTNAME error:&error];
	NSString *upw = [SFHFKeychainUtils getPasswordForUsername:GD_PicasaPW
											   andServiceName:GD_PRODUCTNAME error:&error];
	[self loginID:uid withPW:upw isSetting:NO];
	return self;
}

//- (void)uploadData:(NSData *)photoData  photoTitle:(NSString *)photoTitle
- (void)uploadE3:(E3*)e3target
{
	assert(e3target);
	if (e3target==nil && e3target.photoData==nil) {
		NSLog(@"AZPicasa: uploadE3: No photoData");
		return;
	}
	if (e3target.photoUrl) {
		NSLog(@"AZPicasa: uploadE3: exist photoUrl=%@", e3target.photoUrl);
		return;
	}

	/* insertだけでも変更が生じているため、常時保存にした。
	NSManagedObjectContext *moc = e3target.managedObjectContext;
	if (moc && [moc hasChanges]) { //未保存があれば中止する
		NSLog(@"AZPicasa: uploadE3: moc hasChanges");
		return;
	}*/
	
	// 写真を追加する
	// get the URL for the album
	NSLog(@"AZPicasa: uploadE3: uploadUrl_=[%@]", uploadUrl_);
	if (uploadUrl_==nil) {
		NSLog(@"AZPicasa: uploadE3: uploadUrl_=nil");
		return;
	}

	GDataEntryPhoto *newPhoto = [GDataEntryPhoto photoEntry];
	if (0 < [e3target.name length]) {
		[newPhoto setTitleWithString: e3target.name];
	} else {
		[newPhoto setTitleWithString: @"No Name"];
	}
	[newPhoto setPhotoDescriptionWithString:NSLocalizedString(@"Picasa Photo Description", nil)];
	
	// attach the photo data
	[newPhoto setPhotoData: e3target.photoData];
	[newPhoto setPhotoMIMEType:@"image/jpeg"];
	
	// the slug is just the upload file's filename
	[newPhoto setUploadSlug: @"PackList"];
	NSLog(@"AZPicasa: uploadE3: newPhoto='%@'", newPhoto);
	
	// 開始
	[[self photoService] fetchEntryByInsertingEntry:newPhoto forFeedURL:uploadUrl_ 
								  completionHandler:^(GDataServiceTicket *ticket, GDataEntryBase *entry, NSError *error) {
									  //NSLog(@"AZPicasa: uploadE3: ticket description='%@'", [ticket description]);
									  if (error) {
										  // 失敗
										  NSLog(@"AZPicasa: uploadE3: Failed '%@'", error.localizedDescription);
									  } else {
										  // 成功
										  GDataEntryContent *ec = [entry content];
										  NSLog(@"AZPicasa: uploadE3: URL [ec sourceURI]=[%@]", [ec sourceURI]);	//NSString
										  // e3target を更新する
										  e3target.photoUrl = [NSString stringWithString:[ec sourceURI]];
										  NSError *error;
										  if (![e3target.managedObjectContext save:&error]) {
											  NSLog(@"AZPicasa: uploadE3: MOC error %@, %@", error, [error userInfo]);
											  assert(NO); //DEBUGでは落とす
										  } 
										  appDelegate_.app_UpdateSave = NO; //保存済み
									  }
								  }];
}


- (void)downloadE3:(E3*)e3target  imageView:(UIImageView*)imageView
{
	assert(e3target);
	if (e3target==nil && e3target.photoUrl==nil) {
		NSLog(@"AZPicasa: downloadE3: No photoUrl");
		return;
	}
	if (e3target.photoData) {
		NSLog(@"AZPicasa: downloadE3: exist photoData");
		return;
	}

	UIActivityIndicatorView *actInd = nil;
	if (imageView) {
		/*imageView.backgroundColor = [UIColor		// Azukid Color
									 colorWithRed:152/255.0f 
													green:81/255.0f 
													 blue:75/255.0f
													alpha:1.0f];*/
		actInd = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		actInd.frame = imageView.bounds;
		[imageView addSubview:actInd];
		[actInd startAnimating];
	}

	GDataServiceGooglePhotos *service = [self photoService];
	NSMutableURLRequest *request = [service requestForURL: [NSURL URLWithString: e3target.photoUrl]
													 ETag:nil   httpMethod:nil];
	// fetch the request
	GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithRequest:request];
	[fetcher setAuthorizer:[service authorizer]];
	
	// http logs are easier to read when fetchers have comments
	[fetcher setCommentWithFormat:@"downloading %@", e3target.name];
	
	[fetcher beginFetchWithCompletionHandler:^(NSData *data, NSError *error) {
		if (error) {
			NSLog(@"AZPicasa: downloadE3: beginFetchWithCompletionHandler Failed '%@'\n", error.localizedDescription);
		} else {
			NSLog(@"AZPicasa: downloadE3: beginFetchWithCompletionHandler OK");
			//NSManagedObjectContext *moc = e3target.managedObjectContext;
			//BOOL bChanged = [moc hasChanges]; ＜＜insertだけでも変更が生じているため、常時保存にした。
			// e3target を更新する　＜＜他の変更が無く、これだけ更新するので、即保存する
			e3target.photoData = [NSData dataWithData:data];
			NSError *error;
			if (![e3target.managedObjectContext save:&error]) {
				NSLog(@"AZPicasa: downloadE3: MOC error %@, %@", error, [error userInfo]);
				assert(NO); //DEBUGでは落とす
			} 
			appDelegate_.app_UpdateSave = NO; //保存済み
			if (imageView) {
				//[UIView beginAnimations:nil context:NULL]; ＜＜効果なし
				//[UIView setAnimationDuration:1.0];
				//[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
				imageView.image = [UIImage imageWithData:data];
				//[UIView commitAnimations];
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
