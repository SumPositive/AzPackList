//
//  InformationVC.m
//  AzPacking
//
//  Created by 松山 和正 on 10/02/04.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Global.h"
#import "InformationVC.h"


@interface InformationVC (PrivateMethods)
	BOOL MbOptShouldAutorotate;
@end
@implementation InformationVC


- (void)dealloc {
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
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
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];

	[self.view setAlpha:0.9f]; // Information時
	[self.view setBackgroundColor: MpColorBlue(0.1f)];
	self.view.userInteractionEnabled = YES; //タッチの可否
	
	//------------------------------------------アイコン
	UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(20, 100, 57, 57)];
	[iv setImage:[UIImage imageNamed:@"icon.png"]];
	[self.view addSubview:iv];
	[iv release];
	
	UILabel *label;
	//------------------------------------------Lable:タイトル
	label = [[UILabel alloc] initWithFrame:CGRectMake(100, 100, 200, 25)];
	label.text = @"AzPacking";
	label.textAlignment = UITextAlignmentLeft;
	label.textColor = [UIColor whiteColor];
	label.backgroundColor = [UIColor clearColor]; //背景透明
	label.font = [UIFont boldSystemFontOfSize:20];
	[self.view addSubview:label];
	[label release];
	
	//------------------------------------------Lable:Version
	label = [[UILabel alloc] initWithFrame:CGRectMake(130, 120, 200, 35)];
	label.text = [NSString stringWithFormat:@"Version %2d.  Release %2d.", (int)AzVERSION, (int)AzRELEASE];
	label.textAlignment = UITextAlignmentLeft;
	label.lineBreakMode = UILineBreakModeWordWrap;
	label.textColor = [UIColor whiteColor];
	label.backgroundColor = [UIColor clearColor]; //背景透明
	label.font = [UIFont boldSystemFontOfSize:12];
	[self.view addSubview:label];
	[label release];
	
	//------------------------------------------Lable:著作権表示
	label = [[UILabel alloc] initWithFrame:CGRectMake(100, 158, 200, 100)];
	label.text =	@"AzukiSoft Project\n"
					@"AzPacking Born on March 2.\n"
					@"Copyright © 1995-2010\n"
					@"Sunsho.Kazu＠Azukid.com\n"
					@"All Rights Reserved.";
	label.numberOfLines = 5;
	label.textAlignment = UITextAlignmentLeft;
	label.lineBreakMode = UILineBreakModeWordWrap;
	label.textColor = [UIColor whiteColor];
	label.backgroundColor = [UIColor clearColor]; //背景透明
	label.font = [UIFont systemFontOfSize:12];
	[self.view addSubview:label];
	[label release];	
	
	//------------------------------------------免責
	label = [[UILabel alloc] initWithFrame:CGRectMake(20, 260, 280, 100)];
	label.text = NSLocalizedString(@"Disclaimer",@"免責 max10行");
	label.textAlignment = UITextAlignmentLeft;
	label.numberOfLines = 10;
	label.lineBreakMode = UILineBreakModeWordWrap;
	label.textColor = [UIColor whiteColor];
	label.backgroundColor = [UIColor clearColor]; //背景透明
	label.font = [UIFont fontWithName:@"Courier" size:10];
	[self.view addSubview:label];
	[label release];	
	
	//------------------------------------------CLOSE
	label = [[UILabel alloc] initWithFrame:CGRectMake(20, 450, 280, 25)];
	label.text = @"Touch anywhere to open the Information.";
	label.textAlignment = UITextAlignmentCenter;
	label.textColor = [UIColor whiteColor];
	label.backgroundColor = [UIColor clearColor]; //背景透明
	label.lineBreakMode = UILineBreakModeWordWrap;
	label.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
	[self.view addSubview:label];
	[label release];	
}

// 回転サポート
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	// 回転禁止でも万一ヨコからはじまった場合、タテにはなるようにしてある。
	return MbOptShouldAutorotate OR (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// ユーザインタフェースの回転の最後の半分が始まる前にこの処理が呼ばれる　＜＜このタイミングで配置転換すると見栄え良い＞＞
- (void)willAnimateSecondHalfOfRotationFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation 
													   duration:(NSTimeInterval)duration
{

}

// 他のViewやキーボードが隠れて、現れる都度、呼び出される
- (void)viewWillAppear:(BOOL)animated 
{
	// 画面表示に関係する Option Setting を取得する
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	MbOptShouldAutorotate = [userDefaults boolForKey:GD_OptShouldAutorotate];
	
    [super viewWillAppear:animated];
	
	self.title = NSLocalizedString(@"Information", nil);
	
}

// タッチイベント
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{
	[self.navigationController dismissModalViewControllerAnimated:YES];	// < 前のViewへ戻る
}

@end
