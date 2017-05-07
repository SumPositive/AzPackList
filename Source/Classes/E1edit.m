//
//  E1edit.m
//  iPack
//
//  Created by 松山 和正 on 09/12/03.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
// InterfaceBuilderを使わずに作ったViewController

#import "Global.h"
#import "AppDelegate.h"
#import "Elements.h"
#import "E1viewController.h"
#import "E1edit.h"
//#import "E2viewController.h"
#import "GooDocsTVC.h"


@interface E1edit (PrivateMethods)
- (void)cancel:(id)sender;
- (void)save:(id)sender;
- (void)viewDesign;
- (void)tvNoteNarrow; // Noteフィールドをキーボードに隠れなくする
@end

@implementation E1edit   // ViewController
{
@private
	UITextField		*MtfName;  // self.viewがOwner
	UITextView		*MtvNote;  // self.viewがOwner
	AppDelegate		*appDelegate_;
}
@synthesize e1target = e1target_;
@synthesize addRow = addRow_;
//@synthesize delegate = delegate_;	<<<<<Notificationにしたため
@synthesize selfPopover = selfPopover_;


#pragma mark - iCloud
- (void)refreshAllViews:(NSNotification*)note 
{	// iCloud-CoreData に変更があれば呼び出される
	@synchronized(note)
	{
		[self viewWillAppear:YES];
	}
}


#pragma mark - View lifecycle

- (id)init 
{
	self = [super init];
	if (self) {
		// 初期化処理：インスタンス生成時に1回だけ通る
		appDelegate_ = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		appDelegate_.ppChanged = NO;
		if (appDelegate_.ppIsPad) {
			self.preferredContentSize = GD_POPOVER_SIZE_E1edit;
		}
		// 背景テクスチャ・タイルペイント
		self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Tx-Back"]];
	}
	return self;
}

// IBを使わずにviewオブジェクトをプログラム上でcreateするときに使う（viewDidLoadは、nibファイルでロードされたオブジェクトを初期化するために使う）
- (void)loadView
{	//【Tips】ここでaddSubviewするオブジェクトは全てautoreleaseにすること。メモリ不足時には自動的に解放後、改めてここを通るので、初回同様に生成するだけ。
	[super loadView];
	
	// その他、初期化
	self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
	
	// E1.name
	MtfName = [[UITextField alloc] init]; // 位置はviewDesignで決定

	if (appDelegate_.ppIsPad) {
		MtfName.font = [UIFont systemFontOfSize:20];
	} else {
		MtfName.font = [UIFont systemFontOfSize:16];
	}

	MtfName.textColor = [UIColor blackColor];
	MtfName.borderStyle = UITextBorderStyleRoundedRect;
	MtfName.placeholder = NSLocalizedString(@"(New Pack)",nil);  //(@"Plan name", @"AzPack名称");
	MtfName.keyboardType = UIKeyboardTypeDefault;
	MtfName.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter; // 縦中央
	MtfName.delegate = self;
	[self.view addSubview:MtfName]; //[MtfName release]; // self.viewがOwnerになる
	
	// E1.note
	MtvNote = [[UITextView alloc] init];

	if (appDelegate_.ppIsPad) {
		MtvNote.font = [UIFont systemFontOfSize:20];
	} else {
		MtvNote.font = [UIFont systemFontOfSize:14];
	}

	MtvNote.textColor = [UIColor brownColor];
	MtvNote.keyboardType = UIKeyboardTypeDefault;
	MtvNote.delegate = self;
	[self.view addSubview:MtvNote]; //[MtvNote release]; // self.viewがOwnerになる
	
	// CANCELボタンを左側に追加する  Navi標準の戻るボタンでは cancel:処理ができないため
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
											  initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
											  target:self action:@selector(cancel:)];
	// SAVEボタンを右側に追加する
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
											   initWithBarButtonSystemItem:UIBarButtonSystemItemSave
											   target:self action:@selector(save:)];
	self.navigationItem.rightBarButtonItem.enabled = NO; // 変更なし [Save]無効
}

