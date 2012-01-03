//
//  editLabelNumberVC.m
//  AzPacking
//
//  Created by 松山 和正 on 10/01/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Global.h"
#import "AppDelegate.h"
#import "editLabelNumberVC.h"

@interface editLabelNumberVC (PrivateMethods)
- (void)viewDesign;
- (void)done:(id)sender;
@end

@implementation editLabelNumberVC
@synthesize RlbStock;
@synthesize RlbNeed;
@synthesize RlbWeight;
@synthesize PiFirstResponder;

- (void)dealloc    // 生成とは逆順に解放するのが好ましい
{
	//--------------------------------@property (retain)
	[RlbStock release];
	[RlbNeed release];
	[RlbWeight release];
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


// IBを使わずにviewオブジェクトをプログラム上でcreateするときに使う（viewDidLoadは、nibファイルでロードされたオブジェクトを初期化するために使う）
- (void)loadView
{
	[super loadView];
	// メモリ不足時に self.viewが破棄されると同時に破棄されるオブジェクトを初期化する
	MtfStock = nil;		// ここで生成 [self.view addSubview:]
	MtfNeed = nil;		// ここで生成 [self.view addSubview:]
	MtfWeight = nil;	// ここで生成 [self.view addSubview:]
	MlabelStock = nil;	// ここで生成 [self.view addSubview:]
	MlabelNeed = nil;	// ここで生成 [self.view addSubview:]
	MlabelWeight = nil;	// ここで生成 [self.view addSubview:]


	self.view.backgroundColor = MpColorBlue(0.3f); //[UIColor groupTableViewBackgroundColor];

	// DONEボタンを右側に追加する
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
											   initWithBarButtonSystemItem:UIBarButtonSystemItemDone
											   target:self action:@selector(done:)] autorelease];

	// とりあえず生成、位置はviewDesignにて決定
	//------------------------------------------------------
	MlabelStock = [[UILabel alloc] init];
	MlabelStock.text = NSLocalizedString(@"StockQty",nil);
	MlabelStock.textAlignment = UITextAlignmentCenter;
	MlabelStock.textColor = [UIColor whiteColor];
	MlabelStock.backgroundColor = [UIColor clearColor];
	MlabelStock.font = [UIFont systemFontOfSize:14];
	[self.view addSubview:MlabelStock]; [MlabelStock release]; // self.viewがOwnerになる
	//------------------------------------------------------
	MtfStock = [[UITextField alloc] init];
	MtfStock.borderStyle = UITextBorderStyleRoundedRect;
	MtfStock.clearButtonMode = UITextFieldViewModeAlways;
	MtfStock.font = [UIFont fontWithName:@"Verdana-Bold" size:30];
	MtfStock.textAlignment = UITextAlignmentRight;
	MtfStock.keyboardType = UIKeyboardTypeNumberPad;
	MtfStock.returnKeyType = UIReturnKeyDone;
	MtfStock.delegate = self;  // textViewDidBeginEditingなどが呼び出されるように
	MtfStock.tag = 999; // 最大値
	[self.view addSubview:MtfStock]; [MtfStock release];
	[MtfStock resignFirstResponder];  // 初期キーボード表示しない　viewDidAppearにて表示
	
	//------------------------------------------------------
	MlabelNeed = [[UILabel alloc] init];
	MlabelNeed.text = NSLocalizedString(@"Need Qty",nil);
	MlabelNeed.textAlignment = UITextAlignmentCenter;
	MlabelNeed.textColor = [UIColor whiteColor];
	MlabelNeed.backgroundColor = [UIColor clearColor];
	MlabelNeed.font = [UIFont systemFontOfSize:14];
	[self.view addSubview:MlabelNeed]; [MlabelNeed release];
	//------------------------------------------------------
	MtfNeed = [[UITextField alloc] init];
	MtfNeed.borderStyle = UITextBorderStyleRoundedRect;
	MtfNeed.clearButtonMode = UITextFieldViewModeAlways;
	MtfNeed.font = [UIFont fontWithName:@"Verdana-Bold" size:30];
	MtfNeed.textAlignment = UITextAlignmentRight;
	MtfNeed.keyboardType = UIKeyboardTypeNumberPad;
	MtfNeed.returnKeyType = UIReturnKeyDone;
	MtfNeed.delegate = self;  // textViewDidBeginEditingなどが呼び出されるように
	MtfNeed.tag = 999; // 最大値
	[self.view addSubview:MtfNeed]; [MtfNeed release];
	[MtfNeed resignFirstResponder];  // 初期キーボード表示しない　viewDidAppearにて表示

	//------------------------------------------------------
	MlabelWeight = [[UILabel alloc] init];
	MlabelWeight.text = NSLocalizedString(@"One Weight",nil);
	MlabelWeight.textAlignment = UITextAlignmentCenter;
	MlabelWeight.textColor = [UIColor whiteColor];
	MlabelWeight.backgroundColor = [UIColor clearColor];
	MlabelWeight.font = [UIFont systemFontOfSize:14];
	[self.view addSubview:MlabelWeight]; [MlabelWeight release];
	//------------------------------------------------------
	MtfWeight = [[UITextField alloc] init];
	MtfWeight.borderStyle = UITextBorderStyleRoundedRect;
	MtfWeight.clearButtonMode = UITextFieldViewModeAlways;
	MtfWeight.font = [UIFont fontWithName:@"Verdana-Bold" size:30];
	MtfWeight.textAlignment = UITextAlignmentRight;
	MtfWeight.keyboardType = UIKeyboardTypeNumberPad;
	MtfWeight.returnKeyType = UIReturnKeyDone;
	MtfWeight.delegate = self;  // textViewDidBeginEditingなどが呼び出されるように
	MtfWeight.tag = 99999; // 最大値
	[self.view addSubview:MtfWeight]; [MtfWeight release];
	[MtfWeight resignFirstResponder];  // 初期キーボード表示しない　viewDidAppearにて表示
}

