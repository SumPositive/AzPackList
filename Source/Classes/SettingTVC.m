//
//  SettingTVC.m
//  AzPacking
//
//  Created by 松山 和正 on 10/01/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SFHFKeychainUtils.h"
#import "Global.h"
#import "AppDelegate.h"
#import "SettingTVC.h"
//#import "GoogleService.h"

#define TAG_OptShouldAutorotate				998  // UD_OptShouldAutorotate
#define TAG_OptStartupRestoreLevel			997
#define TAG_OptCheckingAtEditMode			996
#define TAG_OptTotlWeightRound				995
#define TAG_OptShowTotalWeight				994
#define TAG_OptShowTotalWeightReq			993
#define TAG_OptSearchItemsNote				992
#define TAG_OptAdvertising							991



@interface SettingTVC (PrivateMethods)
- (void)switchAction:(UISwitch *)sender;
@end

@implementation SettingTVC
{
@private
	AppDelegate		*mAppDelegate;
	UITextField			*mTfGoogleID;
	UITextField			*mTfGooglePW;

	UITextField			*mTfPass1;
	UITextField			*mTfPass2;
}


/***随時同期はしない。閉じてから同期で十分
#pragma mark - iCloud
- (void)kvsValueChange:(NSNotification*)note 
{	// iCloud-KVS に変更があれば呼び出される
	@synchronized(note)
	{
		[self viewWillAppear:YES];
	}
}*/

#pragma mark - View lifecycle

// UITableViewインスタンス生成時のイニシャライザ　viewDidLoadより先に1度だけ通る
- (id)initWithStyle:(UITableViewStyle)style 
{
	if ((self = [super initWithStyle:UITableViewStyleGrouped])) {  // セクションありテーブル

		mAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	/*	if (mAppDelegate.app_is_iPad) {
			self.contentSizeForViewInPopover = CGSizeMake(480, 580);
			self.navigationItem.hidesBackButton = YES;
		}*/
	}
	return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.title = NSLocalizedString(@"menu Setting", nil);

	if (mAppDelegate.ppIsPad) {
		// CANCELボタンを左側に追加する  Navi標準の戻るボタンでは cancel:処理ができないため
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
												 initWithTitle:NSLocalizedString(@"Back", nil)
												 style:UIBarButtonItemStyleBordered
												 target:self action:@selector(actionBack:)];
	}
}

- (void)actionBack:(id)sender
{
	//[self dismissModalViewControllerAnimated:YES];
	[self dismissViewControllerAnimated:YES completion:nil];
}

// 他のViewやキーボードが隠れて、現れる都度、呼び出される
- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
	
	// 画面表示に関係する Option Setting を取得する
	//NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	//self.title = NSLocalizedString(@"menu Setting", nil);
	
	[[NSUbiquitousKeyValueStore defaultStore] synchronize]; // 最新取得
	// テーブルビューを更新します。
    [self.tableView reloadData];	// これにより修正結果が表示される
}


// ビューが最後まで描画された後やアニメーションが終了した後にこの処理が呼ばれる
- (void)viewDidAppear:(BOOL)animated 
{
    [super viewDidAppear:animated];
	GA_TRACK_METHOD
	//[self.tableView flashScrollIndicators]; // Apple基準：スクロールバーを点滅させる

//	// 広告表示に変化があれば、広告スペースを調整するための処理
//	BOOL bAd = [[NSUbiquitousKeyValueStore defaultStore] boolForKey:KV_OptAdvertising];
//	if (mAppDelegate.ppOptShowAd != bAd) {
//		mAppDelegate.ppOptShowAd = bAd;
//		// viewWillDisappear:にて再描画する
//	}
}


// 回転サポート
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{	
	if (mAppDelegate.ppIsPad) {
		return YES;	// FormSheet窓対応
	}
	else if (mAppDelegate.ppOptAutorotate==NO) {	// 回転禁止にしている場合
		return (interfaceOrientation == UIInterfaceOrientationPortrait); // 正面（ホームボタンが画面の下側にある状態）のみ許可
	}
    return YES;
}

