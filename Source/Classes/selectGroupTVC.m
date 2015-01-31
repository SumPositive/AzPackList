//
//  selectGroupTVC.m
//  AzPacking
//
//  Created by 松山 和正 on 10/02/02.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Global.h"
#import "AppDelegate.h"
#import "Elements.h"
#import "selectGroupTVC.h"

@interface selectGroupTVC (PrivateMethods)
@end

@implementation selectGroupTVC
@synthesize RaE2array;
@synthesize RlbGroup;

- (void)dealloc    // 生成とは逆順に解放するのが好ましい
{
	//--------------------------------@property (retain)
	//[RlbGroup release];
	//[RaE2array release];
	//[super dealloc];
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleGrouped];
	if (self) {
		// 初期化成功
		appDelegate_ = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		if (appDelegate_.ppIsPad) {
			self.preferredContentSize = GD_POPOVER_SIZE_E3edit;
		}
    }
    return self;
}

/*
// IBを使わずにviewオブジェクトをプログラム上でcreateするときに使う（viewDidLoadは、nibファイルでロードされたオブジェクトを初期化するために使う）
- (void)loadView
{	//【Tips】ここでaddSubviewするオブジェクトは全てautoreleaseにすること。メモリ不足時には自動的に解放後、改めてここを通るので、初回同様に生成するだけ。
	[super loadView];
}
*/

- (void)viewDidLoad 
{
	[super viewDidLoad];
	// 背景テクスチャ・タイルペイント
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Tx-Back"]];
}

- (void)viewWillAppear:(BOOL)animated 	// ＜＜見せない処理＞＞
{
    [super viewWillAppear:animated];
	
	// 画面表示に関係する Option Setting を取得する
	//NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	self.title = NSLocalizedString(@"Group choice",nil);

	//[self.tableView flashScrollIndicators]; // Apple基準：スクロールバーを点滅させる
}


- (void)viewDidAppear:(BOOL)animated {	// ＜＜魅せる処理＞＞
    [super viewDidAppear:animated];
	GA_TRACK_METHOD
	
	// 選択グループを中央に近づける
	NSIndexPath* indexPath = [NSIndexPath indexPathForRow:RlbGroup.tag inSection:0];
	[self.tableView scrollToRowAtIndexPath:indexPath 
							atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}

/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

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


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // セクションは1つだけ section==0
	return [RaE2array count];
}

// セルの高さを指示する
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	return 40; // デフォルト：44ピクセル
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault  // Subtitle
									   reuseIdentifier:CellIdentifier];
    }

    // セクションは1つだけ section==0
	E2 *e2obj = [RaE2array objectAtIndex:indexPath.row];

	if ([e2obj.name length] <= 0) 
		cell.textLabel.text = NSLocalizedString(@"(New Index)", nil);
	else
		cell.textLabel.text = e2obj.name;

	if (appDelegate_.ppIsPad) {
		cell.textLabel.font = [UIFont systemFontOfSize:20];
	} else {
		cell.textLabel.font = [UIFont systemFontOfSize:16];
	}
	cell.textLabel.textAlignment = NSTextAlignmentLeft;
	cell.textLabel.textColor = [UIColor blackColor];
	
	if (RlbGroup.tag == indexPath.row) {
		cell.accessoryType = UITableViewCellAccessoryCheckmark; // チェックマーク
	} else {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];	// 選択状態を解除する
	
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	cell.accessoryType = UITableViewCellAccessoryCheckmark; // チェックマーク
	
	if (RlbGroup.tag != indexPath.row) {
		RlbGroup.tag = indexPath.row;
		RlbGroup.text = cell.textLabel.text;
		AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		appDelegate.ppChanged = YES; // 変更あり
	}
	
#ifdef xxxAzPAD
	if (appDelegate_.app_is_iPad) {
	} else {
	}

	if (Rpopover) {
		[Rpopover dismissPopoverAnimated:YES];
	}
#else
	[self.navigationController popViewControllerAnimated:YES];	// < 前のViewへ戻る
#endif
}


@end

