//
//  DropboxView.m
//  AzPacking
//
//  Created by Sum Positive on 11/11/03.
//  Copyright (c) 2011 AzukiSoft. All rights reserved.
//

#import "Global.h"
#import "AppDelegate.h"
#import "DropboxVC.h"
#import "FileCsv.h"


#define TAG_ACTION_Save			109
#define TAG_ACTION_Retrieve		118
#define TAG_ALERT_Delete			127


@implementation DropboxVC

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

- (void)alertMsg:(NSString*)msg  detail:(NSString*)detail
{
	//NSString *msg = NSLocalizedString(@"Dropbox CommErrorMsg", nil);
	UIAlertView *alv = [[UIAlertView alloc] initWithTitle: msg
												   message: detail
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
/*
- (IBAction)ibBuClose:(UIButton *)button
{
	[self dismissModalViewControllerAnimated:YES];
}*/

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

	// 上書き確認
	overWriteRev_ = nil;
	for (DBMetadata *dbm in  mMetadatas) {
		if ([filename  isEqualToString:[dbm.filename stringByDeletingPathExtension]]) {  // 拡張子を除く
			overWriteRev_ = dbm.rev;  // OverWrite Revision
			break;
		}
	}
	
	NSString *destructiveButtonTitle = nil;
	NSString *otherButtonTitle = nil;
	if (overWriteRev_) {
		destructiveButtonTitle = NSLocalizedString(@"Dropbox OverWrite", nil); // 上書き保存　＜＜ overWriteRev_を使ってアップロード
		otherButtonTitle = NSLocalizedString(@"Dropbox Sequential", nil); // 連番を付けて保存
	} else {
		otherButtonTitle = NSLocalizedString(@"Dropbox Save", nil); // 新規保存
	}
	
	if (iS_iPAD) {
		//[2.0.1]Bug: iPadタテ向きでUIActionSheetを出すと落ちる(iOSのバグらしい）
		//[2.0.1]Fix: UIActionSheetを UIAlertViewに変えて回避。
		//さらに、iPadでUIActionSheetを使用するとdestructiveButtonTitleが表示されない不具合あり。
		UIAlertView *av = [[UIAlertView alloc] initWithTitle: filename
													 message:@"" 
													delegate: self 
										   cancelButtonTitle: NSLocalizedString(@"Cancel", nil) 
										   otherButtonTitles: otherButtonTitle, destructiveButtonTitle, nil];
		av.tag = TAG_ACTION_Save;
		[av show];
	} else {
		UIActionSheet *as = [[UIActionSheet alloc] initWithTitle: filename  
														delegate:self 
											   cancelButtonTitle: NSLocalizedString(@"Cancel", nil) 
										  destructiveButtonTitle: destructiveButtonTitle
											   otherButtonTitles: otherButtonTitle, nil];
		as.tag = TAG_ACTION_Save;
		[as showInView:self.view];
	}	
	[ibTfName resignFirstResponder]; // キーボードを隠す
}

- (IBAction)ibSwEncrypt:(UISwitch *)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:ibSwEncrypt.selected forKey:UD_Crypt_Switch];
}

- (IBAction)ibSegSort:(UISegmentedControl *)segment
{
	[self alertIndicatorOn:NSLocalizedString(@"Dropbox Communicating", nil)];
	[[self restClient] loadMetadata:@"/"];
}


#pragma mark - View lifecycle

- (id)initWithE1:(E1*)e1upload
{
	if (e1upload) {
		self = [super initWithNibName:@"DropboxUpVC" bundle:nil];
	} else {
		self = [super initWithNibName:@"DropboxDownVC" bundle:nil];
	}
    if (self) {
        // Custom initialization
		mE1upload = e1upload;
		//self.contentSizeForViewInPopover =  //FormSheetスタイルにしたので不要
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	ibTfName.keyboardType = UIKeyboardTypeDefault;
	ibTfName.returnKeyType = UIReturnKeyDone;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults boolForKey:UD_OptCrypt]) {
		ibLbEncrypt.enabled = YES;
		ibSwEncrypt.enabled = YES;
		ibSwEncrypt.selected = [defaults boolForKey:UD_Crypt_Switch];
	}
	
	// alertIndicatorOn: alertIndicatorOff: のための準備
	//[mAlert release];
	mAlert = [[UIAlertView alloc] initWithTitle:@"" message:@"" delegate:self cancelButtonTitle:nil otherButtonTitles:nil]; // deallocにて解放
	//[self.view addSubview:mAlert];　　alertIndicatorOn:にてaddSubviewしている。
	//[mActivityIndicator release];
	mActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	mActivityIndicator.frame = CGRectMake(0, 0, 50, 50);
	[mAlert addSubview:mActivityIndicator];

	AppDelegate *ad = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	if (ad.app_is_iPad) {
		// CANCELボタンを左側に追加する  Navi標準の戻るボタンでは cancel:処理ができないため
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
												 initWithTitle:NSLocalizedString(@"Back", nil)
												 style:UIBarButtonItemStyleBordered
												 target:self action:@selector(actionBack:)];
	}
}

