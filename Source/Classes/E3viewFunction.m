//
//  E3viewFunction.m
//  iPack
//
//  Created by 松山 和正 on 09/12/20.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Global.h"
#import "AppDelegate.h"
#import "Elements.h"
#import "E3viewFunction.h"
#import "E3edit.h"
#import "SettingView.h"

@implementation E3viewFunction

@synthesize managedObjectContext;
@synthesize fetchedE1;
@synthesize e2list;
@synthesize e3list;
@synthesize e1selected;
@synthesize iFunction;
@synthesize AzOptDisclosureButtonToEditable;
@synthesize buGrayHideShow;
@synthesize mbFirstView;
@synthesize miGrayTag;

#pragma mark Memory management

- (void)dealloc {    // 生成とは逆順に解放するのが好ましい
	// assign: zFunctionName
	// assign: iFunction
	// assign: firstCall
	// assign: e3section
	[buGrayHideShow release];
	[e1selected release];
	[e3list release];
	[e2list release];
	[fetchedE1 release];
	[managedObjectContext release];
    [super dealloc];
}

- (void)viewDidUnload {

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark View lifecycle

- (id)initWithStyle:(UITableViewStyle)style {
	if (self != [super initWithStyle:UITableViewStylePlain]) return self;  // セクションありテーブルにする

	return self;
}

- (void)azSettingView
{
	SettingView *vi = [[SettingView alloc] initWithFrame:[self.view.window bounds]];
	vi.IaParentViewCon = self;
	[self.view.window addSubview:vi];
	[vi show];
	[vi release];
}

- (void)azGrayHideShow
{
	// 表示行数が変化するための処理　　
	// 表示最上業を取得する
	NSArray *arCells = [self.tableView indexPathsForVisibleRows];
	NSIndexPath *topPath = nil;
	for (NSInteger i=0 ; i<[arCells count] ; i++) {
		topPath = [arCells objectAtIndex:i]; 
		if (topPath.section==0 && topPath.row < [self.e3list count]) {
			// E3func Node Object
			E3 *e3obj = [self.e3list objectAtIndex:topPath.row]; // sectionなし
			if ([e3obj.required intValue] != 0) {
				// 必要数が0でない「Grayでない」セル発見
				break;
			}
		}
	}
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if (self.buGrayHideShow.tag == 1) {
		self.buGrayHideShow.tag = 0;
		[self viewWillAppear:YES];
		self.buGrayHideShow.title = @"Gray Show";
		[defaults setBool:YES forKey:GD_OptItemsGrayHide];
	}
	else {
		self.buGrayHideShow.tag = 1;
		[self viewWillAppear:YES];
		self.buGrayHideShow.title = @"Gray Hide";
		[defaults setBool:NO forKey:GD_OptItemsGrayHide];
	}
	
	// 表示行数が変化するための処理　　
	// 元の最上行を再現する
	if (topPath) [self.tableView scrollToRowAtIndexPath:topPath 
				  atScrollPosition:UITableViewScrollPositionTop animated:NO];  
}

- (void)azItemRefresh
{
	self.mbFirstView = YES;
	[self viewWillAppear:YES];
}

// viewDidLoadメソッドは，TableViewContorllerオブジェクトが生成された後，実際に表示される際に1度だけ呼び出されるメソッド
- (void)viewDidLoad {
	[super viewDidLoad];

	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	self.tableView.allowsSelectionDuringEditing = YES;
	
	// Tool Bar Button
	UIBarButtonItem *buFlex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																			target:nil action:nil];
	UIBarButtonItem *buSet = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Setting-icon16.png"]
															  style:UIBarButtonItemStyleBordered
															 target:self action:@selector(azSettingView)];
	self.buGrayHideShow = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStyleBordered
														  target:self action:@selector(azGrayHideShow)];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults boolForKey:GD_OptItemsGrayHide]) {
		self.buGrayHideShow.tag = 0; // Now HIDE
		self.buGrayHideShow.title = @"Gray Show";
	} else {
		self.buGrayHideShow.tag = 1; // Now SHOW
		self.buGrayHideShow.title = @"Gray Hide";
	}
	
	NSArray *buArray = nil;
	if ([defaults boolForKey:GD_OptItemsQuickSort]==NO) {
		UIBarButtonItem *buRef = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
															target:self action:@selector(azItemRefresh)] autorelease];
		buArray = [NSArray arrayWithObjects: self.buGrayHideShow, buFlex, buRef, buFlex, buSet, nil];
	}
	else {
		buArray = [NSArray arrayWithObjects: self.buGrayHideShow, buFlex, buSet, nil];
	}
	[self setToolbarItems:buArray animated:YES];
	[buSet release];
	[buFlex release];
	
	self.mbFirstView = YES;
}

