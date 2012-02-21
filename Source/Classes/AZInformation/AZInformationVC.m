//
//  AZInformationVC.m
//
//  Created by Sum Positive on 11/10/06.
//  Copyright (c) 2011 Azukid. All rights reserved.
//

#import "Global.h"
#import "AppDelegate.h"
#import "AZInformationVC.h"
#import "UIDevice-Hardware.h"

#define ALERT_TAG_GoSupportBlog			46
#define ALERT_TAG_PostToAuthor			37


@interface AZInformationVC (PrivateMethods)
@end

@implementation AZInformationVC
{
	AppDelegate		*appDelegate_;	// アプリ固有仕様
}


#pragma mark - Mail

- (void)sendmail
{
	MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
	picker.mailComposeDelegate = self;
	// To: 宛先
	NSArray *toRecipients = [NSArray arrayWithObject:@"packlist@azukid.com"];
	[picker setToRecipients:toRecipients];
	
	// Subject: 件名
	NSString* zSubj = NSLocalizedString(@"Product Title",nil);
	if (appDelegate_.app_is_iPad) {
		zSubj = [zSubj stringByAppendingString:@" for iPad"];
	} else {
		zSubj = [zSubj stringByAppendingString:@" for iPhone"];
	}
	
	if (appDelegate_.app_pid_SwitchAd) {
		zSubj = [zSubj stringByAppendingString:@"  (AdOff)"];
	}
	[picker setSubject:zSubj];  
	
	// Body: 本文
	NSString *zVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]; //（リリース バージョン）は、ユーザーに公開した時のレベルを表現したバージョン表記
	NSString *zBuild = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]; //（ビルド回数 バージョン）は、ユーザーに非公開のレベルも含めたバージョン表記
	NSString* zBody = [NSString stringWithFormat:@"Product: %@\n",  zSubj];
	zBody = [zBody stringByAppendingFormat:@"Version: %@ (%@)\n",  zVersion, zBuild];
	UIDevice *device = [UIDevice currentDevice];
	NSString* deviceID = [device platformString];	
	zBody = [zBody stringByAppendingFormat:@"Device: %@   iOS: %@\n", 
			 deviceID,
			 [[UIDevice currentDevice] systemVersion]]; // OSの現在のバージョン
	
	NSArray *languages = [NSLocale preferredLanguages];
	zBody = [zBody stringByAppendingFormat:@"Locale: %@ (%@)\n\n",
			 [[NSLocale currentLocale] objectForKey:NSLocaleIdentifier],
			 [languages objectAtIndex:0]];
	
	zBody = [zBody stringByAppendingString:NSLocalizedString(@"Contact message",nil)];
	[picker setMessageBody:zBody isHTML:NO];
	
	picker.modalPresentationStyle = UIModalPresentationFormSheet;
	[self presentModalViewController:picker animated:YES];
}

#pragma mark  <MFMailComposeViewControllerDelegate>

- (void)mailComposeController:(MFMailComposeViewController*)controller 
		  didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{
    switch (result){
        case MFMailComposeResultCancelled:
            //キャンセルした場合
            break;
        case MFMailComposeResultSaved:
            //保存した場合
            break;
        case MFMailComposeResultSent:
            //送信した場合
			alertBox( NSLocalizedString(@"Contact Sent",nil), NSLocalizedString(@"Contact Sent msg",nil), @"OK" );
            break;
        case MFMailComposeResultFailed:
            //[self setAlert:@"メール送信失敗！":@"メールの送信に失敗しました。ネットワークの設定などを確認して下さい"];
			alertBox( NSLocalizedString(@"Contact Failed",nil), NSLocalizedString(@"Contact Failed msg",nil), @"OK" );
            break;
        default:
            break;
    }
	// Close
	[self dismissModalViewControllerAnimated:YES];
}


#pragma mark - <alertView>

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != 1) return; // Cancel
	// OK
	switch (alertView.tag) 
	{
		case ALERT_TAG_GoSupportBlog: {
			NSURL *url = [NSURL URLWithString:@"http://packlist.azukid.com/"];
			[[UIApplication sharedApplication] openURL:url];
		}	break;
			
		case ALERT_TAG_PostToAuthor: { // Post commens
			[self sendmail];
		}	break;
	}
}


#pragma mark - Action

- (IBAction)ibBuGoSupportBlog:(UIButton *)button
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"GoSupportSite",nil)
													message:NSLocalizedString(@"GoSupportSite msg",nil)
												   delegate:self		// clickedButtonAtIndexが呼び出される
										  cancelButtonTitle:@"Cancel"
										  otherButtonTitles:@"OK", nil];
	alert.tag = ALERT_TAG_GoSupportBlog;
	[alert show];
}

- (IBAction)ibBuPostToAuthor:(UIButton *)button
{
	//メール送信可能かどうかのチェック　　＜＜＜MessageUI.framework が必要＞＞＞
    if (![MFMailComposeViewController canSendMail]) {
		//[self setAlert:@"メールが起動出来ません！":@"メールの設定をしてからこの機能は使用下さい。"];
		alertBox( NSLocalizedString(@"Contact NoMail",nil), NSLocalizedString(@"Contact NoMail msg",nil), @"OK" );
        return;
    }
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Contact mail",nil)
													message:NSLocalizedString(@"Contact mail msg",nil)
												   delegate:self		// clickedButtonAtIndexが呼び出される
										  cancelButtonTitle:@"Cancel"
										  otherButtonTitles:@"OK", nil];
	alert.tag = ALERT_TAG_PostToAuthor;
	[alert show];
}

- (IBAction)ibBuClose:(UIButton *)button	//iPadのみ
{
	[self dismissModalViewControllerAnimated:YES];
}


#pragma mark - View lifecycle

- (id)init
{
	self = [super initWithNibName:@"AZInformation" bundle:nil];
    if (self) {
        // Custom initialization
		appDelegate_ = (AppDelegate *)[[UIApplication sharedApplication] delegate];

		// 背景色　小豆色 RGB(152,81,75) #98514B
		self.view.backgroundColor = [UIColor colorWithRed:152/255.0f 
													green:81/255.0f 
													 blue:75/255.0f
													alpha:1.0f];

		self.contentSizeForViewInPopover = CGSizeMake(320, 416); //iPad-Popover
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.title = NSLocalizedString(@"menu Information",nil);
	
	//（リリース バージョン）は、ユーザーに公開した時のレベルを表現したバージョン表記
	NSString *zVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]; 
	ibLbVersion.text = [NSString stringWithFormat:@"Version %@", zVersion];
	
	ibLbCopyright.text =	COPYRIGHT		@"\n"
										@"Author: Sum Positive\n"
										@"All Rights Reserved.";

	if (appDelegate_.app_is_iPad) {
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
	AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	if (app.app_is_iPad) {
		return YES;
	} else {
		// 回転禁止でも、正面は常に許可しておくこと。
		return app.app_opt_Autorotate OR (interfaceOrientation == UIInterfaceOrientationPortrait);
	}
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

}



@end
