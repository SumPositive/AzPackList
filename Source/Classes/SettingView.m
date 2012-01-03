//
//  AzInfoView.m
//  iPack
//
//  Created by 松山 和正 on 10/01/03.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Global.h"
#import "E1viewController.h"
#import "SettingView.h"
//#import "WindshieldView.h"

#define SetOptTOP	100		// Option行の最上行(Y)
#define SetOptGAP	 60		// Option行間隔

#define TAG_OptStartupWindshield			998
#define TAG_OptStartupRestoreLevel			997
#define TAG_OptDisclosureButtonToEditable	996
#define TAG_OptTotlWeightRound				995
#define TAG_OptShowTotalWeight				994
#define TAG_OptShowTotalWeightReq			993
#define TAG_OptEditAnimation				992

@interface SettingView (PrivateMethods)
	static UIColor *MpColorBlue(float percent);
	- (void)switchAction:(UISwitch *)sender;
@end
@implementation SettingView
@synthesize PparentViewCon;

- (void)dealloc 
{
	// @property (retain)
	AzRETAIN_CHECK(@"SettingView PparentViewCon", PparentViewCon, 1)
	[PparentViewCon release];

    [super dealloc];
}

static UIColor *MpColorBlue(float percent) {
	float red = percent * 255.0f;
	float green = (red + 20.0f) / 255.0f;
	float blue = (red + 45.0f) / 255.0f;
	if (green > 1.0) green = 1.0f;
	if (blue > 1.0f) blue = 1.0f;
	
	return [UIColor colorWithRed:percent green:green blue:blue alpha:1.0f];
}

/*
- (void) setTitle: (NSString *)titleText
{
	[(UILabel *)[self viewWithTag:TITLE_TAG] setText:titleText];
}

- (void) setMessage: (NSString *)messageText
{
	[(UILabel *)[self viewWithTag:MESSAGE_TAG] setText:messageText];
}
*/

