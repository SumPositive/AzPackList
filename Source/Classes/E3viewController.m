//
//  E3viewController.m
//  iPack
//
//  Created by 松山 和正 on 09/12/06.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Global.h"
#import "AppDelegate.h"
#import "Elements.h"
#import "EntityRelation.h"
#import "E3viewController.h"
#import "E3detailTVC.h"
#import "SettingTVC.h"
#import "ItemTouchV.h"

#import "PadRootVC.h"
#import "E2viewController.h"
//#import "PadPopoverInNaviCon.h"

//#define ACTIONSEET_TAG_DELETEITEM		101
#define TAG_CELL_ITEM								102
#define TAG_CELL_ADD								103
#define TAG_TOOLBAR									104


@interface E3viewController (PrivateMethods)
- (void)azSettingView;
- (void)azReflesh;
- (void)azItemsGrayHide: (UIBarButtonItem *)sender;
- (void)azSearchBar;
- (void)e3detailView:(NSIndexPath *)indexPath;
- (void)cellButtonCheck: (UIButton *)button ;
- (void)cellButtonClip: (UIButton *)button ;
- (void)cellButtonPaste: (UIButton *)button ;
- (void)alertWeightOver;
- (void)requreyMe3array; //:(NSString *)searchText;
- (void)viewDesign;

- (void)padE2refresh:(NSInteger)iRow;
@end

@implementation E3viewController
{
@private
	//E1				*Re1selected;  // grandParent: 常にセットされる
	//NSInteger		PiFirstSection;  // E2から呼び出されたとき頭出しするセクション viewWillAppear内でジャンプ後、(-1)にする。
	//NSInteger		PiSortType;		// (-1)Group  (0〜)Sort list.
	//BOOL			PbSharePlanList;	// SharePlan プレビューモード
	
	//----------------------------------------------viewDidLoadでnil, dealloc時にrelese
	//NSAutoreleasePool	*RautoPool;		// [0.3]autorelease独自解放のため
	NSMutableArray		*RaE2array;			//[1.0.2]E2から受け取るのではなく、ここで生成するようにした。
	NSMutableArray		*RaE3array;
	//----------------------------------------------Owner移管につきdealloc時のrelese不要
	UIPopoverController*	Mpopover;
	NSIndexPath*				MindexPathEdit;	//[1.1]ポインタ代入注意！copyするように改善した。
	UIToolbar*					Me2toolbar;
	//----------------------------------------------assign
	AppDelegate *appDelegate_;
	NSIndexPath		*MpathClip;					//[1.1]ポインタ代入注意！copyするように改善した。
	NSIndexPath	  *MindexPathActionDelete;	//[1.1]ポインタ代入注意！copyするように改善した。
	//BOOL MbFirstOne;
	//BOOL MbOptShouldAutorotate;
	BOOL MbAzOptTotlWeightRound;
	BOOL MbAzOptShowTotalWeight;
	BOOL MbAzOptShowTotalWeightReq;
	BOOL MbAzOptItemsGrayShow;
	BOOL MbAzOptItemsQuickSort;
	BOOL MbAzOptCheckingAtEditMode;
	BOOL MbAzOptSearchItemsNote;
	BOOL MbClipPaste;
	CGPoint		McontentOffsetDidSelect; // didSelect時のScrollView位置を記録
}
@synthesize  Re1selected;
@synthesize  PiFirstSection;
@synthesize  PiSortType;
@synthesize PbSharePlanList;



#pragma mark - Delegate

- (void)refreshE3view
{
	if (MindexPathEdit)
	{
		[self requreyMe3array];//Add行を読む込む為に必要
		
		//NSArray* ar = [NSArray arrayWithObject:MindexPathEdit];
		//[self.tableView reloadRowsAtIndexPaths:ar withRowAnimation:NO];	//【Tips】1行だけリロードする
		//[1.0.6]上の1行再表示では、セクションヘッダにある重量が更新されない不具合あり。
		
		//[1.0.6]【Tips】「reloadData＆復元」方式
		//CGPoint po = self.tableView.contentOffset;	//現在のスクロール位置を記録
		//[self.tableView reloadData];
		//self.tableView.contentOffset = po;		//スクロール位置を復元
		
		//[1.0.6]【Tips】セクション単位でリロード
		//NSIndexSet* iset = [NSIndexSet indexSetWithIndex:MindexPathEdit.section];
		//[self.tableView reloadSections:iset withRowAnimation:NO]; //【Tips】セクション単位でリロードする
		
		//[1.0.6]【Tips】結局、これが一番良い。 ＜＜行位置変わらず、表示の乱れも無い
		[self.tableView reloadData];
		// 左側 E2 再描画
		[self padE2refresh:MindexPathEdit.section];
	}
	else {
		[self.tableView reloadData];
		// 左側 E2 再描画
		[self padE2refresh:(-1)];
	}
}


#pragma mark - View lifecicle

// UITableViewインスタンス生成時のイニシャライザ　viewDidLoadより先に1度だけ通る
- (id)initWithStyle:(UITableViewStyle)style 
{
	self = [super initWithStyle:UITableViewStylePlain];
	if (self) {
		// 初期化成功
		appDelegate_ = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		RaE3array = nil;
		PbSharePlanList = NO;
	}
	return self;
}

// IBを使わずにviewオブジェクトをプログラム上でcreateするときに使う（viewDidLoadは、nibファイルでロードされたオブジェクトを初期化するために使う）
- (void)loadView
{	//【Tips】ここでaddSubviewするオブジェクトは全てautoreleaseにすること。メモリ不足時には自動的に解放後、改めてここを通るので、初回同様に生成するだけ。
	[super loadView];

	if (appDelegate_.app_is_iPad) {
		if (PbSharePlanList) {
			self.contentSizeForViewInPopover = GD_POPOVER_SIZE;
			self.navigationController.toolbarHidden = YES;	// ツールバー不要
			MbAzOptItemsGrayShow = YES; //グレー全表示
			return;  // 以下不要
		} else {
			//Popover表示なし  self.contentSizeForViewInPopover = CGSizeMake(360, 600);
		}
	}

	if (PbSharePlanList==NO) {
		// Set up Right [Edit] buttons.
		self.navigationItem.rightBarButtonItem = self.editButtonItem;
		self.tableView.allowsSelectionDuringEditing = YES;
	}
	
	if (appDelegate_.app_is_iPad) {
		if (Me2toolbar==nil) {
			Me2toolbar = [[UIToolbar alloc] init];
			
			//[Me2toolbar setItems: [NSArray array]];
			UIBarButtonItem* buFlexible = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
			
			UIBarButtonItem* buFixed = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
			
			NSString* str;
			if (30<[self.title length]) {
				str = [self.title substringToIndex:30];	//loadView以降でしかセットされない
			} else {
				str = self.title;
			}
			UIBarButtonItem* buTitle = [[UIBarButtonItem alloc] initWithTitle:str style:UIBarButtonItemStylePlain target:nil action:nil];
			
			NSMutableArray* buttons = [[NSMutableArray alloc] initWithObjects:
									   buFixed, buFlexible, buTitle, buFlexible, nil];
			
			if (appDelegate_.padRootVC.popoverButtonItem) {
				appDelegate_.padRootVC.popoverButtonItem.title = NSLocalizedString(@"Index button", nil);
				[buttons insertObject:appDelegate_.padRootVC.popoverButtonItem atIndex:1]; //この位置は、showPopoverButtonItemなどと一致させること
			}
			
			Me2toolbar.barStyle = UIBarStyleDefault;
			[Me2toolbar setItems:buttons animated:NO];
			[Me2toolbar sizeToFit];
			//[buttons release];
			self.navigationItem.titleView = Me2toolbar;
		}
	} else {
		// Set up NEXT Left [Back] buttons.
		self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]
												  initWithTitle:NSLocalizedString(@"Back", nil)
												  style:UIBarButtonItemStylePlain  
												  target:nil  action:nil];
	}
	
	// Search Bar
	UISearchBar *sb = [[UISearchBar alloc] initWithFrame:CGRectMake(0,0, self.tableView.bounds.size.width,0)];
	sb.delegate = self;
	[sb sizeToFit];
	sb.showsCancelButton = YES;
	self.tableView.tableHeaderView = sb; 
	//[sb release];
	
	// ここで参照しているため。 基本的には、viewWillAppearで取得すること
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	MbAzOptItemsGrayShow = [defaults boolForKey:GD_OptItemsGrayShow];
	//MbAzOptItemsQuickSort = [defaults boolForKey:GD_OptItemsQuickSort];  [1.0.3]廃止
	MbAzOptItemsQuickSort = NO;
	
	// Tool Bar Button
	UIBarButtonItem *buFlex = [[UIBarButtonItem alloc] 
								initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace  target:nil action:nil];
	UIBarButtonItem *buSearch = [[UIBarButtonItem alloc] 
								 initWithBarButtonSystemItem:UIBarButtonSystemItemSearch  
								  target:self action:@selector(azSearchBar)];
	// セグメントが回転に対応せず不具合（高さが変わる）発生するため、ボタンに戻した。
	UIImage *img;
	if (MbAzOptItemsGrayShow) {
		img = [UIImage imageNamed:@"Icon16-ItemGrayShow.png"]; // Gray Show
	} else {
		img = [UIImage imageNamed:@"Icon16-ItemGrayHide.png"]; // Gray Hide
	}
	UIBarButtonItem *buGray = [[UIBarButtonItem alloc] initWithImage:img
																style:UIBarButtonItemStylePlain
																target:self 
															   action:@selector(azItemsGrayHide:)];
	UIBarButtonItem *buRefresh = [[UIBarButtonItem alloc] 
								  initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
								   target:self action:@selector(azReflesh)];
	NSArray *aArray = [NSArray arrayWithObjects:  buGray, buFlex, buRefresh, buFlex, buSearch, nil];
	[self setToolbarItems:aArray animated:YES];
}

- (void)viewDidLoad 
{
	[super viewDidLoad];
	// 背景テクスチャ・タイルペイント
	//self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Tx-Back"]];

	// listen to our app delegates notification that we might want to refresh our detail view
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshAllViews:) name:NFM_REFRESH_ALL_VIEWS
											   object:[[UIApplication sharedApplication] delegate]];
}

- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];

	// 画面表示に関係する Option Setting を取得する
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	MbAzOptTotlWeightRound = [defaults boolForKey:GD_OptTotlWeightRound]; // YES=四捨五入 NO=切り捨て
	MbAzOptShowTotalWeight = [defaults boolForKey:GD_OptShowTotalWeight];
	MbAzOptShowTotalWeightReq = [defaults boolForKey:GD_OptShowTotalWeightReq]; // [0.3]Fix:抜けていた
	MbAzOptCheckingAtEditMode = [defaults boolForKey:GD_OptCheckingAtEditMode];
	MbAzOptSearchItemsNote = [defaults boolForKey:GD_OptSearchItemsNote];
	
	//self.title = ;　呼び出す側でセット済み。　変化させるならばココで。
	
	static int siSortType = (-99); //Pad対応のため必要になった。
	if (PiSortType==(-9)) {	// (-9)E3初期化（リロード＆再描画、セクション0表示）
		PiSortType = (-1);
		[self requreyMe3array];
	}
	else if (RaE3array && siSortType==PiSortType && 0<=PiSortType && MbAzOptItemsQuickSort==NO) {
		// 読み込み(ソート)せずに、既存テーブルビューを更新します。
		[self.tableView reloadData];  // これがないと、次のセクションスクロールでエラーになる
	}
	else {
		[self requreyMe3array];
	}
	siSortType = PiSortType;
	
	// 指定位置までテーブルビューの行をスクロールさせる初期処理　＜＜レコードセット後でなければならないので、この位置になった＞＞
	if (0<=PiFirstSection && PiFirstSection < [RaE3array count]) 
	{
		if (0<=PiSortType) PiFirstSection = 0; // SortListならば常に0のみ
		if (0 < [[RaE3array objectAtIndex:PiFirstSection] count]) 
		{ // Sample表示のときAdd行が無いので回避しないとエラー発生する
			NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:PiFirstSection];
			[self.tableView scrollToRowAtIndexPath:indexPath 
								  atScrollPosition:UITableViewScrollPositionTop animated:NO];  // 実機検証結果:NO
		}
		PiFirstSection = (-1); //クリア
	}
	else if (0 < McontentOffsetDidSelect.y) {
		// app.Me3dateUse=nil のときや、メモリ不足発生時に元の位置に戻すための処理。
		// McontentOffsetDidSelect は、didSelectRowAtIndexPath にて記録している。
		self.tableView.contentOffset = McontentOffsetDidSelect;
	}
	else {
		[self viewDesign]; // cell生成の後
		[self.tableView flashScrollIndicators]; // Apple基準：スクロールバーを点滅させる
	}
}

// ビューが最後まで描画された後やアニメーションが終了した後にこの処理が呼ばれる　＜＜魅せる処理をする＞＞
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	
	if (appDelegate_.app_is_iPad) {
		//loadViewの設定優先　[self.navigationController setToolbarHidden:NO animated:animated]; // ツールバー表示する
	} else {
		if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) { // ヨコ
			[self.navigationController setToolbarHidden:YES animated:animated]; // ツールバー消す
		} else {
			[self.navigationController setToolbarHidden:NO animated:animated]; // ツールバー表示する
		}
	}
	
	[self.tableView flashScrollIndicators]; // Apple基準：スクロールバーを点滅させる

	if (appDelegate_.app_is_Ad) {
		// 各viewDidAppear:にて「許可/禁止」を設定する
		[appDelegate_ AdRefresh:NO];	//広告禁止
	}
}

- (void)padE2refresh:(NSInteger)iRow
{
	UINavigationController* MnaviLeftE2 = [appDelegate_.mainSVC.viewControllers objectAtIndex:0]; //[0]
	if ([[MnaviLeftE2 visibleViewController] isMemberOfClass:[E2viewController class]])
	{	// E2 既存
		E2viewController* e2vc = (E2viewController*)[MnaviLeftE2 visibleViewController];
		[e2vc viewWillAppear:YES]; // .contentOffset により位置再現している
		if (0 <= iRow) 
		{
			NSIndexPath* idx = [NSIndexPath indexPathForRow:iRow inSection:0];
		/*	// 頭出し
			//レシーバに表示されている(可視可能な)行のインデックスパスを配列で返す。
			NSArray* ar = [e2vc.tableView indexPathsForVisibleRows];
			if ([ar indexOfObject:idx]==NSNotFound) 
			{	// idxセルが見えない状態なので、見える位置までスクロールする
				@try {
					[e2vc.tableView scrollToRowAtIndexPath:idx
										  atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
				}
				@catch (NSException *exception) {
					NSLog(@"E2.refresh: ip.section=%d : error %@ : %@\n", 
						  (int)idx.row, [exception name], [exception reason]);
				}
			}*/
			// E2更新セルを点滅させる
			[e2vc.tableView selectRowAtIndexPath:idx animated:YES 
								  scrollPosition:UITableViewScrollPositionNone];
			[e2vc.tableView deselectRowAtIndexPath:idx animated:YES];
		}
	}
}


- (void)requreyMe3array		//:(NSString *)searchText
{
	//[1.0.2]
	if (RaE2array) {
		//[RaE2array release], 
		RaE2array = nil;
	}
	RaE2array = [[NSMutableArray alloc] initWithArray:[Re1selected.childs allObjects]];
	if ([RaE2array count] <= 0) return;  // NoGroup
	// Sorting
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"row" ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:&sortDescriptor count:1];
	[RaE2array sortUsingDescriptors:sortDescriptors];
	//[sortDescriptor release];
	//[sortDescriptors release];
	
	
	NSString *zSearchText = nil;
	if (self.tableView.tableHeaderView) {
		UISearchBar *sb = (UISearchBar *)self.tableView.tableHeaderView;
		if (sb.text.length == 0)
			zSearchText = nil;
		else 
			zSearchText = sb.text;
	}
	
	NSMutableArray *muE3arry = [[NSMutableArray alloc] init];
	
	if (PiSortType < 0) {
		// セクション(Group)別リスト
		for (E2 *e2obj in RaE2array) 
		{
			//---------------------------------------------------------------------------- E3 Section
			// SELECT & ORDER BY　　テーブルの行番号を記録した属性"row"で昇順ソートする
			NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"row" ascending:YES];
			NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:&sortDescriptor count:1];
			
			NSMutableArray *muSection = [[NSMutableArray alloc] init];
			BOOL bE3Add = NO;
			if (zSearchText == nil) {
				// All Objects
				// 選択中の E2(e2selected) の子となる E3(e2selected.childs) を抽出する。
				[muSection setArray:[e2obj.childs allObjects]];
				for (E3 *e3obj in muSection) {
					if ([e3obj.need integerValue] == (-1)) { // Add専用行
						bE3Add = YES;
						break;
					}
				}
			}
			else {
				// Search 抽出
				for (E3 *e3obj in e2obj.childs) {
					if ([e3obj.need integerValue] == (-1)) { // Add専用行
						bE3Add = YES;
					} else {											// options:大文字小文字を区別しない
						NSRange rng = [e3obj.name rangeOfString:zSearchText options:NSCaseInsensitiveSearch];
						if (rng.location != NSNotFound) {
							[muSection addObject:e3obj]; // searchText を含むならば追加
						}
						else if (MbAzOptSearchItemsNote) { // Noteまで検索する
							NSRange rng = [e3obj.note rangeOfString:zSearchText options:NSCaseInsensitiveSearch];
							if (rng.location != NSNotFound) {
								[muSection addObject:e3obj]; // searchText を含むならば追加
							}
						}
					}
				}
			}
			
			if (!bE3Add && PbSharePlanList==NO) {
				//(V0.4)Add専用 E3 なしにつき、追加する
				E3 *e3obj = [NSEntityDescription insertNewObjectForEntityForName:@"E3"
														  inManagedObjectContext:Re1selected.managedObjectContext];
				//e3obj.name = GD_ADD_E3_NAME; //(V0.4)特殊レコード：Add行
				e3obj.need = [NSNumber numberWithInt:(-1)];  //(-1)Add行であることを示す専用値
				e3obj.row = [NSNumber numberWithInteger:[e2obj.childs count]];
				e3obj.parent = e2obj;
				[muSection addObject:e3obj];
			}
			// 並べ替えを実行してlistContentに格納します。
			[muSection sortUsingDescriptors:sortDescriptors]; // NSMutableArray内ソート　NSArrayはダメ
			[muE3arry addObject:muSection];  // 二次元追加　addObjectsFromArray:にすると同次元になってしまう。
			//[muSection release];
			//[sortDescriptors release];
			//[sortDescriptor release];
		}
		if (PbSharePlanList==NO) {
			// SAVE : 変更あれば保存する		Bug:Add行が通常行のように表示される-->Fix[1.1.0]
			NSError *error = nil;
			if ([Re1selected.managedObjectContext hasChanges] && ![Re1selected.managedObjectContext save:&error]) {
				// Handle error.
				NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
				assert(NO); //DEBUGでは落とす
			} 
		}
	}
	else {
		// 全体ソートリスト　＜＜セクション[0]に全アイテムを入れてソートする＞＞
		NSMutableArray *muSect0 = nil;
		for (E2 *e2obj in RaE2array) {
			//---------------------------------------------------------------------------- E3 Section
			// 選択中の E2(e2obj) の子となる E3(e2obj.childs) を抽出する。
			//NSMutableArray *muSection = [[NSMutableArray alloc] initWithArray:[e2obj.childs allObjects]];
			NSMutableArray *muSection = [[NSMutableArray alloc] init];
			if (zSearchText == nil) {
				// All Objects
				// 選択中の E2(e2selected) の子となる E3(e2selected.childs) を抽出する。
				[muSection setArray:[e2obj.childs allObjects]];
			}
			else {
				// Search 抽出
				for (E3 *e3obj in e2obj.childs) {
					if ([e3obj.need integerValue] == (-1)) { // Add専用行
						// Throw
					} else {											// options:大文字小文字を区別しない
						NSRange rng = [e3obj.name rangeOfString:zSearchText options:NSCaseInsensitiveSearch];
						if (rng.location != NSNotFound) {
							[muSection addObject:e3obj]; // searchText を含むならば追加
						}
						else if (MbAzOptSearchItemsNote) { // Noteまで検索する
							NSRange rng = [e3obj.note rangeOfString:zSearchText options:NSCaseInsensitiveSearch];
							if (rng.location != NSNotFound) {
								[muSection addObject:e3obj]; // searchText を含むならば追加
							}
						}
					}
				}
			}
			
			if (muSect0 == nil) {
				[muE3arry addObject:muSection];  // Section[0]を新たに追加
				muSect0 = [muE3arry objectAtIndex:0]; // Section[0]のArray
			} else {
				[muSect0 addObjectsFromArray:muSection]; // Section[0]のArray末尾に追加
			}
			//[muSection release];
			//(V0.4) ソートモードではAdd行なし
		}
		// SELECT & ORDER BY　　テーブルの行番号を記録した属性"row"で昇順ソートする
		// Sort条件セット
		NSString *zSortKey;
		BOOL bSortAscending;
		switch (PiSortType) {
			case 0:
				zSortKey = @"lack";   //NSLocalizedString(@"Sort0key", nil);
				bSortAscending = NO;  //[NSLocalizedString(@"Sort0ascending", nil) isEqualToString:@"YES"];
				break;
			case 1:
				zSortKey = @"weightLack";  //NSLocalizedString(@"Sort1key", nil);
				bSortAscending = NO;       //[NSLocalizedString(@"Sort1ascending", nil) isEqualToString:@"YES"];
				break;
			case 2:
				zSortKey = @"weightStk";  //NSLocalizedString(@"Sort2key", nil);
				bSortAscending = NO;      //[NSLocalizedString(@"Sort2ascending", nil) isEqualToString:@"YES"];
				break;
				//			case 3:
				//				zSortKey = @"weightNed";  //NSLocalizedString(@"Sort3key", nil);
				//				bSortAscending = NO;      //[NSLocalizedString(@"Sort3ascending", nil) isEqualToString:@"YES"];
				//				break;
			default:
				zSortKey = @"row";
				bSortAscending = YES;
				break;
		}
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:zSortKey ascending:bSortAscending];
		NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:&sortDescriptor count:1];
		// 並べ替えを実行
		[muSect0 sortUsingDescriptors:sortDescriptors]; // muE3arry[0]をソートしていることになる
		//[sortDescriptor release];
		//[sortDescriptors release];
	}
	
	if (RaE3array != muE3arry) {
		//[muE3arry retain];	//先に確保
		//[RaE3array release];	//その後解放
		RaE3array = muE3arry;
	}
	//[muE3arry release];
	
	// テーブルビューを更新します。
    [self.tableView reloadData];  // これがないと、次のセクションスクロールでエラーになる
}