// ユーザインタフェースの回転の最後の半分が始まる前にこの処理が呼ばれる　＜＜このタイミングで配置転換すると見栄え良い＞＞
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation 
										 duration:(NSTimeInterval)duration
{
	[self.tableView reloadData];
}

// ユーザインタフェースが回転した後この処理が呼ばれる。
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation // 直前の向き
{	// self.view.frame は、回転後の状態
//	[self.tableView reloadData];
}

 - (void)viewWillDisappear:(BOOL)animated 
{
	[super viewWillDisappear:animated];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[[NSUbiquitousKeyValueStore defaultStore] synchronize];

	if (mAppDelegate.ppIsPad) {
//		[mAppDelegate AdRefresh:mAppDelegate.ppOptShowAd];
		// 再描画　　重量表示やAdスペースを変化させるため
		[[NSNotificationCenter defaultCenter] postNotificationName:NFM_REFRESH_ALL_VIEWS 
															object:self userInfo:nil];
	} //iPhoneは、E1viewController:viewWillAppear:を通ってAd再開される
}

/*
 - (void)viewDidDisappear:(BOOL)animated {
 [super viewDidDisappear:animated];
 }
 */

/***随時同期はしない。閉じてから同期で十分
- (void)viewDidUnload 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[super viewDidUnload];
}*/
/*
- (void)dealloc    // 生成とは逆順に解放するのが好ましい
{
	//[super dealloc];
}*/



#pragma mark - Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	switch (section) {
		case 0: // 
			if (mAppDelegate.ppIsPad) {
				return 8;	// (0)回転は不要
			} else {
				return 9;
			}
			break;
	}
    return 0;
}

