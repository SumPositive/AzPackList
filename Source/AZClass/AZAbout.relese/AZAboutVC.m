//
//  AZAboutVC.m
//
//  Created by Sum Positive on 11/10/06.
//  Copyright (c) 2011 Azukid. All rights reserved.
//
#undef  NSLocalizedString		//⇒ AZLocalizedString  AZClass専用にすること

#import "AZAboutVC.h"

#define ALERT_TAG_GoSupportBlog			46
#define ALERT_TAG_PostToAuthor			37


@interface AZAboutVC (PrivateMethods)
@end

@implementation AZAboutVC
@synthesize ppImgIcon;
@synthesize ppProductTitle;
@synthesize ppProductSubtitle;
//@synthesize ppProductYear;
@synthesize ppSupportSite;
@synthesize ppCopyright;
@synthesize ppAuthor;


#pragma mark - Mail
- (void)sendmail
{
	MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
	picker.mailComposeDelegate = self;
	// To: 宛先
	NSArray *toRecipients = [NSArray arrayWithObject:@"post@azukid.com"];
	[picker setToRecipients:toRecipients];
	
	// Subject: 件名
	NSString* zSubj = [NSString stringWithFormat:@"%@ - Customer Review",  self.ppProductTitle];
	[picker setSubject:zSubj];		// 件名： 
	
	// Body: 本文
	NSString *zVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]; //（リリース バージョン）は、ユーザーに公開した時のレベルを表現したバージョン表記
	NSString *zBuild = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]; //（ビルド回数 バージョン）は、ユーザーに非公開のレベルも含めたバージョン表記
	NSString* zBody = [NSString stringWithFormat:@"Product: %@\n",  self.ppProductSubtitle]; // ローカライズ名称
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
	
	zBody = [zBody stringByAppendingString:AZLocalizedString(@"AZAbout Mail body",nil)];
	[picker setMessageBody:zBody isHTML:NO];
	
	picker.modalPresentationStyle = UIModalPresentationFormSheet;
	[self presentViewController:picker animated:YES completion:nil];
}

#pragma mark  <MFMailComposeViewControllerDelegate>
- (void)mailComposeController:(MFMailComposeViewController*)controller 
		  didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{
	if (error) {
		GA_TRACK_EVENT_ERROR([error localizedDescription],0);
	}
    switch (result){
        case MFMailComposeResultCancelled:
            //キャンセルした場合
            break;
        case MFMailComposeResultSaved:
            //保存した場合
            break;
        case MFMailComposeResultSent:
            //送信した場合
			azAlertBox( AZLocalizedString(@"AZAbout Mail Sent",nil), 
							AZLocalizedString(@"AZAbout Mail Sent msg",nil), @"OK" );
            break;
        case MFMailComposeResultFailed:
            //[self setAlert:@"メール送信失敗！":@"メールの送信に失敗しました。ネットワークの設定などを確認して下さい"];
			azAlertBox( AZLocalizedString(@"AZAbout Mail Failed",nil), 
							AZLocalizedString(@"AZAbout Mail Failed msg",nil), @"OK" );
			GA_TRACK_LOG(@"MFMailComposeResultFailed")
            break;
        default:
            break;
    }
	// Close
	[controller dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - <alertView>
- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != 1) return; // Cancel
	// OK
	switch (alertView.tag) 
	{
		case ALERT_TAG_GoSupportBlog: {
			//NSURL *url = [NSURL URLWithString:@"http://packlist.azukid.com/"];
			NSURL *url = [NSURL URLWithString:self.ppSupportSite];
			[[UIApplication sharedApplication] openURL:url];
		}	break;
			
		case ALERT_TAG_PostToAuthor: { // Post commens
			[self sendmail];
		}	break;
	}
}


#pragma mark - Action

- (void)actionBack:(id)sender
{
/*	if (mIsPad) {
		[self dismissModalViewControllerAnimated:YES];
	} else {
		[self.navigationController popViewControllerAnimated:YES];	// < 前のViewへ戻る
	}*/
	// ここを通る場合は、navigationController:から呼び出されたものではない。
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)ibBuGoSupportBlog:(UIButton *)button
{
	AZWebView *wv = [[AZWebView alloc] init];
	wv.title = @"AzukiSoft";
	wv.ppUrl = self.ppSupportSite;
	wv.ppDomain = [NSSet setWithObjects:
				   @".azukid.com", 
				   @".tumblr.com",
				   @"azukisoft.seesaa.net",
				   nil]; //許可ドメインを列記する
	wv.ppBookmarkDelegate = nil;
	
	if (mIsPad) {
		UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:wv];
		nc.modalPresentationStyle = UIModalPresentationPageSheet;  // 背景Viewが保持される
		nc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;//	UIModalTransitionStyleFlipHorizontal
		[self presentViewController:nc animated:YES completion:nil];
	} else {
		[self.navigationController pushViewController:wv animated:YES];
	}
}

