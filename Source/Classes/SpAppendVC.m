//
//  SpAppendVC.m
//
//  Created by 松山 和正 on 10/01/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Global.h"
#import "AppDelegate.h"
#import "Elements.h"
#import "FileCsv.h"
#import "SpPOST.h"
#import "SpAppendVC.h"

#define ALERT_TAG_PREVIEW	901
#define ALERT_TAG_PUBLISH	910


@interface SpAppendVC (PrivateMethods)
- (void)viewDesign;
- (void)vBarDone:(id)sender;
- (void)vBuPublish:(id)sender;
- (NSString *)vSharePlanAppend:(NSMutableArray *)maTags;
@end

@implementation SpAppendVC
@synthesize Re1selected;
@synthesize selfPopover;


- (void)unloadRelease	// dealloc, viewDidUnload から呼び出される
{
	NSLog(@"--- unloadRelease --- SpAppendVC");
	
	[RurlConnection cancel]; // 停止させてから解放する
	//[RurlConnection release],	
	RurlConnection = nil;
	
	//[RdaResponse release],			
	RdaResponse = nil;
	//[RbarButtonItemDone release],	
	RbarButtonItemDone = nil;
	//[RaPickerSource release],		
	RaPickerSource = nil;
}

- (void)dealloc    // 生成とは逆順に解放するのが好ましい
{
	[self unloadRelease];
	//[selfPopover release],
	selfPopover = nil;
	//--------------------------------@property (retain)
	[Re1selected.managedObjectContext rollback]; //一時的に修正された可能性がある.name .note を取り消すため
	//[Re1selected release];
	//[super dealloc];
}

- (void)viewDidUnload 
{	// メモリ不足時、裏側にある場合に呼び出されるので、viewDidLoadで生成したObjを解放する。
	//NSLog(@"--- viewDidUnload ---"); 
	// メモリ不足時、裏側にある場合に呼び出される。addSubviewされたOBJは、self.viewと同時に解放される
	[self unloadRelease];
	[super viewDidUnload];
	// この後に loadView ⇒ viewDidLoad ⇒ viewWillAppear がコールされる
}


