//
//  SettingTVC.m
//  AzPacking
//
//  Created by 松山 和正 on 10/01/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Global.h"
#import "AppDelegate.h"
#import "SettingTVC.h"

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


- (void)changeAdvertising
{
	if (appDelegate_.app_is_iPad) {
		[appDelegate_ AdRefresh:appDelegate_.app_opt_Ad];
		// 再描画　　Adスペースを変化させるため
		[[NSNotificationCenter defaultCenter] postNotificationName:NFM_REFRESH_ALL_VIEWS 
															object:self userInfo:nil];
	} //iPhoneは、E1viewController:viewWillAppear:を通ってAd再開される
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

		appDelegate_ = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		if (appDelegate_.app_is_iPad) {
			self.contentSizeForViewInPopover = CGSizeMake(480, 420);
			self.navigationItem.hidesBackButton = YES;
		}
	}
	return self;
}

/***随時同期はしない。閉じてから同期で十分
- (void)viewDidLoad 
{
	[super viewDidLoad];
	
	// iCloud-KVS 変更通知を受ける
    [[NSNotificationCenter defaultCenter] addObserver:self			// viewDidUnload:にて removeObserver:必須
											 selector:@selector(kvsValueChange:) 
												 name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification	// KVSの値が変化したとき
											   object:nil];  //=nil: 全てのオブジェクトからの通知を受ける
}*/

// 他のViewやキーボードが隠れて、現れる都度、呼び出される
- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
	
	// 画面表示に関係する Option Setting を取得する
	//NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	self.title = NSLocalizedString(@"Setting", nil);
	
	[[NSUbiquitousKeyValueStore defaultStore] synchronize]; // 最新取得
	// テーブルビューを更新します。
    [self.tableView reloadData];	// これにより修正結果が表示される
}


// ビューが最後まで描画された後やアニメーションが終了した後にこの処理が呼ばれる
- (void)viewDidAppear:(BOOL)animated 
{
    [super viewDidAppear:animated];
	//[self.tableView flashScrollIndicators]; // Apple基準：スクロールバーを点滅させる

	// 広告表示に変化があれば、広告スペースを調整するための処理
	BOOL bAd = [[NSUbiquitousKeyValueStore defaultStore] boolForKey:KV_OptAdvertising];
	if (appDelegate_.app_opt_Ad != bAd) {
		appDelegate_.app_opt_Ad = bAd;
		[self changeAdvertising];
	}
}


// 回転サポート
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{	
	if (appDelegate_.app_is_iPad) {
		return (interfaceOrientation == UIInterfaceOrientationPortrait);	// Popover内につき回転不要 <正面は常に許可>
	} else {
		// 回転禁止でも、正面は常に許可しておくこと。
		AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		return app.app_opt_Autorotate OR (interfaceOrientation == UIInterfaceOrientationPortrait);
	}
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
			if (appDelegate_.app_is_iPad) {
				return 6;	// (0)回転は不要
			} else {
				return 7;
			}
			break;
	}
    return 0;
}

// セルの高さを指示する
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{
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
	if (appDelegate_.app_is_iPad) {
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
		{ // KV_OptAdvertising
			UISwitch *sw = (UISwitch*)[cell.contentView viewWithTag:TAG_OptAdvertising];
			if (sw==nil) {
				// add UISwitch
				sw = [[UISwitch alloc] init];
				[sw addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
				sw.tag = TAG_OptAdvertising;
				sw.backgroundColor = [UIColor clearColor]; //背景透明
				sw.enabled = appDelegate_.app_pid_AdOff;
				[cell.contentView  addSubview:sw]; //[sw release];
				cell.textLabel.text = NSLocalizedString(@"Advertising",nil);
				cell.detailTextLabel.text = NSLocalizedString(@"Advertising msg",nil);
			}
			sw.frame = CGRectMake(fX, 5, 120, 25); // 回転対応
			[sw setOn:[kvs boolForKey:KV_OptAdvertising] animated:YES];
		}	break;
	}
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];	// 選択状態を解除する
}


// UISwitch Action
- (void)switchAction: (UISwitch *)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSUbiquitousKeyValueStore *kvs = [NSUbiquitousKeyValueStore defaultStore];
	switch (sender.tag) {  // .tag は UIView にて NSInteger で存在する、　
		case TAG_OptShouldAutorotate: {
			[defaults setBool: [sender isOn]  forKey:UD_OptShouldAutorotate];
			appDelegate_.app_opt_Autorotate = [sender isOn];
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
			[kvs setBool:[sender isOn] forKey:KV_OptAdvertising];
			appDelegate_.app_opt_Ad = [sender isOn];
			[self changeAdvertising];
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

@end