// この画面が非表示になる直前に呼ばれる
- (void)viewWillDisappear:(BOOL)animated 
{
	if (appDelegate_.app_is_iPad) {
		if ([Mpopover isPopoverVisible]) { //[1.0.6-Bug01]戻る同時タッチで落ちる⇒強制的に閉じるようにした。
			[Mpopover dismissPopoverAnimated:animated];
		}
		// 左側のＥ２を閉じる
		if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) 
		{	// ヨコでＥ２が表示されている場合　　＜＜＜タテでＥ２が隠れているとき処理すると落ちる --> Ｅ２表示時に処理している＞＞＞
			UINavigationController* navLeft = [appDelegate_.mainSVC.viewControllers objectAtIndex:0]; //[0]
			[navLeft popToRootViewControllerAnimated:animated];  // PadRootVC
		}
	}
	[super viewWillDisappear:animated];
}


#pragma mark  View Rotate

// 回転サポート
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if (appDelegate_.app_is_iPad) {
		return YES;  // 現在の向きは、self.interfaceOrientation で取得できる
	} else {
		//[0.8.2]viewWillAppearより先に通るためAppDelegate広域参照にした。
		if (appDelegate_.AppShouldAutorotate==NO) {
			// 回転禁止にしている場合
			[self.navigationController setToolbarHidden:NO animated:YES]; // ツールバー表示する
			if (interfaceOrientation == UIInterfaceOrientationPortrait)
			{ // 正面（ホームボタンが画面の下側にある状態）
				return YES; // この方向だけ常に許可する
			}
			return NO; // その他、禁止
		}
		
		// 回転許可
		if (UIInterfaceOrientationIsPortrait(interfaceOrientation))
		{	// タテ
			[self.navigationController setToolbarHidden:NO animated:YES]; // ツールバー表示する
		} else {
			[self.navigationController setToolbarHidden:YES animated:YES]; // ツールバー消す
		}
		return YES;  // 現在の向きは、self.interfaceOrientation で取得できる
	}
}

// shouldAutorotateToInterfaceOrientation で YES を返すと、回転開始時に呼び出される
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation 
								duration:(NSTimeInterval)duration
{
	// 広告非表示でも回転時に位置調整しておく必要あり ＜＜現れるときの開始位置のため＞＞
	[appDelegate_ AdViewWillRotate:toInterfaceOrientation];
}

// 回転した後に呼び出される
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{	// Popoverの位置を調整する　＜＜UIPopoverController の矢印が画面回転時にターゲットから外れてはならない＞＞
	if ([Mpopover isPopoverVisible]) {
		if (MindexPathEdit) { 
			@try {		//何度かここでSIGABRT発生、MindexPathEdit不正だと思うが原因不明につき @try 回避
							//[1.1]原因は、retainしていないポインタを代入していたことだと思う。　代入時に copy した。
				//NSLog(@"MindexPathEdit=%@", MindexPathEdit);
				[self.tableView scrollToRowAtIndexPath:MindexPathEdit 
									  atScrollPosition:UITableViewScrollPositionMiddle animated:NO]; // YESだと次の座標取得までにアニメーションが終了せずに反映されない
				CGRect rc = [self.tableView rectForRowAtIndexPath:MindexPathEdit];
				rc.origin.x += (rc.size.width/2 - 100);	//(-100)ヨコのとき幅が縮小されてテンキーが欠けるため
				rc.size.width = 1;
				[Mpopover presentPopoverFromRect:rc  inView:self.tableView 
						permittedArrowDirections:UIPopoverArrowDirectionLeft  animated:YES];
			}
			@catch (NSException *exception) {
				assert(NO);
				[Mpopover dismissPopoverAnimated:YES];
			}
		} else {
			// 回転後のアンカー位置が再現不可なので閉じる
			[Mpopover dismissPopoverAnimated:YES];
			//[Mpopover release], Mpopover = nil;
		}
	}
}

- (void)viewDesign
{	// 回転によるリサイズ
	// Search Bar
	[self.tableView.tableHeaderView sizeToFit];
}


#pragma mark View Sub

- (void)azSettingView
{
	SettingTVC *vi = [[SettingTVC alloc] init];
	[vi setHidesBottomBarWhenPushed:YES]; // 現在のToolBar状態をPushした上で、次画面では非表示にする
	[self.navigationController pushViewController:vi animated:YES];
	//[vi release];
}