// 他のViewやキーボードが隠れて、現れる都度、呼び出される
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

	//self.title = ;　呼び出す側でセット済み。　変化させるならばココで。

	// Option Reset
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	AzOptDisclosureButtonToEditable = [defaults boolForKey:GD_OptDisclosureButtonToEditable];  // YES==>>ディスクロージャ「ボタン」ON
	BOOL bQuickSort = [defaults boolForKey:GD_OptItemsQuickSort];
	// GD_OptItemsGrayHide は viewDidLoadのボタン生成と同時にセットしている

	if (self.mbFirstView OR bQuickSort){
		self.mbFirstView = NO;
		// 最新データ取得：初ロード時 および 編集直後ソート指示があるときだけ、再読み込みする
		//----------------------------------------------------------------------------CoreData Loading
		self.e3list = nil;
		self.e3list = [[NSMutableArray alloc] init];
		if ([self.e2list count] <= 0) return;  // NoGroup
		int i;
		for( i=0 ; i<[self.e2list count] ; i++ ) {
			E2 *e2obj = [self.e2list objectAtIndex:i];
			//---------------------------------------------------------------------------- E3 Section
			// 選択中の E2(e2selected) の子となる E3(e2selected.childs) を抽出する。
			NSArray *e3array = [[NSArray alloc] initWithArray:[e2obj.childs allObjects]];
			[self.e3list addObjectsFromArray:e3array];  // addObjectsFromArray:により同次元にする。
			[e3array release];
		}
		// SELECT & ORDER BY　　テーブルの行番号を記録した属性"row"で昇順ソートする
		NSSortDescriptor *sortDescriptor;
		switch (self.iFunction) {
			case 1: // 不足数量降順
				sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lack" ascending:NO];
				break;
			case 2: // 不足重量降順
				sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"weightLack" ascending:NO];
				break;
			case 3: // 在庫重量降順
				sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"weightStk" ascending:NO];
				break;
			case 4: // 必要重量降順
				sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"weightReq" ascending:NO];
				break;
			default:
				sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"row" ascending:YES];
				break;
		}
		NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:&sortDescriptor count:1];
		// 並べ替えを実行
		[self.e3list sortUsingDescriptors:sortDescriptors];
		[sortDescriptor release];
		[sortDescriptors release];
	}
	// テーブルビューを更新します。
    [self.tableView reloadData];	// これにより修正結果が表示される
}

// 復帰再現処理
- (void)viewDidAppear:(BOOL)animated
{
	// (-1,-1)にしてE3を未選択状態にする
	AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate.comebackIndex replaceObjectAtIndex:4 withObject:[NSNumber numberWithInteger:-1]];
	[appDelegate.comebackIndex replaceObjectAtIndex:5 withObject:[NSNumber numberWithInteger:-1]];
}

// 復帰再現処理：E2 から呼ばれる
- (void)viewComeback:(NSArray *)selectionArray
{
	NSInteger iSec = [[selectionArray objectAtIndex:4] intValue];
	NSInteger iRow = [[selectionArray objectAtIndex:5] intValue];
	if (iSec < 0) return; // この画面表示
	if (iRow < 0) return; // fail.

	if ([self.e3list count] <= iSec) return; // 無効セクション
	if ([[self.e3list objectAtIndex:iSec] count] <= iRow) return; // 無効セル（削除されたとか）

	// 前回選択したセル位置
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:iRow inSection:iSec];
	
	// E3 では、前回選択セルを中央に復元するところまで。　Edit状態までは復元しない。
	// 指定位置までテーブルビューの行をスクロールさせる初期処理
	[self.tableView scrollToRowAtIndexPath:indexPath
						atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
}


#pragma mark Local methods
	
