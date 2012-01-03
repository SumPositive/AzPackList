//
//  InformationView.m
//  iPack
//
//  Created by 松山 和正 on 10/01/04.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Global.h"
#import "AppDelegate.h"
#import "InformationView.h"
#import "UIDevice-Hardware.h"

#define ALERT_TAG_GoAppStore			28
#define ALERT_TAG_PostComment		37
#define ALERT_TAG_GoSupportSite		46


@implementation InformationView

static UIColor *MpColorBlue(float percent) {
	float red = percent * 255.0f;
	float green = (red + 20.0f) / 255.0f;
	float blue = (red + 45.0f) / 255.0f;
	if (green > 1.0) green = 1.0f;
	if (blue > 1.0f) blue = 1.0f;
	
	return [UIColor colorWithRed:percent green:green blue:blue alpha:1.0f];
}


#pragma mark - dealloc

- (void)dealloc {
    [super dealloc];
}


#pragma mark - Button functions

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != 1) return; // Cancel
	// OK
	switch (alertView.tag) 
	{
		case ALERT_TAG_GoAppStore: {	// Paid App Store
#ifdef AzPAD
			//iPad//																																					モチメモ for iPad	439606448
			NSURL *url = [NSURL URLWithString:@"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=439606448&mt=8"];
#else
			//iPhone//																																							モチメモ	431276623
			NSURL *url = [NSURL URLWithString:@"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=431276623&mt=8"];
#endif
			[[UIApplication sharedApplication] openURL:url];
		}	break;
			
		case ALERT_TAG_GoSupportSite: {
			NSURL *url = [NSURL URLWithString:@"http://packlist.tumblr.com/"];
			[[UIApplication sharedApplication] openURL:url];
		}	break;
			
		case ALERT_TAG_PostComment: { // Post commens
			MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
			picker.mailComposeDelegate = self;
			// To: 宛先
			NSArray *toRecipients = [NSArray arrayWithObject:@"PackList@azukid.com"];
			[picker setToRecipients:toRecipients];

			// Subject: 件名
			NSString* zSubj = NSLocalizedString(@"Product Title",nil);
#ifdef AzSTABLE
			//zSubj = [zSubj stringByAppendingString:@" Stable"];
#else
			zSubj = [zSubj stringByAppendingString:@" Free"];
#endif
#ifdef AzPAD
			zSubj = [zSubj stringByAppendingString:@" for iPad"];
#else
			zSubj = [zSubj stringByAppendingString:@" for iPhone"];
#endif
			[picker setSubject:zSubj];  
			
			// Body: 本文
			NSString *zVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]; //（リリース バージョン）は、ユーザーに公開した時のレベルを表現したバージョン表記
			NSString *zBuild = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]; //（ビルド回数 バージョン）は、ユーザーに非公開のレベルも含めたバージョン表記
			NSString* zBody = [NSString stringWithFormat:@"Product: %@\n",  zSubj];
#ifdef AzSTABLE
			zBody = [zBody stringByAppendingFormat:@"Version: %@ (%@) Stable\n",  zVersion, zBuild];
#else
			zBody = [zBody stringByAppendingFormat:@"Version: %@ (%@)\n",  zVersion, zBuild];
#endif
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


			AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
			[app.mainVC presentModalViewController:picker animated:YES];
			[picker release];
			//Bug//[self hide]; 上のアニメと競合してメール画面が表示されない。これより先にhideするように改めた。
		}	break;
	}
}

- (void)buGoAppStore:(UIButton *)button
{
	//alertBox( NSLocalizedString(@"Contact mail",nil), NSLocalizedString(@"Contact mail msg",nil), @"OK" );
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"GoAppStore Paid",nil)
													message:NSLocalizedString(@"GoAppStore Paid msg",nil)
												   delegate:self		// clickedButtonAtIndexが呼び出される
										  cancelButtonTitle:@"Cancel"
										  otherButtonTitles:@"OK", nil];
	alert.tag = ALERT_TAG_GoAppStore;
	[alert show];
	[alert autorelease];
}

- (void)buGoSupportSite:(UIButton *)button
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"GoSupportSite",nil)
													message:NSLocalizedString(@"GoSupportSite msg",nil)
												   delegate:self		// clickedButtonAtIndexが呼び出される
										  cancelButtonTitle:@"Cancel"
										  otherButtonTitles:@"OK", nil];
	alert.tag = ALERT_TAG_GoSupportSite;
	[alert show];
	[alert autorelease];
}

-(void)buPostComment:(UIButton*)sender 
{
	//メール送信可能かどうかのチェック　　＜＜＜MessageUI.framework が必要＞＞＞
    if (![MFMailComposeViewController canSendMail]) {
		//[self setAlert:@"メールが起動出来ません！":@"メールの設定をしてからこの機能は使用下さい。"];
		alertBox( NSLocalizedString(@"Contact NoMail",nil), NSLocalizedString(@"Contact NoMail msg",nil), @"OK" );
        return;
    }

	[self hide]; //アニメ競合しないように、先にhideしている。

	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Contact mail",nil)
													message:NSLocalizedString(@"Contact mail msg",nil)
												   delegate:self		// clickedButtonAtIndexが呼び出される
										  cancelButtonTitle:@"Cancel"
										  otherButtonTitles:@"OK", nil];
	alert.tag = ALERT_TAG_PostComment;
	[alert show];
	[alert autorelease];
}