- (void)e3detailView:(NSIndexPath *)indexPath 
{
	if (PbSharePlanList) return;  //サンプルモードにつき
	if (appDelegate_.app_is_iPad) {
		if ([Mpopover isPopoverVisible]) return; //[1.0.6-Bug01]同時タッチで落ちる⇒既に開いておれば拒否
	}

	// E3detailTVC へドリルダウン
	E3detailTVC *e3detail = [[E3detailTVC alloc] init];
	// 以下は、E3detailTVCの viewDidLoad 後！、viewWillAppear の前に処理されることに注意！
	e3detail.title = NSLocalizedString(@"Edit Item", nil);
	e3detail.RaE2array = RaE2array;
	e3detail.RaE3array = RaE3array;
	
	E3 *e3obj = [[RaE3array objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	if ([e3obj.need integerValue] == (-1)) { //(V0.4)Add
		// Add Item
		// ContextにE3ノードを追加する　                               ＜＜Sortのとき、Pe2selected==nil である＞＞
		e3detail.Re3target = [NSEntityDescription insertNewObjectForEntityForName:@"E3"
														   inManagedObjectContext:Re1selected.managedObjectContext];
		e3detail.PiAddGroup = indexPath.section; // Add mode
		e3detail.PiAddRow = [e3obj.row integerValue];
		//
		e3detail.Re3target.need = [NSNumber numberWithInteger:1]; //[1.0.6]初期値1個にした。
	}
	else {
		// Edit Item
		e3detail.Re3target = e3obj;
		e3detail.PiAddGroup = (-1); // Edit mode
	}
	e3detail.PbSharePlanList = PbSharePlanList;
	
	if (appDelegate_.app_is_iPad) {
		//[Mpopover release], Mpopover = nil;
		//Mpopover = [[PadPopoverInNaviCon alloc] initWithContentViewController:e3detail];
		UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:e3detail];
		Mpopover = [[UIPopoverController alloc] initWithContentViewController:nc];
		//[nc release];
		Mpopover.delegate = self;	// popoverControllerDidDismissPopover:を呼び出してもらうため
		//MindexPathEdit = indexPath; Bug!危険　　　下記FIX
		//[MindexPathEdit release], 
		MindexPathEdit = [indexPath copy];
		CGRect rc = [self.tableView rectForRowAtIndexPath:indexPath];
		rc.origin.x += (rc.size.width/2 - 100);	//(-100)ヨコのとき幅が縮小されてテンキーが欠けるため
		rc.size.width = 1;
		[Mpopover presentPopoverFromRect:rc
								  inView:self.tableView  permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
		e3detail.selfPopover = Mpopover;  //[Mpopover release]; //(retain)  内から閉じるときに必要になる
		e3detail.delegate = self;		// refresh callback
	} else {
		[e3detail setHidesBottomBarWhenPushed:YES]; // 現在のToolBar状態をPushした上で、次画面では非表示にする
		[self.navigationController pushViewController:e3detail animated:YES];
	}
	//[e3detail release];
}


#pragma mark View Unload

- (void)unloadRelease {	// dealloc, viewDidUnload から呼び出される
	//【Tips】loadViewでautorelease＆addSubviewしたオブジェクトは全てself.viewと同時に解放されるので、ここでは解放前の停止処理だけする。
	//【Tips】デリゲートなどで参照される可能性のあるデータなどは破棄してはいけない。
	// ただし、他オブジェクトからの参照無く、viewWillAppearにて生成されるものは破棄可能
	
	NSLog(@"--- unloadRelease --- E3viewController");
	//[RaE3array release],	
	RaE3array = nil;
	
	if (appDelegate_.app_is_iPad) {
		self.navigationItem.titleView = nil;  //これなしにE1へ戻ると落ちる
		//[Me2toolbar release], 
		Me2toolbar = nil;
	}
}

- (void)viewDidUnload 
{	// メモリ不足時、裏側にある場合に呼び出されるので、viewDidLoadで生成したObjを解放する。
	//NSLog(@"--- viewDidUnload ---"); 
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[self unloadRelease];
	[super viewDidUnload];
	// この後に loadView ⇒ viewDidLoad ⇒ viewWillAppear がコールされる
}

- (void)dealloc    // 生成とは逆順に解放するのが好ましい
{
	[self unloadRelease];

	if (appDelegate_.app_is_iPad) {
		Mpopover.delegate = nil;	//[1.0.6-Bug01]戻る同時タッチで落ちる⇒delegate呼び出し強制断
		//[MindexPathEdit release], 
		MindexPathEdit = nil;
	}
	//[MindexPathActionDelete release], 
	MindexPathActionDelete = nil;
	//[MpathClip release], 
	MpathClip = nil;
	//--------------------------------@property (retain)
	//[RaE2array release],	
	RaE2array = nil;
	//[Re1selected release],	
	Re1selected = nil;
	//[super dealloc];
}


#pragma mark - iCloud
- (void)refreshAllViews:(NSNotification*)note 
{	// iCloud-CoreData に変更があれば呼び出される
    //if (note) {
		[self.tableView reloadData];
		//[self viewWillAppear:YES];
    //}
}


#pragma mark - Action

- (void)azReflesh
{
	if (MbAzOptItemsQuickSort == NO) {
		MbAzOptItemsQuickSort = YES; // viewWillAppear内でデータ取得(ソート)を通るようにするため
		// 再表示: データ再取得（ソート）して表示する
		[self viewWillAppear:YES];
		MbAzOptItemsQuickSort = NO; // 戻しておく
	}
}

- (void)azItemsGrayHide: (UIBarButtonItem *)sender 
{
	MbAzOptItemsGrayShow = !(MbAzOptItemsGrayShow); // 反転
	
	if (MbAzOptItemsGrayShow) {
		sender.image = [UIImage imageNamed:@"Icon16-ItemGrayShow.png"]; // Gray Show
	} else {
		sender.image = [UIImage imageNamed:@"Icon16-ItemGrayHide.png"]; // Gray Hide
	}
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:MbAzOptItemsGrayShow forKey:GD_OptItemsGrayShow];
	
	// 再表示 -------------------------------------------------------------------
	// 表示行数が変化するための処理　　 表示最上行を取得する
	NSArray *arCells = [self.tableView indexPathsForVisibleRows]; // 現在見えているセル群
	NSIndexPath *topPath = nil;
	for (NSInteger i=0 ; i<[arCells count] ; i++) {
		topPath = [arCells objectAtIndex:i]; 
		if (topPath.row < [[RaE3array objectAtIndex:topPath.section] count]) {
			E3 *e3obj = [[RaE3array objectAtIndex:topPath.section] objectAtIndex:topPath.row];
			if ([e3obj.need intValue] != 0) {  // +Add行は、.need=(-1)にしている。
				// 必要数が0でない「Grayでない」セル発見
				break;
			}
		}
	}

	// 再表示
	//[self viewWillAppear:NO];
	[self.tableView reloadData];
	
	// 元の最上行を再現する
	if (topPath) [self.tableView scrollToRowAtIndexPath:topPath 
									   atScrollPosition:UITableViewScrollPositionTop animated:YES];  
}


- (void)azSearchBar
{
	// Serch Bar にフォーカスを当てる　（このときスクロールはしないので下記のスクロール処理が必要）
	[self.tableView.tableHeaderView becomeFirstResponder];
	// Search Bar が見えるように最上行を表示する
	if (RaE3array && 0 < [RaE3array count] && 0 < [[RaE3array objectAtIndex:0] count]) { // ERROR対策
		NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
		[self.tableView scrollToRowAtIndexPath:indexPath 
							  atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
	}
}

#pragma mark - <UISearchBarDelegate>

// リアルタイム抽出：1文字入力の都度、呼ばれる
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	[self requreyMe3array];  //:searchText];
//	MzSearchText = searchText;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	searchBar.text = @"";
	[searchBar resignFirstResponder]; // Hiddon Keyboard
	[self requreyMe3array];
}


#pragma mark - TableView - Cell

- (void)cellButtonCheck: (UIButton *)button 
{
	if (MbAzOptCheckingAtEditMode && !self.editing) return; // 編集時のみ許可
	
	E3 *e3obj = nil;
	NSIndexPath *checkPath;  // 後半でCheckセルだけ再描画するときに使用
	/*NG* 編集で行移動すると位置がずれるためダメ
	 NSUInteger iSec = button.tag / GD_SECTION_TIMES;
	 NSUInteger iRow = button.tag - (iSec * GD_SECTION_TIMES);
	 checkPath = [NSIndexPath indexPathForRow:iRow  inSection:iSec];
	 e3obj = [[RaE3array objectAtIndex:iSec] objectAtIndex:iRow];
	 */
	// 編集で行移動中にチェックしたときに対応するため、以下のように検索する必要がある。＜＜button.tagにindexPathを入れる方法は没＞＞
	// 現在表示されているセル群
	NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
	for (checkPath in visiblePaths) {
		UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:checkPath];
		if (cell.tag == TAG_CELL_ITEM) { // Add行を除外するため
			NSArray *aSub = [NSArray arrayWithArray:cell.contentView.subviews];
			//if (button == [aSub objectAtIndex:1]) {
			if ([aSub indexOfObject:button] != NSNotFound) { // 位置が変わるケースがあったので、こうした。
				//このbuttonが含まれるセル発見
				e3obj = [[RaE3array objectAtIndex:checkPath.section] objectAtIndex:checkPath.row];
				//AzLOG(@"cellButton -B- .row=%ld", (long)path.row);
				break;
			}
		}
	}
	if (e3obj == nil) return;
	if ([e3obj.need integerValue] <= 0)  return; // (-1)Add行 と (0)Gray を除くため
	
	NSInteger lStock  = [e3obj.stock integerValue];
	NSInteger lNeed   = [e3obj.need integerValue];
	NSInteger lWeight = [e3obj.weight integerValue];
	
	if (lStock < lNeed) {
		// OK
		//iStock++;		カウントアップは没。　将来的にはOption設定にするかも
		lStock = lNeed; // ワンタッチＯＫにした。
	} else {
		// Non
		lStock = 0;
	}
	
	if (lStock == [e3obj.stock integerValue] && lNeed == [e3obj.need integerValue]) return; //変化なし
	
	// ここで、Stock は Need 以下にしかならないからオーバーチェックは不要のはず。
	// しかし、今後の変更でNeedを超えるようになったとき忘れないように入れておく。
	//[0.2c]プラン総重量制限
	if (0 < lWeight) {  // longオーバーする可能性があるため商は求めない
		if (AzMAX_PLAN_WEIGHT / lWeight < lStock OR AzMAX_PLAN_WEIGHT / lWeight < lNeed) {
			[self alertWeightOver];
			return;
		}
	}
	
	// SAVE ----------------------------------------------------------------------
	[e3obj setValue:[NSNumber numberWithInteger:(lStock)] forKey:@"stock"];
	[e3obj setValue:[NSNumber numberWithInteger:(lNeed)] forKey:@"need"];
	
	[e3obj setValue:[NSNumber numberWithInteger:(lWeight*lStock)] forKey:@"weightStk"];
	[e3obj setValue:[NSNumber numberWithInteger:(lWeight*lNeed)] forKey:@"weightNed"];
	[e3obj setValue:[NSNumber numberWithInteger:(lNeed-lStock)] forKey:@"lack"]; // 不足数
	[e3obj setValue:[NSNumber numberWithInteger:(lWeight*(lNeed-lStock))] forKey:@"weightLack"]; // 不足重量
	
	NSInteger iNoGray = 0;
	if (0 < lNeed) iNoGray = 1;
	[e3obj setValue:[NSNumber numberWithInteger:iNoGray] forKey:@"noGray"]; // 有効(0<必要)アイテム
	
	NSInteger iNoCheck = 0;
	if (0 < lNeed && lStock < lNeed) iNoCheck = 1;
	[e3obj setValue:[NSNumber numberWithInteger:iNoCheck] forKey:@"noCheck"]; // 不足アイテム
	
	// E2 sum属性　＜高速化＞ 親sum保持させる
	E2 *e2obj = e3obj.parent;
	[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.noGray"] forKey:@"sumNoGray"];
	[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.noCheck"] forKey:@"sumNoCheck"];
	[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.weightStk"] forKey:@"sumWeightStk"];
	[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.weightNed"] forKey:@"sumWeightNed"];
	
	// E1 sum属性　＜高速化＞ 親sum保持させる
	E1 *e1obj = e2obj.parent;
	[e1obj setValue:[e1obj valueForKeyPath:@"childs.@sum.sumNoGray"] forKey:@"sumNoGray"];
	[e1obj setValue:[e1obj valueForKeyPath:@"childs.@sum.sumNoCheck"] forKey:@"sumNoCheck"];
	NSNumber *sumWeStk = [e1obj valueForKeyPath:@"childs.@sum.sumWeightStk"];
	NSNumber *sumWeNed = [e1obj valueForKeyPath:@"childs.@sum.sumWeightNed"];
	//[0.2c]プラン総重量制限
	if (AzMAX_PLAN_WEIGHT < [sumWeStk integerValue] OR AzMAX_PLAN_WEIGHT < [sumWeNed integerValue]) {
		[self alertWeightOver];
		return;
	}
	[e1obj setValue:sumWeStk forKey:@"sumWeightStk"];
	[e1obj setValue:sumWeNed forKey:@"sumWeightNed"];
	
	if (PbSharePlanList==NO) {
		// SAVE : e3edit,e2list は ManagedObject だから更新すれば ManagedObjectContext に反映されている
		NSError *err = nil;
		if (![e3obj.managedObjectContext save:&err]) {
			NSLog(@"Unresolved error %@, %@", err, [err userInfo]);
			//abort();
		}
	}
	
	// checkPath だけを再描画する
	//[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:checkPath] withRowAnimation:NO];
	//[1.0.6]上の1行再表示では、セクションヘッダにある重量が更新されない不具合あり。
	//NSIndexSet* iset = [NSIndexSet indexSetWithIndex:checkPath.section];
	//[self.tableView reloadSections:iset withRowAnimation:NO]; //セクション単位でリロードする
	//[1.0.6]【Tips】結局、これが一番良い。 ＜＜行位置変わらず、表示の乱れも無い
	[self.tableView reloadData];
	
	if (appDelegate_.app_is_iPad) {
		// 左側 E2 再描画
		[self padE2refresh:[e2obj.row integerValue]];
	}
}

//----------------------------------------------------------- Clip Board
- (BOOL)canBecomeFirstResponder {
	return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
	if (@selector(cut:) == action) {
		if (PbSharePlanList) return NO;
		assert(MpathClip.section < [RaE3array count]);
		assert(MpathClip.row < [[RaE3array objectAtIndex:MpathClip.section] count]);
		E3 *e3obj = [[RaE3array objectAtIndex:MpathClip.section] objectAtIndex:MpathClip.row];
		if (0 <= [e3obj.need integerValue]) return YES;
		return NO; // e3obj.need < 0 ならばAdd行であるのでCut無効
	}
	
	if (@selector(copy:) == action) return YES;
	
	if (@selector(paste:) == action) {
		if (PbSharePlanList) return NO;
		// クリップボード(clipE3objects) にE3があるか調べる
		if (0 < [appDelegate_.RaClipE3objects count]) return YES; // クリップあり
		return NO; // クリップボードが空なのでPaste無効
	}
	return NO;
}

- (void)cut:(id)sender {  // これはプロトコルとして予約されている
	AzLOG(@"--cut:--");
	assert(MpathClip);
	if ([RaE3array count] <= MpathClip.section) return;
	if ([[RaE3array objectAtIndex:MpathClip.section] count] <= MpathClip.row) return;
	
	// クリップボード(clipE3objects) 前処理
	if (MbClipPaste && 0 < [appDelegate_.RaClipE3objects count]) { // 未[Paste]ならばPUSHスタックするため
		// 1回でもPasteしたならば、先ずクリップをクリアする
		for (E3 *e3 in appDelegate_.RaClipE3objects) {
			if (e3.parent == nil) {
				// [Cut]されたE3なので削除する
				[Re1selected.managedObjectContext deleteObject:e3];
			}
		}
		[appDelegate_.RaClipE3objects removeAllObjects]; // 全て削除する
	}
	MbClipPaste = NO;
	//
	E3 *e3obj = [[RaE3array objectAtIndex:MpathClip.section] objectAtIndex:MpathClip.row];
	E2 *e2obj = e3obj.parent; // 後半のsum更新のため親E2を保持する
	e3obj.parent = nil; // リンクを切った状態で残す。Pasteできるようにするため。
	// e3obj をクリップボード(clipE3objects) へ追加する
	[appDelegate_.RaClipE3objects addObject:e3obj];
	
	[[RaE3array objectAtIndex:MpathClip.section] removeObjectAtIndex:MpathClip.row]; // TableViewCell削除
	// アニメーション付きで、MpathClip行をテーブルから削除する　＜＜表示だけの更新＞＞
	[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:MpathClip] withRowAnimation:UITableViewRowAnimationFade];
	// .row 更新
	for (NSInteger i = MpathClip.row ; i < [[RaE3array objectAtIndex:MpathClip.section] count] ; i++) {
		E3 *e3 = [[RaE3array objectAtIndex:MpathClip.section] objectAtIndex:i];
		e3.row = [NSNumber numberWithInteger:i];
	}
	
	
	//[Re1selected.managedObjectContext deleteObject:Me3objCopy] ここでは削除しない！
	
	// E2 sum属性　＜高速化＞ 親sum保持させる
	[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.noGray"] forKey:@"sumNoGray"];
	[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.noCheck"] forKey:@"sumNoCheck"];
	[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.weightStk"] forKey:@"sumWeightStk"];
	[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.weightNed"] forKey:@"sumWeightNed"];
	// E1 sum属性　＜高速化＞ 親sum保持させる
	E1 *e1obj = e2obj.parent;
	[e1obj setValue:[e1obj valueForKeyPath:@"childs.@sum.sumNoGray"] forKey:@"sumNoGray"];
	[e1obj setValue:[e1obj valueForKeyPath:@"childs.@sum.sumNoCheck"] forKey:@"sumNoCheck"];
	[e1obj setValue:[e1obj valueForKeyPath:@"childs.@sum.sumWeightStk"] forKey:@"sumWeightStk"];
	[e1obj setValue:[e1obj valueForKeyPath:@"childs.@sum.sumWeightNed"] forKey:@"sumWeightNed"];
	// Commit!
	[EntityRelation commit];
	[self.tableView reloadData];

	if (appDelegate_.app_is_iPad) {
		// 左側 E2 再描画  ＜＜未チェック数と重量を更新するため
		[self padE2refresh:MpathClip.section];
	}
}

- (void)copy:(id)sender {  // これはプロトコルとして予約されている
	AzLOG(@"--copy:--");
	assert(MpathClip);
	if ([RaE3array count] <= MpathClip.section) return;
	if ([[RaE3array objectAtIndex:MpathClip.section] count] <= MpathClip.row) return;
	
	// クリップボード(clipE3objects) 前処理
	if (MbClipPaste && 0 < [appDelegate_.RaClipE3objects count]) { // 未[Paste]ならばPUSHスタックするため
		// 1回でもPasteしたならば、先ずクリップをクリアする
		for (E3 *e3 in appDelegate_.RaClipE3objects) {
			if (e3.parent == nil) {
				// [Cut]されたE3なので削除する
				[Re1selected.managedObjectContext deleteObject:e3];
			}
		}
		[appDelegate_.RaClipE3objects removeAllObjects]; // 全て削除する
	}
	MbClipPaste = NO;
	//
	E3 *e3obj = [[RaE3array objectAtIndex:MpathClip.section] objectAtIndex:MpathClip.row];
	// e3obj をクリップボード(clipE3objects) へ追加する
	[appDelegate_.RaClipE3objects addObject:e3obj];
}

- (void)paste:(id)sender {  // これはプロトコルとして予約されている
	AzLOG(@"--paste:--");
	assert(MpathClip);
	if ([RaE3array count] <= MpathClip.section) return;
	if ([[RaE3array objectAtIndex:MpathClip.section] count] <= MpathClip.row) return;
	// 貼り付け先
	E3 *e3paste = [[RaE3array objectAtIndex:MpathClip.section] objectAtIndex:MpathClip.row];
	if (e3paste == nil) return;
	
	// クリップボード(clipE3objects) の末尾から e3clip を取り出す(POP)
	E3 *e3clip = [appDelegate_.RaClipE3objects lastObject]; // 最後のオブジェクト参照
	if (e3clip == nil) return; // クリップなし
	
	// MpathClip位置へ追加する
	E3 *e3new = [NSEntityDescription insertNewObjectForEntityForName:@"E3"
											  inManagedObjectContext:Re1selected.managedObjectContext];
	// Paste位置である e3paste から引用
	e3new.row = e3paste.row;
	e3new.parent = e3paste.parent;
	
	if ([e3clip.need integerValue] < 0) {
		//[0.5]e3clip==nil: 空行追加する  OR  < 0:Add行をCopyしたとき空行追加する
		e3new.noGray = [NSNumber numberWithInt:0];
		e3new.noCheck = [NSNumber numberWithInt:1];
	}
	else {
		// 内容は、e3clip から引用
		e3new.name = e3clip.name;
		e3new.note = e3clip.note;
		e3new.stock = e3clip.stock;
		e3new.need = e3clip.need;
		e3new.lack = e3clip.lack;
		e3new.noGray = e3clip.noGray;
		e3new.noCheck = e3clip.noCheck;
		e3new.weight = e3clip.weight;
		e3new.weightStk = e3clip.weightStk;
		e3new.weightNed = e3clip.weightNed;
		e3new.weightLack = e3clip.weightLack;
	}
	
	if (1 < [appDelegate_.RaClipE3objects count]) { // 最後の1個を残すため。それが次にCutやCopyしたものと置き換わる
		// クリップボード(clipE3objects) の末尾を削除し、参照(e3clip)を無効にする
		if (e3clip.parent == nil) {
			// [Cut]されたE3なので削除する
			[Re1selected.managedObjectContext deleteObject:e3clip];
		}
		[appDelegate_.RaClipE3objects removeLastObject]; // 末尾のオブジェクトを削除する
		e3clip = nil;
	}
	MbClipPaste = YES;
	//
	[[RaE3array objectAtIndex:MpathClip.section] insertObject:e3new atIndex:MpathClip.row];
	// アニメーション付きで、テーブルの MpathClip行へ追加する
	[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:MpathClip] withRowAnimation:UITableViewRowAnimationFade];
	// MpathClip.row+1 以下を更新する
	for (NSInteger i = MpathClip.row+1 ; i < [[RaE3array objectAtIndex:MpathClip.section] count] ; i++) {
		E3 *e3 = [[RaE3array objectAtIndex:MpathClip.section] objectAtIndex:i];
		e3.row = [NSNumber numberWithInteger:i];
	}
	// Paste先の E2 sum属性　＜高速化＞ 親sum保持させる
	E2 *e2obj = e3paste.parent;
	[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.noGray"] forKey:@"sumNoGray"];
	[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.noCheck"] forKey:@"sumNoCheck"];
	[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.weightStk"] forKey:@"sumWeightStk"];
	[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.weightNed"] forKey:@"sumWeightNed"];
	// E1 sum属性　＜高速化＞ 親sum保持させる
	E1 *e1obj = e2obj.parent;
	[e1obj setValue:[e1obj valueForKeyPath:@"childs.@sum.sumNoGray"] forKey:@"sumNoGray"];
	[e1obj setValue:[e1obj valueForKeyPath:@"childs.@sum.sumNoCheck"] forKey:@"sumNoCheck"];
	NSNumber *sumWeStk = [e1obj valueForKeyPath:@"childs.@sum.sumWeightStk"];
	NSNumber *sumWeNed = [e1obj valueForKeyPath:@"childs.@sum.sumWeightNed"];
	//[0.2c]プラン総重量制限
	if (AzMAX_PLAN_WEIGHT < [sumWeStk integerValue] OR AzMAX_PLAN_WEIGHT < [sumWeNed integerValue]) {
		[self alertWeightOver];
		return;
	}
	[e1obj setValue:sumWeStk forKey:@"sumWeightStk"];
	[e1obj setValue:sumWeNed forKey:@"sumWeightNed"];
	// Commit!
	[EntityRelation commit];
	[self.tableView reloadData];

	if (appDelegate_.app_is_iPad) {
		// 左側 E2 再描画  ＜＜未チェック数と重量を更新するため
		[self padE2refresh:MpathClip.section];
	}
}

- (void)cellButtonClip: (UIButton *)button 
{
	if (![self becomeFirstResponder]) return;
	
	//buClip.tag = indexPath.section * GD_SECTION_TIMES + indexPath.row;
	NSInteger iSection = button.tag / GD_SECTION_TIMES;
	NSInteger iRow = button.tag - (iSection * GD_SECTION_TIMES);
	//Bug//MpathClip = [NSIndexPath indexPathForRow:iRow inSection:iSection];
	//[MpathClip release], 
	MpathClip = [[NSIndexPath indexPathForRow:iRow inSection:iSection] copy];
	AzLOG(@"cellButtonClip .row=%ld", (long)iRow);
	
	CGRect minRect = [self.tableView rectForRowAtIndexPath:MpathClip]; // 指定したインデックスパスの行の描画領域を返す。
	//AzLOG(@"-1-minRect(%f,%f, %f,%f)", minRect.origin.x,minRect.origin.y,minRect.size.width,minRect.size.height);
	minRect.origin.x = minRect.size.width/2;
	minRect.origin.y += 15;
	minRect.size.width = 10;
	minRect.size.height = 10;
	//AzLOG(@"-2-minRect(%f,%f, %f,%f)", minRect.origin.x,minRect.origin.y,minRect.size.width,minRect.size.height);
	
	UIMenuController *menu = [UIMenuController sharedMenuController];
	[menu setMenuVisible:NO animated:YES];	// 表示中のものがあれば消す
	[menu setTargetRect:minRect inView:self.tableView];
	[menu setMenuVisible:YES animated:YES];	// 新しい位置に表示する
}

- (void)alertWeightOver
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"WeightOver",nil)
													 message:NSLocalizedString(@"WeightOver message",nil)
													delegate:nil 
										   cancelButtonTitle:nil 
										   otherButtonTitles:@"OK", nil];
	[alert show];
}



#pragma mark - TableView lifecicle

// TableView セクション数を応答
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return [RaE3array count];
}

// TableView セクションの行数を応答
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	NSInteger rows = [[RaE3array objectAtIndex:section] count];  // Add行を含む
	return rows;
}

// TableView セクション名を応答
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
	if (PiSortType < 0) {
		// Group E2以下の Sum(E3.weightStk) と Sum(E3.weightNed) の集計値を得ている。
		E2 *e2obj = [RaE2array objectAtIndex:section];
		double dWeightStk;
		double dWeightReq;
		if (MbAzOptShowTotalWeight) {
			long lWeightStk = [[e2obj valueForKeyPath:@"sumWeightStk"] longValue];
			if (MbAzOptTotlWeightRound) {
				// 四捨五入　＜＜ %.1f により小数第2位が丸められる＞＞ 
				dWeightStk = (double)lWeightStk / 1000.0f;
			} else {
				// 切り捨て                       ↓これで下2桁が0になる
				dWeightStk = (double)(lWeightStk / 100) / 10.0f;
			}
		}
		if (MbAzOptShowTotalWeightReq) {
			long lWeightReq = [[e2obj valueForKeyPath:@"sumWeightNed"] longValue];
			if (MbAzOptTotlWeightRound) {
				// 四捨五入　＜＜ %.1f により小数第2位が丸められる＞＞ 
				dWeightReq = (double)lWeightReq / 1000.0f;
			} else {
				// 切り捨て                       ↓これで下2桁が0になる
				dWeightReq = (double)(lWeightReq / 100) / 10.0f;
			}
		}
		
		NSString *zName = e2obj.name;
		if ([zName length]<=0) {
			zName = NSLocalizedString(@"(New Index)", nil);
		}

		if (MbAzOptShowTotalWeight && MbAzOptShowTotalWeightReq) {
			return [NSString stringWithFormat:@"%@  %.1f／%.1fKg", zName, dWeightStk, dWeightReq];
		} else if (MbAzOptShowTotalWeight) {
			return [NSString stringWithFormat:@"%@  %.1fKg", zName, dWeightStk];
		} else if (MbAzOptShowTotalWeightReq) {
			return [NSString stringWithFormat:@"%@  ／%.1fKg", zName, dWeightReq];
		} else {
			return [NSString stringWithFormat:@"%@", zName];
		}
	}
	else {
		switch (PiSortType) {
			case 0:
				return NSLocalizedString(@"SortLackQty",nil);
				break;
			case 1:
				return NSLocalizedString(@"SortLackWeight",nil);
				break;
			case 2:
				return NSLocalizedString(@"SortWeight",nil);
				break;
		}
	}
	return @"Err";
}

// セルの高さを指示する  ＜＜ [Gray Hide] 高さ0にする＞＞
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	E3 *e3obj = [[RaE3array objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	if (!MbAzOptItemsGrayShow && [e3obj.need integerValue] <= 0) {
		// (0)Gray行 (-1)Add行
		return 0; // Hide さらに cell をクリアにしている
		// さらに、canMoveRowAtIndexPath にて return NO; にする
	}
	else if (0 <= PiSortType && [e3obj.need integerValue]==(-1)) {	// .need=(-1) ⇒ Add行（位置自由になったため）
		return 0;  // ソートモード時、Add行を非表示
	}

	if (appDelegate_.app_is_iPad) {
		return 50;
	}
	return 44; // デフォルト：44ピクセル
}

// TableView 指定されたセルを生成＆表示
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	static NSString *zCellHiddon = @"CellHiddon";  // 高さ0非表示用セル
	static NSString *zCellItem = @"CellItem";
	static NSString *zCellItemEdit = @"CellItemEdit";
	static NSString *zCellAdd = @"CellAdd";
	static NSString *zCellAddEdit = @"CellAddEdit";
    UITableViewCell *cell = nil;

	// E3 Node Object
	E3 *e3obj = [[RaE3array objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	
	//if (indexPath.row < [[Me3array objectAtIndex:indexPath.section] count]) {
	if (!MbAzOptItemsGrayShow && [e3obj.need integerValue] <= 0) {
		// 高さ0非表示用セル　＜＜専用セルを作って高速化＞＞
		cell = [tableView dequeueReusableCellWithIdentifier:zCellHiddon];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
										   reuseIdentifier:zCellHiddon];
			cell.textLabel.text = @"";
			cell.detailTextLabel.text = @"";
			cell.imageView.image = nil;
			cell.accessoryType = UITableViewCellAccessoryNone;	// なし
			cell.showsReorderControl = NO; // Move禁止
		}
		return cell;
	}
	else if ([e3obj.need integerValue]==(-1)) {	//(V0.4)Add行セル  .need=(-1)
		if (0 <= PiSortType) 
		{ // ソートモード ならば非表示　（速度優先のため重複記述している）
			// 高さ0非表示用セル　＜＜専用セルを作って高速化＞＞
			cell = [tableView dequeueReusableCellWithIdentifier:zCellHiddon];
			if (cell == nil) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
											   reuseIdentifier:zCellHiddon];
				cell.textLabel.text = @"";
				cell.detailTextLabel.text = @"";
				cell.imageView.image = nil;
				cell.accessoryType = UITableViewCellAccessoryNone;	// なし
				cell.showsReorderControl = NO; // Move禁止
			}
			return cell;
		}
		// Addセル表示
		if (self.editing) {
			cell = [tableView dequeueReusableCellWithIdentifier:zCellAddEdit];
		} else {
			cell = [tableView dequeueReusableCellWithIdentifier:zCellAdd];
		}
		if (cell == nil) {
			if (self.editing) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault     // Default型
												   reuseIdentifier:zCellAddEdit];
			} else {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault     // Default型
												   reuseIdentifier:zCellAdd];
			}
			cell.tag = TAG_CELL_ADD;
			cell.textLabel.text = NSLocalizedString(@"New Goods",nil); // ここに追加

			if (appDelegate_.app_is_iPad) {
				cell.textLabel.font = [UIFont systemFontOfSize:18];
			} else {
				cell.textLabel.font = [UIFont systemFontOfSize:14];
			}
			cell.textLabel.textAlignment = UITextAlignmentCenter; // 中央寄せ
			cell.textLabel.textColor = [UIColor grayColor];
			cell.imageView.image = [UIImage imageNamed:@"Icon24-GreenPlus.png"];
			//Clip表示//cell.accessoryType = UITableViewCellEditingStyleInsert; // (+)
			//Clip表示//cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;	// > ディスクロージャマーク
			cell.showsReorderControl = YES; //(V0.4) Move OK
		}
	} 
	else {
		// 通常セル
		if (self.editing) {
			cell = [tableView dequeueReusableCellWithIdentifier:zCellItemEdit];
		} else {
			cell = [tableView dequeueReusableCellWithIdentifier:zCellItem];
		}

		if (cell == nil) {
			if (self.editing) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle		// サブタイトル型(3.0)
												reuseIdentifier:zCellItemEdit];
			} else {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle		// サブタイトル型(3.0)
											   reuseIdentifier:zCellItem];
			}
			// 行毎に変化の無い定義は、ここで最初に1度だけする
			cell.tag = TAG_CELL_ITEM;
			//Clip表示//cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; // ＞
			if (appDelegate_.app_is_iPad) {
				cell.textLabel.font = [UIFont systemFontOfSize:20];
				cell.detailTextLabel.font = [UIFont systemFontOfSize:14];
			} else {
				cell.textLabel.font = [UIFont systemFontOfSize:16];
				cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
			}
			cell.textLabel.textAlignment = UITextAlignmentLeft;
			cell.textLabel.textColor = [UIColor blackColor];
			cell.detailTextLabel.textAlignment = UITextAlignmentLeft;
			cell.detailTextLabel.textColor = [UIColor brownColor];
		}

		if ([e3obj.name length] <= 0) 
			cell.textLabel.text = NSLocalizedString(@"(New Goods)", nil);
		else
			cell.textLabel.text = e3obj.name;

		long lStock = [e3obj.stock longValue];
		long lNeed = [e3obj.need longValue];
		//long lWeight = [e3obj.weight longValue];
		
		// 左ボタン ------------------------------------------------------------------
		UIButton *bu = [UIButton buttonWithType:UIButtonTypeCustom]; // autorelease
		bu.frame = CGRectMake(0,0, 44,44);
		bu.tag = indexPath.section * GD_SECTION_TIMES + indexPath.row;
		[bu addTarget:self action:@selector(cellButtonCheck:) forControlEvents:UIControlEventTouchUpInside];
		bu.backgroundColor = [UIColor clearColor]; //背景透明
		bu.showsTouchWhenHighlighted = YES;
		[cell.contentView addSubview:bu];  
		//[bu release]; buttonWithTypeにてautoreleseされるため不要。UIButtonにinitは無い。

		if (lNeed == 0) {  // 必要なし
			cell.textLabel.textColor = [UIColor grayColor];
			cell.imageView.image = [UIImage imageNamed:@"Icon32-CircleGray.png"];
		}
		else if (lStock < lNeed) {  // E3では数量比較できるから
			cell.textLabel.textColor = [UIColor blackColor];
			cell.imageView.image = [UIImage imageNamed:@"Icon32-Circle.png"];
		}
		else {
			cell.textLabel.textColor = [UIColor blackColor];
			if (lStock == lNeed) {
				cell.imageView.image = [UIImage imageNamed:@"Icon32-CircleCheck.png"]; // Just OK
			} else {
				cell.imageView.image = [UIImage imageNamed:@"Icon32-CircleCheck2.png"]; // Over
			}
		}
		
		NSString *zNote;
		if (0 < [e3obj.note length]) zNote = e3obj.note;
		else zNote = @"";
		
		switch (PiSortType) {
			case 0: // 不足個数順
				cell.detailTextLabel.text = [NSString stringWithFormat:@"%@／%@  %@g  %@(%@%@)  %@",
											 GstringFromNumber(e3obj.stock),
											 GstringFromNumber(e3obj.need),
											 GstringFromNumber(e3obj.weight),
											 NSLocalizedString(@"Shortage", @"不足"), 
											 GstringFromNumber(e3obj.lack),
											 NSLocalizedString(@"Qty", @"個"), 
											 zNote];
				cell.showsReorderControl = NO;	  // Move禁止
				break;
			case 1: // 不足重量順
				cell.detailTextLabel.text = [NSString stringWithFormat:@"%@／%@  %@g  %@(%@g)  %@",
											 GstringFromNumber(e3obj.stock),
											 GstringFromNumber(e3obj.need),
											 GstringFromNumber(e3obj.weight),
											 NSLocalizedString(@"Shortage", @"不足"), 
											 GstringFromNumber(e3obj.weightLack),
											 zNote];
				cell.showsReorderControl = NO;	  // Move禁止
				break;
			case 2: // 収納重量順
				cell.detailTextLabel.text = [NSString stringWithFormat:@"%@／%@  %@g  %@(%@g)  %@",
											 GstringFromNumber(e3obj.stock),
											 GstringFromNumber(e3obj.need),
											 GstringFromNumber(e3obj.weight),
											 NSLocalizedString(@"Stock", @"収納"),
											 GstringFromNumber(e3obj.weightStk),
											 zNote];
				cell.showsReorderControl = NO;	  // Move禁止
				break;
			default:
#ifdef DEBUG
				cell.detailTextLabel.text = [NSString stringWithFormat:@"%@／%@  %@g  %@ [%d]",
											 GstringFromNumber(e3obj.stock),
											 GstringFromNumber(e3obj.need),
											 GstringFromNumber(e3obj.weight),
											 zNote, [e3obj.row intValue]];
#else
				cell.detailTextLabel.text = [NSString stringWithFormat:@"%@／%@  %@g  %@",
											 GstringFromNumber(e3obj.stock),
											 GstringFromNumber(e3obj.need),
											 GstringFromNumber(e3obj.weight),
											 zNote];
#endif
				cell.showsReorderControl = YES;  // Move許可
				break;
		}
	}
	//AzLOG(@"E3 cell Section=%d Row=%d End", indexPath.section, indexPath.row);
	if (!self.editing && PiSortType < 0 && PbSharePlanList==NO) {
		// Clipボタン ------------------------------------------------------------------
		UIButton *buClip = [UIButton buttonWithType:UIButtonTypeCustom]; // autorelease
		buClip.frame = CGRectMake(0,0, 44,44);
		[buClip setImage:[UIImage imageNamed:@"Icon44-ClipOff.png"] forState:UIControlStateNormal];
		[buClip setImage:[UIImage imageNamed:@"Icon44-ClipOn.png"] forState:UIControlStateHighlighted];
		buClip.tag = indexPath.section * GD_SECTION_TIMES + indexPath.row;
		[buClip addTarget:self action:@selector(cellButtonClip:) forControlEvents:UIControlEventTouchUpInside];
		//[buCopy release]; buttonWithTypeにてautoreleseされるため不要。UIButtonにinitは無い。
		cell.accessoryView = buClip;
		cell.accessoryType = UITableViewCellAccessoryNone;
	} else {
		if (PbSharePlanList) {
			cell.showsReorderControl = NO;		// Move
			cell.selectionStyle = UITableViewCellSelectionStyleNone; // 選択時ハイライトなし
			cell.accessoryType = UITableViewCellAccessoryNone; // なし
		} else {
			if (appDelegate_.app_is_iPad) {
				cell.accessoryType = UITableViewCellAccessoryNone; // なし
			} else {
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; // ＞
			}
		}
	}
	return cell;
}