- (void)e3editView:(NSIndexPath *)indexPath
{
	//if ([[self.e3list objectAtIndex:indexPath.section] count] <= indexPath.row) return;  // Addボタン行の場合パスする
	//E3 *e3obj = [[self.e3list objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	E3 *e3obj = [self.e3list objectAtIndex:indexPath.row];
	
	// EDIT 編集対象のオブジェクトを渡す
	E3edit *e3editView = [[[E3edit alloc] init] autorelease];
	//e3editView.managedObjectContext = self.managedObjectContext;
	e3editView.IaE2array = self.e2list;
	e3editView.IaE3array = self.e3list;
	e3editView.IaE1selected = self.e1selected;
	e3editView.IaE2selected = e3obj.parent;  // ここでは section なしのため
	e3editView.IaE3target = e3obj;
	e3editView.IbAddObj = NO;
	e3editView.title =  NSLocalizedString(@"Edit Item", nil);
	
	// モーダルビューを表示します。
	UINavigationController *navcon = [[UINavigationController alloc] initWithRootViewController:e3editView];
	[self.navigationController presentModalViewController:navcon animated:YES]; // NO:レスポンス優先のためアニメ効果なし
	[navcon release];
}


#pragma mark TableView methods
	
// TableView セクション数を応答
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

// TableView セクションの行数を応答
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger rows = [self.e3list count];
	return rows;
}

// TableView セクション名を応答
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (self.iFunction) {
		case 1: // 不足数量一覧
			return NSLocalizedString(@"Shortage Qty list", nil);
			break;
		case 2: // 不足重量一覧
			return NSLocalizedString(@"Shortage Weight list", nil);
			break;
		case 3: // 在庫重量一覧
			return NSLocalizedString(@"Stock Weight list", nil);
			break;
		case 4: // 必要重量一覧
			return NSLocalizedString(@"Required Weight list", nil);
			break;
	}
	return @"Err";
}

// セルの高さを指示する  ＜＜ [Gray Hide] 高さ0にする＞＞
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if (self.buGrayHideShow.tag==0) {
		// Gray Hide
		if (indexPath.row < [self.e3list count]) {
			// E3func Node Object
			E3 *e3obj = [self.e3list objectAtIndex:indexPath.row]; // sectionなし
			if ([e3obj.required intValue] <= 0) return 0; // Hide さらに cell をクリアにしている
		}
	}
	return 44; // デフォルト：44ピクセル
}

// TableView 指定されたセルを生成＆表示
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *zCellNode = @"CellE3Node";
	UITableViewCell *cell = nil;
	
	// E3ノードセル
	cell = [tableView dequeueReusableCellWithIdentifier:zCellNode];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle		// サブタイトル型(3.0)
									   reuseIdentifier:zCellNode] autorelease];
	}
	// E3func Node Object
	E3 *e3obj = [self.e3list objectAtIndex:indexPath.row]; // sectionなし
	
	if (self.buGrayHideShow.tag==0 && [e3obj.required intValue]==0) {
		// Gray Hide
		cell.textLabel.text = @"";
		cell.detailTextLabel.text = @"";
		cell.accessoryType = UITableViewCellAccessoryNone;	// なし
		cell.showsReorderControl = NO; // Move禁止
		return cell;
	}

	cell.textLabel.text = e3obj.name;
	[cell.textLabel setFont:[UIFont systemFontOfSize:16]];
	
	NSString *zSpec;
	if (e3obj.spec) zSpec = e3obj.spec;
	else zSpec = @"";
	
	switch (self.iFunction) {
		case 1: // 不足数量降順
			cell.detailTextLabel.text = [NSString stringWithFormat:@"%4d／%d %6dg  %@(%d)%@ %@",
										 [e3obj.stock intValue],[e3obj.required intValue],[e3obj.weight intValue],
										 NSLocalizedString(@"Shortage", nil), [e3obj.lack intValue],
										 NSLocalizedString(@"Qty", nil), zSpec];
			break;
		case 2: // 不足重量降順
			cell.detailTextLabel.text = [NSString stringWithFormat:@"%4d／%d %6dg  %@(%d)g %@",
										 [e3obj.stock intValue],[e3obj.required intValue],[e3obj.weight intValue],
										 NSLocalizedString(@"Shortage", nil), [e3obj.weightLack intValue], zSpec];
			break;
		case 3: // 在庫重量降順
			cell.detailTextLabel.text = [NSString stringWithFormat:@"%4d／%d %6dg  %@(%d)g %@",
										 [e3obj.stock intValue],[e3obj.required intValue],[e3obj.weight intValue],
										 NSLocalizedString(@"Stock", nil), [e3obj.weightStk intValue], zSpec];
			break;
		case 4: // 必要重量降順
			cell.detailTextLabel.text = [NSString stringWithFormat:@"%4d／%d %6dg  %@(%d)g %@",
										 [e3obj.stock intValue],[e3obj.required intValue],[e3obj.weight intValue],
										 NSLocalizedString(@"Required", nil), [e3obj.weightReq intValue], zSpec];
			break;
	}
	
	[cell.detailTextLabel setFont:[UIFont systemFontOfSize:12]];
	if ([e3obj.required intValue] == 0) {  // 必要なし
		[cell.textLabel setTextColor:[UIColor grayColor]];
		[cell.detailTextLabel setTextColor:[UIColor grayColor]];
	}
	else if ([e3obj.stock intValue] < [e3obj.required intValue]) {  // E3では数量比較できるから
		[cell.textLabel setTextColor:[UIColor blackColor]];
		[cell.detailTextLabel setTextColor:[UIColor redColor]];
	} else {
		[cell.textLabel setTextColor:[UIColor blackColor]];
		[cell.detailTextLabel setTextColor:[UIColor blueColor]];
	}
	if (AzOptDisclosureButtonToEditable) 
		cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton; // ディスクロージャボタン
	else 
		cell.accessoryType = UITableViewCellAccessoryNone;	// E3 なし
	cell.showsReorderControl = YES;		// Move許可
	return cell;
}