- (void)viewDidLoad 
{
	[super viewDidLoad];

	// listen to our app delegates notification that we might want to refresh our detail view
    [[NSNotificationCenter defaultCenter] addObserver:self			// viewDidUnload:にて removeObserver:必須
											 selector:@selector(refreshAllViews:) 
												 name:NFM_REFRESH_ALL_VIEWS
											   object:nil];  //=nil: 全てのオブジェクトからの通知を受ける
}

- (void)viewDidUnload 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated 
{
	[super viewWillAppear:animated];
	
	[self viewDesign];
	
	if ([[e1target_ valueForKey:@"name"] isEqualToString:NSLocalizedString(@"New Pack",nil)]) {
		MtfName.text = @"";
	} else {
		MtfName.text = [e1target_ valueForKey:@"name"];
	}

	MtvNote.text = [e1target_ valueForKey:@"note"];
	
}

// 画面表示された直後に呼び出される
- (void)viewDidAppear:(BOOL)animated 
{
	[super viewDidAppear:animated];
	//viewWillAppearでキーを表示すると画面表示が無いまま待たされてしまうので、viewDidAppearでキー表示するように改良した。
	if ([MtfName.text length]<=0) {			// ブランクならば、
		[MtfName becomeFirstResponder];  // キーボード表示
	}
}

// ビューが非表示にされる前や解放される前ににこの処理が呼ばれる
- (void)viewWillDisappear:(BOOL)animated 
{
	[super viewWillDisappear:animated];
	// 戻る前にキーボードを消さないと、次に最初から現れた状態になり、表示されるまでが遅くなってしまう。
	// キーボードを消すために全てのコントロールへresignFirstResponderを送る ＜表示中にしか効かない＞
	[MtfName resignFirstResponder];
	[MtvNote resignFirstResponder];
}

// 回転サポート
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{	
	if (appDelegate_.ppIsPad) {
		return YES;	// FormSheet窓対応
	}
	else if (appDelegate_.ppOptAutorotate==NO) {	// 回転禁止にしている場合
		return (interfaceOrientation == UIInterfaceOrientationPortrait); // 正面（ホームボタンが画面の下側にある状態）のみ許可
	}
    return YES;
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
	if (appDelegate_.ppIsPad) {
		CGRect rect;
		rect.origin.x = 10;
		rect.origin.y = 5;
		rect.size.width = self.view.frame.size.width - rect.origin.x * 2;
		rect.size.height = 40;
		MtfName.frame = rect;
		
		rect.origin.x = 15;
		rect.origin.y = 48;
		rect.size.width = self.view.frame.size.width - rect.origin.x * 2;
		rect.size.height = self.view.frame.size.height - rect.origin.y - 10;
		MtvNote.frame = rect;
	} else {
		float fKeyHeight;
		float fHeightOfsset;
		if (self.interfaceOrientation == UIInterfaceOrientationPortrait 
			OR self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
			fKeyHeight = GD_KeyboardHeightPortrait;	 // タテ
			fHeightOfsset = 15; // タテ： MtfNameの高さを少しでも高くして操作しやすくする
		} else {
			fKeyHeight = GD_KeyboardHeightLandscape; // ヨコ
			fHeightOfsset = 0; // ヨコ： MtvNoteの高さをできるだけ確保しなければ入力しにくくなる
		}
		
		CGRect rect;
		rect.origin.x = 10;
		rect.origin.y = 64 + 5;
		rect.size.width = self.view.frame.size.width - rect.origin.x * 2;
		rect.size.height = 25 + fHeightOfsset;
		MtfName.frame = rect;
		
		rect.origin.x = 15;
		rect.origin.y = 64 + 33 + fHeightOfsset;
		rect.size.width = self.view.frame.size.width - rect.origin.x * 2;
		rect.size.height = self.view.frame.size.height - rect.origin.y - 5 - fKeyHeight;
		MtvNote.frame = rect;
	}
}