// IBを使わずにviewオブジェクトをプログラム上でcreateするときに使う（viewDidLoadは、nibファイルでロードされたオブジェクトを初期化するために使う）
- (void)loadView
{
    [super loadView];

	appDelegate_ = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	if (appDelegate_.app_is_iPad) {
		self.contentSizeForViewInPopover = GD_POPOVER_SIZE;
	}

	Mpicker = nil;		// ここで生成
	
	self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
	
	// とりあえず生成、位置はviewDesignにて決定
	//------------------------------------------------------
	Mpicker = [[UIPickerView alloc] init];
	Mpicker.delegate = self;
	Mpicker.dataSource = self;
	Mpicker.showsSelectionIndicator = YES;
	[self.view addSubview:Mpicker]; //[Mpicker release];
	//------------------------------------------------------
	MtfName = [[UITextField alloc] init];
	MtfName.delegate = self;
	MtfName.tag = 40;  //delegate:shouldChangeCharactersInRangeにて最大文字数に使用
	MtfName.font = [UIFont systemFontOfSize:16];
	MtfName.borderStyle = UITextBorderStyleRoundedRect;
	MtfName.placeholder = NSLocalizedString(@"Plan name",nil);
	MtfName.keyboardType = UIKeyboardTypeDefault;
	[self.view addSubview:MtfName]; //[MtfName release];
	//------------------------------------------------------
	MtvNote = [[UITextView alloc] init];
	MtvNote.delegate = self;
	MtvNote.tag = 200;  //delegate:shouldChangeTextInRangeにて最大文字数に使用
	MtvNote.font = [UIFont systemFontOfSize:14];
	MtvNote.keyboardType = UIKeyboardTypeDefault;
	//mTvNote.returnKeyType = UIReturnKeyDone;
	[self.view addSubview:MtvNote]; //[MtvNote release];
	//------------------------------------------------------
	MtfNickname = [[UITextField alloc] init];
	MtfNickname.delegate = self;
	MtfNickname.tag = 20;  //delegate:shouldChangeCharactersInRangeにて最大文字数に使用
	MtfNickname.font = [UIFont systemFontOfSize:14];
	MtfNickname.borderStyle = UITextBorderStyleRoundedRect;
	MtfNickname.placeholder = NSLocalizedString(@"Nickname",nil);
	MtfNickname.text = [[NSUserDefaults standardUserDefaults] valueForKey:GD_DefNickname];
	MtfNickname.keyboardType = UIKeyboardTypeDefault;
	[self.view addSubview:MtfNickname]; //[MtfNickname release];
	//------------------------------------------------------
	MlbNickname = [[UILabel alloc] init];
	MlbNickname.font = [UIFont systemFontOfSize:12];
	MlbNickname.text = NSLocalizedString(@"Nickname info",nil);
	MlbNickname.backgroundColor = [UIColor clearColor];
	[self.view addSubview:MlbNickname]; //[MlbNickname release];
	//------------------------------------------------------
	MbuUpload = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	MbuUpload.titleLabel.font = [UIFont boldSystemFontOfSize:20];
	[MbuUpload setTitle:NSLocalizedString(@"Publish",nil) forState:UIControlStateNormal];
	[MbuUpload addTarget:self action:@selector(vBuPublish:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:MbuUpload]; //[mBuUpload release];
	//------------------------------------------------------
	// SharePlanTag.plist からタグリストを読み込む
	NSString *zPath = [[NSBundle mainBundle] pathForResource:@"SharePlanTag" ofType:@"plist"];
	RaPickerSource = [[NSArray alloc] initWithContentsOfFile:zPath];
	if (RaPickerSource==nil) {
		AzLOG(@"ERROR: SharePlanTag.plist not Open");
		//exit(-1);
	}
	
	if (RbarButtonItemDone == nil) {
		RbarButtonItemDone = [[UIBarButtonItem alloc] initWithTitle:@"Done"
															  style:UIBarButtonItemStyleDone
															 target:self
															 action:@selector(vBarDone:)];
	}
}

- (void)textFieldDidBeginEditing:(UITextField *)sender
{
	self.navigationItem.rightBarButtonItem = RbarButtonItemDone;

	if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) { //タテ
		CGRect rc = MtvNote.frame;
		rc.size.height = 60;
		MtvNote.frame = rc;
		//
		MtfNickname.hidden = NO;
		MlbNickname.hidden = NO;
	}
}

// UITextField テキストが変更される「直前」に呼び出される。これにより入力文字数制限を行っている。
- (BOOL)textField:(UITextField *)sender shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSMutableString *zText = [sender.text mutableCopy];
    [zText replaceCharactersInRange:range withString:string];
	// 置き換えた後の長さをチェックする
	return ([zText length] <= sender.tag);  //UITextField.tagに最大文字数セット済み
}

- (void)textViewDidBeginEditing:(UITextView *)sender
{
	self.navigationItem.rightBarButtonItem = RbarButtonItemDone;
	
	if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) { //タテ
		CGRect rc = MtvNote.frame;
		rc.size.height = 160;
		MtvNote.frame = rc;
		// 重なるため一時非表示にする
		MtfNickname.hidden = YES;
		MlbNickname.hidden = YES;
	}
}

// UITextView テキストが変更される「直前」に呼び出される。これにより入力文字数制限を行っている。
- (BOOL)textView:(UITextView *)sender shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)string
{
    NSMutableString *zText = [sender.text mutableCopy];
    [zText replaceCharactersInRange:range withString:string];
	// 置き換えた後の長さをチェックする
	return ([zText length] <= sender.tag);  //UITextView.tagに最大文字数セット済み
}