// TableView Editボタンスタイル
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.buGrayHideShow.tag==0) {
		E3 *e3obj = [self.e3list objectAtIndex:indexPath.row]; // sectionなし
		if ([e3obj.required intValue]==0) {
			return UITableViewCellEditingStyleNone; // なし
		}
	}
	return UITableViewCellEditingStyleDelete;
}

// TableView 行選択時の動作
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	// 次回の画面復帰のための状態記録
	AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	//						E1 replaceObjectAtIndex:0,1 は決定済み
	//						E2 replaceObjectAtIndex:2,3 は決定済み
	[appDelegate.comebackIndex replaceObjectAtIndex:4 withObject:[NSNumber numberWithInteger:indexPath.section]];
	[appDelegate.comebackIndex replaceObjectAtIndex:5 withObject:[NSNumber numberWithInteger:indexPath.row]];

	if (self.editing) {
		[self e3editView:indexPath];
	} 
	else {
		// 数量＆重量 専用修正モード
		//E3 *e3obj = [[self.e3list objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
		E3 *e3obj = [self.e3list objectAtIndex:indexPath.row]; // ここではセクションなし
		UIActionSheet *sheet = [[UIActionSheet alloc] 
								initWithTitle:[NSString stringWithFormat:@"%@ = %ld／%ld %@", e3obj.name, 
											   [e3obj.stock longValue], 
											   [e3obj.required longValue],
											   NSLocalizedString(@"Qty", nil)]
								delegate:self 
								cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
								destructiveButtonTitle:nil
								otherButtonTitles:NSLocalizedString(@"Same to required Qty", nil), @"+ 1", @"- 1", 
													NSLocalizedString(@"ZERO", nil), 
													nil];
		sheet.destructiveButtonIndex = 3;
		sheet.actionSheetStyle = UIActionSheetStyleAutomatic;
		sheet.tag = indexPath.row;  // セクションなし
//		[sheet showInView:self.view.window];
		[sheet showFromToolbar:self.navigationController.toolbar];
		[sheet release];
//		// 選択行を最上に表示する
//		[self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];  
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];		// 先ずは選択状態表示を解除する
}

