//
//  DropboxView.m
//  AzPacking
//
//  Created by Sum Positive on 11/11/03.
//  Copyright (c) 2011 AzukiSoft. All rights reserved.
//

#import "Global.h"
#import "DropboxVC.h"
#import "FileCsv.h"

#define TAG_ACTION_Save			109
#define TAG_ACTION_Retrieve		118

//#define USER_FILENAME			@"My PackList"
//#define USER_FILENAME_KEY	@"MyPackList"

@implementation DropboxVC
//@synthesize delegate;
@synthesize Re1selected;


#pragma mark - Alert

- (void)alertIndicatorOn:(NSString*)zTitle
{
	[mAlert setTitle:zTitle];
	[mAlert show];
	[mActivityIndicator setFrame:CGRectMake((mAlert.bounds.size.width-50)/2, mAlert.frame.size.height-75, 50, 50)];
	[mActivityIndicator startAnimating];
}

- (void)alertIndicatorOff
{
	[mActivityIndicator stopAnimating];
	[mAlert dismissWithClickedButtonIndex:mAlert.cancelButtonIndex animated:YES];
}

- (void)alertCommError
{
	UIAlertView *alv = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Dropbox CommError", nil) 
												   message:NSLocalizedString(@"Dropbox CommErrorMsg", nil) 
												  delegate:nil cancelButtonTitle:nil 
										 otherButtonTitles:NSLocalizedString(@"Roger", nil), nil];
	[alv show];
}

#pragma mark - Dropbox DBRestClient

- (DBRestClient *)restClient 
{
	if (!restClient) {
		restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
		restClient.delegate = self;
	}
	return restClient;
}


#pragma mark - IBAction

- (IBAction)ibBuClose:(UIButton *)button
{
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)ibBuSave:(UIButton *)button
{
	NSString *filename = [ibTfName.text stringByDeletingPathExtension]; // 拡張子を除く
	if ([filename length] < 3) {
		UIAlertView *alv = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Dropbox NameLeast", nil) 
													  message:NSLocalizedString(@"Dropbox NameLeastMsg", nil)  
													  delegate:nil cancelButtonTitle:nil 
											 otherButtonTitles:NSLocalizedString(@"Roger", nil), nil];
		[alv show];
		return;
	}
	
	UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Dropbox Are you sure", nil) 
													delegate:self 
										   cancelButtonTitle:NSLocalizedString(@"Cancel", nil) 
									  destructiveButtonTitle:nil 
											otherButtonTitles:NSLocalizedString(@"Dropbox Save", nil), nil];
	as.tag = TAG_ACTION_Save;
	[as showInView:self.view];
	[ibTfName resignFirstResponder]; // キーボードを隠す
}

- (IBAction)ibSegSort:(UISegmentedControl *)segment
{
	[self alertIndicatorOn:NSLocalizedString(@"Dropbox Communicating", nil)];
	[[self restClient] loadMetadata:@"/"];
}


#pragma mark - View lifecycle

