//
//  GDocUploadVC.m
//  AzPackList5
//
//  Created by Sum Positive on 12/02/18.
//  Copyright (c) 2012 Azukid. All rights reserved.
//

#import "Global.h"
#import "AppDelegate.h"
#import "SFHFKeychainUtils.h"
#import "Elements.h"
#import "MocFunctions.h"
#import "FileCsv.h"

#import "GoogleService.h"
#import "GDocUploadVC.h"

#define TAG_ACTION_UPLOAD					800
#define TAG_ACTION_UPLOAD_START	810


@implementation GDocUploadVC
{	// @Private
	AppDelegate						*mAppDelegate;
	UIAlertView							*mAlert;
	UIActivityIndicatorView		*mActivityIndicator;

	GDataServiceGoogleDocs	*mDocService;
	GDataFeedBase					*mDocFeed;
	GDataEntryDocBase			*mDocSelect;
}
@synthesize Re1selected;

/*
#pragma mark - Alert Indicator

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
*/

#pragma mark - IBAction

- (IBAction)ibBuUpload:(UIButton *)button
{
	NSString *filename = [ibTfName.text stringByDeletingPathExtension]; // 拡張子があれば除く
	if ([filename length] < 3) {
		azAlertBox(NSLocalizedString(@"Dropbox NameLeast", nil), NSLocalizedString(@"Dropbox NameLeastMsg", nil), @"OK");
		return;
	}
	
	if (iS_iPAD) {
		//[2.0.1]Bug: iPadタテ向きでUIActionSheetを出すと落ちる(iOSのバグらしい）
		//[2.0.1]Fix: UIActionSheetを UIAlertViewに変えて回避。
		//さらに、iPadでUIActionSheetを使用するとdestructiveButtonTitleが表示されない不具合あり。
		UIAlertView *av = [[UIAlertView alloc] initWithTitle: filename
													 message:@"" 
													delegate: self 
										   cancelButtonTitle: NSLocalizedString(@"Cancel", nil) 
										   otherButtonTitles: NSLocalizedString(@"Google Start upload",nil), nil];
		av.tag = TAG_ACTION_UPLOAD;
		[av show];
	} else {
		UIActionSheet *as = [[UIActionSheet alloc] initWithTitle: filename
														delegate:self 
											   cancelButtonTitle: NSLocalizedString(@"Cancel", nil) 
										  destructiveButtonTitle: nil
											   otherButtonTitles: NSLocalizedString(@"Google Start upload", nil), nil];
		as.tag = TAG_ACTION_UPLOAD;
		[as showInView:self.view];
	}
	[ibTfName resignFirstResponder]; // キーボードを隠す
}

- (IBAction)ibSwEncrypt:(UISwitch *)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:ibSwEncrypt.isOn forKey:UD_Crypt_Switch];
}


#pragma mark - View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		mAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		mDocService = [GoogleService docService];
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

	if (mAppDelegate.ppIsPad) {
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
	
	//self.title = NSLocalizedString(@"Backup Google", nil);
	if (Re1selected.name) {
		self.title = Re1selected.name;
		//ibTfName.text = Re1selected.name;
		ibTfName.text = azStringNoEmoji(  Re1selected.name ); // 絵文字を除去する
	} else {
		self.title = NSLocalizedString(@"(New Pack)", nil);
		ibTfName.text = NSLocalizedString(@"(New Pack)", nil);
	}

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults boolForKey:UD_OptCrypt]) {
		ibLbEncrypt.enabled = YES;
		ibSwEncrypt.enabled = YES;
		[ibSwEncrypt setOn:[defaults boolForKey:UD_Crypt_Switch]];
	}
	
	ibTfName.keyboardType = UIKeyboardTypeDefault;
	ibTfName.returnKeyType = UIReturnKeyDone;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{	// Return YES for supported orientations
	if (mAppDelegate.ppIsPad) {
		return YES;	// FormSheet窓対応
	}
	else if (mAppDelegate.ppOptAutorotate==NO) {	// 回転禁止にしている場合
		return (interfaceOrientation == UIInterfaceOrientationPortrait); //タテのみ
	}
    return YES;
}

#pragma mark  <UIActionSheetDelegate>
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == actionSheet.cancelButtonIndex) return; // CANCEL
	if (actionSheet.tag != TAG_ACTION_UPLOAD) return;
	
	// アップロード開始
	[GoogleService docUploadE1:Re1selected  title:ibTfName.text  crypt:ibSwEncrypt.isOn];
}

#pragma mark - <UIAlertViewDelegate>
// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex==alertView.cancelButtonIndex) return;
	
	switch (alertView.tag) {
		case TAG_ACTION_UPLOAD:
			if (buttonIndex == 1) {  // START
				// アップロード開始
				[GoogleService docUploadE1:Re1selected  title:ibTfName.text  crypt:ibSwEncrypt.isOn];
			}
			break;
	}
}


@end