// UIActionSheetDelegate 処理部
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// actionSheet.tag = 選択行(indexPath.section * GD_SECTION_TIMES + indexPath.row)が代入されている
	NSInteger row = actionSheet.tag;  // セクションなし
	if (row < 0 OR [self.e3list count] <= row) return;
	
	//E3 *e3obj = [[self.e3list objectAtIndex:section] objectAtIndex:row];
	E3 *e3obj = [self.e3list objectAtIndex:row]; // ここではセクションなし
	long lStock = [e3obj.stock longValue];
	switch(buttonIndex) {  // actionSheetの上から順に(0〜)
		case 0: // Pass
			lStock = [e3obj.required longValue];
			break;
		case 1: // +1
			lStock++;
			break;
		case 2: // -1
			lStock--;
			break;
		case 3: // ZERO
			lStock = 0;
			break;
/*		case 4: // Edit
			{
				NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
				[self e3editView:indexPath];
			}
			return;
			break; */
		default: // CANCEL
			return;
	}
	long lWeight = [e3obj.weight longValue];
	long lRequired = [e3obj.required longValue];
	[e3obj setValue:[NSNumber numberWithLong:lStock] forKey:@"stock"];
	[e3obj setValue:[NSNumber numberWithLong:(lWeight*lStock)] forKey:@"weightStk"];
	[e3obj setValue:[NSNumber numberWithLong:(lRequired-lStock)] forKey:@"lack"]; // 不足数
	[e3obj setValue:[NSNumber numberWithLong:((lRequired-lStock)*lWeight)] forKey:@"weightLack"]; // 不足重量
	
	// SAVE : e3edit,e2list は ManagedObject だから更新すれば ManagedObjectContext に反映されている
	NSError *err = nil;
	if (![self.managedObjectContext save:&err]) {
		NSLog(@"Unresolved error %@, %@", err, [err userInfo]);
		abort();
	}
	[self viewWillAppear:YES]; // 再フェッチせずに、位置が変わらないようにする
	return;
}

// ディスクロージャボタンが押されたときの処理
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	[self e3editView:indexPath];
}

// TableView Editモードの表示
- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	// Add行やGray行の分だけズレる現象を補正する
	// 編集モードに入る前の表示最上業を取得する
/*	NSArray *arCells = [self.tableView indexPathsForVisibleRows];
	NSIndexPath *topPath = nil;
	for (NSInteger i=0 ; i<[arCells count] ; i++) {
		topPath = [arCells objectAtIndex:i]; 
		if (topPath.section==0 && topPath.row < [self.e3list count]) {
			// E3func Node Object
			E3 *e3obj = [self.e3list objectAtIndex:topPath.row]; // sectionなし
			if ([e3obj.required intValue] != 0) {
				// 必要数が0でない「Grayでない」セル発見
				if (0 < topPath.row) topPath = [NSIndexPath indexPathForRow:topPath.row - 1 
																  inSection:topPath.section];
				break;
			}
		}
	}
	
	if (editing) {  // 注意！ self.editing ではダメ。　self.editingは、super処理内で editingが代入される
		// 編集時は常に [Gray Show] にする
		miGrayTag = self.buGrayHideShow.tag; // 退避、後ほど復帰させるため
		self.buGrayHideShow.tag = 1;
		self.buGrayHideShow.enabled = NO; // ボタンを無効にする
	} else {
		// 復帰
		self.buGrayHideShow.tag = miGrayTag;
		self.buGrayHideShow.enabled = YES; // ボタンを有効にする
	}
*/	
	// super
	[super setEditing:editing animated:animated];
    // この後、self.editing = YES になっている。
	
/*	if (miGrayTag == 0) {
		// Gray Hide から編集するとき、アニメがうるさすぎるので、こうしている。
		[self.tableView reloadData];
		// [self.tableView reloadData]だとアニメ効果が消される。　(OS 3.0 Function)を使って解決した。
		//NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 1)]; // [0]セクションから1個 E3func
		//[self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationBottom]; // (OS 3.0 Function)
		// 表示行数が変化するための処理　　
		// 元の最上行を再現する
		if (topPath) [self.tableView scrollToRowAtIndexPath:topPath 
					  atScrollPosition:UITableViewScrollPositionTop animated:NO];  
	} else {
		// E3funcには、Add行が無いので、この再描画は不要。super処理だけで十分
		//NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 1)]; // [0]セクションから1個 E3func
		//[self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone]; // (OS 3.0 Function)
	}
*/
}

// TableView Editモード処理
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
																forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		// Delete the e3list object.
		E3 *e3obj = [self.e3list objectAtIndex:indexPath.row];
		[self.e3list removeObject:e3obj];
		// Delete the managed object.
		[self.managedObjectContext deleteObject:e3obj];
		// SAVE　＜＜万一システム障害で落ちてもデータが残るようにコマメに保存する方針＞＞
		NSError *error = nil;
		if (![self.managedObjectContext save:&error]) {
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			exit(-1);  // Fail
		}
        // テーブルビューから選択した行を削除します。
		[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
												withRowAnimation:UITableViewRowAnimationFade];
    }
}
	
	
@end