// TableView Editボタンスタイル
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	E3 *e3obj = [[RaE3array objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	if (!MbAzOptItemsGrayShow && [e3obj.need integerValue]==0) {
		return UITableViewCellEditingStyleNone; // なし
	}
	else if ([e3obj.need integerValue] == (-1)) {
		//if (0 <= PiSortType) return UITableViewCellEditingStyleNone; // ソートモード時なし
		//else                 return UITableViewCellEditingStyleInsert;
		return UITableViewCellEditingStyleNone;
		
	} 
	return UITableViewCellEditingStyleDelete;
}


// TableView 行選択時の動作
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];		// 先ずは選択状態表示を解除する
	
	// didSelect時のScrollView位置を記録する（viewWillAppearにて再現するため）
	McontentOffsetDidSelect = [tableView contentOffset];

	[self e3detailView:indexPath];
}


/* // ディスクロージャボタンが押されたときの処理
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath 
{
	[self e3detailView:indexPath];
}*/

#pragma mark  TableView - Editting

// TableView Editモードの表示
- (void)setEditing:(BOOL)editing animated:(BOOL)animated 
{
	if (editing) {
		// 編集モードに入るとき
		//[self.tableView reloadData];  // [0.3.1]セクション間移動後、タイトル部の重量計表示更新するため
	} else {
		// 編集モードから出るとき
		[self.tableView reloadData];  // [0.3.1]セクション間移動後、タイトル部の重量計表示更新するため
	}
	[super setEditing:editing animated:animated];
}

