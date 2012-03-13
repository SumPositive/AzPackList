//
//  SpSearchVC.m
//
//  Created by 松山 和正 on 10/01/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Global.h"
#import "AppDelegate.h"
#import "SpSearchVC.h"
#import "SpListTVC.h"


@interface SpSearchVC (PrivateMethods)
//- (void)viewDesign;
//- (void)done:(id)sender;
@end

@implementation SpSearchVC


#pragma mark - Action

- (void)actionBack:(id)sender
{
	[self dismissModalViewControllerAnimated:YES];
}

- (void)vBuSearch:(id)sender
{
	/*	// Tag条件
	 NSMutableArray *ma = [NSMutableArray new];
	 for (int comp=0; comp<3; comp++) {
	 NSInteger iRow = [Mpicker selectedRowInComponent:comp];
	 if (0 < iRow) {
	 [ma addObject:[[RaPickerSource objectAtIndex:comp] objectAtIndex:iRow]];
	 }
	 }*/
	
	// Search
	SpListTVC *vc = [[SpListTVC alloc] init];
	
	// Language
	NSInteger iRow = [Mpicker selectedRowInComponent:0];
	if (0 < iRow) {
		vc.RzLanguage = [[NSLocale preferredLanguages] objectAtIndex:iRow-1];
	} else {
		vc.RzLanguage = nil; // * ALL
	}
	
	// Sort条件
	NSInteger iSort = MsegSort.selectedSegmentIndex;
	if (iSort <= 0)	vc.RzSort = @"N"; //N 新着順
	else					vc.RzSort = @"P"; //P 人気順
	
	[self.navigationController pushViewController:vc animated:YES];
}


#pragma mark - View lifestyle

- (id)init 
{
	self = [super init];
	if (self) {
		// 初期化処理：インスタンス生成時に1回だけ通る
		// loadView:では遅い。shouldAutorotateToInterfaceOrientation:が先に呼ばれるため
		appDelegate_ = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		// 背景テクスチャ・タイルペイント
		self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Tx-Back"]];
		//self.contentSizeForViewInPopover =  //FormSheetスタイルにしたので不要
	}
	return self;
}


// IBを使わずにviewオブジェクトをプログラム上でcreateするときに使う（viewDidLoadは、nibファイルでロードされたオブジェクトを初期化するために使う）
- (void)loadView
{
	//NG//遅い//appDelegate_ = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [super loadView];
	// メモリ不足時に self.viewが破棄されると同時に破棄されるオブジェクトを初期化する
	Mpicker = nil;		// ここで生成
	
	//self.title = NSLocalizedString(@"Import SharePlan",nil);
	self.title = NSLocalizedString(@"SharePlan",nil);
	
	// Set up NEXT Left ＜Back] buttons.
	self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]
											  initWithTitle:NSLocalizedString(@"Search",nil)
											  style:UIBarButtonItemStylePlain  
											  target:nil  action:nil];

	if (appDelegate_.app_is_iPad) {
		// CANCELボタンを左側に追加する  Navi標準の戻るボタンでは cancel:処理ができないため
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
												 initWithTitle:NSLocalizedString(@"Back", nil)
												 style:UIBarButtonItemStyleBordered
												 target:self action:@selector(actionBack:)];
	}

	// とりあえず生成、位置はviewDesignにて決定
	//------------------------------------------------------
	Mpicker = [[UIPickerView alloc] init];
	Mpicker.delegate = self;
	Mpicker.dataSource = self;
	Mpicker.showsSelectionIndicator = YES;
	[self.view addSubview:Mpicker]; //[Mpicker release];
	[Mpicker selectRow:1 inComponent:0 animated:NO]; // デフォルト言語を選択

	//------------------------------------------------------ソート
	if (RaSegSortSource == nil) {
		RaSegSortSource = [[NSArray alloc] initWithObjects:
						  NSLocalizedString(@"New Order",nil),
						  NSLocalizedString(@"Sort by popularity",nil),
						  nil];
	}
	MsegSort = [[UISegmentedControl alloc] initWithItems:RaSegSortSource];
	MsegSort.selectedSegmentIndex = 0;
	//[MsegSort addTarget:self action:@selector(vSegSort:) forControlEvents:UIControlEventValueChanged];
	[self.view addSubview:MsegSort]; //[MsegSort release];
	//MsegSort.hidden = YES;  //GAE-V1:人気順("-downCount")に不具合あるため保留中

	//------------------------------------------------------
	MbuSearch = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	MbuSearch.titleLabel.font = [UIFont boldSystemFontOfSize:20];
	[MbuSearch setTitle:NSLocalizedString(@"Search",nil) forState:UIControlStateNormal];
	[MbuSearch addTarget:self action:@selector(vBuSearch:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:MbuSearch]; //[mBuSearch release]; autorelease
	//------------------------------------------------------
	
/*	// SharePlanTag.plist からタグリストを読み込む
	NSString *zPath = [[NSBundle mainBundle] pathForResource:@"SharePlanTag" ofType:@"plist"];
	RaPickerSource = [[NSArray alloc] initWithContentsOfFile:zPath];
	if (RaPickerSource==nil) {
		AzLOG(@"ERROR: SharePlanTag.plist not Open");
		exit(-1);
	}*/
}