- (void)vBarDone:(id)sender
{
	[MtfName resignFirstResponder]; //キーボードを隠す
	[MtvNote resignFirstResponder]; //キーボードを隠す
	[MtfNickname resignFirstResponder]; //キーボードを隠す
	self.navigationItem.rightBarButtonItem = nil; // Hide
	
	if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) { //タテ
		CGRect rc = MtvNote.frame;
		rc.size.height = 60;
		MtvNote.frame = rc;
		//
		MtfNickname.hidden = NO;
		MlbNickname.hidden = NO;
	}
}


// viewWillAppear はView表示直前に呼ばれる。よって、Viewの変化要素はここに記述する。　 　// viewDidAppear はView表示直後に呼ばれる
- (void)viewWillAppear:(BOOL)animated 
{
	[super viewWillAppear:animated];
	
	// 画面表示に関係する Option Setting を取得する
	//NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	self.title = NSLocalizedString(@"SharePlan Append",nil);

	MtfName.text = Re1selected.name;
	MtvNote.text = Re1selected.note;
	
	[self viewDesign];
	//ここでキーを呼び出すと画面表示が無いまま待たされてしまうので、viewDidAppearでキー表示するように改良した。
}

// 画面表示された直後に呼び出される
- (void)viewDidAppear:(BOOL)animated 
{
	[super viewDidAppear:animated];
	
	if (appDelegate_.app_opt_Ad) {
		// 各viewDidAppear:にて「許可/禁止」を設定する
		[appDelegate_ AdRefresh:NO];	//広告禁止
	}

	//viewWillAppearでキーを表示すると画面表示が無いまま待たされてしまうので、viewDidAppearでキー表示するように改良した。
//	[MtfAmount becomeFirstResponder];  // キーボード表示
}

// 回転サポート
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if (appDelegate_.app_is_iPad) {
		return NO;	//[MENU]Popover内のとき回転禁止にするため
	} else {
		// 回転禁止でも万一ヨコからはじまった場合、タテにはなるようにしてある。
		AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		return app.app_opt_Autorotate OR (interfaceOrientation == UIInterfaceOrientationPortrait);
	}
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
	CGRect rect = self.view.bounds;

/*	//Picker: iOS4.1から高さ可変になったようだが3.0互換のため規定値(216)にする
	rect.origin.y = rect.size.height - 216;  
	rect.size.height = 216;
	mPicker.frame = rect;*/
	
	if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
	{	// タテ
		rect.origin.y = 5;		rect.size.height = 25;
		rect.origin.x = 10;		rect.size.width -= 20;
		MtfName.frame = rect;

		rect.origin.y = 35;		rect.size.height = 70;
		MtvNote.frame = rect;
		
		rect.origin.y = 110;	rect.size.height = 25;
		MtfNickname.frame = rect;

		rect.origin.y = 137;	rect.size.height = 18;
		MlbNickname.frame = rect;
		MlbNickname.textAlignment = UITextAlignmentCenter;
		MlbNickname.numberOfLines = 1;
		
		rect.origin.y = 160;	rect.size.height = 216;
		rect.origin.x = 0;		rect.size.width = self.view.bounds.size.width;
		Mpicker.frame = rect;

		rect.origin.y = 380;	rect.size.height = 32;
		rect.size.width = 150;
		rect.origin.x = (self.view.bounds.size.width - rect.size.width) / 2;
		MbuUpload.frame = rect;
	}
	else {	// ヨコ
		rect.origin.y = 3;		rect.size.height = 25;
		rect.origin.x = 10;		rect.size.width -= 20;
		MtfName.frame = rect;
		
		rect.origin.y = 30;		rect.size.height = 50;
		MtvNote.frame = rect;
		
		rect.origin.y = self.view.bounds.size.height - 216;	rect.size.height = 216;
		rect.origin.x = 0;		rect.size.width = 320;
		Mpicker.frame = rect;

		rect.origin.y += 30;	rect.size.height = 22;
		rect.origin.x = 330;	rect.size.width = self.view.bounds.size.width - rect.origin.x - 10;
		MtfNickname.frame = rect;
		
		rect.origin.y += 25;	rect.size.height = 28;
		MlbNickname.frame = rect;
		MlbNickname.textAlignment = UITextAlignmentCenter;
		MlbNickname.numberOfLines = 2;
		
		rect.origin.y = self.view.bounds.size.height - 40;	rect.size.height = 32;
		rect.origin.x = self.view.bounds.size.width - 130;	rect.size.width = 100;
		MbuUpload.frame = rect;
	}
}	