- (void)actionBack:(id)sender
{
	[self dismissModalViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

	if (mE1upload) {
		//self.title = NSLocalizedString(@"Backup Dropbox", nil);
		if (mE1upload.name) {
			self.title = mE1upload.name;
			//ibTfName.text = e1upload_.name;
			ibTfName.text = GstringNoEmoji(  mE1upload.name ); // 絵文字を除去する
		} else {
			self.title = NSLocalizedString(@"(New Pack)", nil);
			ibTfName.text = NSLocalizedString(@"(New Pack)", nil);
		}
		ibTfName.enabled = YES;
		ibBuSave.enabled = YES;
	} else {
		self.title = NSLocalizedString(@"Import Dropbox", nil);
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
{	// Return YES for supported orientations
	AppDelegate *ad = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	if (ad.app_is_iPad) {
		return YES;	// FormSheet窓対応
	}
	else if (ad.app_opt_Autorotate==NO) {	// 回転禁止にしている場合
		return (interfaceOrientation == UIInterfaceOrientationPortrait); //タテのみ
	}
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
	if (restClient) {
		restClient.delegate = nil;
	}
	mDidSelectRowAtIndexPath = nil;
	mMetadatas = nil;
}


#pragma mark - Dropbox <DBRestClientDelegate>

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata 
{	// メタデータ読み込み成功
	// mMetadatasオブジェクトを解放
	overWriteRev_ = nil;
	deletePath_ = nil;

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
    NSLog(@"Error loading metadata: %@", [error description]);
	//[mMetadatas release];
	mMetadatas = nil;
	[ibTableView reloadData];
	//
	[self alertIndicatorOff];
	[self alertMsg:NSLocalizedString(@"Dropbox CommErrorMsg", nil) detail:[error localizedDescription]];
}


- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)localPath 
{	// ファイル読み込み成功
    NSLog(@"File loaded into path: %@", localPath);
	// ダウンロード成功
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(queue, ^{
		// CSV読み込み
		FileCsv *fcsv = [[FileCsv alloc] init];
		NSString *zErr = [fcsv zLoadTmpFile];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[self alertIndicatorOff];	// 進捗サインOFF
			if (zErr==nil) {
				// 成功アラート
				UIAlertView *alv = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Dropbox QuoteDone", nil)
															  message:nil
															 delegate:nil
													cancelButtonTitle:nil
													otherButtonTitles:@"OK", nil];
				[alv	show];
				// 再読み込み 通知発信
				[[NSNotificationCenter defaultCenter] postNotificationName:NFM_REFRESH_ALL_VIEWS
																	object:self userInfo:nil];
			}
			else {
				// 読み込み失敗
				[self alertMsg:NSLocalizedString(@"Dropbox DL error", nil) detail:zErr];
			}
			// 閉じる
			[self dismissModalViewControllerAnimated:YES];
		});
	});
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error 
{	// ファイル読み込み失敗
    NSLog(@"There was an error loading the file - %@", [error description]);
	[self alertIndicatorOff];
	[self alertMsg:NSLocalizedString(@"Dropbox DL error", nil) detail:[error localizedDescription]];
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
										 otherButtonTitles:@"OK", nil];
	[alv show];
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error 
{	// ファイル書き込み失敗
    NSLog(@"File upload failed with error - %@", [error description]);
	[self alertIndicatorOff];
	if (error.code==400) { //ファイル名に絵文字が使われているなど
		[self alertMsg:NSLocalizedString(@"Dropbox UP error", nil) detail:NSLocalizedString(@"Dropbox UP error400", nil)];
	} else {
		[self alertMsg:NSLocalizedString(@"Dropbox UP error", nil) detail:[error localizedDescription]];
	}
}

- (void)restClient:(DBRestClient*)client deletedPath:(NSString *)path
{	// Folder is the metadata for the newly created folder
    NSLog(@"File deleted successfully to path: %@", path);
	[[self restClient] loadMetadata:@"/"];
	[self alertIndicatorOff];
}