#pragma mark - Touch

// タッチイベント
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[self hide];
}


#pragma mark - View

//- (id)initWithFrame:(CGRect)rect 
- (id)init
{
	// アニメションの開始位置
//	rect.origin.y = 20.0f - rect.size.height;
									// ↓
// if (!(self = [super initWithFrame:rect])) return self;
	self = [super init];
	if (!self) return nil;

	// 小豆色 RGB(152,81,75) #98514B
	self.view.backgroundColor = [UIColor colorWithRed:152/255.0f 
												green:81/255.0f 
												 blue:75/255.0f
												alpha:1.0f];
#ifdef AzPAD
	// Popover
	self.contentSizeForViewInPopover = CGSizeMake(320, 480);
#else	
	self.view.userInteractionEnabled = YES; //タッチの可否
#endif
	
	//------------------------------------------アイコン
#ifdef AzPAD
	UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(20, 35, 72, 72)];
#ifdef AzSTABLE
	[iv setImage:[UIImage imageNamed:@"Icon72s1.png"]];
#else
	[iv setImage:[UIImage imageNamed:@"Icon72Free.png"]];
#endif
#else	
	UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(20, 50, 57, 57)];
#ifdef AzSTABLE
	[iv setImage:[UIImage imageNamed:@"Icon57s1.png"]];
#else
	[iv setImage:[UIImage imageNamed:@"Icon57.png"]];
#endif
#endif
	[self.view addSubview:iv]; [iv release];
	
	UILabel *label;
	//------------------------------------------Lable:タイトル
	label = [[UILabel alloc] initWithFrame:CGRectMake(100, 40, 200, 40)];
	label.text = NSLocalizedString(@"Product Title",nil);
	label.textAlignment = UITextAlignmentCenter;
	label.textColor = [UIColor whiteColor];
	label.backgroundColor = [UIColor clearColor]; //背景透明
	//label.font = [UIFont boldSystemFontOfSize:25];
	label.font = [UIFont fontWithName:@"Futura-CondensedExtraBold" size:35];
	label.adjustsFontSizeToFitWidth = YES;
	label.minimumFontSize = 16;
	label.baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
	[self.view addSubview:label]; [label release];
	
	//------------------------------------------Lable:Version
	label = [[UILabel alloc] initWithFrame:CGRectMake(100, 80, 200, 45)];
#ifdef AzSTABLE
	NSString *zFree = @"PackList";
#else	
	NSString *zFree = @"PackList Free";
#endif
#ifdef AzPAD
	NSString *zDevice = @"for iPad";
#else	
	NSString *zDevice = @"for iPhone";
