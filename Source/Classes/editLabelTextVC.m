//
//  editLabelTextVC.m
//  AzPacking
//
//  Created by 松山 和正 on 10/01/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Global.h"
#import "AppDelegate.h"
#import "editLabelTextVC.h"

@interface editLabelTextVC (PrivateMethods)
- (void)viewDesign;
- (void)done:(id)sender;
@end

@implementation editLabelTextVC
@synthesize Rlabel;
@synthesize PiMaxLength;
@synthesize PiSuffixLength;

- (void)dealloc    // 生成とは逆順に解放するのが好ましい
{
	//--------------------------------@property (retain)
	[Rlabel release];
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

	self.view.backgroundColor = MpColorBlue(0.3f); //[UIColor groupTableViewBackgroundColor];

	// DONEボタンを右側に追加する
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
											   initWithBarButtonSystemItem:UIBarButtonSystemItemDone
											   target:self action:@selector(done:)] autorelease];

	// とりあえず生成、位置はviewDesignにて決定
	MtextView = [[[UITextView alloc] init] autorelease];
	MtextView.font = [UIFont systemFontOfSize:16];
	MtextView.textAlignment = UITextAlignmentLeft;
	MtextView.keyboardType = UIKeyboardTypeDefault;
	MtextView.returnKeyType = UIReturnKeyDefault; // Return
	MtextView.delegate = self;
	[self.view addSubview:MtextView]; //[MtextView release]; // self.viewがOwnerになる
	
	[MtextView resignFirstResponder];  // 初期キーボード表示しない　viewDidAppearにて表示
}

// viewWillAppear はView表示直前に呼ばれる。よって、Viewの変化要素はここに記述する。　 　// viewDidAppear はView表示直後に呼ばれる
- (void)viewWillAppear:(BOOL)animated 
{
	[super viewWillAppear:animated];

	// 画面表示に関係する Option Setting を取得する
	//NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	[self viewDesign];
	
	if (0 < PiSuffixLength) {
		// 末尾改行文字("\n")を PiSuffixLength 個除く -->> doneにて追加する
		if ([Rlabel.text length] <= PiSuffixLength) {
			MtextView.text = @"";  //この処理が無いと新規のときフリーズする
		} else {
			MtextView.text = [Rlabel.text substringToIndex:([Rlabel.text length] - PiSuffixLength)];
		}
	} else {
		MtextView.text = Rlabel.text;
	}
	
	//ここでキーを呼び出すと画面表示が無いまま待たされてしまうので、viewDidAppearでキー表示するように改良した。
	//[MtextView becomeFirstResponder];  // キーボード表示
}

// 画面表示された直後に呼び出される
- (void)viewDidAppear:(BOOL)animated 
{
	[super viewDidAppear:animated];
	//viewWillAppearでキーを表示すると画面表示が無いまま待たされてしまうので、viewDidAppearでキー表示するように改良した。
	[MtextView becomeFirstResponder];  // キーボード表示
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
	
	//BOOL	bPortrait;
	float	fKeyHeight;

	if (self.interfaceOrientation == UIInterfaceOrientationPortrait OR self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
		fKeyHeight = GD_KeyboardHeightPortrait;	 // タテ
												 //bPortrait = YES;
	} else {
		fKeyHeight = GD_KeyboardHeightLandscape; // ヨコ
												 //bPortrait = NO;
	}

	rect = self.view.bounds;
	rect.origin.x += 10;
	rect.origin.y += 10;
	rect.size.width -= 20;
	rect.size.height -= (20 + fKeyHeight);
	MtextView.frame = rect;	
}	


// <UITextViewDelegete> テキストが変更される「直前」に呼び出される。これにより入力文字数制限を行っている。
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range 
													replacementText:(NSString *)zReplace
{
	if (PiMaxLength <= 0) return YES; // 無制限
	
	// senderは、MtextView だけ
    NSMutableString *zText = [[textView.text mutableCopy] autorelease];
    [zText replaceCharactersInRange:range withString:zReplace];
	// 置き換えた後の長さをチェックする
	return ([zText length] <= PiMaxLength); // PiMaxLength以下YES
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

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)done:(id)sender
{
	if (0 < PiSuffixLength) {
		// 末尾改行文字("\n")を PiSuffixLength 個追加する
		NSMutableString *str = [NSMutableString stringWithString:MtextView.text];
		for (NSInteger i=0; i<PiSuffixLength; i++) {
			[str appendString:@"\n"];
		}
		Rlabel.text = str;
	} else {
		Rlabel.text = MtextView.text;
	}
	
	[self.navigationController popViewControllerAnimated:YES];	// < 前のViewへ戻る
}

@end