- (void)restClient:(DBRestClient*)client deletePathFailedWithError:(NSError*)error
{	// [error userInfo] contains the root and path
    NSLog(@"File deleted failed with error - %@", error);
	[[self restClient] loadMetadata:@"/"];
	[self alertIndicatorOff];
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
			if (mMetadatas==nil) {
				cell.textLabel.text = @"  Please wait.";
			}
			else if (0 < [mMetadatas count]) {
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

			if (iS_iPAD) {
				NSString *otherButtonTitle = nil;
				if (mE1upload) {
					otherButtonTitle = NSLocalizedString(@"Dropbox Delete", nil);
				} else {
					otherButtonTitle = NSLocalizedString(@"Dropbox Change", nil);
				}
				//[2.0.1]Bug: iPadタテ向きでUIActionSheetを出すと落ちる(iOSのバグらしい）
				//[2.0.1]Fix: UIActionSheetを UIAlertViewに変えて回避。
				//さらに、iPadでUIActionSheetを使用するとdestructiveButtonTitleが表示されない不具合あり。
				UIAlertView *av = [[UIAlertView alloc] initWithTitle: [dbm.filename stringByDeletingPathExtension]
															 message:@"" 
															delegate: self 
												   cancelButtonTitle: NSLocalizedString(@"Cancel", nil) 
												   otherButtonTitles: otherButtonTitle, nil];
				av.tag = TAG_ACTION_Retrieve;
				[av show];
			} else {
				NSString *destructiveButtonTitle = nil;
				NSString *otherButtonTitle = nil;
				if (mE1upload) {
					destructiveButtonTitle = NSLocalizedString(@"Dropbox Delete", nil);
				} else {
					otherButtonTitle = NSLocalizedString(@"Dropbox Change", nil);
				}
				UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:[dbm.filename stringByDeletingPathExtension]
																delegate:self 
													   cancelButtonTitle:NSLocalizedString(@"Cancel", nil) 
												  destructiveButtonTitle: destructiveButtonTitle
													   otherButtonTitles: otherButtonTitle, nil];
				as.tag = TAG_ACTION_Retrieve;
				[as showInView:self.view];
			}
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
- (void)actionSaveIsOverwrite:(BOOL)isOverwrite
{
	if (mE1upload==nil) return;
	[self alertIndicatorOn:NSLocalizedString(@"Dropbox Communicating", nil)];
	if (isOverwrite==NO) {
		// < Overwrite > しない！
		overWriteRev_ = nil; // 連番を付けて保存
	}
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(queue, ^{		// 非同期マルチスレッド処理
		// ファイルへ書き出す
		FileCsv *fcsv = [[FileCsv alloc] init];
		NSString *zErr = [fcsv zSaveTmpFile:mE1upload crypt:ibSwEncrypt.selected];
		
		dispatch_async(dispatch_get_main_queue(), ^{	// 終了後の処理
			if (zErr==nil) {
				// Upload開始
				NSString *filePath = fcsv.tmpPathFile;
				NSString *filename = [ibTfName.text stringByDeletingPathExtension]; // 拡張子を除く
				filename = [filename stringByAppendingFormat:@".%@", DBOX_EXTENSION]; // 拡張子を付ける
				NSLog(@"SAVE: filePath=%@ --Upload--> filename=%@　　overWriteRev_=%@", filePath, filename, overWriteRev_);
				// overWriteRev_=nil ならば連番付加追記
				[[self restClient] uploadFile:filename toPath:@"/" withParentRev:overWriteRev_ fromPath:filePath];
			}
			else {
				[self alertIndicatorOff];	// 進捗サインOFF
				[self alertMsg:NSLocalizedString(@"Dropbox UP error", nil) detail:zErr];
			}
		});
	});
}

- (void)actionRetrieve
{
	if (mDidSelectRowAtIndexPath && mDidSelectRowAtIndexPath.row < [mMetadatas count]) {
		DBMetadata *dbm = [mMetadatas objectAtIndex:mDidSelectRowAtIndexPath.row];
		if (dbm) {
			if (mE1upload) {
				// DELETE!!!
				deletePath_ = dbm.path;
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Dropbox Delete LastAns", nil)
																message:nil
															   delegate:self	
													  cancelButtonTitle:NSLocalizedString(@"Cancel", nil) 
													  otherButtonTitles:@"DELETE", nil];
				[alert show];
				alert.tag = TAG_ALERT_Delete;
			}
			else {
				// Download
				[self alertIndicatorOn:NSLocalizedString(@"Dropbox Communicating", nil)];
				//NSString *pathTmp = [NSHomeDirectory() stringByAppendingPathComponent:@"tmp"];
				//NSString *pathCsv = [pathTmp stringByAppendingPathComponent:GD_CSVFILENAME4];
				FileCsv *fcsv = [[FileCsv alloc] init];
				NSString *filePath = fcsv.tmpPathFile;
				NSLog(@"LOAD: dbm.path=%@ --Download--> filePath=%@", dbm.path, filePath);
				[[self restClient] loadFile:dbm.path intoPath:filePath]; // DownLoad開始 ---> delagate loadedFile:
				// この後 <DBRestClientDelegate> Call
			}
		}
	}
}

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
		case TAG_ACTION_Save:	// アップロード
			[self actionSaveIsOverwrite:(buttonIndex == actionSheet.destructiveButtonIndex)];
			break;
			
		case TAG_ACTION_Retrieve:		// このモチメモを読み込む。
			[self actionRetrieve];
			break;
	}
}


#pragma mark - <UIAlertViewDelegate>
// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex==alertView.cancelButtonIndex) return;
	
	switch (alertView.tag) {
		case TAG_ALERT_Delete:
			if (deletePath_) 
			{	// Delete
				[self alertIndicatorOn:NSLocalizedString(@"Dropbox Communicating", nil)];
				NSLog(@"DELETE: dbm.path=%@", deletePath_);
				[[self restClient] deletePath: deletePath_];
				// この後 <DBRestClientDelegate> Call
			}
			break;

		case TAG_ACTION_Save:	// アップロード
			[self actionSaveIsOverwrite:(buttonIndex == 2)];
			break;
		case TAG_ACTION_Retrieve:		// このモチメモを読み込む。
			[self actionRetrieve];
			break;
	}
}


@end