- (void)dealloc 
{
	//[selfPopover_ release], 
	selfPopover_ = nil;
	// @property (retain)
	//[e1target_ release];
    //[super dealloc];
}


#pragma mark - <UITextFieldDelegate>
// <UITextFieldDelegate> テキストが変更される「直前」に呼び出される。これにより入力文字数制限を行っている。
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range 
												replacementString:(NSString *)string 
{
	// senderは、MtfName だけ
    NSMutableString *text = [textField.text mutableCopy];
    [text replaceCharactersInRange:range withString:string];
	// 置き換えた後の長さをチェックする
	if ([text length] <= AzMAX_NAME_LENGTH) {
		appDelegate_.ppChanged = YES; // 変更あり
		self.navigationItem.rightBarButtonItem.enabled = YES; // 変更あり [Save]有効
		return YES;
	} else {
		return NO;
	}
}

// UITextView テキストが変更される「直前」に呼び出される。これにより入力文字数制限を行っている。
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range 
											replacementText:(NSString *)zReplace
{
	// senderは、MtvNote だけ
    NSMutableString *zText = [textView.text mutableCopy];
    [zText replaceCharactersInRange:range withString:zReplace];
	// 置き換えた後の長さをチェックする
	if ([zText length] <= AzMAX_NOTE_LENGTH) {
		appDelegate_.ppChanged = YES; // 変更あり
		self.navigationItem.rightBarButtonItem.enabled = YES; // 変更あり [Save]有効
		return YES;
	} else {
		return NO;
	}
}


#pragma mark - Action

- (void)cancel:(id)sender
{
	if (appDelegate_.ppIsPad) {
		//Cancelでも「新しい・・」を削除しない。Rootに戻ったときに配下クリーン処理している。
		//[(PadNaviCon*)self.navigationController dismissPopoverCancel];  // PadNaviCon拡張メソッド
		if (selfPopover_) {
			[selfPopover_ dismissPopoverAnimated:YES];
		}
	} else {
		/*	Cancelでも「新しい・・」を削除しない。Rootに戻ったときに配下クリーン処理している。
		 if (e1target_ && 0 <= addRow_) 
		 {	// SAVEしたときには、e1target_=nil にしているので通らない。
		 // 新オブジェクトのキャンセルなので、呼び出し元で挿入したオブジェクトを削除する
		 NSManagedObjectContext *ct = e1target_.managedObjectContext;
		 [ct deleteObject:e1target_];
		 e1target_ = nil;
		 NSError *err = nil;
		 if (![ct save:&err]) {
		 NSLog(@"Unresolved error %@, %@", err, [err userInfo]);
		 abort();
		 }
		 }*/
		[self.navigationController popViewControllerAnimated:YES];	// < 前のViewへ戻る
	}
}

- (void)save:(id)sender 
{
	// 編集フィールドの値を editObj にセットする
	[e1target_ setValue:MtfName.text forKey:@"name"];
	[e1target_ setValue:MtvNote.text forKey:@"note"];

	if (0 <= addRow_) {
		// 新規のとき、末尾になるように行番号を付与する
		[e1target_ setValue:[NSNumber numberWithInteger:addRow_] forKey:@"row"];
	}
	
	NSManagedObjectContext *ct = e1target_.managedObjectContext;
	NSError *err = nil;
	if (![ct save:&err]) {
		NSLog(@"Unresolved error %@, %@", err, [err userInfo]);
		//abort();
	}
	
	if (appDelegate_.ppIsPad) {
		if (selfPopover_) {
			/*if ([delegate_ respondsToSelector:@selector(refreshE1view)]) {	// メソッドの存在を確認する
				[delegate_ refreshE1view];// 親の再描画を呼び出す
			}*/
			// 再表示 通知発信
			[[NSNotificationCenter defaultCenter] postNotificationName:NFM_REFRESH_ALL_VIEWS
																object:self  userInfo:nil];
			[selfPopover_ dismissPopoverAnimated:YES];
		}
	} else {
		[self.navigationController popViewControllerAnimated:YES];	// < 前のViewへ戻る
	}
}

@end