// セルの高さを指示する
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	int iRaw = indexPath.row;
	if (mAppDelegate.ppIsPad) iRaw++;
	switch (iRaw) {
		case 6: // Google+
		case 8: // Crypt
			return 75;
	}
	return 60; // デフォルト：44ピクセル
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    NSString *zCellIndex = [NSString stringWithFormat:@"Setting%d:%d", (int)indexPath.section, (int)indexPath.row];
	UITableViewCell *cell = nil;
	
	if (indexPath.section != 0) return nil;  // section=0 のみ

	cell = [tableView dequeueReusableCellWithIdentifier:zCellIndex];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
									   reuseIdentifier:zCellIndex];
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.showsReorderControl = NO; // Move禁止
		
		cell.textLabel.font = [UIFont systemFontOfSize:20];
		cell.textLabel.textColor = [UIColor blackColor];
		
		cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
		cell.detailTextLabel.textColor = [UIColor grayColor];

		cell.selectionStyle = UITableViewCellSelectionStyleNone; // 選択時ハイライトなし
	}
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSUbiquitousKeyValueStore *kvs = [NSUbiquitousKeyValueStore defaultStore];
	
	float fX;
	int  iCase;
	if (mAppDelegate.ppIsPad) {
		fX = self.tableView.frame.size.width - 60 - 120;
		 iCase = indexPath.row + 1;
	} else {
		//fX = cell.frame.size.width - 120;
		fX = self.tableView.frame.size.width - 120;
		 iCase = indexPath.row;
	}

	switch (iCase) {
		case 0:
		{ // UD_OptShouldAutorotate
			UISwitch *sw = (UISwitch*)[cell.contentView viewWithTag:TAG_OptShouldAutorotate];
			if (sw==nil) {
				// add UISwitch
				sw = [[UISwitch alloc] init];
				BOOL bOpt = [userDefaults boolForKey:UD_OptShouldAutorotate];
				[sw setOn:bOpt animated:NO]; // 初期値セット
				[sw addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
				sw.tag = TAG_OptShouldAutorotate;
				sw.backgroundColor = [UIColor clearColor]; //背景透明
				[cell.contentView  addSubview:sw]; //[sw release];
				cell.textLabel.text = NSLocalizedString(@"Autorotate",nil);
				cell.detailTextLabel.text = NSLocalizedString(@"Autorotate comment",nil);
			}
			sw.frame = CGRectMake(fX, 5, 120, 25); // 回転対応
		}	break;
		
		case 1:
		{ // KV_OptShowTotalWeight
			UISwitch *sw = (UISwitch*)[cell.contentView viewWithTag:TAG_OptShowTotalWeight];
			if (sw==nil) {
				// add UISwitch
				sw = [[UISwitch alloc] init];
				[sw addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
				sw.tag = TAG_OptShowTotalWeight;
				sw.backgroundColor = [UIColor clearColor]; //背景透明
				[cell.contentView  addSubview:sw]; //[sw release];
				cell.textLabel.text = NSLocalizedString(@"Stock weight",nil);
				cell.detailTextLabel.text = NSLocalizedString(@"Stock weight comment",nil);
			}
			sw.frame = CGRectMake(fX, 5, 120, 25); // 回転対応
			[sw setOn:[kvs boolForKey:KV_OptShowTotalWeight] animated:YES];
		}	break;
		
		case 2:
		{ // KV_OptShowTotalWeightReq
			UISwitch *sw = (UISwitch*)[cell.contentView viewWithTag:TAG_OptShowTotalWeightReq];
			if (sw==nil) {
				// add UISwitch
				sw = [[UISwitch alloc] init];
				[sw addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
				sw.tag = TAG_OptShowTotalWeightReq;
				sw.backgroundColor = [UIColor clearColor]; //背景透明
				[cell.contentView  addSubview:sw];// [sw release];
				cell.textLabel.text = NSLocalizedString(@"Need weight",nil);
				cell.detailTextLabel.text = NSLocalizedString(@"Need weight comment",nil);
			}
			sw.frame = CGRectMake(fX, 5, 120, 25); // 回転対応
			[sw setOn:[kvs boolForKey:KV_OptShowTotalWeightReq] animated:YES];
		}	break;
		
		case 3:
		{ // KV_OptWeightRound
			UISwitch *sw = (UISwitch*)[cell.contentView viewWithTag:TAG_OptTotlWeightRound];
			if (sw==nil) {
				// add UISwitch
				sw = [[UISwitch alloc] init];
				[sw addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
				sw.tag = TAG_OptTotlWeightRound;
				sw.backgroundColor = [UIColor clearColor]; //背景透明
				[cell.contentView  addSubview:sw]; //[sw release];
				cell.textLabel.text = NSLocalizedString(@"Round off Weight",nil);
				cell.detailTextLabel.text = NSLocalizedString(@"Round off Weight comment",nil);
			}
			sw.frame = CGRectMake(fX, 5, 120, 25); // 回転対応
			[sw setOn:[kvs boolForKey:KV_OptWeightRound] animated:YES];
		}	break;
		
		case 4:
		{ // KV_OptCheckingAtEditMode
			UISwitch *sw = (UISwitch*)[cell.contentView viewWithTag:TAG_OptCheckingAtEditMode];
			if (sw==nil) {
				// add UISwitch
				sw = [[UISwitch alloc] init];
				[sw addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
				sw.tag = TAG_OptCheckingAtEditMode;
				sw.backgroundColor = [UIColor clearColor]; //背景透明
				[cell.contentView  addSubview:sw]; //[sw release];
				cell.textLabel.text = NSLocalizedString(@"Checking",nil);
				cell.detailTextLabel.text = NSLocalizedString(@"Checking comment",nil);
			}
			sw.frame = CGRectMake(fX, 5, 120, 25); // 回転対応
			[sw setOn:[kvs boolForKey:KV_OptCheckingAtEditMode] animated:YES];
		}	break;
		
		case 5:
		{ // KV_OptSearchItemsNote
			UISwitch *sw = (UISwitch*)[cell.contentView viewWithTag:TAG_OptSearchItemsNote];
			if (sw==nil) {
				// add UISwitch
				sw = [[UISwitch alloc] init];
				[sw addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
				sw.tag = TAG_OptSearchItemsNote;
				sw.backgroundColor = [UIColor clearColor]; //背景透明
				[cell.contentView  addSubview:sw]; //[sw release];
				cell.textLabel.text = NSLocalizedString(@"SearchItemsNote",nil);
				cell.detailTextLabel.text = NSLocalizedString(@"SearchItemsNote comment",nil);
			}
			sw.frame = CGRectMake(fX, 5, 120, 25); // 回転対応
			[sw setOn:[kvs boolForKey:KV_OptSearchItemsNote] animated:YES];
		}	break;

		case 6:
//		{ // Google+ Picasa
//			if (mTfGoogleID==nil) {
//				mTfGoogleID = [[UITextField alloc] init];
//				mTfGoogleID.borderStyle = UITextBorderStyleRoundedRect;
//				mTfGoogleID.placeholder = @"ID@gmail.com";
//				mTfGoogleID.keyboardType = UIKeyboardTypeASCIICapable;
//				mTfGoogleID.returnKeyType = UIReturnKeyNext;
//				mTfGoogleID.autocapitalizationType = UITextAutocapitalizationTypeNone; //自動SHIFTなし
//				mTfGoogleID.text = @"";
//				mTfGoogleID.delegate = self;
//				[cell.contentView  addSubview:mTfGoogleID];
//				// KeyChainから保存しているパスワードを取得する
//				NSError *error; // nilを渡すと異常終了するので注意
//				mTfGoogleID.text = [SFHFKeychainUtils getPasswordForUsername:GS_KC_LoginName
//															  andServiceName:GS_KC_ServiceName error:&error];
//			}
//			mTfGoogleID.frame = CGRectMake(fX-35, 8, 130, 25); // 回転対応
//			// add UITextField2
//			if (mTfGooglePW==nil) {
//				mTfGooglePW = [[UITextField alloc] init];
//				mTfGooglePW.borderStyle = UITextBorderStyleRoundedRect;
//				mTfGooglePW.placeholder = @"Password";  //NSLocalizedString(@"PackListCrypt Key2 place",nil);
//				mTfGooglePW.keyboardType = UIKeyboardTypeASCIICapable;
//				mTfGooglePW.secureTextEntry = YES;
//				mTfGooglePW.returnKeyType = UIReturnKeyDone;
//				mTfGooglePW.hidden = YES;  // mTfPicasaID入力直後にだけ表示する
//				mTfGooglePW.text = @"";
//				mTfGooglePW.delegate = self;
//				[cell.contentView  addSubview:mTfGooglePW];
//				// KeyChainから保存しているパスワードを取得する
//				NSError *error; // nilを渡すと異常終了するので注意
//				NSString *pw = [SFHFKeychainUtils getPasswordForUsername:GS_KC_LoginPassword
//															  andServiceName:GS_KC_ServiceName error:&error];
//				if (6 <= [pw length]) {
//					mTfGooglePW.text = @"xxxxxxxxxx";  //偽装// pwをセットしない
//				}
//			}
//			mTfGooglePW.frame = CGRectMake(fX-35,38, 130, 25); // 回転対応
//			//
//			cell.textLabel.text = NSLocalizedString(@"Google Login",nil);
//			cell.detailTextLabel.text = NSLocalizedString(@"Google Login msg",nil);
//			cell.detailTextLabel.numberOfLines = 2;
//			//
///*			if ([GoogleAuth isAuthorized]) {
//				cell.textLabel.text = NSLocalizedString(@"Google Authorized",nil);
//				cell.detailTextLabel.text = NSLocalizedString(@"Google Authorized msg",nil);
//			} else {
//				cell.textLabel.text = NSLocalizedString(@"Google NoAuthorize",nil);
//				cell.detailTextLabel.text = NSLocalizedString(@"Google NoAuthorize msg",nil);
//			}
//			cell.detailTextLabel.numberOfLines = 2;
//			cell.selectionStyle = UITableViewCellSelectionStyleBlue; // 選択時ハイライト
//			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; // >
// */
//		}
            break;

		case 7:
		{ // KV_OptAdvertising
			UISwitch *sw = (UISwitch*)[cell.contentView viewWithTag:TAG_OptAdvertising];
			if (sw==nil) {
				// add UISwitch
				sw = [[UISwitch alloc] init];
				[sw addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
				sw.tag = TAG_OptAdvertising;
				sw.backgroundColor = [UIColor clearColor]; //背景透明
				//sw.hidden = !(appDelegate_.app_pid_AdOff); // AdOff支払により可視化 ＜＜NG 購入後の状態が解るように見せることにする
				sw.enabled = mAppDelegate.ppPaid_SwitchAd; // AdOff支払により有効化
				[cell.contentView  addSubview:sw]; //[sw release];
				cell.textLabel.text = NSLocalizedString(@"Advertising",nil);
			}
			if (mAppDelegate.ppPaid_SwitchAd) {
				cell.textLabel.enabled = YES;
				cell.detailTextLabel.text = NSLocalizedString(@"Advertising enable",nil);
				cell.detailTextLabel.textColor = [UIColor grayColor];
			} else {
				cell.textLabel.enabled = NO;
				cell.detailTextLabel.text = NSLocalizedString(@"Advertising disable",nil);
				cell.detailTextLabel.textColor = [UIColor blueColor];
			}
			sw.frame = CGRectMake(fX, 5, 120, 25); // 回転対応
			[sw setOn:[kvs boolForKey:KV_OptAdvertising] animated:YES];
		}	break;

		case 8:
		{ // KV_OptCrypt
			// add UITextField1
			if (mTfPass1==nil) {
				mTfPass1 = [[UITextField alloc] init];
				mTfPass1.borderStyle = UITextBorderStyleRoundedRect;
				mTfPass1.placeholder = NSLocalizedString(@"PackListCrypt Key1 place",nil);
				mTfPass1.keyboardType = UIKeyboardTypeASCIICapable;
				mTfPass1.secureTextEntry = YES;
				mTfPass1.returnKeyType = UIReturnKeyNext;
				mTfPass1.enabled = mAppDelegate.ppPaid_SwitchAd; // AdOff支払により有効化
				mTfPass1.text = @"";
				mTfPass1.delegate = self;
				[cell.contentView  addSubview:mTfPass1];
			}
			mTfPass1.frame = CGRectMake(fX-45, 8, 140, 25); // 回転対応
			// add UITextField2
			if (mTfPass2==nil) {
				mTfPass2 = [[UITextField alloc] init];
				mTfPass2.borderStyle = UITextBorderStyleRoundedRect;
				mTfPass2.placeholder = NSLocalizedString(@"PackListCrypt Key2 place",nil);
				mTfPass2.keyboardType = UIKeyboardTypeASCIICapable;
				mTfPass2.secureTextEntry = YES;
				mTfPass2.returnKeyType = UIReturnKeyDone;
				mTfPass2.hidden = YES;  // tfPass1_入力直後にだけ表示する
				mTfPass2.text = @"";
				mTfPass2.delegate = self;
				[cell.contentView  addSubview:mTfPass2];
			}
			mTfPass2.frame = CGRectMake(fX-45,38, 140, 25); // 回転対応
			//
			cell.textLabel.text = NSLocalizedString(@"PackListCrypt",nil);
			if (mAppDelegate.ppPaid_SwitchAd) {
				NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
				if ([defaults boolForKey:UD_OptCrypt]) {
					// KeyChainから保存しているパスワードを取得する
					NSError *error; // nilを渡すと異常終了するので注意
					mTfPass1.text = [SFHFKeychainUtils getPasswordForUsername:UD_OptCrypt
															   andServiceName:GD_PRODUCTNAME error:&error];
					cell.detailTextLabel.text = NSLocalizedString(@"PackListCrypt enable",nil);
				} else {
					cell.detailTextLabel.text = NSLocalizedString(@"PackListCrypt enable NoKey",nil);
				}
				cell.textLabel.enabled = YES;
				cell.detailTextLabel.textColor = [UIColor grayColor];
				cell.detailTextLabel.numberOfLines = 2;
			} else {
				cell.textLabel.enabled = NO;
				cell.detailTextLabel.text = NSLocalizedString(@"PackListCrypt disable",nil);
				cell.detailTextLabel.textColor = [UIColor blueColor];
				cell.detailTextLabel.numberOfLines = 1;
			}
		}	break;
	}
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];	// 選択状態を解除する
	
/*	if (indexPath.row==6) {
		// Google OAuth2
		[self.navigationController pushViewController:[GoogleAuth viewControllerOAuth2:self] animated:YES];
	}*/
}


// UISwitch Action
- (void)switchAction: (UISwitch *)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSUbiquitousKeyValueStore *kvs = [NSUbiquitousKeyValueStore defaultStore];
	switch (sender.tag) {  // .tag は UIView にて NSInteger で存在する、　
		case TAG_OptShouldAutorotate: {
			[defaults setBool: [sender isOn]  forKey:UD_OptShouldAutorotate];
			mAppDelegate.ppOptAutorotate = [sender isOn];
		}	break;
		case TAG_OptTotlWeightRound:
			[kvs setBool:[sender isOn] forKey:KV_OptWeightRound];
			break;
		case TAG_OptShowTotalWeight:
			[kvs setBool:[sender isOn] forKey:KV_OptShowTotalWeight];
			break;
		case TAG_OptShowTotalWeightReq:
			[kvs setBool:[sender isOn] forKey:KV_OptShowTotalWeightReq];
			break;
		case TAG_OptCheckingAtEditMode:
			[kvs setBool:[sender isOn] forKey:KV_OptCheckingAtEditMode];
			break;
		case TAG_OptSearchItemsNote:
			[kvs setBool:[sender isOn] forKey:KV_OptSearchItemsNote];
			break;
		case TAG_OptAdvertising:
//			[kvs setBool:[sender isOn] forKey:KV_OptAdvertising];
//			mAppDelegate.ppOptShowAd = [sender isOn];
			// viewWillDisappear:にて再描画する
			break;
	}
	//[kvs synchronize]; ＜＜＜viewWillDisappear:にて保存する。
}

/*
- (void)done:(id)sender
{
	//[self.navigationController dismissModalViewControllerAnimated:YES];	// モーダルView閉じる
	[self.navigationController popViewControllerAnimated:YES];
}
*/


#pragma make - <UITextFieldDelegate>

// キーボードのリターンキーを押したときに呼ばれる
- (BOOL)textFieldShouldReturn:(UITextField *)sender 
{
	if (sender==mTfPass1) {	//-------------------------------------------------------------Crypt Key1
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setBool:NO forKey:UD_OptCrypt];  // 解除
		[defaults setBool:NO forKey:UD_Crypt_Switch];  // OFF
		if ([sender.text length] <= 0) {
			// 秘密キーを破棄する
			NSError *error; // nilを渡すと異常終了するので注意
			[SFHFKeychainUtils deleteItemForUsername:UD_OptCrypt 
									  andServiceName:GD_PRODUCTNAME error:&error];
			sender.text = @"";
			[mTfPass1 resignFirstResponder];
			mTfPass2.hidden = YES;
			mTfPass2.text = @"";
			[self.tableView reloadData];  // cell表示更新のため
			azAlertBox(NSLocalizedString(@"PackListCrypt Disable",nil), nil, @"OK");
			return YES;
		}
		else if ([sender.text length] < 3 OR 20 < [sender.text length]) {
			sender.text = @"";
			azAlertBox(NSLocalizedString(@"PackListCrypt Key Over",nil), nil, @"OK");
			return NO;
		}
		mTfPass2.hidden = NO;
		mTfPass2.text = @"";
		[mTfPass2 becomeFirstResponder];
	}
	else if (sender==mTfPass2) {	//-------------------------------------------------------------Crypt Key2
		[mTfPass2 resignFirstResponder];	//iPad//disablesAutomaticKeyboardDismissalカテゴリ定義が必要＞Global定義
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		if ([mTfPass1.text isEqualToString:mTfPass2.text]) {
			// 一致、パス変更
			// 秘密キーをKeyChainに保存する
			NSError *error; // nilを渡すと異常終了するので注意
			[SFHFKeychainUtils storeUsername:UD_OptCrypt
								 andPassword:mTfPass1.text 
							  forServiceName:GD_PRODUCTNAME 
							  updateExisting:YES error:&error];
			if (error) {
				mTfPass1.text = @"";
				[mTfPass1 becomeFirstResponder];
				mTfPass2.hidden = YES;
				mTfPass2.text = @"";
				azAlertBox(NSLocalizedString(@"PackListCrypt Key Error",nil), 
						 [error localizedDescription], @"OK");
			} else {
				[defaults setBool:YES forKey:UD_OptCrypt]; // 有効
				[self.tableView reloadData];  // cell表示更新のため
				azAlertBox(NSLocalizedString(@"PackListCrypt Key Changed",nil), nil, @"OK");
			}
			mTfPass2.hidden = YES;
		}
		else {
			// 不一致　　Does not match.
			mTfPass2.hidden = NO;
			mTfPass2.text = @"";
			[mTfPass2 becomeFirstResponder];
			azAlertBox(NSLocalizedString(@"PackListCrypt Key NoMatch",nil), nil, @"OK");
		}
	}
	else if (sender==mTfGoogleID) {	//-------------------------------------------------------------Google+ ID
//		if ([sender.text length] <= 0 OR 80 < [sender.text length]) {
//			// GoogleServiceログイン状態をクリアする
//			[GoogleService docServiceClear];
//			[GoogleService photoServiceClear];
//			// IDを破棄する
//			NSError *error; // nilを渡すと異常終了するので注意
//			[SFHFKeychainUtils deleteItemForUsername:GS_KC_LoginName
//									  andServiceName:GS_KC_ServiceName error:&error];
//			sender.text = @"";
//			[mTfGoogleID resignFirstResponder];
//			mTfGooglePW.text = @"";
//			[self.tableView reloadData];  // cell表示更新のため
//			azAlertBox(NSLocalizedString(@"Picasa ID delete",nil), nil, @"OK");
//			return YES;
//		}
//		// ID KeyChainに保存する
//		NSError *error; // nilを渡すと異常終了するので注意
//		[SFHFKeychainUtils storeUsername:GS_KC_LoginName
//							 andPassword: sender.text
//						  forServiceName:GS_KC_ServiceName 
//						  updateExisting:YES error:&error];
//		mTfGooglePW.text = @"";
//		mTfGooglePW.hidden = NO;
//		[mTfGooglePW becomeFirstResponder];
	}
	else if (sender==mTfGooglePW) {	//-------------------------------------------------------------Google+ PW
//		[mTfGooglePW resignFirstResponder];	//iPad//disablesAutomaticKeyboardDismissalカテゴリ定義が必要＞Global定義
//		mTfGooglePW.hidden = YES;
//		if ([sender.text length] <= 0 OR 80 < [sender.text length]) {
//			// PWを破棄する
//			NSError *error; // nilを渡すと異常終了するので注意
//			[SFHFKeychainUtils deleteItemForUsername:GS_KC_LoginPassword
//									  andServiceName:GS_KC_ServiceName error:&error];
//			sender.text = @"";
//			[self.tableView reloadData];  // cell表示更新のため
//			azAlertBox(NSLocalizedString(@"Picasa PW delete",nil), nil, @"OK");
//			return YES;
//		}
//		if (0 < [mTfGoogleID.text length] && 0 < [mTfGooglePW.text length]) {
//			//没// Google OAuth2
//			//没// [self presentModalViewController:[GoogleAuth viewControllerOAuth2] animated:YES];
//			// Google Service Login
//			[GoogleService loginID: mTfGoogleID.text  withPW: mTfGooglePW.text  isSetting:YES];
//		}
	}
    return YES;
}


@end