//-----------------------------------------------------------Picker
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return [RaPickerSource count];
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	return [[RaPickerSource objectAtIndex:component] count];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
	switch (component) {
		case 0: return 140;
			break;
		case 1: return 80;
			break;
		case 2: return 80;
			break;
	}
	return 0;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	return [[RaPickerSource objectAtIndex:component] objectAtIndex:row];
}

//- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component



- (void)vBuPublish:(id)sender
{
	// Name
	if ([MtfName.text length] < 3) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Publish Name Title",nil)
														message:NSLocalizedString(@"Publish Name Msg",nil)
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
		//[alert release];
		[MtfName becomeFirstResponder];
		return;
	}
	Re1selected.name = MtfName.text; //保存しない！Publish時のみ有効とする（deallocにてrollbackしている）
	
	// Note
	if ([MtvNote.text length] < 10) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Publish Note Title",nil)
														message:NSLocalizedString(@"Publish Note Msg",nil)
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
		//[alert release];
		[MtvNote becomeFirstResponder];
		return;
	}
	Re1selected.note = MtvNote.text; //保存しない！Publish時のみ有効とする（deallocにてrollbackしている）

	// Nickname
	if ([MtfNickname.text length] < 2) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Publish Nickname Title",nil)
														message:NSLocalizedString(@"Publish Nickname Msg",nil)
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
		//[alert release];
		[MtfNickname becomeFirstResponder];
		return;
	}
	NSUserDefaults *uds = [NSUserDefaults standardUserDefaults];
	[uds setObject:MtfNickname.text forKey:GD_DefNickname];
	[uds synchronize]; // plistへ書き出す
			
	// Tag
	for (int comp=0; comp<3; comp++) {
		NSInteger iRow = [Mpicker selectedRowInComponent:comp];
		if (iRow <= 0) {
			// 未定タグが1つでもあれば中断
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Publish Tag Title",nil)
															message:NSLocalizedString(@"Publish Tag Msg",nil)
														   delegate:nil
												  cancelButtonTitle:@"OK"
												  otherButtonTitles:nil];
			[alert show];
			//[alert release];
			return;
		}
	}
	
	// 最終確認アラート
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Publish Exec Title",nil)
													message:NSLocalizedString(@"Publish Exec Msg",nil)
												   delegate:self
										  cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
										  otherButtonTitles:NSLocalizedString(@"Agree",nil), nil];
	alert.tag = ALERT_TAG_PUBLISH;
	[alert show];
	//[alert release];
}