// viewWillAppear はView表示直前に呼ばれる。よって、Viewの変化要素はここに記述する。　 　// viewDidAppear はView表示直後に呼ばれる
- (void)viewWillAppear:(BOOL)animated 
{
	[super viewWillAppear:animated];
	
	// 画面表示に関係する Option Setting を取得する
	//NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	if (0 < [RlbStock.text length])		MtfStock.placeholder = RlbStock.text;
	else	MtfStock.placeholder = @"0";

	if (0 < [RlbNeed.text length])		MtfNeed.placeholder = RlbNeed.text;
	else	MtfNeed.placeholder = @"0";

	if (0 < [RlbWeight.text length])	MtfWeight.placeholder = RlbWeight.text;
	else	MtfWeight.placeholder = @"0";

	[self viewDesign];
	//ここでキーを呼び出すと画面表示が無いまま待たされてしまうので、viewDidAppearでキー表示するように改良した。
	//[MtextView becomeFirstResponder];  // キーボード表示
}

// 画面表示された直後に呼び出される
- (void)viewDidAppear:(BOOL)animated 
{
	[super viewDidAppear:animated];
	
	self.title = NSLocalizedString(@"Numeric Input",nil);
	
	//viewWillAppearでキーを表示すると画面表示が無いまま待たされてしまうので、viewDidAppearでキー表示するように改良した。
	switch (self.PiFirstResponder) {
		case 0:
			[MtfStock becomeFirstResponder];  // キーボード表示
			break;
		case 1:
			[MtfNeed becomeFirstResponder];  // キーボード表示
			break;
		case 2:
			[MtfWeight becomeFirstResponder];  // キーボード表示
			break;
		default:
			// 初期レスポンダなし
			break;
	}
}