- (id)init
{
	self = [super initWithNibName:@"DropboxVC" bundle:nil];
    if (self) {
        // Custom initialization
		self.contentSizeForViewInPopover = GD_POPOVER_SIZE;  //   CGSizeMake(320, 416); //iPad-Popover
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	// init:では早すぎるようなので、ここで制御する。
	if ([[[UIDevice currentDevice] model] hasPrefix:@"iPad"]) {	// iPad
		ibBuClose.hidden = NO;
	} else {
		// iPhone
		ibBuClose.hidden = YES;
		self.title = @"Dropbox";
	}
	
	ibTfName.keyboardType = UIKeyboardTypeDefault;
	ibTfName.returnKeyType = UIReturnKeyDone;
	
	// alertIndicatorOn: alertIndicatorOff: のための準備
	//[mAlert release];
	mAlert = [[UIAlertView alloc] initWithTitle:@"" message:@"" delegate:self cancelButtonTitle:nil otherButtonTitles:nil]; // deallocにて解放
	//[self.view addSubview:mAlert];　　alertIndicatorOn:にてaddSubviewしている。
	//[mActivityIndicator release];
	mActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	mActivityIndicator.frame = CGRectMake(0, 0, 50, 50);
	[mAlert addSubview:mActivityIndicator];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	
	if (Re1selected) {
		ibTfName.text = Re1selected.name;
		ibTfName.enabled = YES;
		ibBuSave.enabled = YES;
	} 
	else { // 取込専用　（保存関係は非表示）
		ibTfName.text = NSLocalizedString(@"Dropbox NotSelected", nil);
		ibTfName.enabled = NO;
		ibBuSave.enabled = NO;
	}
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	
	[self alertIndicatorOn:NSLocalizedString(@"Dropbox Communicating", nil)];
	// Dropbox/App/CalcRoll 一覧表示
	[[self restClient] loadMetadata:@"/"];
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
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
	return YES;
}

#pragma mark unload

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc 
{
	//[Re1selected release];
	
	//[mDidSelectRowAtIndexPath release], 
	mDidSelectRowAtIndexPath = nil;
	//[mActivityIndicator release];
	//[mAlert release];
	//[mMetadatas release], 
	mMetadatas = nil;
    //[super dealloc];
}


#pragma mark - Dropbox <DBRestClientDelegate>

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata 
{	// メタデータ読み込み成功
    if (metadata.isDirectory) {
#ifdef DEBUG
        NSLog(@"Folder '%@' contains:", metadata.path);
		for (DBMetadata *file in metadata.contents) {
			NSLog(@"\t%@", file.filename);
		}
#endif
		//[mMetadatas release], 
		mMetadatas = nil;
		if (0 < [metadata.contents count]) {
			//mMetadatas = [[NSMutableArray alloc] initWithArray:metadata.contents];
			mMetadatas = [NSMutableArray new];
			for (DBMetadata *dbm in metadata.contents) {
				if ([[dbm.filename pathExtension] caseInsensitiveCompare:DBOX_EXTENSION]==NSOrderedSame) { // 大小文字区別なく比較する
					[mMetadatas addObject:dbm];
				}
			}
			// Sorting
			if (ibSegSort.selectedSegmentIndex==0) { // Name Asc
				NSSortDescriptor *sort1 = [[NSSortDescriptor alloc] initWithKey:@"filename" ascending:YES];
				NSArray *sorting = [[NSArray alloc] initWithObjects:sort1,nil];
				//[sort1 release];
				[mMetadatas sortUsingDescriptors:sorting]; // 降順から昇順にソートする
				//[sorting release];
			} else { // Date Desc
				NSSortDescriptor *sort1 = [[NSSortDescriptor alloc] initWithKey:@"lastModifiedDate" ascending:NO];
				NSArray *sorting = [[NSArray alloc] initWithObjects:sort1,nil];
				//[sort1 release];
				[mMetadatas sortUsingDescriptors:sorting]; // 降順から昇順にソートする
				//[sorting release];
			}
			[ibTableView reloadData];
		}
	}
	// 必ず通ること。
	[self alertIndicatorOff];
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error 
{	// メタデータ読み込み失敗
    NSLog(@"Error loading metadata: %@", error);
	//[mMetadatas release];
	mMetadatas = nil;
	[ibTableView reloadData];
	//
	[self alertIndicatorOff];
	[self alertCommError];
}


- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)localPath 
{	// ファイル読み込み成功
    NSLog(@"File loaded into path: %@", localPath);
	// ダウンロード成功
	// CSV読み込み   "HOME/tmp/<GD_CSVFILENAME4>"
	NSString *zErr = [FileCsv zLoadPath:localPath]; // この間、待たされるのが問題になるかも！！
	[self alertIndicatorOff];	// 進捗サインOFF
	if (zErr) {
		// CSV読み込み失敗
		[self alertCommError];
	}
	else {
		// 成功アラート
		UIAlertView *alv = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Dropbox QuoteDone", nil)
													   message:nil
													  delegate:nil
											 cancelButtonTitle:nil
											 otherButtonTitles:NSLocalizedString(@"Roger", nil), nil];
		[alv	show];
		// 再読み込み 通知発信
		[[NSNotificationCenter defaultCenter] postNotificationName:NFM_REFRESH_ALL_VIEWS
															object:self userInfo:nil];
	}
	// 閉じる
	[self dismissModalViewControllerAnimated:YES];
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error 
{	// ファイル読み込み失敗
    NSLog(@"There was an error loading the file - %@", error);
	[self alertIndicatorOff];
	[self alertCommError];
}

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath
			  from:(NSString*)srcPath metadata:(DBMetadata*)metadata
{	// ファイル書き込み成功
    NSLog(@"File uploaded successfully to path: %@", metadata.path);
	// Dropbox/App/CalcRoll 一覧表示
	[[self restClient] loadMetadata:@"/"];
	[self alertIndicatorOff];
	UIAlertView *alv = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Dropbox SaveDone", nil) 
												   message:nil  delegate:nil cancelButtonTitle:nil 
										 otherButtonTitles:NSLocalizedString(@"Roger", nil), nil];
	[alv show];
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error 
{	// ファイル書き込み失敗
    NSLog(@"File upload failed with error - %@", error);
	[self alertIndicatorOff];
	[self alertCommError];
}



#pragma mark - <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section) {
		case 0:
			if (0 < [mMetadatas count]) {
				return [mMetadatas count];
			} else {
				return 1;
			}
	}
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
									   reuseIdentifier:CellIdentifier];
    }
	
	switch (indexPath.section) {
		case 0: {
			if (0 < [mMetadatas count]) {
				DBMetadata *dbm = [mMetadatas objectAtIndex:indexPath.row];
				cell.textLabel.text = [dbm.filename stringByDeletingPathExtension]; // 拡張子を除く
			} else {
				cell.textLabel.text = NSLocalizedString(@"Dropbox NoFile", nil);
			}
		} break;
	}
    return cell;
}