- (SettingView *)initWithFrame: (CGRect)rect
{
	// アニメションの開始位置
	rect.origin.y = 20.0f - rect.size.height; // Place above status bar
	
	if (!(self = [super initWithFrame:rect])) return self;
	
	[self setAlpha:0.9];
	[self setBackgroundColor: MpColorBlue(0.4f)];

	BOOL bOpt;
	UILabel *lb;
	UISwitch *sw;
	UIButton *bu;
	
	//------------------------------------------クローズボタン
	bu = [[UIButton alloc] initWithFrame:CGRectMake(280, 440, 32, 32)];
	[bu setBackgroundImage:[UIImage imageNamed:@"simpleUpOpen-icon32.png"] forState:UIControlStateNormal];
	[bu addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:bu];
	[bu release];
	
	//------------------------------------------Lable:タイトル
	lb = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 50.0f, 320.0f, 32.0f)];
	lb.text = @"Option Setting";
	lb.textAlignment = UITextAlignmentCenter;
	lb.textColor = [UIColor whiteColor];
	lb.backgroundColor = [UIColor clearColor]; //背景透明
	lb.font = [UIFont boldSystemFontOfSize:20.0f];
	[self addSubview:lb];
	[lb release];
	
	
	NSInteger iOptTop = SetOptTOP;
	//------------------------------------------SWITCH:Opt起動時、前回の階層を復元する。
	lb = [[UILabel alloc] initWithFrame:CGRectMake(10, iOptTop, 300, 20)];
	lb.text = NSLocalizedString(@"Startup, to restore the previous level.",@"起動時前回復帰");
	lb.font = [UIFont systemFontOfSize:14];
	lb.textColor = [UIColor whiteColor];
	lb.backgroundColor = [UIColor clearColor]; //背景透明
	[self addSubview:lb];
	[lb release];
	sw = [[UISwitch alloc] initWithFrame:CGRectMake(210, iOptTop+20, 100, 25)];
	//switchView.delegate = self;
	bOpt = [[NSUserDefaults standardUserDefaults] boolForKey:GD_OptStartupRestoreLevel];
	[sw setOn:bOpt animated:NO]; // 初期値セット
	[sw addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
	sw.tag = TAG_OptStartupRestoreLevel;
	sw.backgroundColor = [UIColor clearColor]; //背景透明
	[self addSubview:sw];
	[sw release];

	//------------------------------------------SWITCH:Optディスクロージャボタンから編集できるようにする。
	iOptTop += SetOptGAP;
	lb = [[UILabel alloc] initWithFrame:CGRectMake(10, iOptTop, 300, 20)];
	lb.text = NSLocalizedString(@"To be able to edit from Disclosure button.",@"右ボタンで編集可能");
	lb.font = [UIFont systemFontOfSize:14];
	lb.textColor = [UIColor whiteColor];
	lb.backgroundColor = [UIColor clearColor]; //背景透明
	[self addSubview:lb];
	[lb release];
	sw = [[UISwitch alloc] initWithFrame:CGRectMake(210, iOptTop+20, 100, 25)];
	//switchView.delegate = self;
	bOpt = [[NSUserDefaults standardUserDefaults] boolForKey:GD_OptDisclosureButtonToEditable];
	[sw setOn:bOpt animated:NO]; // 初期値セット
	[sw addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
	sw.tag = TAG_OptDisclosureButtonToEditable;
	sw.backgroundColor = [UIColor clearColor]; //背景透明
	[self addSubview:sw];
	[sw release];
	
	//------------------------------------------GD_OptEditAnimation
	iOptTop += SetOptGAP;
	lb = [[UILabel alloc] initWithFrame:CGRectMake(10, iOptTop, 300, 40)];
	lb.text = NSLocalizedString(@"Edit panel animation.", @"編集画面アニメ");
	lb.numberOfLines = 2;
	lb.font = [UIFont systemFontOfSize:14];
	lb.textColor = [UIColor whiteColor];
	lb.backgroundColor = [UIColor clearColor]; //背景透明
	[self addSubview:lb];
	[lb release];
	sw = [[UISwitch alloc] initWithFrame:CGRectMake(210, iOptTop+20, 100, 25)];
	//switchView.delegate = self;
	bOpt = [[NSUserDefaults standardUserDefaults] boolForKey:GD_OptEditAnimation];
	[sw setOn:bOpt animated:NO]; // 初期値セット
	[sw addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
	sw.tag = TAG_OptEditAnimation;
	sw.backgroundColor = [UIColor clearColor]; //背景透明
	[self addSubview:sw];
	[sw release];
	
	//------------------------------------------GD_OptShowTotalWeight
	iOptTop += SetOptGAP;
	//-------------------------
	lb = [[UILabel alloc] initWithFrame:CGRectMake(10, iOptTop, 300, 40)];
	lb.text = NSLocalizedString(@"Show total Weight.\n"
								@"   Stock                           ／Req",	@"重量表示");
	lb.numberOfLines = 2;
	lb.lineBreakMode = UILineBreakModeWordWrap;
	lb.font = [UIFont systemFontOfSize:14];
	lb.textColor = [UIColor whiteColor];
	lb.backgroundColor = [UIColor clearColor]; //背景透明
	[self addSubview:lb];
	[lb release];
	//-------------------------在庫重量
	sw = [[UISwitch alloc] initWithFrame:CGRectMake(60, iOptTop+20, 100, 25)];
	//switchView.delegate = self;
	bOpt = [[NSUserDefaults standardUserDefaults] boolForKey:GD_OptShowTotalWeight];
	[sw setOn:bOpt animated:NO]; // 初期値セット
	[sw addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
	sw.tag = TAG_OptShowTotalWeight;
	sw.backgroundColor = [UIColor clearColor]; //背景透明
	[self addSubview:sw];
	[sw release];
	//-------------------------必要重量
	sw = [[UISwitch alloc] initWithFrame:CGRectMake(210, iOptTop+20, 100, 25)];
	//switchView.delegate = self;
	bOpt = [[NSUserDefaults standardUserDefaults] boolForKey:GD_OptShowTotalWeightReq];
	[sw setOn:bOpt animated:NO]; // 初期値セット
	[sw addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
	sw.tag = TAG_OptShowTotalWeightReq;
	sw.backgroundColor = [UIColor clearColor]; //背景透明
	[self addSubview:sw];
	[sw release];
	//-------------------------
	
	//------------------------------------------SWITCH:Opt重量の小数第2位は、四捨五入する。でなければ切り捨て。
	iOptTop += SetOptGAP;
	lb = [[UILabel alloc] initWithFrame:CGRectMake(10, iOptTop, 300, 40)];
	lb.text = NSLocalizedString(@"Second round of the weight is to be rounded.\n"
								@" Otherwise discarded.", @"四捨五入／切り捨て");
	lb.numberOfLines = 2;
	lb.lineBreakMode = UILineBreakModeWordWrap;
	lb.font = [UIFont systemFontOfSize:14];
	lb.textColor = [UIColor whiteColor];
	lb.backgroundColor = [UIColor clearColor]; //背景透明
	[self addSubview:lb];
	[lb release];
	sw = [[UISwitch alloc] initWithFrame:CGRectMake(210, iOptTop+20, 100, 25)];
	//switchView.delegate = self;
	bOpt = [[NSUserDefaults standardUserDefaults] boolForKey:GD_OptTotlWeightRound];
	[sw setOn:bOpt animated:NO]; // 初期値セット
	[sw addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
	sw.tag = TAG_OptTotlWeightRound;
	sw.backgroundColor = [UIColor clearColor]; //背景透明
	[self addSubview:sw];
	[sw release];
	
	return self;
}

// UISwitch Action
- (void)switchAction: (UISwitch *)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	switch (sender.tag) {  // .tag は UIView にて NSInteger で存在する、　
		case TAG_OptStartupRestoreLevel:
			[defaults setBool:[sender isOn] forKey:GD_OptStartupRestoreLevel];
			break;
		case TAG_OptDisclosureButtonToEditable:
			[defaults setBool:[sender isOn] forKey:GD_OptDisclosureButtonToEditable];
			break;
		case TAG_OptTotlWeightRound:
			[defaults setBool:[sender isOn] forKey:GD_OptTotlWeightRound];
			break;
		case TAG_OptShowTotalWeight:
			[defaults setBool:[sender isOn] forKey:GD_OptShowTotalWeight];
			break;
		case TAG_OptShowTotalWeightReq:
			[defaults setBool:[sender isOn] forKey:GD_OptShowTotalWeightReq];
			break;
		case TAG_OptEditAnimation:
			[defaults setBool:[sender isOn] forKey:GD_OptEditAnimation];
			break;
	}
	
	if (self.PparentViewCon) {
		// E1 or E2 or E3 の TableView を再描画する
		[self.PparentViewCon viewWillAppear:YES];
	}
}

- (void)show
{
	// Scroll in the overlay
	CGContextRef context = UIGraphicsGetCurrentContext();
	[UIView beginAnimations:nil context:context];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.5];
	
	//[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:[self superview] cache:YES];
	//[[self superview] exchangeSubviewAtIndex:0 withSubviewAtIndex:1];
	
	CGRect rect = [self frame];
	rect.origin.y = 0.0f;
	[self setFrame:rect];
	
	
	// Complete the animation
	[UIView commitAnimations];
}

- (void)hide
{
	// Scroll away the overlay
	CGContextRef context = UIGraphicsGetCurrentContext();
	[UIView beginAnimations:nil context:context];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.5];
	
	//[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:[self superview] cache:YES];
	//[[self superview] exchangeSubviewAtIndex:0 withSubviewAtIndex:1];
	
	CGRect rect = [self frame];
	rect.origin.y = -10.0f - rect.size.height;
	[self setFrame:rect];
	
	// Complete the animation
	[UIView commitAnimations];
}

/*
- (void)windShieldClose
{
	// WindshieldView 画面をタップすれば開く
	WindshieldView *shieldView = [[WindshieldView alloc] initWithFrame:[self.window bounds] closeAnimated:YES];
	[self addSubview:shieldView];
	[shieldView shieldClose];
	[shieldView release];
}
*/

@end