// [削除]ボタンのキャプションを変える
- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
		return NSLocalizedString(@"Cut",nil);
}

// TableView Editモード処理
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
															forRowAtIndexPath:(NSIndexPath *)indexPath 
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		/*[1.1.0]削除を[Cut]動作同等にした。
		// 削除コマンド警告　==>> (void)actionSheet にて処理
		//Bug//MindexPathActionDelete = indexPath;
		[MindexPathActionDelete release], MindexPathActionDelete = [indexPath copy];
		// 削除コマンド警告
		UIActionSheet *action = [[UIActionSheet alloc] 
								 initWithTitle:NSLocalizedString(@"CAUTION", nil)
								 delegate:self 
								 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
								 destructiveButtonTitle:NSLocalizedString(@"DELETE Item", nil)
								 otherButtonTitles:nil];
		action.tag = ACTIONSEET_TAG_DELETEITEM;
		if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
			// タテ：ToolBar表示
			[action showFromToolbar:self.navigationController.toolbar]; // ToolBarがある場合
		} else {
			// ヨコ：ToolBar非表示（TabBarも無い）　＜＜ToolBar無しでshowFromToolbarするとFreeze＞＞
			[action showInView:self.view]; //windowから出すと回転対応しない
		}
		[action release];
		 */
		// [1.1.0]削除を[Cut]動作同等にした。
		//[MpathClip release],
		MpathClip = [indexPath copy];
		[self cut:nil];
    }
}