#pragma mark - <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (0<=indexPath.row && indexPath.row<[mMetadatas count]) 
	{
		//[mDidSelectRowAtIndexPath release], 
		mDidSelectRowAtIndexPath = nil;
		DBMetadata *dbm = [mMetadatas objectAtIndex:indexPath.row];
		if (dbm) {
			mDidSelectRowAtIndexPath = [indexPath copy];
			NSLog(@"dbm.filename=%@", dbm.filename);

			UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Dropbox Are you sure", nil) 
															 delegate:self 
													cancelButtonTitle:NSLocalizedString(@"Cancel", nil) 
											   destructiveButtonTitle:nil
													otherButtonTitles:NSLocalizedString(@"Dropbox Change", nil), nil];
			as.tag = TAG_ACTION_Retrieve;
			[as showInView:self.view];
		}
		else {
			[ibTableView deselectRowAtIndexPath:indexPath animated:YES]; // 選択解除
		}
	}
	else {
		[ibTableView deselectRowAtIndexPath:indexPath animated:YES]; // 選択解除
	}
}


#pragma mark - <UITextFieldDelegate>

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder]; // キーボードを隠す
	return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range 
replacementString:(NSString *)string 
{
	// senderは、MtfName だけ
    NSMutableString *text = [textField.text mutableCopy];
    [text replaceCharactersInRange:range withString:string];
	// 置き換えた後の長さをチェックする
	if ([text length] <= 40) {
		//appDelegate.AppUpdateSave = YES; // 変更あり
		//self.navigationItem.rightBarButtonItem.enabled = YES; // 変更あり [Save]有効
		return YES;
	} else {
		return NO;
	}
}


#pragma mark - <UIActionSheetDelegate>

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (mDidSelectRowAtIndexPath) {
		@try {
			[ibTableView deselectRowAtIndexPath:mDidSelectRowAtIndexPath animated:YES]; // 選択解除
		}
		@catch (NSException *exception) {
			NSLog(@"ERROR");
		}
	}

	if (buttonIndex==actionSheet.cancelButtonIndex) return; // CANCEL
	
	switch (actionSheet.tag) {
		case TAG_ACTION_Save:	// 保存
			//NSLog(@"homeTmpPath_=%@", homeTmpPath_);
			//if (Re1selected  &&  homeTmpPath_) {
			if (Re1selected) {
				[self alertIndicatorOn:NSLocalizedString(@"Dropbox Communicating", nil)];
				// ファイルへ書き出す
				NSString *zErr = [FileCsv zSave:Re1selected toLocalFileName:GD_CSVFILENAME4]; // この間、待たされるのが問題になるかも！！
				if (zErr) {
					[self alertIndicatorOff];	// 進捗サインOFF
					UIAlertView *alert = [[UIAlertView alloc] 
										  initWithTitle:NSLocalizedString(@"Upload Fail", @"アップロード失敗")
										  message:zErr
										  delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
					[alert show];
					//[alert release];
					break;
				}
				// Upload開始
				NSString *pathTmp = [NSHomeDirectory() stringByAppendingPathComponent:@"tmp"];  // "tmp"フォルダは、iCloud同期除外される
				NSString *pathCsv = [pathTmp stringByAppendingPathComponent:GD_CSVFILENAME4];
				NSString *filename = [ibTfName.text stringByDeletingPathExtension]; // 拡張子を除く
				filename = [filename stringByAppendingFormat:@".%@", DBOX_EXTENSION]; // 拡張子を付ける
				NSLog(@"SAVE: pathCsv=%@ --Upload--> filename=%@", pathCsv, filename);
				[[self restClient] uploadFile:filename toPath:@"/" withParentRev:nil fromPath:pathCsv];
			}
			break;
			
		case TAG_ACTION_Retrieve:		// このモチメモを読み込む。
			if (mDidSelectRowAtIndexPath && mDidSelectRowAtIndexPath.row < [mMetadatas count]) {
				DBMetadata *dbm = [mMetadatas objectAtIndex:mDidSelectRowAtIndexPath.row];
				if (dbm) {
					[self alertIndicatorOn:NSLocalizedString(@"Dropbox Communicating", nil)];
					NSString *pathTmp = [NSHomeDirectory() stringByAppendingPathComponent:@"tmp"];  // "tmp"フォルダは、iCloud同期除外される
					NSString *pathCsv = [pathTmp stringByAppendingPathComponent:GD_CSVFILENAME4];
					NSLog(@"LOAD: dbm.path=%@ --Download--> pathCsv=%@", dbm.path, pathCsv);
					[[self restClient] loadFile:dbm.path intoPath:pathCsv]; // DownLoad開始 ---> delagate loadedFile:
				}
			}
			break;
	}
}


@end