- (NSString *)vSharePlanAppend:(NSMutableArray *)maTags
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES; // NetworkアクセスサインON

	//NSString *postCmd = @"func=Append";
	NSString *postCmd = [NSString stringWithString:@"func=Append"];
	
	// Nickname
	postCmd = [postCmd stringByAppendingString:@"&userName="];
	postCmd = [postCmd stringByAppendingString:[[NSUserDefaults standardUserDefaults] valueForKey:GD_DefNickname]];
	
	// userPass
	postCmd = postCmdAddUserPass( postCmd );
	
	// language
	postCmd = postCmdAddLanguage( postCmd );
	
	// planCsv
	NSMutableString *zCsv = [NSMutableString new]; //こちら側でメモリ管理する
	NSString *zCsvErr = [FileCsv zSave:Re1selected toMutableString:zCsv]; // E1 ⇒ CSV string
	if (zCsvErr) {
		//[zCsv release];
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO; // NetworkアクセスサインOFF
		return zCsvErr; // pool変数
	}
	postCmd = [postCmd stringByAppendingString:@"&planCsv="];
	postCmd = [postCmd stringByAppendingString:zCsv];
	//[zCsv release];
	
	// tag
	for (NSString *zz in maTags) {
		postCmd = [postCmd stringByAppendingFormat:@"&tag=%@", zz];
	}
	
	if (RurlConnection) {
		[RurlConnection cancel]; // 停止させてから解放する
		//[RurlConnection release];
		RurlConnection = nil;
	}
	// 非同期通信
	RurlConnection = [[NSURLConnection alloc] initWithRequest:requestSpPOST(postCmd)
													 delegate:self];
	MiConnectTag = 2; // Append
	return nil; //OK
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{	// データ受信時
	if (RdaResponse==nil) {
		RdaResponse = [NSMutableData new];
	}
	[RdaResponse appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{	// 通信終了時
	if (RdaResponse) {
		switch (MiConnectTag) {
			case 2: { // Append
				NSString *str = [[NSString alloc] initWithData:RdaResponse encoding:NSUTF8StringEncoding];
				AzLOG(@"str: %@", str);
				NSRange rg = [str rangeOfString:@"Append:OK"];
				if (rg.length <= 0) {
					alertMsgBox( NSLocalizedString(@"Append Err",nil), 
								str,
								NSLocalizedString(@"Roger",nil) );
				}
				//[str release];
			}	break;
			default:
				break;
		}
	}
	MiConnectTag = 0; // 通信してません
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO; // NetworkアクセスサインOFF
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{	// 通信中断時
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO; // NetworkアクセスサインOFF
	MiConnectTag = 0; // 通信してません

	NSString *error_str = [error localizedDescription];
	if (0<[error_str length]) {
		alertMsgBox( NSLocalizedString(@"Connection Error",nil), 
					error_str,
					NSLocalizedString(@"Roger",nil) );
	}
	//[RdaResponse release], 
	RdaResponse = nil;
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (alertView.tag) {
		case ALERT_TAG_PREVIEW:	// 前画面に戻す
			if (appDelegate_.app_is_iPad) {
				if (selfPopover) {
					[selfPopover dismissPopoverAnimated:YES];
				}
			} else {
				[self.navigationController popViewControllerAnimated:YES];	// 前のViewへ戻る
			}
			break;
		
		case ALERT_TAG_PUBLISH: 
			if (buttonIndex==1) {
				// Tag
				NSMutableArray *ma = [NSMutableArray new];
				for (int comp=0; comp<3; comp++) {
					NSInteger iRow = [Mpicker selectedRowInComponent:comp];
					if (0 < iRow) {
						[ma addObject:[[RaPickerSource objectAtIndex:comp] objectAtIndex:iRow]];
					}
				}
				// Append - Upload - Publish
				@autoreleasepool {
					NSString *err = [self vSharePlanAppend:ma];
					if (err) {
						UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Append Err",nil)
																		message:err
																	   delegate:self 
															  cancelButtonTitle:NSLocalizedString(@"Roger",nil)
															  otherButtonTitles:nil];
						alert.tag = ALERT_TAG_PREVIEW; // 前のViewへ戻る
						[alert show];
						//[alert release];
					} else {
						UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Append OK",nil)
																		message:NSLocalizedString(@"Append OK Msg",nil)
																	   delegate:self 
															  cancelButtonTitle:@"OK"
															  otherButtonTitles:nil];
						alert.tag = ALERT_TAG_PREVIEW; // 前のViewへ戻る
						[alert show];
						//[alert release];
					}
				}
				//[ma release];
			}
			break;
	}
}

@end
