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
#import "AZPicasa.h"

#define ALBUM_NAME		@"AzPackList5"

@implementation AZPicasa
{
	GDataServiceGooglePhotos	*photoService_;
	GDataFeedPhotoAlbum			*feedAlbum_;
}


- (GDataServiceGooglePhotos *)photoService
{
	if (photoService_) {
		return photoService_;
	}
	// NEW
	photoService_ = [[GDataServiceGooglePhotos alloc] init];
	[photoService_ setUserCredentialsWithUsername:@"azpacking@gmail.com"   password:@"enjiSmei"];
	return photoService_;
}

- (id)init
{	// 専用アルバムが無ければ追加する
    self = [super init];
    if (self==nil) return nil;

	// Custom initialization
	// get the URL for the user
	NSURL *userURL = [GDataServiceGooglePhotos
					  photoFeedURLForUserID:@"azpacking" albumID:nil
					  albumName:nil photoID:nil kind:@"album" access:nil];
	NSLog(@"GDataServiceGooglePhotos: userURL='%@'", userURL);
	
	[[self photoService] fetchFeedWithURL:userURL
			completionHandler:^(GDataServiceTicket *ticket, GDataFeedBase *feed, NSError *error) {
				NSLog(@"Album: feed='%@'\n", feed);
				if (error) {
					// 失敗
					NSLog(@"Album: Failed '%@'\n", error.localizedDescription);
					//alertBox(@"New Album: Failed", error.localizedDescription, @"OK");
				} else {
					// 成功
					NSLog(@"Album: OK ticket=[%@]\n  feed=[%@]\n", ticket, feed);
					BOOL bNew = YES;
					
					for (GDataEntryPhotoAlbum *album in [feed entries]) {
						NSLog(@"--- Album: %@", [album title]);
						if ([[[album title] contentStringValue] isEqualToString:ALBUM_NAME]) {
							NSLog(@"Album Find OK!");
							bNew = NO;
							break;
						}
					}
					if (bNew) {
						NSLog(@"No Album");
						// アルバムを追加する
						NSURL *postLink =  [[feed postLink] URL];
						GDataEntryPhotoAlbum *newAlbum = [GDataEntryPhotoAlbum albumEntry];
						[newAlbum setTitleWithString:ALBUM_NAME];
						//[newAlbum setPhotoDescriptionWithString:@""];
						[newAlbum setAccess:kGDataPhotoAccessPrivate];  //or kGDataPhotoAccessPublic
						// 開始
						[[self photoService] fetchEntryByInsertingEntry:newAlbum forFeedURL:postLink 
													  completionHandler:^(GDataServiceTicket *ticket, GDataEntryBase *entry, NSError *error) {
														  NSLog(@"New Album: ticket description='%@'\n", [ticket description]);
														  if (error) {
															  // 失敗
															  NSLog(@"New Album: Failed '%@'\n", error.localizedDescription);
															  //alertBox(@"New Album: Failed", error.localizedDescription, @"OK");
														  } else {
															  // 成功
															  NSLog(@"New Album: OK ticket=[%@]\n  entry=[%@]\n", ticket, entry);
														  }
													  }];
					}
				}
			}];
	return self;
}

- (void)uploadData:(NSData *)photoData  photoTitle:(NSString *)photoTitle
{
	assert(photoData);
	// 写真を追加する
	// get the URL for the album
	NSURL *albumURL = [GDataServiceGooglePhotos
					   photoFeedURLForUserID:@"azpacking" 
					   albumID:nil
					   albumName:ALBUM_NAME
					   photoID:nil kind:nil access:nil];
	NSLog(@"Upload: albumURL='%@'", albumURL);
	
	[[self photoService] fetchFeedWithURL:albumURL
						completionHandler:^(GDataServiceTicket *ticket, GDataFeedBase *feed, NSError *error) {
							NSLog(@"Album: feed='%@'\n", feed);
							if (error) {
								// 失敗
								NSLog(@"Album: Failed '%@'\n", error.localizedDescription);
								//alertBox(@"New Album: Failed", error.localizedDescription, @"OK");
							} else {
								// 成功
								NSLog(@"Album: OK ticket=[%@]\n  feed=[%@]\n", ticket, feed);
								// 写真を追加する
								//NSURL *uploadURL =  [[feed postLink] URL];
								NSURL *uploadURL = [NSURL URLWithString:kGDataGooglePhotosDropBoxUploadURL];

								GDataEntryPhoto *newPhoto = [GDataEntryPhoto photoEntry];
								[newPhoto setTitleWithString:photoTitle];
								[newPhoto setPhotoDescriptionWithString:@"PackList"];
								//[newPhoto setTimestamp:[GDataPhotoTimestamp timestampWithDate:[NSDate date]]];
								
								// attach the photo data
								[newPhoto setPhotoData:photoData];
								
								//NSString *mimeType = [GDataUtilities MIMETypeForFileAtPath:photoPath
								//                                           defaultMIMEType:@"image/jpeg"];
								//[newPhoto setPhotoMIMEType:mimeType];
								[newPhoto setPhotoMIMEType:@"image/jpeg"];
								
								// the slug is just the upload file's filename
								[newPhoto setUploadSlug:photoTitle];
								NSLog(@"Upload: newPhoto='%@'", newPhoto);
								// 開始
								[[self photoService] fetchEntryByInsertingEntry:newPhoto forFeedURL:uploadURL 
															  completionHandler:^(GDataServiceTicket *ticket, GDataEntryBase *entry, NSError *error) {
																  NSLog(@"Upload: ticket description='%@'", [ticket description]);
																  if (error) {
																	  // 失敗
																	  NSLog(@"Upload: Failed '%@'", error.localizedDescription);
																	  //alertBox(@"Upload: Failed", error.localizedDescription, @"OK");
																  } else {
																	  // 成功
																	  //NSLog(@"Upload: OK ticket=[%@]  entry=[%@]", ticket, entry);
																	  //NSLog(@"[entry identifier]=[%@]", [entry identifier]);
																	  //NSLog(@"URL [entry content]=[%@]", [entry content]);
																	  GDataEntryContent *ec = [entry content];
																	  NSLog(@"URL [ec sourceURI]=[%@]", [ec sourceURI]);
																	  NSLog(@"URL [ec sourceURL]=[%@]", [ec sourceURL]);
																	  // この後、e3.photoUrl を更新する
																  }
															  }];
							}
						}];
}



@end
