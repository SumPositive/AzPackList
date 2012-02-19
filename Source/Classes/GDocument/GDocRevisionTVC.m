//
//  GDocRevisionTVC.m
//  AzPackList5
//
//  Created by Sum Positive on 12/02/18.
//  Copyright (c) 2012 Azukid. All rights reserved.
//

#import "Global.h"
#import "AppDelegate.h"
#import "SFHFKeychainUtils.h"
#import "Elements.h"
#import "EntityRelation.h"
#import "FileCsv.h"

#import "GoogleService.h"
#import "GDocDownloadTVC.h"
#import "GDocRevisionTVC.h"

#define TAG_ACTION_DOWNLOAD_START	900

@implementation GDocRevisionTVC
{
	AppDelegate						*mAppDelegate;
	GDataServiceGoogleDocs	*mDocService;
	GDataFeedBase					*mRevFeed;
	GDataEntryDocBase			*mRevSelect;
	BOOL									mLatestEdition;
}
@synthesize docSelect;


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
		mAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		if (mAppDelegate.app_is_iPad) {
			self.contentSizeForViewInPopover = GD_POPOVER_SIZE;
		}
		mDocService = [GoogleService docService];
		mLatestEdition = NO;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

	self.title = [[[self.docSelect title] stringValue] stringByDeletingPathExtension];
	
	// リビジョン リストを抽出する
	mRevFeed = nil;

	GDataEntryDocBase *selectedDoc = self.docSelect;
	GDataFeedLink *revisionFeedLink = [selectedDoc revisionFeedLink];
	NSURL *revisionFeedURL = [revisionFeedLink URL];
	if (revisionFeedURL) {
		// リビジョン一覧を取得する
		[mDocService fetchFeedWithURL: revisionFeedURL
					completionHandler:^(GDataServiceTicket *ticket, GDataFeedBase *feed, NSError *error) {
						if (error) {
							// 失敗
							//[GoogleService docDownloadErrorNo:100 description:error.localizedDescription];
							// リビジョンなし ： 最新版のみ
							mRevFeed = nil;
							mLatestEdition = YES; // 最新版のみ
						} else {
							// 成功
							mRevFeed = feed;
							mLatestEdition = NO;
						}
						[self.tableView reloadData];
					}];	
	}
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{   // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{   // Return the number of rows in the section.
	if (mLatestEdition) {
		return 1;
	}
    return [[mRevFeed entries] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (section==0) {
		return NSLocalizedString(@"Google - Upload Revision",nil);
	}
	return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
	if (mLatestEdition) {
		cell.textLabel.text = NSLocalizedString(@"Google Rev Latest edition",nil);
	} else {
		GDataEntryDocBase *rev = [mRevFeed entryAtIndex:indexPath.row];
		cell.textLabel.text = [NSString stringWithFormat:@"Rev. %@", [[rev editedDate] date]];
	}
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{   // Navigation logic may go here. Create and push another view controller.
	[tableView deselectRowAtIndexPath:indexPath animated:YES];	// 選択状態を解除する

	NSString *title;
	if (mLatestEdition) {
		mRevSelect = self.docSelect;
		title = NSLocalizedString(@"Google Rev Latest edition",nil);
	} else {
		mRevSelect = [mRevFeed entryAtIndex:indexPath.row];
		title = [[mRevSelect title] stringValue];
	}
	
	UIActionSheet *sheet = [[UIActionSheet alloc] 
							initWithTitle: title
							delegate:self 
							cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
							destructiveButtonTitle:nil
							otherButtonTitles:NSLocalizedString(@"Download START",nil), 
							nil];
	sheet.tag = TAG_ACTION_DOWNLOAD_START;
	[sheet showInView:self.view];
}



- (void)downloadData:(NSData *)data
{
	FileCsv *fcsv = [[FileCsv alloc] init];
	NSString *savePath = fcsv.tmpPathFile;
	
	NSError *error = nil;
	BOOL didWrite = [data writeToFile:savePath
							  options:NSAtomicWrite
								error:&error];
	
	if (!didWrite) {
		NSLog(@"Error saving file: %@", error);
		// ＜＜＜エラー発生！何らかのアラートを出すこと＞＞
		//alertBox(NSLocalizedString(@"Download Fail",nil), NSLocalizedString(@"Login please try again.",nil), @"OK");
		[GoogleService docDownloadErrorNo:200 description:error.localizedDescription];
	}
	else {
		// ダウンロード成功
		dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		dispatch_async(queue, ^{
			// CSV読み込み
			NSString *zErr = [fcsv zLoadTmpFile];  //tmpPathFile-->E1へ読み込む
			
			dispatch_async(dispatch_get_main_queue(), ^{
				// 進捗サインOFF
				if (zErr) {
					// CSV読み込み失敗
					[GoogleService docDownloadErrorNo:300 description:zErr];
				}
				else {
					// 成功
					alertBox(NSLocalizedString(@"Download Compleat!",nil), NSLocalizedString(@"Added Plan",nil), @"OK");
				}
			});
		});
	}
}

- (void)saveDocEntry:(GDataEntryBase *)entry
			  toPath:(NSString *)savePath
		exportFormat:(NSString *)exportFormat
		 authService:(GDataServiceGoogle *)service 
{
	NSURL *exportURL = [[entry content] sourceURL];
	if (exportURL != nil) {
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
				[GoogleService docDownloadErrorNo:300 description:error.localizedDescription];
			} else {
				[self downloadData: data];
			}
		}];
	}
	
}