// 回転サポート
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{	// 回転禁止でも万一ヨコからはじまった場合、タテにはなるようにしてある。
	AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	return app.AppShouldAutorotate OR (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// ユーザインタフェースの回転の最後の半分が始まる前にこの処理が呼ばれる　＜＜このタイミングで配置転換すると見栄え良い＞＞
- (void)willAnimateSecondHalfOfRotationFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation 
													   duration:(NSTimeInterval)duration
{
	//[self viewWillAppear:NO];没：これを呼ぶと、回転の都度、編集がキャンセルされてしまう。
	[self viewDesign]; // これで回転しても編集が継続されるようになった。
}

- (void)viewDesign
{
	CGRect rect;
	
	if (self.interfaceOrientation == UIInterfaceOrientationPortrait 
	 OR self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) 
	{	// タテ
		// Stock
		rect.size.width = 130; // 999
		rect.origin.x = self.view.bounds.size.width/4 - rect.size.width/2;
		rect.origin.y = 30;
		rect.size.height = 20;
		MlabelStock.frame = rect;
		rect.origin.y = 50;
		rect.size.height = 40;
		MtfStock.frame = rect;	

		// Need
		rect.size.width = 130; // 999
		rect.origin.x = (self.view.bounds.size.width/4) * 3 - rect.size.width/2;
		rect.origin.y = 30;
		rect.size.height = 20;
		MlabelNeed.frame = rect;
		rect.origin.y = 50;
		rect.size.height = 40;
		MtfNeed.frame = rect;	
		
		// Weight
		rect.size.width = 160; // 99999
		rect.origin.x = self.view.bounds.size.width/2 - rect.size.width/2;
		rect.origin.y = 110;
		rect.size.height = 20;
		MlabelWeight.frame = rect;
		rect.origin.y = 130;
		rect.size.height = 40;
		MtfWeight.frame = rect;	
	}
	else {	// ヨコ
		NSInteger iGapX = (self.view.bounds.size.width - 120 - 120 - 160) / 4;
		// Stock
		rect.size.width = 130; // 999
		rect.origin.x = iGapX;
		rect.origin.y = 20;
		rect.size.height = 20;
		MlabelStock.frame = rect;
		rect.origin.y = 40;
		rect.size.height = 40;
		MtfStock.frame = rect;	
		
		// Need
		rect.size.width = 130; // 999
		rect.origin.x = iGapX + 120 + iGapX;
		rect.origin.y = 20;
		rect.size.height = 20;
		MlabelNeed.frame = rect;
		rect.origin.y = 40;
		rect.size.height = 40;
		MtfNeed.frame = rect;	
		
		// Weight
		rect.size.width = 160; // 99999
		rect.origin.x = iGapX + 120 + iGapX + 120 + iGapX;
		rect.origin.y = 20;
		rect.size.height = 20;
		MlabelWeight.frame = rect;
		rect.origin.y = 40;
		rect.size.height = 40;
		MtfWeight.frame = rect;	
	}

}	

//テキストフィールドの文字変更のイベント処理
// UITextFieldオブジェクトから1文字入力の都度呼び出されることにより入力文字数制限を行っている。
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range 
														replacementString:(NSString *)string 
{	// textField.tag = 最大値がセットされてある
	if (![string boolValue] && ![string isEqual:@"0"]) return YES; // 数字でない [X]キーなど
	
	if ([textField.text isEqual:@"0"]) {
		textField.text = @""; // 先頭の0を取り除くため
		return NO;
	}
	
	// 範囲ペーストされることも考慮したチェック方法
	NSMutableString *text = [[textField.text mutableCopy] autorelease];
    [text replaceCharactersInRange:range withString:string];
	[text replaceOccurrencesOfString:@"," withString:@"" 
							 options:NSLiteralSearch range:NSMakeRange(0,[text length])]; // コンマを取り除く
	NSInteger iNum = [text integerValue]; // 入力を受け入れた後の値
	if (iNum < 0 OR textField.tag < iNum) return NO; // OVER

	// 3桁コンマを入れる
	
	return YES; // この後、stringが追加される。
}

//テキストフィールドのクリア時のイベント処理
//- (BOOL)textFieldShouldClear:(UITextField *)textField {

//テキストフィールドリターン時のイベント処理
- (BOOL)textFieldShouldReturn:(UITextField *)sender 
{
	[self done:sender];
    return YES;
}

- (void)done:(id)sender
{
	if (0 < [MtfStock.text length])		RlbStock.text = MtfStock.text;

	if (0 < [MtfNeed.text length])		RlbNeed.text = MtfNeed.text;

	if (0 < [MtfWeight.text length])	RlbWeight.text = MtfWeight.text;
	
	[self.navigationController popViewControllerAnimated:YES];	// < 前のViewへ戻る
}

@end