// Editモード時の行Edit可否
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES; // 行編集許可
}

/*
- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	// スワイプにより1行だけが編集モードに入るときに呼ばれる。
	// このオーバーライドにより、setEditting が呼び出されないようにしている。 Add行を出さないため
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	// スワイプにより1行だけが編集モードに入り、それが解除されるときに呼ばれる。
	// このオーバーライドにより、setEditting が呼び出されないようにしている。 Add行を出さないため
}
*/

#pragma mark  TableView - Moveing

// Editモード時の行移動の可否
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if (0 <= PiSortType) return NO; // SortTypeでは常時移動禁止
	if (!MbAzOptItemsGrayShow) {	// この処理が無いと三途の川がハミダス
		E3 *e3obj = [[RaE3array objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
		if ([e3obj.need integerValue]<=0) {
			return NO;  // Gray行につき移動禁止  Add行も同様
		}
	}
	return YES;
}

//(V0.4)Add行も移動可能にした。ただし、セクションを超えられなくすること。
// Editモード時の行移動「先」を応答　　＜＜最終行のAdd行への移動ならば1つ前の行を応答している＞＞
- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)oldPath
																toProposedIndexPath:(NSIndexPath *)newPath 
{
	E3 *e3old = [[RaE3array objectAtIndex:oldPath.section] objectAtIndex:oldPath.row];
	if ([e3old.need integerValue] == (-1)) { //(V0.4)Add
		//(V0.4)Add行の場合、セクション内に限る
		if (oldPath.section == newPath.section) {
			return newPath;
		} 
		else if (oldPath.section < newPath.section) {
			NSInteger rows = [[RaE3array objectAtIndex:oldPath.section] count];
			return [NSIndexPath indexPathForRow:rows-1 inSection:oldPath.section]; // oldPathの末尾
		}
		return [NSIndexPath indexPathForRow:0 inSection:oldPath.section]; // oldPathの先頭
	}
	// E3普通行はどこへでも移動可能  ＜＜各セクションの行末を移動先にできない！行頭と行末を同時に有効にできないため＞＞
	return newPath;
}