// UIActionSheetDelegate 処理部
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (actionSheet.tag) 
	{
		case TAG_ACTION_DOWNLOAD_START:
			if (buttonIndex == 0 && mRevSelect) {  // START  actionSheetの上から順に(0〜)
				// Save File Path
				FileCsv *fcsv = [[FileCsv alloc] init];
				NSString *savePath = fcsv.tmpPathFile;
				// Download開始
				BOOL isSpreadsheet = [mRevSelect isKindOfClass:[GDataEntrySpreadsheetDoc class]];
				if (!isSpreadsheet) {
					// in a revision entry, we've add a property above indicating if this is a
					// spreadsheet revision
					isSpreadsheet = [[mRevSelect propertyForKey:@"is spreadsheet"] boolValue];
				}
				
				if (isSpreadsheet) {
					// to save a spreadsheet, we need to authenticate a spreadsheet service
					// object, and then download the spreadsheet file
					//[self saveSpreadsheet:(GDataEntrySpreadsheetDoc *)mDocSelect   toPath:savePath];
					// この後、Downloadが成功すれば、downloadFile:finishedWithData の中から csvRead が呼び出される。
					GDataServiceGoogleSpreadsheet *spreadsheetService = [[GDataServiceGoogleSpreadsheet alloc] init];
					[spreadsheetService setUserAgent:[mDocService userAgent]];
					[spreadsheetService setUserCredentialsWithUsername:[mDocService username]
															  password:[mDocService password]];
					GDataServiceTicket *ticket;
					ticket = [spreadsheetService authenticateWithDelegate:self
												  didAuthenticateSelector:@selector(spreadsheetTicket:authenticatedWithError:)];
					// we'll hang on to the spreadsheet service object with a ticket property
					// since we need it to create an authorized NSURLRequest
					[ticket setProperty:mRevSelect forKey:@"docEntry"];
					[ticket setProperty:savePath forKey:@"savePath"];
				} 
				else {
					// since the user has already fetched the doc list, the service object
					// has the proper authentication token.  We'll use the service object
					// to generate an NSURLRequest with the auth token in the header, and
					// then fetch that asynchronously.
					[self saveDocEntry:mRevSelect  toPath:savePath	  exportFormat:@"txt"  authService:mDocService];
					// the content src attribute is used for downloading
				}
			}
			break;
	}
}

- (void)spreadsheetTicket:(GDataServiceTicket *)ticket  authenticatedWithError:(NSError *)error 
{
	if (error) {
		// failed to authenticate; give up
		NSLog(@"Spreadsheet authentication error: %@", error);
		[GoogleService docDownloadErrorNo:400 description:error.localizedDescription];
	}
	else {
		GDataEntrySpreadsheetDoc *docEntry = [ticket propertyForKey:@"docEntry"];
		NSString *savePath = [ticket propertyForKey:@"savePath"];
		[self saveDocEntry:docEntry	toPath:savePath	  exportFormat:@"csv" authService:[ticket service]];
	}
}


@end