#endif
	NSString *zVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]; //（リリース バージョン）は、ユーザーに公開した時のレベルを表現したバージョン表記
	label.text = [NSString stringWithFormat:@"%@\n%@\nVersion %@", zFree, zDevice, zVersion];
	label.numberOfLines = 3;
	label.textAlignment = UITextAlignmentCenter;
	label.textColor = [UIColor whiteColor];
	label.backgroundColor = [UIColor clearColor]; //背景透明
	label.font = [UIFont boldSystemFontOfSize:12];
	[self.view addSubview:label]; [label release];

	//------------------------------------------Lable:Azuki Color
	label = [[UILabel alloc] initWithFrame:CGRectMake(20, 110, 100, 77)];
	label.text = @"Azukid Color\n"
						@"RGB(151,80,77)\n"
						@"Code#97504D\n"
						@"Japanese\n"
						@"tradition\n"
						@"color.";
	label.numberOfLines = 6;
	label.textAlignment = UITextAlignmentLeft;
	label.textColor = [UIColor whiteColor];
	label.backgroundColor = [UIColor clearColor]; //背景透明
	label.font = [UIFont boldSystemFontOfSize:10];
	[self.view addSubview:label]; [label release];
	
	//------------------------------------------Lable:著作権表示
	label = [[UILabel alloc] initWithFrame:CGRectMake(100, 130, 200, 60)];
	label.text =	@"Born on March 2\n"
						@"© 1995-2011 Azukid\n"
						@"Creator Sum Positive\n"
						@"All Rights Reserved.";
	label.numberOfLines = 4;
	label.textAlignment = UITextAlignmentCenter;
	label.textColor = [UIColor whiteColor];
	label.backgroundColor = [UIColor clearColor]; //背景透明
	label.font = [UIFont systemFontOfSize:12];
	[self.view addSubview:label]; [label release];	
	
	//------------------------------------------Go to Support blog.
	UIButton *bu = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	bu.titleLabel.font = [UIFont boldSystemFontOfSize:12];
	bu.frame = CGRectMake(20, 210, 120,26);
	[bu setTitle:NSLocalizedString(@"GoSupportSite",nil) forState:UIControlStateNormal];
	[bu addTarget:self action:@selector(buGoSupportSite:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:bu];  //autorelease

#if defined(AzFREE)
	//------------------------------------------Go to App Store
	bu = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	bu.titleLabel.font = [UIFont boldSystemFontOfSize:10];
	bu.frame = CGRectMake(150, 210, 150,26);
	[bu setTitle:NSLocalizedString(@"GoAppStore Paid",nil) forState:UIControlStateNormal];
	[bu addTarget:self action:@selector(buGoAppStore:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:bu];  //autorelease
#endif
	
	//------------------------------------------Post Comment
	bu = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	bu.titleLabel.font = [UIFont boldSystemFontOfSize:14];
	bu.frame = CGRectMake(20, 255, 280, 30); //  110, 240, 180,30);
	[bu setTitle:NSLocalizedString(@"Contact mail",nil) forState:UIControlStateNormal];
	[bu addTarget:self action:@selector(buPostComment:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:bu];  //autorelease
	
	//------------------------------------------免責
	label = [[UILabel alloc] initWithFrame:CGRectMake(20, 300, 280, 50)];
	label.text = NSLocalizedString(@"Disclaimer",nil);
	label.textAlignment = UITextAlignmentLeft;
	label.numberOfLines = 4;
	label.textColor = [UIColor whiteColor];
	label.backgroundColor = [UIColor clearColor]; //背景透明
	label.font = [UIFont fontWithName:@"Courier" size:10];
	[self.view addSubview:label]; [label release];	
	
	//------------------------------------------注意
	label = [[UILabel alloc] initWithFrame:CGRectMake(20, 360, 280, 65)];
	label.text = NSLocalizedString(@"Security Alert",nil);
	label.textAlignment = UITextAlignmentLeft;
	label.numberOfLines = 5;
	label.textColor = [UIColor whiteColor];
	label.backgroundColor = [UIColor clearColor]; //背景透明
	label.font = [UIFont fontWithName:@"Courier" size:10];
	[self.view addSubview:label]; [label release];	

	//------------------------------------------CLOSE
	label = [[UILabel alloc] initWithFrame:CGRectMake(20, 435, 280, 25)];
#ifdef AzPAD
	label.text = NSLocalizedString(@"Infomation Open Pad",nil);
#else
	label.text = NSLocalizedString(@"Infomation Open",nil);
#endif
	label.textAlignment = UITextAlignmentCenter;
	label.textColor = [UIColor whiteColor];
	label.backgroundColor = [UIColor clearColor]; //背景透明
	label.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
	[self.view addSubview:label]; [label release];	

    return self;
}

/*
- (void)viewWillAppear:(BOOL)animated 
{
	[super viewWillAppear:animated];

#ifdef AzPAD
	self.title = NSLocalizedString(@"Information", nil);
#endif
}
 */

// 回転サポート
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
#ifdef AzPAD
	return YES;
#else
	return (interfaceOrientation == UIInterfaceOrientationPortrait); // 正面のみ許可
#endif
}

/*
// ユーザインタフェースの回転の最後の半分が始まる前にこの処理が呼ばれる　＜＜このタイミングで配置転換すると見栄え良い＞＞
- (void)willAnimateSecondHalfOfRotationFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation 
													   duration:(NSTimeInterval)duration
{
	[self hide]; // 回転が始まるとhideする
}

- (void)openWebSite
{
	UIWebView *web = [[UIWebView alloc] init];
	web.frame = self.bounds;
	web.autoresizingMask = UIViewAutoresizingFlexibleWidth OR UIViewAutoresizingFlexibleHeight;
	web.scalesPageToFit = YES;
	[self addSubview:web]; [web release];
	
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://azpacking.azukid.com/"]];
	[web loadRequest:request];
}
*/

- (void)hide
{
	[self dismissModalViewControllerAnimated:YES];
}

- (void)show
{
	return;
}

/*
- (void)hide
{
	// Scroll away the overlay
	CGContextRef context = UIGraphicsGetCurrentContext();
	[UIView beginAnimations:nil context:context];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.5];
	
	CGRect rect = [self frame];
	rect.origin.y = -10.0f - rect.size.height;
	[self setFrame:rect];
	
	// Complete the animation
	[UIView commitAnimations];
}

- (void)show
{
	// Scroll in the overlay
	CGContextRef context = UIGraphicsGetCurrentContext();
	[UIView beginAnimations:nil context:context];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.5];
	
	CGRect rect = [self frame];
	rect.origin.y = 0.0f;
	[self setFrame:rect];
	
	// Complete the animation
	[UIView commitAnimations];
}
 */

#pragma mark - MFMailComposeViewControllerDelegate

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
	// [self dismissModalViewControllerAnimated:YES];
	AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	[app.mainVC dismissModalViewControllerAnimated:YES];
}


@end