- (IBAction)ibBuPostToAuthor:(UIButton *)button
{
	//メール送信可能かどうかのチェック　　＜＜＜MessageUI.framework が必要＞＞＞
    if (![MFMailComposeViewController canSendMail]) {
		//[self setAlert:@"メールが起動出来ません！":@"メールの設定をしてからこの機能は使用下さい。"];
		azAlertBox( AZLocalizedString(@"AZAbout Mail NG",nil), 
						AZLocalizedString(@"AZAbout Mail NG msg",nil), @"OK" );
        return;
    }
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:AZLocalizedString(@"AZAbout PostTo",nil)
													message:AZLocalizedString(@"AZAbout PostTo msg",nil)
												   delegate:self		// clickedButtonAtIndexが呼び出される
										  cancelButtonTitle:@"Cancel"
										  otherButtonTitles:@"OK", nil];
	alert.tag = ALERT_TAG_PostToAuthor;
	[alert show];
}
/*
- (IBAction)ibBuClose:(UIButton *)button	//iPadのみ
{
	[self dismissModalViewControllerAnimated:YES];
}
*/

#pragma mark - View lifecycle

- (id)init
{
	//NG//mIsPad = [[[UIDevice currentDevice] model] hasPrefix:@"iPad"];
	//NG//iPad上でiPhoneモードのとき、iPhoneにならない。
	mIsPad = iS_iPAD; //(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
	if (mIsPad) {
		self = [super initWithNibName:@"AZAbout-iPad" bundle:nil];
	} else {
		self = [super initWithNibName:@"AZAbout" bundle:nil];
	}
    if (self) {
        // Custom initialization
		GA_TRACK_PAGE(@"AZAboutVC");
		self.ppCopyright = @"© Azukid";
		self.ppAuthor = @"M.Matsuyama"; //@"Sum Positive";

		// 背景色　小豆色 RGB(152,81,75) #98514B
		self.view.backgroundColor = [UIColor colorWithRed:152/255.0f
													green:81/255.0f 
													 blue:75/255.0f
													alpha:1.0f];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.title = AZLocalizedString(@"AZAbout",nil);
	
	//（リリース バージョン）は、ユーザーに公開した時のレベルを表現したバージョン表記
	NSString *zVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]; 
	ibLbVersion.text = [NSString stringWithFormat:@"Version %@", zVersion];
	
	//NSLog(@"-1-self.navigationController.viewControllers={%@}", self.navigationController.viewControllers);
	//この時点では、=(null) になる。
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

	ibIvIcon.image = self.ppImgIcon;
	ibLbTitle.text = self.ppProductTitle;
	ibLbSubtitle.text = self.ppProductSubtitle;
	
	//NSLog(@"-2-self.navigationController.viewControllers={%@}", self.navigationController.viewControllers);
	if ([self.navigationController.viewControllers count]==1) {	// viewDidLoad:では未設定であり判断できない
		// 最初のPushViewには <Back ボタンが無いので、左側に追加する ＜＜ iPadの場合
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
												 initWithTitle:AZLocalizedString(@"<Back", nil)
												 style:UIBarButtonItemStylePlain
												 target:self action:@selector(actionBack:)];
	}

//	ibLbCopyright.text = [NSString stringWithFormat:
//						  @"%@\n"
//						  @"%@\n"
//						  @"All Rights Reserved.",
//						  self.ppCopyright, self.ppAuthor];

    ibLbCopyright.text = [NSString stringWithFormat:
                          @"Copyright 1995\n"
                          @"Masakazu.Matsuyama\n"
                          @"All Rights Reserved."];

	[ibBuGoSupport setTitle:AZLocalizedString(@"AZAbout GoSupport",nil) 
				 forState:UIControlStateNormal];
	[ibBuPostTo setTitle:AZLocalizedString(@"AZAbout PostTo",nil)
				forState:UIControlStateNormal];

	
	NSError *error;
	ibTvAgree.text = [NSString stringWithContentsOfFile:
					  [[NSBundle mainBundle] pathForResource:@"AZAbout_Agree" ofType:@"txt"]
											   encoding:NSUTF8StringEncoding
												  error:&error];
	if (error) {
		NSLog(@"ibTvAgree.text: stringWithContentsOfFile: ERROR: %@", [error localizedDescription]);
		GA_TRACK_EVENT_ERROR([error localizedDescription],0);
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
	return YES;	// FormSheet窓対応
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