// Editモード時の行移動処理　　＜＜CoreDataにつきArrayのように削除＆挿入ではダメ。ソート属性(row)を書き換えることにより並べ替えている＞＞
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)oldPath 
												  toIndexPath:(NSIndexPath *)newPath {
	// e3list 更新 ==>> なんと、managedObjectContextも更新される。 ただし、削除や挿入は反映されない！！！
	// セクションを跨いだ移動にも対応
	
	//--------------------------------------------------(1)MutableArrayの移動
	E3 *e3obj = [[RaE3array objectAtIndex:oldPath.section] objectAtIndex:oldPath.row];
	E2 *e2objOld = e3obj.parent; // [0.3.1]セクション間移動時に再集計するために必要となる
	// 移動元から削除
	[[RaE3array objectAtIndex:oldPath.section] removeObjectAtIndex:oldPath.row];
	// 移動先へ挿入　＜＜newPathは、targetIndexPathForMoveFromRowAtIndexPath にて[Gray]行の回避処理した行である＞＞
	[[RaE3array objectAtIndex:newPath.section] insertObject:e3obj atIndex:newPath.row];

	NSInteger i;
	//--------------------------------------------------(2)row 付け替え処理
	if (oldPath.section == newPath.section) {
		// 同セクション内での移動
		NSInteger start = oldPath.row;
		NSInteger end = newPath.row;
		if (end < start) {
			start = newPath.row;
			end = oldPath.row;
		}
		for (i = start ; i <= end ; i++) {
			e3obj = [[RaE3array objectAtIndex:newPath.section] objectAtIndex:i];
			e3obj.row = [NSNumber numberWithInteger:i];
		}
	} else {
		// 異セクション間の移動　＜＜親(.e2selected)の変更が必要＞＞
		// 移動元セクション（親）から子を削除する
		[[RaE2array objectAtIndex:oldPath.section] removeChildsObject:e3obj];	// 元の親ノードにある子登録を抹消する
		// 異動先セクション（親）へ子を追加する
		[[RaE2array objectAtIndex:newPath.section] addChildsObject:e3obj];	// 新しい親ノードに子登録する
		// 異セクション間での移動： 双方のセクションで変化あったrow以降、全て更新する
		// 元のrow付け替え処理
		for (i = oldPath.row ; i < [[RaE3array objectAtIndex:oldPath.section] count] ; i++) {
			e3obj = [[RaE3array objectAtIndex:oldPath.section] objectAtIndex:i];
			e3obj.row = [NSNumber numberWithInteger:i];
		}
		// 先のrow付け替え処理
		for (i = newPath.row ; i < [[RaE3array objectAtIndex:newPath.section] count] ; i++) {
			e3obj = [[RaE3array objectAtIndex:newPath.section] objectAtIndex:i];
			e3obj.row = [NSNumber numberWithInteger:i];
		}
		E2 *e2objNew = e3obj.parent;  // [0.3.1]セクション間移動時に再集計するために必要となる
		//-------------------------------[0.3.1]セクション間移動のとき、新旧sum項目の再集計が必要
		// 旧sum更新
		if (e2objOld != nil) { // 旧E2
			[e2objOld setValue:[e2objOld valueForKeyPath:@"childs.@sum.noGray"] forKey:@"sumNoGray"];
			[e2objOld setValue:[e2objOld valueForKeyPath:@"childs.@sum.noCheck"] forKey:@"sumNoCheck"];
			[e2objOld setValue:[e2objOld valueForKeyPath:@"childs.@sum.weightStk"] forKey:@"sumWeightStk"];
			[e2objOld setValue:[e2objOld valueForKeyPath:@"childs.@sum.weightNed"] forKey:@"sumWeightNed"];
			// E1 に変化は無いのでなにもしない
		}
		// 新sum更新
		if (e2objNew != nil) { // 旧E2
			[e2objNew setValue:[e2objNew valueForKeyPath:@"childs.@sum.noGray"] forKey:@"sumNoGray"];
			[e2objNew setValue:[e2objNew valueForKeyPath:@"childs.@sum.noCheck"] forKey:@"sumNoCheck"];
			[e2objNew setValue:[e2objNew valueForKeyPath:@"childs.@sum.weightStk"] forKey:@"sumWeightStk"];
			[e2objNew setValue:[e2objNew valueForKeyPath:@"childs.@sum.weightNed"] forKey:@"sumWeightNed"];
			// E1 に変化は無いのでなにもしない
		}
	}

	if (PbSharePlanList==NO) {  // SpMode=YESならば[SAVE]ボタンを非表示にしたので通らないハズだが、念のため。
		// SAVE　＜＜万一システム障害で落ちてもデータが残るようにコマメに保存する方針である＞＞
		NSError *error = nil;
		// ＜＜Sortのとき、Pe2selected==nil であるからPe2selectedは使えない＞＞
		if (![Re1selected.managedObjectContext save:&error]) {
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			exit(-1);  // Fail
		}
	}

	if (MbAzOptShowTotalWeight || MbAzOptShowTotalWeightReq) 
	{ // セクションヘッダの重量表示を更新する
		[self.tableView reloadData];
	}

	if (appDelegate_.app_is_iPad) {
		// 左側 E2 再描画  ＜＜未チェック数も更新するため
		[self padE2refresh:oldPath.section];
		[self padE2refresh:newPath.section];
	}
}


#pragma mark - <PadRootVC delegate>
// タテになり左が非表示になる前に呼ばれる  <willHideViewController>
- (void)showPopoverButtonItem:(UIBarButtonItem *)barButtonItem
{
    NSMutableArray *items = [[Me2toolbar items] mutableCopy];
	if ([items count]==4) {
		barButtonItem.title = NSLocalizedString(@"Index button", nil);
		[items insertObject:barButtonItem atIndex:1]; //この位置は、loadView:にある初期定義と一致させること
	}
	[Me2toolbar setItems:items animated:YES];
   // [items release];
}

// ヨコになり左が表示される前に呼ばれる  <willShowViewController>
- (void)hidePopoverButtonItem:(UIBarButtonItem *)barButtonItem
{
	NSMutableArray *items = [[Me2toolbar items] mutableCopy];
	if ([items count]==5) {
		[items removeObjectAtIndex:1]; //この位置は、loadView:にある初期定義と一致させること
	}
    [Me2toolbar setItems:items animated:YES];
    //[items release];
}


#pragma mark - <UIPopoverControllerDelegate>

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{	// Popoverの外部をタップして閉じる前に通知
	// 内部(SAVE)から、dismissPopoverAnimated:で閉じた場合は呼び出されない。
	//[1.0.6]Cancel: 今更ながら、insert後、saveしていない限り、rollbackだけで十分であることが解った。

	UINavigationController* nc = (UINavigationController*)[popoverController contentViewController];
	if ( [[nc visibleViewController] isMemberOfClass:[E3detailTVC class]] ) {	// E3detailTVC のときだけ、
		if (appDelegate_.AppUpdateSave) { // E3detailTVCにて、変更あるので閉じさせない
			alertBox(NSLocalizedString(@"Cancel or Save",nil), 
					 NSLocalizedString(@"Cancel or Save msg",nil), NSLocalizedString(@"Roger",nil));
			return NO; 
		}
	}
	[Re1selected.managedObjectContext rollback]; // 前回のSAVE以降を取り消す
	return YES; // 閉じることを許可
}
/*
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{	// Popoverの外部をタップして閉じた後に通知
	// E3 再描画
	if (MindexPathEdit) {
		[self requreyMe3array];//Add行を読む込む為に必要
		
		//NSArray* ar = [NSArray arrayWithObject:MindexPathEdit];
		//[self.tableView reloadRowsAtIndexPaths:ar withRowAnimation:NO];	//【Tips】1行だけリロードする
		//[1.0.6]上の1行再表示では、セクションヘッダにある重量が更新されない不具合あり。
		
		//[1.0.6]【Tips】「reloadData＆復元」方式
		//CGPoint po = self.tableView.contentOffset;	//現在のスクロール位置を記録
		//[self.tableView reloadData];
		//self.tableView.contentOffset = po;		//スクロール位置を復元
		
		//[1.0.6]【Tips】セクション単位でリロード
		//NSIndexSet* iset = [NSIndexSet indexSetWithIndex:MindexPathEdit.section];
		//[self.tableView reloadSections:iset withRowAnimation:NO]; //【Tips】セクション単位でリロードする
		
		//[1.0.6]【Tips】結局、これが一番良い。 ＜＜行位置変わらず、表示の乱れも無い
		[self.tableView reloadData];
		
		// 左側 E2 再描画
		[self padE2refresh:MindexPathEdit.section];
	}
	else {
		[self.tableView reloadData];
		// 左側 E2 再描画
		[self padE2refresh:(-1)];
	}
	// [Cancel][Save][枠外タッチ]何れでも閉じるときここを通るので解放する。さもなくば回転後に現れることになる
	[Mpopover release], Mpopover = nil;
	return;
}*/


@end