- (void)viewDesign
{
	CGRect rect = self.view.bounds;
	//rect.origin.x = (rect.size.width - 320)/2;
	//rect.size.width = 320;
	rect.size.height = 216;  // iOS4.1から高さ可変になったようだが3.0互換のため規定値(216)にする
	Mpicker.frame = rect;
	
	if (appDelegate_.app_is_iPad || UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
	{	// タテ
		rect.origin.y += (Mpicker.frame.size.height + 20);
		rect.size.width = 250;
		rect.size.height = 40;
		rect.origin.x = (self.view.bounds.size.width - rect.size.width) / 2;
		MsegSort.frame = rect;
		
		rect.origin.y += 70;
		rect.size.width = 100;
		rect.size.height = 40;
		rect.origin.x = (self.view.bounds.size.width - rect.size.width) / 2;
		MbuSearch.frame = rect;
	}
	else {	// ヨコ
		rect.origin.y += (Mpicker.frame.size.height + 10);
		rect.size.width = 250;
		rect.size.height = 30;
		rect.origin.x = 50;
		MsegSort.frame = rect;
		
		rect.size.width = 100;
		rect.size.height = 30;
		rect.origin.x = self.view.bounds.size.width - rect.size.width - 50;
		MbuSearch.frame = rect;
	}
}	

// viewWillAppear はView表示直前に呼ばれる。よって、Viewの変化要素はここに記述する。　 　// viewDidAppear はView表示直後に呼ばれる
- (void)viewWillAppear:(BOOL)animated 
{
	[super viewWillAppear:animated];
	
	// 画面表示に関係する Option Setting を取得する
	//NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	[self viewDesign];
	//ここでキーを呼び出すと画面表示が無いまま待たされてしまうので、viewDidAppearでキー表示するように改良した。
}

// 画面表示された直後に呼び出される
- (void)viewDidAppear:(BOOL)animated 
{
	[super viewDidAppear:animated];
	
	//viewWillAppearでキーを表示すると画面表示が無いまま待たされてしまうので、viewDidAppearでキー表示するように改良した。
//	[MtfAmount becomeFirstResponder];  // キーボード表示
}

// 回転サポート
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{	
	if (appDelegate_.app_is_iPad) {
		return YES;	// FormSheet窓対応
	}
	else if (appDelegate_.app_opt_Autorotate==NO) {	// 回転禁止にしている場合
		return (interfaceOrientation == UIInterfaceOrientationPortrait); // 正面（ホームボタンが画面の下側にある状態）のみ許可
	}
    return YES;
}

// ユーザインタフェースの回転の最後の半分が始まる前にこの処理が呼ばれる　＜＜このタイミングで配置転換すると見栄え良い＞＞
- (void)willAnimateSecondHalfOfRotationFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation   duration:(NSTimeInterval)duration
{
	//[self viewDesign]; // これで回転しても編集が継続されるようになった。
}

- (void)unloadRelease	// dealloc, viewDidUnload から呼び出される
{
	NSLog(@"--- unloadRelease --- SpSearchVC");
	//[RaSegSortSource release],	
	RaSegSortSource = nil;
	//[RaPickerSource release],	
	//RaPickerSource = nil;
}

- (void)viewDidUnload 
{	// メモリ不足時、裏側にある場合に呼び出されるので、viewDidLoadで生成したObjを解放する。
	//NSLog(@"--- viewDidUnload ---"); 
	// メモリ不足時、裏側にある場合に呼び出される。addSubviewされたOBJは、self.viewと同時に解放される
	[self unloadRelease];
	[super viewDidUnload];
	// この後に loadView ⇒ viewDidLoad ⇒ viewWillAppear がコールされる
}

- (void)dealloc    // 生成とは逆順に解放するのが好ましい
{
	[self unloadRelease];
	//--------------------------------@property (retain)
	//[super dealloc];
}



#pragma mark - <UIPickerViewDelegate>
//-----------------------------------------------------------Picker
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	// [NSLocale preferredLanguages] デフォルト言語が先頭(:0)に配置されている。
	return [[NSLocale preferredLanguages] count] + 1;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
	switch (component) {
		case 0: 
			return 300;
			break;
	}
	return 0;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	if (row<=0) {
		return @"(* All Language)";
	}
	NSString *zLcd = [[NSLocale preferredLanguages] objectAtIndex:row - 1];
	NSString *zLang = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:zLcd];
#ifdef DEBUG
	return [NSString stringWithFormat:@"%@  (%@)", zLang, zLcd];
#else
	return zLang;
#endif
}

//- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component



@end
