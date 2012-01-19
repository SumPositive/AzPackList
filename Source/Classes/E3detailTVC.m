//
//  E3detailTVC.m
//  AzPacking
//
//  Created by 松山 和正 on 10/01/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Global.h"
#import "AppDelegate.h"
#import "Elements.h"
#import "E3viewController.h"
#import "E3detailTVC.h"
#import "selectGroupTVC.h"
//#import "editLabelTextVC.h"
#import "editLabelNumberVC.h"
#import "CalcView.h"
#import "WebSiteVC.h"
#import "PatternImageView.h"


//#define LABEL_NOTE_SUFFIX   @"\n\n\n\n\n"  // UILabel *MlbNoteを上寄せするための改行（5行）
#define TEXTFIELD_MAXLENGTH		50
#define TEXTVIEW_MAXLENGTH		400
#define WEIGHT_SLIDER_STEP		   10		// Weight Slider Step (g)
#define WEIGHT_CENTER_OFFSET	  500		// Weight 中央値から最大最小値までの量
#define WEIGHT_MAX				99999		// Weight 中央値から最大最小値までの量
#define NEED_MAX				 9999
#define STOCK_MAX				 9999

#define OFSX1		115
#define OFSX2		 30


@interface E3detailTVC (PrivateMethods)
- (void)slidStock:(UISlider *)slider;
- (void)slidStockUp:(UISlider *)slider;
- (void)slidNeed:(UISlider *)slider;
- (void)slidNeedUp:(UISlider *)slider;
- (void)slidWeight:(UISlider *)slider;
- (void)slidWeightUp:(UISlider *)slider;
- (void)cellButtonCalc: (UIButton *)button ;
- (void)cancelClose:(id)sender;
- (void)saveClose:(id)sender;
- (void)viewDesign;
- (void)alertWeightOver;
@end

@implementation E3detailTVC
{
@private
	UILabel		*lbGroup_;	// .tag = E2.row　　　以下全てcellがOwnerになる
	UITextField	*tfName_;
	UITextField	*tfKeyword_;	//[1.1]Shopping keyword
	UITextView	*tvNote_;
	UILabel		*lbStock_;
	UILabel		*lbNeed_;
	UILabel		*lbWeight_;
	//UILabel		*MlbStockMax;
	//UILabel		*MlbNeedMax;
	//UISlider			*MsliderStock;
	//UISlider			*MsliderNeed;
	AZDial			*dialStock_;
	AZDial			*dialNeed_;
#ifdef WEIGHT_DIAL
	AZDial			*dialWeight_;
#else
	UISlider			*MsliderWeight;
	UILabel		*MlbWeightMax;
	UILabel		*MlbWeightMin;
#endif
	
	CalcView		*calcView_;
	
	AppDelegate		*appDelegate_;
	float						tableViewContentY_;
}
@synthesize e2array = e2array_;
@synthesize e3array = e3array_;
@synthesize e3target = e3target_;
@synthesize addE2section = addE2section_;
@synthesize addE3row = addE3row_;
@synthesize sharePlanList = sharePlanList_;
@synthesize delegate = delegate_;
@synthesize selfPopover = selfPopover_;


#pragma mark - dealloc

- (void)dealloc    // 生成とは逆順に解放するのが好ましい
{
	//[selfPopover release], 
	selfPopover_ = nil;
	//[e3target_ release];
	//[RaE3array release];
	//[RaE2array release];
	//[super dealloc];
}


#pragma mark - View lifecicle

// UITableViewインスタンス生成時のイニシャライザ　viewDidLoadより先に1度だけ通る
- (id)initWithStyle:(UITableViewStyle)style 
{
	if ((self = [super initWithStyle:UITableViewStyleGrouped])) {  // セクションありテーブル
		// 初期化成功
		appDelegate_ = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		appDelegate_.app_UpdateSave = NO;
		sharePlanList_ = NO;
		tableViewContentY_ = -1;

		// 背景テクスチャ・タイルペイント
		if (appDelegate_.app_is_iPad) {
			//self.view.backgroundColor = //iPad1では無効
			UIView* view = self.tableView.backgroundView;
			if (view) {
				PatternImageView *tv = [[PatternImageView alloc] initWithFrame:view.frame
																  patternImage:[UIImage imageNamed:@"Tx-Back"]]; // タイルパターン生成
				[view addSubview:tv];
			}
			self.contentSizeForViewInPopover = GD_POPOVER_E3detailTVC_SIZE;
			//[1.1]//[self.tableView setScrollEnabled:NO]; // スクロール禁止
		}
		else {
			self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Tx-Back"]];
		}
	}
	return self;
}

// IBを使わずにviewオブジェクトをプログラム上でcreateするときに使う（viewDidLoadは、nibファイルでロードされたオブジェクトを初期化するために使う）
- (void)loadView
{	//【Tips】ここでaddSubviewするオブジェクトは全てautoreleaseにすること。メモリ不足時には自動的に解放後、改めてここを通るので、初回同様に生成するだけ。
	[super loadView];

	// Set up NEXT Left [Back] buttons.
	self.navigationItem.backBarButtonItem  = [[UIBarButtonItem alloc]
											   initWithTitle:NSLocalizedString(@"Cancel", nil)
											   style:UIBarButtonItemStylePlain 
											   target:nil  action:nil];
	
	// CANCELボタンを左側に追加する  Navi標準の戻るボタンでは cancel:処理ができないため
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
											  initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
											  target:self action:@selector(cancelClose:)];
	
	if (sharePlanList_==NO) {
		// SAVEボタンを右側に追加する
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] 
												   initWithBarButtonSystemItem:UIBarButtonSystemItemSave
												   target:self action:@selector(saveClose:)];
	}
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

// 他のViewやキーボードが隠れて、現れる都度、呼び出される
- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];

	self.navigationItem.rightBarButtonItem.enabled = appDelegate_.app_UpdateSave;

	// 電卓が出ておれば消す
	if (calcView_ && [calcView_ isShow]) {
		[calcView_ hide]; //　ここでは隠すだけ。 removeFromSuperviewするとアニメ無く即消えてしまう。
	}
	
	// 画面表示に関係する Option Setting を取得する
	//NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	[self viewDesign]; // 下層で回転して戻ったときに再描画が必要
	// テーブルビューを更新します。
    [self.tableView reloadData];
}

- (void)viewDesign
{
	// 回転によるリサイズ
	CGRect rect;
	float fWidth = self.tableView.frame.size.width;
	
	rect = lbGroup_.frame;
	rect.size.width = fWidth - 80;
	lbGroup_.frame = rect;
	
	rect = tfName_.frame;
	rect.size.width = fWidth - 60;
	tfName_.frame = rect;
	
	rect = tvNote_.frame;
	rect.size.width = fWidth - 60;
	tvNote_.frame = rect;
	
	rect = tfKeyword_.frame;
	rect.size.width = fWidth - 60;
	tfKeyword_.frame = rect;
	
/*	rect = MlbStock.frame;
	rect.origin.x = fWidth / 2 - OFSX2;
	MlbStock.frame = rect;
	MlbNeed.frame = rect;
	MlbWeight.frame = rect;*/
	
	rect = dialStock_.frame;
	rect.size.width = fWidth - 80;
	[dialStock_ setFrame:rect]; 	//NG//mDialStock.frame = rect;
	[dialNeed_ setFrame:rect];
#ifdef WEIGHT_DIAL
	[dialWeight_ setFrame:rect];
#else
	rect = MsliderStock.frame;
	rect.size.width = fWidth - 80;
	MsliderWeight.frame = rect;
#endif
	
/*	NSInteger iVal;
	iVal = [e3target_.stock integerValue];  //  MlbStock.text integerValue];
	MsliderStock.maximumValue = 10 + (iVal / 10) * 10;
	MlbStockMax.text = [NSString stringWithFormat:@"%4ld", (long)MsliderStock.maximumValue];
	MsliderStock.value = (float)iVal; // Min,Maxを変えてから、その範囲でしか代入できないため、最後に代入
	
	iVal = [e3target_.need integerValue];  // MlbNeed.text integerValue];
	MsliderNeed.maximumValue = 10 + (iVal / 10) * 10;
	MlbNeedMax.text = [NSString stringWithFormat:@"%4ld", (long)MsliderNeed.maximumValue];
	MsliderNeed.value = (float)iVal;
*/	
#ifdef WEIGHT_DIAL
#else
	NSInteger iVal;
	// One Weight
	iVal = [e3target_.weight integerValue];  // MlbWeight.text integerValue];
	// Min
	MsliderWeight.minimumValue = (float)(iVal - WEIGHT_CENTER_OFFSET);
	if (MsliderWeight.minimumValue < 0) MsliderWeight.minimumValue = 0.0f;
	MlbWeightMin.text = [NSString stringWithFormat:@"%ld", (long)MsliderWeight.minimumValue];
	// Max										  //  ↑左寄せにつき数字不要
	MsliderWeight.maximumValue = (float)(iVal + WEIGHT_CENTER_OFFSET);
	if (WEIGHT_MAX < MsliderWeight.maximumValue) MsliderWeight.maximumValue = WEIGHT_MAX;
	MlbWeightMax.text = [NSString stringWithFormat:@"%5ld", (long)MsliderWeight.maximumValue];
	// Value
	MsliderWeight.value = (float)iVal;
#endif
	
/*	rect = MlbStockMax.frame;
	rect.origin.x = fWidth - OFSX1;
	MlbStockMax.frame = rect;
	MlbNeedMax.frame = rect;
	MlbWeightMax.frame = rect;
 */
}

- (void)performNameFirstResponder
{
	if (tfName_ && [tfName_.text length]<=0) {			// ブランクならば、
		[tfName_ becomeFirstResponder];  // キーボード表示  NG/iPadでは効かなかった。0.5秒後にするとOK
	}
}

// ビューが最後まで描画された後やアニメーションが終了した後にこの処理が呼ばれる
- (void)viewDidAppear:(BOOL)animated 
{
    [super viewDidAppear:animated];
	[self.navigationController setToolbarHidden:YES animated:animated]; // ツールバー消す
	[self.tableView flashScrollIndicators]; // Apple基準：スクロールバーを点滅させる
	
	if (appDelegate_.app_opt_Ad) {
		// 各viewDidAppear:にて「許可/禁止」を設定する
		[appDelegate_ AdRefresh:NO];	//広告禁止
	}

	//この時点で MtfName は未生成だから、0.5秒後に処理する
	[self performSelector:@selector(performNameFirstResponder) withObject:nil afterDelay:0.5f]; // 0.5秒後に呼び出す
}

// ビューが非表示にされる前や解放される前ににこの処理が呼ばれる
- (void)viewWillDisappear:(BOOL)animated 
{
	if (appDelegate_.app_is_iPad) {
		//
	} else {
		if (calcView_) {	// あれば破棄する
			[calcView_ hide];
			[calcView_ removeFromSuperview];  // これでCalcView.deallocされる
			//[McalcView release]; +1残っているが、viewが破棄されるときにreleseされるので、ここは不要
			calcView_ = nil;
		}
	}
	[super viewWillDisappear:animated];
}


#pragma mark  View Rotate

// 回転サポート
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{	
	if (appDelegate_.app_is_iPad) {
		return YES;	// Popover内につき回転不要だが、NO にすると Shopping(Web)から戻ると強制的にタテ向きになってしまう。
	} else {
		// 回転禁止の場合、万一ヨコからはじまった場合、タテにはなるようにしてある。
		return appDelegate_.app_opt_Autorotate OR (interfaceOrientation == UIInterfaceOrientationPortrait);
	}
}

// ユーザインタフェースの回転を始める前にこの処理が呼ばれる。 ＜＜OS 3.0以降の推奨メソッド＞＞
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
	// この開始時に消す。　　この時点で self.view.frame は回転していない。
	if (calcView_ && [calcView_ isShow]) {
		[calcView_ hide]; //　ここでは隠すだけ。 removeFromSuperviewするとアニメ無く即消えてしまう。
	}
}

// ユーザインタフェースの回転の最後の半分が始まる前にこの処理が呼ばれる　＜＜このタイミングで配置転換すると見栄え良い＞＞
- (void)willAnimateSecondHalfOfRotationFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation 
													   duration:(NSTimeInterval)duration
{
	//[self.tableView reloadData];
	[self viewDesign]; // cell生成の後
}


#pragma mark - iCloud
- (void)refreshAllViews:(NSNotification*)note 
{	// iCloud-CoreData に変更があれば呼び出される
	@synchronized(note)
	{
		[self viewWillAppear:YES];
	}
}


#pragma mark - Action

- (void)cancelClose:(id)sender 
{	// E3は、Cancel時、新規ならば破棄、修正ならば復旧、させる
	if (e3target_ && sharePlanList_==NO) {  // Sample表示のときrollbackすると、一時表示用のE1まで消えてしまうので回避する。
		// ROLLBACK
#ifdef xxxDEBUG
		NSManagedObjectContext *moc = e3target_.managedObjectContext;
		//NSLog(@"--1-- e3target_=%@", e3target_);
		//[1.0.6]insertされたentityが本当にrollbackされているのかを検証
		{
			E2 *e2 = e3target_.parent;
			NSLog(@"--1-- [[e2.childs allObjects] count]=%d", (int)[[e2.childs allObjects] count]);
			
			NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
			NSEntityDescription *entity = [NSEntityDescription entityForName:@"E3" inManagedObjectContext:moc];
			[fetchRequest setEntity:entity];
			NSArray *arFetch = [moc executeFetchRequest:fetchRequest error:nil];
			NSLog(@"--1-- E3 count=%d", (int)[arFetch count]); //＜＜ New Goods CANCEL時、insertNewされたものが増えている。
			[fetchRequest release];
		}
#endif		

		//[1.0.6]今更ながら、insert後、saveしていない限り、rollbackだけで十分であることが解った。 ＜＜前後のDEBUGによる検証済み。
		[e3target_.managedObjectContext rollback]; // 前回のSAVE以降を取り消す
		
#ifdef xxxDEBUG
		//NSLog(@"--2-- e3target_=%@", e3target_);
		//[1.0.6]insertされたentityが本当にrollbackされているのかを検証
		{
			E2 *e2 = e3target_.parent;
			NSLog(@"--2-- [[e2.childs allObjects] count]=%d", (int)[[e2.childs allObjects] count]);
			
			NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
			NSEntityDescription *entity = [NSEntityDescription entityForName:@"E3" inManagedObjectContext:moc];
			[fetchRequest setEntity:entity];
			NSArray *arFetch = [moc executeFetchRequest:fetchRequest error:nil];
			NSLog(@"--2-- E3 count=%d", (int)[arFetch count]); //＜＜ New Goods CANCEL時、--1-- E3 count より1つ減っていることを確認した。
			[fetchRequest release];
		}
#endif		
		
	}

	if (appDelegate_.app_is_iPad) {
		if (selfPopover_) {
			[selfPopover_ dismissPopoverAnimated:YES];
		}
	} else {
		[self.navigationController popViewControllerAnimated:YES];	// < 前のViewへ戻る
	}
}

// 編集フィールドの値を e3target_ にセットする
- (void)saveClose:(id)sender 
{
	if (sharePlanList_) return; // [Save]ボタンを消しているので通らないハズだが、念のため。
	
	if (appDelegate_.app_is_iPad) {
	} else {
		//[McalcView hide]; // 電卓が出ておれば消す
		if (calcView_) {	// あれば破棄する
			[calcView_ save]; // 有効値あれば保存
		}
	}
	
	NSInteger lWeight = [e3target_.weight integerValue];  // MlbWeight.text integerValue];
	NSInteger lStock = [e3target_.stock integerValue];  // MlbStock.text integerValue];
	NSInteger lNeed = [e3target_.need integerValue];  // MlbNeed.text integerValue];
	//[0.2c]プラン総重量制限
	if (0 < lWeight) {  // longオーバーする可能性があるため商は求めない
		if (AzMAX_PLAN_WEIGHT / lWeight < lStock OR AzMAX_PLAN_WEIGHT / lWeight < lNeed) {
			[self alertWeightOver];
			return;
		}
	}
	
	//Pe3target,Pe2selected は ManagedObject だから更新すれば ManagedObjectContext に反映される
	// PICKER 指定したコンポーネントで選択された行のインデックスを返す。
	NSInteger newSection = lbGroup_.tag;
	if ([e2array_ count]<=newSection) {
		NSLog(@"*** OVER newSection=%d", newSection);
		return;
	}
	E2 *e2objNew = [e2array_ objectAtIndex:newSection];
	
	if (addE2section_< 0 && 0 <= newSection)
	{	// Edit mode のときだけ、グループ移動による「旧グループの再集計」が必要になる
		NSInteger oldSection = [e3target_.parent.row integerValue];  // Edit mode
		
		if (oldSection != newSection) 
		{	// グループに変化があれば、
			// E2セクション(Group)の変更あり  self.e3section ==>> newSection
			NSInteger oldRow = [e3target_.row integerValue];	// 元ノードのrow　最後のrow更新処理で、ie3nodeRow以降を更新する。
			
			NSInteger newRow = (-1);
			// Add行に追加する （Add行は1つ下へ）
			for (E3* e3 in [e3array_ objectAtIndex:newSection]) {
				if ([e3.need integerValue]==(-1)) { // Add行
					newRow = [e3.row integerValue];
				}
			}
			if (newRow<0) {	// 万一、Add行がバグで削除されたときのため
				newRow = [[e3array_ objectAtIndex:newSection] count];  // セクション末尾
			}
			
			E2 *e2objOld = [e2array_ objectAtIndex:oldSection];
			//--------------------------------------------------(1)MutableArrayの移動
			[[e3array_ objectAtIndex:oldSection] removeObjectAtIndex:oldRow];
			[[e3array_ objectAtIndex:newSection] insertObject:e3target_ atIndex:newRow];
			
			// 異セクション間の移動　＜＜親(.e2selected)の変更が必要＞＞
			// 移動元セクション（親）から子を削除する
			[e2objOld removeChildsObject:e3target_];	// 元の親ノードにある子登録を抹消する
			// e2objOld 子が無くなったので再集計する
			[e2objOld setValue:[e2objOld valueForKeyPath:@"childs.@sum.noGray"] forKey:@"sumNoGray"];
			[e2objOld setValue:[e2objOld valueForKeyPath:@"childs.@sum.noCheck"] forKey:@"sumNoCheck"];
			[e2objOld setValue:[e2objOld valueForKeyPath:@"childs.@sum.weightStk"] forKey:@"sumWeightStk"];
			[e2objOld setValue:[e2objOld valueForKeyPath:@"childs.@sum.weightNed"] forKey:@"sumWeightNed"];
			// 異動先セクション（親）へ子を追加する
			[e2objNew addChildsObject:e3target_];	// 新しい親ノードに子登録する
			// e2objNew の再集計は、変更を含めて最後に実施
			
			// 元のrow付け替え処理　 異セクション間での移動： 双方のセクションで変化あったrow以降、全て更新
			NSInteger i;
			E3 *e3obj;
			for (i = oldRow ; i < [[e3array_ objectAtIndex:oldSection] count] ; i++) {
				e3obj = [[e3array_ objectAtIndex:oldSection] objectAtIndex:i];
				e3obj.row = [NSNumber numberWithInteger:i];
			}
			// Add行に追加
			e3target_.row = [NSNumber numberWithInteger:newRow];  
			// Add行以下のrow付け替え処理
			for (i = newRow ; i < [[e3array_ objectAtIndex:newSection] count] ; i++) {
				e3obj = [[e3array_ objectAtIndex:newSection] objectAtIndex:i];
				e3obj.row = [NSNumber numberWithInteger:i];
			}
		}
	}
	
	if( 50 < [tfName_.text length] ){
		// 長さが50超ならば、0文字目から50文字を切り出して保存　＜以下で切り出すとフリーズする＞
		[e3target_ setValue:[tfName_.text substringWithRange:NSMakeRange(0, 50)] forKey:@"name"];
	} else {
		//[Pe3target setValue:MlbName.text forKey:@"name"];
		e3target_.name = tfName_.text;
	}
	
	if( 50 < [tfKeyword_.text length] ){
		// 長さが50超ならば、0文字目から50文字を切り出して保存　＜以下で切り出すとフリーズする＞
		[e3target_ setValue:[tfKeyword_.text substringWithRange:NSMakeRange(0, 50)] forKey:@"shopKeyword"];
	} else {
		e3target_.shopKeyword = tfKeyword_.text;
	}
	
	NSString *zNote;
	zNote = tvNote_.text;
	/*
	 if ([MlbNote.text length] <= 0) {
	 zNote = @"";
	 } 
	 else if (0 < [LABEL_NOTE_SUFFIX length]) {
	 // 末尾改行文字("\n")を PiSuffixLength 個除く -->> doneにて追加する
	 zNote = [MlbNote.text substringToIndex:([MlbNote.text length] - [LABEL_NOTE_SUFFIX length])];
	 } else {
	 zNote = MlbNote.text;
	 }
	 */
	if( TEXTVIEW_MAXLENGTH < [zNote length] ){
		// 長さがTEXTVIEW_MAXLENGTH超ならば、0文字目からTEXTVIEW_MAXLENGTH文字を切り出して保存　＜以下で切り出すとフリーズする＞
		[e3target_ setValue:[zNote substringWithRange:NSMakeRange(0, TEXTVIEW_MAXLENGTH)] forKey:@"note"];
	} else {
		[e3target_ setValue:zNote forKey:@"note"];
	}
	
	[e3target_ setValue:[NSNumber numberWithInteger:lWeight] forKey:@"weight"];  // 最小値が0でないとエラー発生
	[e3target_ setValue:[NSNumber numberWithInteger:lStock] forKey:@"stock"];
	[e3target_ setValue:[NSNumber numberWithInteger:lNeed] forKey:@"need"];
	[e3target_ setValue:[NSNumber numberWithInteger:(lWeight*lStock)] forKey:@"weightStk"];
	[e3target_ setValue:[NSNumber numberWithInteger:(lWeight*lNeed)] forKey:@"weightNed"];
	[e3target_ setValue:[NSNumber numberWithInteger:(lNeed-lStock)] forKey:@"lack"]; // 不足数
	[e3target_ setValue:[NSNumber numberWithInteger:((lNeed-lStock)*lWeight)] forKey:@"weightLack"]; // 不足重量
	
	NSInteger iNoGray = 0;
	if (0 < lNeed) iNoGray = 1;
	[e3target_ setValue:[NSNumber numberWithInteger:iNoGray] forKey:@"noGray"]; // NoGray:有効(0<必要数)アイテム
	
	NSInteger iNoCheck = 0;
	if (0 < lNeed && lStock < lNeed) iNoCheck = 1;
	[e3target_ setValue:[NSNumber numberWithInteger:iNoCheck] forKey:@"noCheck"]; // NoCheck:不足アイテム
	
	if (0 <= addE2section_&& 0 <= addE3row_) {
		/*(V0.4)addE3row_ に新規追加する。 addE3row_以下を先にずらすこと。
		 // 新規のとき、末尾になるように行番号を付与する
		 NSInteger rows = [[Pe3array objectAtIndex:newSection] count]; // 追加するセクションの現在行数
		 [Pe3target setValue:[NSNumber numberWithInteger:rows] forKey:@"row"];
		 // 親(E2)のchilesにe3editを追加する
		 [e2objNew addChildsObject:Pe3target];
		 */
		
		//(V0.4)addE3row_以下について、.row++ して、addE3row_を空ける。
		//		NSArray *aE3s = [NSArray arrayWithArray:[Pe3array objectAtIndex:newSection]];
		for (E3 *e3 in [e3array_ objectAtIndex:newSection]) {
			if (addE3row_ <= [e3.row integerValue]) {
				e3.row = [NSNumber numberWithInteger:[e3.row integerValue]+1]; // +1
			}
		}
		//(V0.4)addE3row_に追加する。
		e3target_.row = [NSNumber numberWithInteger:addE3row_];
		// E2-E3 Link
		e3target_.parent = e2objNew;
	}
	
	// E2 sum属性　＜高速化＞ 親sum保持させる
	[e2objNew setValue:[e2objNew valueForKeyPath:@"childs.@sum.noGray"] forKey:@"sumNoGray"];
	[e2objNew setValue:[e2objNew valueForKeyPath:@"childs.@sum.noCheck"] forKey:@"sumNoCheck"];
	[e2objNew setValue:[e2objNew valueForKeyPath:@"childs.@sum.weightStk"] forKey:@"sumWeightStk"];
	[e2objNew setValue:[e2objNew valueForKeyPath:@"childs.@sum.weightNed"] forKey:@"sumWeightNed"];
	
	// E1 sum属性　＜高速化＞ 親sum保持させる
	E1 *e1obj = e2objNew.parent;
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
	
	if (sharePlanList_==NO) {  // SpMode=YESならば[SAVE]ボタンを非表示にしたので通らないハズだが、念のため。
		// SAVE : e3edit,e2list は ManagedObject だから更新すれば ManagedObjectContext に反映されている
		NSError *err = nil;
		if (![e3target_.managedObjectContext save:&err]) {
			NSLog(@"Unresolved error %@, %@", err, [err userInfo]);
			//abort();
		}
	}
	
	if (appDelegate_.app_is_iPad) {
		//[(PadNaviCon*)self.navigationController dismissPopoverSaved];  // SAVE: PadNaviCon拡張メソッド
		if (selfPopover_) {
			if ([delegate_ respondsToSelector:@selector(refreshE3view)]) {	// メソッドの存在を確認する
				[delegate_ refreshE3view];// 親の再描画を呼び出す
			}
			[selfPopover_ dismissPopoverAnimated:YES];
		}
	} else {
		[self.navigationController popViewControllerAnimated:YES];	// < 前のViewへ戻る
	}
	
	// 必要数0が追加された場合、前に戻ったときに追加失敗している錯覚をおこさないように通知する
	if (lNeed <= 0) 
	{
		NSUbiquitousKeyValueStore *kvs = [NSUbiquitousKeyValueStore defaultStore];
		if ([kvs boolForKey:KV_OptItemsGrayShow] == NO) 
		{
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Added Item",nil)
															 message:NSLocalizedString(@"GrayHiddon Alert",nil)
															delegate:nil 
												   cancelButtonTitle:nil 
												   otherButtonTitles:@"OK", nil];
			[alert show];
		}
	}
}

- (void)closePopover
{
	if (selfPopover_) {	//dismissPopoverCancel
		if (calcView_ && [calcView_ isShow]) {
			[calcView_ cancel];  //　ラベル表示を元に戻す
		}
		[selfPopover_ dismissPopoverAnimated:YES];
	}
}

#pragma mark - CalcRoll

- (void)showCalc:(UILabel *)pLabel 
		  forKey:(NSString *)zKey 
		forTitle:(NSString *)zTitle
		 withRow:(NSInteger)iRow
		 withMax:(NSInteger)iMax
{
	if (calcView_) {	// あれば一旦、破棄する
		[calcView_ hide];
		[calcView_ removeFromSuperview];  // これでCalcView.deallocされる
		//[McalcView release]; +1残っているが、viewが破棄されるときにreleseされるので、ここは不要
		calcView_ = nil;
	}
	[tfName_ resignFirstResponder]; // ファーストレスポンダでなくす ⇒ キーボード非表示
	[tvNote_ resignFirstResponder]; // ファーストレスポンダでなくす ⇒ キーボード非表示
	[tfKeyword_ resignFirstResponder]; // ファーストレスポンダでなくす ⇒ キーボード非表示
	
	CGRect rect = self.view.bounds;

	if (appDelegate_.app_is_iPad) {
		//テンキー表示位置
		rect.origin.y = 400;  //全体が見えるようにした + (iRow-3)*60;  
	} else {
		tableViewContentY_ = self.tableView.contentOffset.y; // Hide時に元の表示に戻すため
		if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
			// 横
			rect.origin.y = 170 + (iRow-3)*60;
		}
		else {
			// 縦
			rect.origin.y = 78 + (iRow-3)*60;
		}
		// アニメ準備
		CGContextRef context = UIGraphicsGetCurrentContext();
		[UIView beginAnimations:nil context:context];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		[UIView setAnimationDuration:0.3]; // 出は早く
		// アニメ終了位置
		self.tableView.contentOffset = CGPointMake(0, rect.origin.y);
		// アニメ実行
		[UIView commitAnimations];
	}
	
	calcView_ = [[CalcView alloc] initWithFrame:rect];
	calcView_.Rlabel = pLabel;  // MlbAmount.tag にはCalc入力された数値(long)が記録される
	calcView_.Rentity = e3target_;
	calcView_.RzKey = zKey;
	calcView_.delegate = self;
	calcView_.maxValue = iMax;
	[self.view addSubview:calcView_];
	//[McalcView release]; // addSubviewにてretain(+1)されるため、こちらはrelease(-1)して解放
	[calcView_ show];
}

#pragma mark  <CalcViewDelegate>
//============================================<CalcViewDelegate>
- (void)calcViewWillAppear	// CalcViewが現れる直前に呼び出される
{
	[self.tableView setScrollEnabled:NO]; // スクロール禁止
}

- (void)calcViewWillDisappear	// CalcViewが隠れるときに呼び出される
{
	[self.tableView setScrollEnabled:YES]; // スクロール許可
	if (0 <= tableViewContentY_) {
		// AzPacking Original 元の位置に戻す
		self.tableView.contentOffset = CGPointMake(0, tableViewContentY_);
	}
	[dialStock_ setDial:[e3target_.stock integerValue] animated:YES];
	[dialNeed_ setDial:[e3target_.need integerValue] animated:YES];
#ifdef WEIGHT_MAX
	[dialWeight_ setDial:[e3target_.weight integerValue] animated:YES];
#else
	[self viewWillAppear:NO]; // スライドバーを再描画するため
#endif
	
	self.navigationItem.rightBarButtonItem.enabled = appDelegate_.app_UpdateSave;
}


#pragma mark - TableView Cell

- (void)cellButtonCalc: (UIButton *)button 
{
	//assert(self.editing);
	//if (![self becomeFirstResponder]) return;
	
	//bu.tag = indexPath.section * GD_SECTION_TIMES + indexPath.row;
	NSInteger iSection = button.tag / GD_SECTION_TIMES;
	NSInteger iRow = button.tag - (iSection * GD_SECTION_TIMES);
	AzLOG(@"cellButtonCalc .row=%ld", (long)iRow);
	
	switch (iRow) {
		case 3: // Stock
			[self showCalc:lbStock_ forKey:@"stock" forTitle:NSLocalizedString(@"StockQty", nil) withRow:3 withMax:STOCK_MAX];
			break;
		case 4: // Need
			[self showCalc:lbNeed_ forKey:@"need" forTitle:NSLocalizedString(@"Need Qty", nil) withRow:4 withMax:NEED_MAX];
			break;
		case 5: // Weight
			[self showCalc:lbWeight_ forKey:@"weight" forTitle:NSLocalizedString(@"One Weight", nil) withRow:5 withMax:WEIGHT_MAX];
			break;
	}
}

/*****
- (void)slidStock:(UISlider *)slider
{
	long lVal = (long)(slider.value + 0.5f);
	if (9999 < lVal) lVal = 9999;
	if ([e3target_.stock longValue] != lVal) { // 変更あり
		MlbStock.text = GstringFromNumber([NSNumber numberWithInteger:lVal]);  //[NSString stringWithFormat:@"%5ld", lVal];
		e3target_.stock = [NSNumber numberWithInteger:lVal];
		appDelegate.AppUpdateSave = YES; // 変更あり
		self.navigationItem.rightBarButtonItem.enabled = appDelegate.AppUpdateSave;
	}
}

- (void)slidStockUp:(UISlider *)slider
{
	long lVal = (long)(slider.value + 0.5f);
	slider.minimumValue = 0;
	slider.value = lVal;
	lVal = 10 + (lVal / 10) * 10;
	if (9999 < lVal) lVal = 9999;
	slider.maximumValue = lVal;
	MlbStockMax.text = [NSString stringWithFormat:@"%4ld", lVal];
}

- (void)slidNeed:(UISlider *)slider
{
	long lVal = (long)(slider.value + 0.5f);
	if (9999 < lVal) lVal = 9999;
	if ([e3target_.need longValue] != lVal) { // 変更あり
		MlbNeed.text = GstringFromNumber([NSNumber numberWithInteger:lVal]);  //[NSString stringWithFormat:@"%5ld", lVal];
		e3target_.need = [NSNumber numberWithInteger:lVal];
		appDelegate.AppUpdateSave = YES; // 変更あり
		self.navigationItem.rightBarButtonItem.enabled = appDelegate.AppUpdateSave;
	}
}

- (void)slidNeedUp:(UISlider *)slider
{
	long lVal = (long)(slider.value + 0.5f);
	slider.minimumValue = 0;
	slider.value = lVal;
	lVal = 10 + (lVal / 10) * 10;
	if (9999 < lVal) lVal = 9999;
	slider.maximumValue = lVal;
	MlbNeedMax.text = [NSString stringWithFormat:@"%4ld", lVal];
}
 *****/

#ifdef WEIGHT_DIAL
#else
- (void)slidWeight:(UISlider *)slider
{
	long lVal = (long)(slider.value + 0.5f);
	lVal = (lVal / WEIGHT_SLIDER_STEP) * WEIGHT_SLIDER_STEP;
	if (WEIGHT_MAX < lVal) lVal = WEIGHT_MAX;
	if ([e3target_.weight longValue] != lVal) { // 変更あり
		MlbWeight.text = GstringFromNumber([NSNumber numberWithInteger:lVal]);  //[NSString stringWithFormat:@"%5ld", lVal];
		e3target_.weight = [NSNumber numberWithInteger:lVal];
		appDelegate.AppUpdateSave = YES; // 変更あり
		self.navigationItem.rightBarButtonItem.enabled = appDelegate.AppUpdateSave;
	}	
}

- (void)slidWeightUp:(UISlider *)slider
{
	long lVal = (long)(slider.value + 0.5f);
	lVal = (lVal / WEIGHT_SLIDER_STEP) * WEIGHT_SLIDER_STEP;
	
	if (lVal <= WEIGHT_CENTER_OFFSET)
		slider.minimumValue = 0.0f;
	else
		slider.minimumValue = (float)(lVal - WEIGHT_CENTER_OFFSET);
	
	if (lVal < WEIGHT_MAX - WEIGHT_CENTER_OFFSET)
		slider.maximumValue = (float)(lVal + WEIGHT_CENTER_OFFSET);
	else
		slider.maximumValue = WEIGHT_MAX;
	// Minは、↓左寄せにつき数字不要
	MlbWeightMin.text = [NSString stringWithFormat:@"%ld", (long)slider.minimumValue];
	MlbWeightMax.text = [NSString stringWithFormat:@"%5ld", (long)slider.maximumValue];
}
#endif

- (void)alertWeightOver
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"WeightOver",nil)
													 message:NSLocalizedString(@"WeightOver message",nil)
													delegate:nil 
										   cancelButtonTitle:nil 
										   otherButtonTitles:@"OK", nil];
	[alert show];
}


#pragma mark  <UITableViewDelegate>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}



// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	switch (section) {
		case 0: // 
			return 6;
			break;
		case 1: // Shopping
			return 4;
			break;
	}
    return 0;
}

// TableView セクションタイトルを応答
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
	if (section==1) {
		return NSLocalizedString(@"Shopping", nil);
	}
	return nil;
}


// TableView セクションフッタを応答
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section 
{
	if (section==1) {
		return	@"\n\n\n\n\n"
		@"AzukiSoft Project\n"
		COPYRIGHT
		@"\n\n\n\n\n";
	}
	return nil;
}

// セルの高さを指示する
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if (indexPath.section==0) {
		switch (indexPath.row) {
			case 2:
				if (appDelegate_.app_is_iPad) {
					return 150; // Note
				}
				return 110; // Note

			case 3:
			case 4:
			case 5:
				return 58;  // etc
		}
	}

	if (appDelegate_.app_is_iPad) {
		return 50;
	}
	return 44; // デフォルト：44ピクセル
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    NSString *zCellIndex = [NSString stringWithFormat:@"E3detail%d:%d", (int)indexPath.section, (int)indexPath.row];
	UITableViewCell *cell = nil;

	cell = [tableView dequeueReusableCellWithIdentifier:zCellIndex];
	if (cell) {
		return cell; // このTVではCell個体識別しているため
	}
	
	// 以下、1回だけ通る
	
	cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
								  reuseIdentifier:zCellIndex];
	if (sharePlanList_) {
		// 選択禁止
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.selectionStyle = UITableViewCellSelectionStyleNone; // 選択時ハイライトなし
	} else {
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;	// > ディスクロージャマーク
	}
	cell.showsReorderControl = NO; // Move禁止
	
	switch (indexPath.section) {
		case 0: // 
			if (3 <= indexPath.row) {  // stock, need, weight
				// Calcボタン ------------------------------------------------------------------
				UIButton *bu = [UIButton buttonWithType:UIButtonTypeCustom]; // autorelease
				bu.frame = CGRectMake(0,16, 44,44);
				[bu setImage:[UIImage imageNamed:@"Icon44-Calc.png"] forState:UIControlStateNormal];
				//[bu setImage:[UIImage imageNamed:@"Icon-ClipOn.png"] forState:UIControlStateHighlighted];
				//buClip.showsTouchWhenHighlighted = YES;
				bu.tag = indexPath.section * GD_SECTION_TIMES + indexPath.row;
				[bu addTarget:self action:@selector(cellButtonCalc:) forControlEvents:UIControlEventTouchUpInside];
				//[buCopy release]; buttonWithTypeにてautoreleseされるため不要。UIButtonにinitは無い。
				cell.accessoryView = bu;
				cell.accessoryType = UITableViewCellAccessoryNone;
				cell.selectionStyle = UITableViewCellSelectionStyleNone; // 選択時ハイライトなし
			}
			switch (indexPath.row) {
				case 0: // Group
				{
					UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5,3, 100,12)];
					label.text = NSLocalizedString(@"Group", nil);
					label.textColor = [UIColor grayColor];
					label.backgroundColor = [UIColor clearColor];
					label.font = [UIFont systemFontOfSize:12];
					[cell.contentView addSubview:label]; //[label release];

					if (appDelegate_.app_is_iPad) {
						lbGroup_ = [[UILabel alloc] initWithFrame:
									CGRectMake(20,18, self.tableView.frame.size.width-60,24)];
						lbGroup_.font = [UIFont systemFontOfSize:20];
					} else {
						lbGroup_ = [[UILabel alloc] initWithFrame:
									CGRectMake(20,18, self.tableView.frame.size.width-60,16)];
						lbGroup_.font = [UIFont systemFontOfSize:14];
					}
											   // cell.frame.size.width ではダメ。初期幅が常に縦になっているため
					// selectGroupTVC が MlbGroup を参照、変更する
					if (addE2section_< 0) {
						// Edit Mode
						lbGroup_.tag = [e3target_.parent.row integerValue]; // E2.row
						lbGroup_.text = e3target_.parent.name;
					} else {
						// Add Mode
						lbGroup_.tag = addE2section_; // E2.row
						lbGroup_.text = [[e2array_ objectAtIndex:addE2section_] valueForKey:@"name"];
					}
					if ([lbGroup_.text length] <= 0) { // (未定)
						lbGroup_.text = NSLocalizedString(@"(New Index)", nil);
					}
					lbGroup_.backgroundColor = [UIColor clearColor]; // [UIColor grayColor]; //範囲チェック用
					[cell.contentView addSubview:lbGroup_]; //[MlbGroup release];
				}
					break;
				case 1: // Name
				{
					UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5,3, 100,12)];
					label.font = [UIFont systemFontOfSize:12];
					label.text = NSLocalizedString(@"Item name", nil);
					label.textColor = [UIColor grayColor];
					label.backgroundColor = [UIColor clearColor];
					[cell.contentView addSubview:label]; //[label release];

					if (appDelegate_.app_is_iPad) {
						tfName_ = [[UITextField alloc] initWithFrame:
								   CGRectMake(20,18, self.tableView.frame.size.width-60,24)];
						tfName_.font = [UIFont systemFontOfSize:20];
					} else {
						tfName_ = [[UITextField alloc] initWithFrame:
								   CGRectMake(20,18, self.tableView.frame.size.width-60,20)];
						tfName_.font = [UIFont systemFontOfSize:16];
					}
					tfName_.placeholder = NSLocalizedString(@"(New Goods)", nil);
					tfName_.keyboardType = UIKeyboardTypeDefault;
					tfName_.autocapitalizationType = UITextAutocapitalizationTypeSentences;
					tfName_.returnKeyType = UIReturnKeyDone; // ReturnキーをDoneに変える
					tfName_.backgroundColor = [UIColor clearColor]; //[UIColor grayColor]; //範囲チェック用
					tfName_.delegate = self; // textFieldShouldReturn:を呼び出すため
					[cell.contentView addSubview:tfName_]; //[MtfName release];
					tfName_.text = e3target_.name; // (未定)表示しない。Editへ持って行かれるため
					cell.accessoryType = UITableViewCellAccessoryNone; // なし
				}
					break;
				case 2: // Note
				{
					UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5,3, 100,12)];
					label.text = NSLocalizedString(@"Note", nil);
					label.textColor = [UIColor grayColor];
					label.backgroundColor = [UIColor clearColor];
					label.font = [UIFont systemFontOfSize:12];
					[cell.contentView addSubview:label]; //[label release];

					if (appDelegate_.app_is_iPad) {
						tvNote_ = [[UITextView alloc] initWithFrame:
								   CGRectMake(20,15, self.tableView.frame.size.width-60,130)];
						tvNote_.font = [UIFont systemFontOfSize:20];
					} else {
						tvNote_ = [[UITextView alloc] initWithFrame:
								   CGRectMake(20,15, self.tableView.frame.size.width-60,95)];
						tvNote_.font = [UIFont systemFontOfSize:16];
					}
					tvNote_.textAlignment = UITextAlignmentLeft;
					tvNote_.keyboardType = UIKeyboardTypeDefault;
					tvNote_.returnKeyType = UIReturnKeyDefault;  //改行有効にする
					tvNote_.backgroundColor = [UIColor clearColor];
					//MtvNote.backgroundColor = [UIColor grayColor]; //範囲チェック用
					tvNote_.delegate = self;
					[cell.contentView addSubview:tvNote_]; //[MtvNote release];
					if (e3target_.note == nil) {
						tvNote_.text = @"";  // TextViewは、(nil) と表示されるので、それを消すため。
					} else {
						tvNote_.text = e3target_.note;
					}
					cell.accessoryType = UITableViewCellAccessoryNone; // なし
				}
					break;
				case 3: // Stock Qty.
				{
#ifdef DEBUG
					//cell.backgroundColor = [UIColor grayColor]; //範囲チェック用
#endif
					{
						UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(120,2, 90,20)];
						label.text = NSLocalizedString(@"StockQty", nil);
						label.textAlignment = UITextAlignmentLeft;
						label.textColor = [UIColor grayColor];
						label.backgroundColor = [UIColor clearColor];
						label.font = [UIFont systemFontOfSize:14];
						[cell.contentView addSubview:label]; //[label release];
					}
					long lVal = (long)[e3target_.stock integerValue];
					{
						lbStock_ = [[UILabel alloc] initWithFrame:CGRectMake(10, 2, 94, 20)];
									//CGRectMake(self.tableView.frame.size.width-30-90,1, 90,20)];
						lbStock_.backgroundColor = [UIColor clearColor];
						lbStock_.textAlignment = UITextAlignmentCenter;
						lbStock_.font = [UIFont systemFontOfSize:24];
						[cell.contentView addSubview:lbStock_];
						// 3桁コンマ付加
						lbStock_.text = GstringFromNumber(e3target_.stock);
					}
					dialStock_ = [[AZDial alloc] initWithFrame:CGRectMake(10,16, self.tableView.frame.size.width-80,44)
																		delegate:self  dial:lVal  min:0  max:9999  step:1  stepper:YES];
					dialStock_.backgroundColor = [UIColor clearColor];
					[cell.contentView addSubview:dialStock_];
				}
					break;
				case 4: // Need
				{
					{
						UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(120,2, 90,20)];
						label.text = NSLocalizedString(@"Need Qty", nil);
						label.textAlignment = UITextAlignmentLeft;
						label.textColor = [UIColor grayColor];
						label.backgroundColor = [UIColor clearColor];
						label.font = [UIFont systemFontOfSize:14];
						[cell.contentView addSubview:label]; //[label release];
					}
					long lVal = (long)[e3target_.need integerValue];
					{
						lbNeed_ = [[UILabel alloc] initWithFrame:CGRectMake(10, 2, 94, 20)];
									//CGRectMake(self.tableView.frame.size.width/2-OFSX2,1, 90,20)];
						lbNeed_.backgroundColor = [UIColor clearColor];
						lbNeed_.textAlignment = UITextAlignmentCenter;
						lbNeed_.font = [UIFont systemFontOfSize:24];
						[cell.contentView addSubview:lbNeed_];
						// 3桁コンマ付加
						lbNeed_.text = GstringFromNumber(e3target_.need);
					}
					dialNeed_ = [[AZDial alloc] initWithFrame:CGRectMake(10,16, self.tableView.frame.size.width-80,44)
													  delegate:self  dial:lVal  min:0  max:9999  step:1  stepper:YES];
					dialNeed_.backgroundColor = [UIColor clearColor];
					[cell.contentView addSubview:dialNeed_];
				}
					break;
				case 5: // Weight
				{
					{
						UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(120,2, 90,20)];
						label.text = NSLocalizedString(@"One Weight", nil);
						label.textAlignment = UITextAlignmentLeft;
						label.textColor = [UIColor grayColor];
						label.backgroundColor = [UIColor clearColor];
						label.font = [UIFont systemFontOfSize:14];
						label.adjustsFontSizeToFitWidth = YES;
						label.minimumFontSize = 8;
						label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
						[cell.contentView addSubview:label];
					}
					long lVal = (long)[e3target_.weight integerValue];
					{
						lbWeight_ = [[UILabel alloc] initWithFrame:CGRectMake(10, 2, 94, 20)];
									 //CGRectMake(self.tableView.frame.size.width/2-OFSX2,1, 90,20)];
						lbWeight_.backgroundColor = [UIColor clearColor];
						lbWeight_.textAlignment = UITextAlignmentCenter;
						lbWeight_.font = [UIFont systemFontOfSize:24];
						[cell.contentView addSubview:lbWeight_];
						// 3桁コンマ付加
						lbWeight_.text = GstringFromNumber(e3target_.weight);
					}
#ifdef WEIGHT_DIAL
					dialWeight_ = [[AZDial alloc] initWithFrame:CGRectMake(10,16, self.tableView.frame.size.width-80,44)
													   delegate:self  dial:lVal  min:0  max:WEIGHT_MAX  step:10  stepper:YES];
					dialWeight_.backgroundColor = [UIColor clearColor];
					//[mDialWeight setStepperMagnification:10.0];
					[cell.contentView addSubview:dialWeight_];
#else				
					{
						MsliderWeight = [[UISlider alloc] initWithFrame:
										 CGRectMake(10,0, self.tableView.frame.size.width-80,60)];
						[MsliderWeight addTarget:self action:@selector(slidWeight:) forControlEvents:UIControlEventValueChanged];
						[MsliderWeight addTarget:self action:@selector(slidWeightUp:) forControlEvents:UIControlEventTouchUpInside];
						[cell.contentView addSubview:MsliderWeight]; [MsliderWeight release];
						if (lVal <= WEIGHT_CENTER_OFFSET)
							MsliderWeight.minimumValue = 0.0f;
						else
							MsliderWeight.minimumValue = (float)(lVal - WEIGHT_CENTER_OFFSET);
						
						if (lVal < WEIGHT_MAX - WEIGHT_CENTER_OFFSET)
							MsliderWeight.maximumValue = (float)(lVal + WEIGHT_CENTER_OFFSET);
						else
							MsliderWeight.maximumValue = WEIGHT_MAX;
						//
						MsliderWeight.value = lVal;
					}{
						MlbWeightMin = [[UILabel alloc] initWithFrame:CGRectMake(10,40, 40,15)];
						MlbWeightMin.textAlignment = UITextAlignmentLeft;
						MlbWeightMin.textColor = [UIColor grayColor];
						MlbWeightMin.backgroundColor = [UIColor clearColor];
						MlbWeightMin.font = [UIFont systemFontOfSize:12];
						[cell.contentView addSubview:MlbWeightMin]; [MlbWeightMin release];
						MlbWeightMin.text = [NSString stringWithFormat:@"%ld", (long)MsliderWeight.minimumValue];
																		// ↑左寄せにつき数字不要
					}{
						MlbWeightMax = [[UILabel alloc] initWithFrame:
										CGRectMake(self.tableView.frame.size.width-OFSX1,40, 40,15)];
						MlbWeightMax.textAlignment = UITextAlignmentRight;
						MlbWeightMax.textColor = [UIColor grayColor];
						MlbWeightMax.backgroundColor = [UIColor clearColor];
						MlbWeightMax.font = [UIFont systemFontOfSize:12];
						[cell.contentView addSubview:MlbWeightMax]; [MlbWeightMax release];
						MlbWeightMax.text = [NSString stringWithFormat:@"%5ld", (long)MsliderWeight.maximumValue];
					}
#endif
				}
					break;
			}
			break;
			
		case 1:	// section 1: Shopping
			switch (indexPath.row) {
				case 0: // Keyword
				{
					UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5,3, 100,12)];
					label.font = [UIFont systemFontOfSize:12];
					label.text = NSLocalizedString(@"Shop Keyword", nil);
					label.textColor = [UIColor grayColor];
					label.backgroundColor = [UIColor clearColor];
					[cell.contentView addSubview:label]; //[label release];

					if (appDelegate_.app_is_iPad) {
						tfKeyword_ = [[UITextField alloc] initWithFrame:
									  CGRectMake(20,18, self.tableView.frame.size.width-60,24)];
						tfKeyword_.font = [UIFont systemFontOfSize:20];
					} else {
						tfKeyword_ = [[UITextField alloc] initWithFrame:
									  CGRectMake(20,18, self.tableView.frame.size.width-60,20)];
						tfKeyword_.font = [UIFont systemFontOfSize:16];
					}
					tfKeyword_.placeholder = NSLocalizedString(@"Shop Keyword placeholder", nil);
					tfKeyword_.keyboardType = UIKeyboardTypeDefault;
					tfKeyword_.autocapitalizationType = UITextAutocapitalizationTypeSentences;
					tfKeyword_.returnKeyType = UIReturnKeyDone; // ReturnキーをDoneに変える
					tfKeyword_.backgroundColor = [UIColor clearColor]; //[UIColor grayColor]; //範囲チェック用
					tfKeyword_.delegate = self; // textFieldShouldReturn:を呼び出すため
					[cell.contentView addSubview:tfKeyword_]; //[MtfKeyword release];
					tfKeyword_.text = e3target_.shopKeyword; // (未定)表示しない。Editへ持って行かれるため
					cell.accessoryType = UITableViewCellAccessoryNone; // なし
					cell.tag = 00;
				}
					break;
				
				default:
				{
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.selectionStyle = UITableViewCellSelectionStyleBlue; // 選択時ハイライト
					if ([NSLocalizedString(@"CountryCode", nil) isEqualToString:@"jp"]) {
						switch (indexPath.row) {
							case 1: 
								cell.imageView.image = [UIImage imageNamed:@"Icon32-Amazon"];
								cell.textLabel.text = NSLocalizedString(@"Shop Amazon.co.jp", nil);	
								cell.tag = 01;		break;
							case 2: 
								cell.imageView.image = [UIImage imageNamed:@"Icon32-Rakuten"];
								cell.textLabel.text = NSLocalizedString(@"Shop Rakuten", nil);				
								cell.tag = 11;		break;
							case 3: 
								cell.imageView.image = [UIImage imageNamed:@"Icon32-Amazon"];
								cell.textLabel.text = NSLocalizedString(@"Shop Amazon.com", nil);	
								cell.tag = 02;		break;
						}
					} else {
						switch (indexPath.row) {
							case 1: 
								cell.imageView.image = [UIImage imageNamed:@"Icon32-Amazon"];
								cell.textLabel.text = NSLocalizedString(@"Shop Amazon.com", nil);	
								cell.tag = 02;		break;
							case 2: 
								cell.imageView.image = [UIImage imageNamed:@"Icon32-Amazon"];
								cell.textLabel.text = NSLocalizedString(@"Shop Amazon.co.jp", nil);	
								cell.tag = 01;		break;
							case 3: 
								cell.imageView.image = [UIImage imageNamed:@"Icon32-Rakuten"];
								cell.textLabel.text = NSLocalizedString(@"Shop Rakuten", nil);				
								cell.tag = 11;		break;
						}
					}
				}
					break;
			}
	}
    return cell;
}

- (void)actionWebTitle:(NSString*)zTitle  URL:(NSString*)zUrl  Domain:(NSString*)zDomain
{
	if ([tfKeyword_.text length]<=0) {
		tfKeyword_.text = tfName_.text;
		appDelegate_.app_UpdateSave = YES; // 変更あり
		self.navigationItem.rightBarButtonItem.enabled = appDelegate_.app_UpdateSave;
	}
	// 日本語を含むURLをUTF8でエンコーディングする
	// 第3引数のCFSTR(";,/?:@&=+$#")で指定した文字列はエンコードされずにそのまま残る
	//NSString *zKeyword = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
	//																		 (CFStringRef)MtfKeyword.text,
	//																		 CFSTR(";,/?:@&=+$#"),
	//																		 NULL,
	//																		 kCFStringEncodingUTF8);	// release必要

	// __bridge_transfer : CオブジェクトをARC管理オブジェクトにする
	NSString *zKeyword = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
																			 (__bridge CFStringRef)tfKeyword_.text,
																			 CFSTR(";,/?:@&=+$#"),
																			 NULL,
																			 kCFStringEncodingUTF8);	// release必要

	WebSiteVC *web = [[WebSiteVC alloc] init];
	web.title = zTitle;
	web.Rurl = [zUrl stringByAppendingString:zKeyword];
	web.RzDomain = zDomain;
	//[zKeyword release], 
	zKeyword = nil;

	if (appDelegate_.app_is_iPad) {
		UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:web];
		nc.modalPresentationStyle = UIModalPresentationPageSheet;  // 背景Viewが保持される
		// FullScreenにするとPopoverが閉じられる。さらに、背後が破棄されてE3viewController:viewWillAppear が呼び出されるようになる。
		nc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;//	UIModalTransitionStyleFlipHorizontal
		//[self　 presentModalViewController:nc animated:YES];  NG//回転しない
		//[self.navigationController presentModalViewController:nc animated:YES];  NG//回転しない
		[appDelegate_.mainSVC presentModalViewController:nc animated:YES];  //回転する
		//[nc release];
	} else {
		[self.navigationController pushViewController:web animated:YES];
	}
	//[web release];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];	// 選択状態を解除する

	[tfName_ resignFirstResponder]; // キーボード非表示
	[tvNote_ resignFirstResponder]; // キーボード非表示
	[tfKeyword_ resignFirstResponder]; // キーボード非表示
	
	switch (indexPath.section) {
		case 0: // 
			switch (indexPath.row) {
				case 0: // Group
				{
					// selectGroupTVC へ
					selectGroupTVC *selectGroup = [[selectGroupTVC alloc] init];
					selectGroup.RaE2array = e2array_;
					selectGroup.RlbGroup = lbGroup_; // .tag=E2.row  .text=E2.name
					[self.navigationController pushViewController:selectGroup animated:YES];
					//[selectGroup release];
				}
					break;
				case 1: // Name
				{
					[tfName_ becomeFirstResponder]; // ファーストレスポンダにする ⇒ キーボード表示
				}
					break;
				case 2: // Note
				{
					[tvNote_ becomeFirstResponder]; // ファーストレスポンダにする ⇒ キーボード表示
				}
					break;
			}
			break;
		
		case 1: {	// section 1: Shopping
			UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
			switch (cell.tag) {
				case 00: // Name
				{
					[tfKeyword_ becomeFirstResponder]; // ファーストレスポンダにする ⇒ キーボード表示
				}
					break;
				case 01: // Amazon.co.jp
				{
					NSString *zUrl;
					if (appDelegate_.app_is_iPad) {
						// PCサイト　　　　URL表示するようになったので長くする＜＜TAGが見えないように
						// アソシエイトリンク作成方法⇒ https://affiliate.amazon.co.jp/gp/associates/help/t121/a1
						//www.amazon.co.jp/gp/search?ie=UTF8&keywords=[SEARCH_PARAMETERS]&tag=[ASSOCIATE_TAG]&index=blended&linkCode=ure&creative=6339
						zUrl = @"http://www.amazon.co.jp/s/?ie=UTF8&index=blended&linkCode=ure&creative=6339&tag=art063-22&keywords=";
					} else {
						// モバイルサイト　　　　　"ie=UTF8" が無いと日本語キーワードが化ける
						//www.amazon.co.jp/gp/aw/s/ref=is_s_?__mk_ja_JP=%83J%83%5E%83J%83i&k=[SEARCH_PARAMETERS]&url=search-alias%3Daps
						zUrl = @"http://www.amazon.co.jp/gp/aw/s/ref=is_s_?ie=UTF8&__mk_ja_JP=%83J%83%5E%83J%83i&url=search-alias%3Daps&at=art063-22&k=";
					}
					[self actionWebTitle:NSLocalizedString(@"Shop Amazon.co.jp", nil)
									 URL:zUrl
								  Domain:@".amazon.co.jp"];
				}
					break;
				case 02: // Amazon.com
				{
					NSString *zUrl;
					if (appDelegate_.app_is_iPad) {
						// PCサイト
						//www.amazon.com/s/?tag=azuk-20&creative=392009&campaign=212361&link_code=wsw&_encoding=UTF-8&search-alias=aps&field-keywords=LEGO&Submit.x=16&Submit.y=14&Submit=Go
						//NSString *zUrl = @"http://www.amazon.com/s/?tag=azuk-20&_encoding=UTF-8&k="; URL表示するようになったので長くする＜＜TAGが見えないように
						zUrl = @"http://www.amazon.com/s/?_encoding=UTF-8&search-alias=aps&creative=392009&campaign=212361&tag=azuk-20&field-keywords=";
					} else {
						// モバイルサイト
						//www.amazon.com/gp/aw/s/ref=is_box_?k=LEGO
						zUrl = @"http://www.amazon.com/gp/aw/s/ref=is_box_?_encoding=UTF-8&link_code=wsw&search-alias=aps&tag=azuk-20&k=";
					}
					[self actionWebTitle:NSLocalizedString(@"Shop Amazon.com", nil)
									 URL:zUrl
								  Domain:@".amazon.com"];
				}
					break;
				case 11: // 楽天 Search
				{			// アフィリエイトID(β版): &afid=0e4c9297.0f29bc13.0e4c9298.6adf8529
					NSString *zUrl;
					if (appDelegate_.app_is_iPad) {
						// PCサイト
						zUrl = @"http://search.rakuten.co.jp/search/mall/?sv=2&p=0&afid=0e4c9297.0f29bc13.0e4c9298.6adf8529&sitem=";
					} else {
						// モバイルサイト
						//http://search.rakuten.co.jp/search/spmall?sv=2&p=0&sitem=SG7&submit=商品検索&scid=af_ich_link_search&scid=af_ich_link_search
						zUrl = @"http://search.rakuten.co.jp/search/spmall/?sv=2&p=0&afid=0e4c9297.0f29bc13.0e4c9298.6adf8529&sitem=";
					}
					[self actionWebTitle:NSLocalizedString(@"Shop Rakuten", nil)
									 URL:zUrl
								  Domain:@".rakuten.co.jp"];
				}
					break;
				case 21: // ケンコーコム Search
				{			// アフィリエイトID
					NSString *zUrl = @"http://sp.kenko.com/";
					[self actionWebTitle:NSLocalizedString(@"Shop Kenko.com", nil)
									 URL:zUrl
								  Domain:@".kenko.com"];
				}
					break;
			}
		}
			break;
	}
}


#pragma mark - <UITextFieldDelegete>
//============================================<UITextFieldDelegete>
- (void)nameDone:(id)sender {
	[tfName_ resignFirstResponder]; // キーボード非表示
	[tvNote_ resignFirstResponder]; // キーボード非表示
	[tfKeyword_ resignFirstResponder]; // キーボード非表示
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	if (calcView_) {	// あれば一旦、破棄する
		[calcView_ hide];
		[calcView_ removeFromSuperview];  // これでCalcView.deallocされる
		calcView_ = nil;
	}
	// スクロールして textField が隠れた状態で resignFirstResponder するとフリースするため
	self.tableView.scrollEnabled = NO; // スクロール禁止
	//self.navigationItem.leftBarButtonItem.enabled = NO;
	if (appDelegate_.app_is_iPad) {
		//iPad：キー操作でキーボードを隠すことができるから[Done]ボタン不要
	} else {
		// 左[Cancel] 無効にする
		self.navigationItem.leftBarButtonItem.enabled = NO;
		// 右[Done]
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] 
												   initWithBarButtonSystemItem:UIBarButtonSystemItemDone
												   target:self action:@selector(nameDone:)];
	}
}

//  テキストが変更される「直前」に呼び出される。これにより入力文字数制限を行っている。
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	// senderは、MtextView だけ
    NSMutableString *zText = [textField.text mutableCopy];
    [zText replaceCharactersInRange:range withString:string];
	// 置き換えた後の長さをチェックする
	if ([zText length] <= TEXTFIELD_MAXLENGTH) {
		appDelegate_.app_UpdateSave = YES; // 変更あり
		self.navigationItem.rightBarButtonItem.enabled = appDelegate_.app_UpdateSave;
		return YES;
	} else {
		return NO;
	}
}

- (BOOL)textFieldShouldReturn: (UITextField *)textField
{
	[textField resignFirstResponder]; // ファーストレスポンダでなくす ⇒ キーボード非表示
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	self.tableView.scrollEnabled = YES; // スクロール許可
	//self.navigationItem.leftBarButtonItem.enabled = YES;
	if (appDelegate_.app_is_iPad) {
		//iPad：キー操作でキーボードを隠すことができるから[Done]ボタン不要
	} else {
		// 左[Cancel] 有効にする
		self.navigationItem.leftBarButtonItem.enabled = YES;
		// 右[Save]
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] 
												   initWithBarButtonSystemItem:UIBarButtonSystemItemSave
												   target:self action:@selector(saveClose:)];
	}
}


#pragma mark - <UITextViewDelegete>
//============================================<UITextViewDelegete>
- (void)noteDone:(id)sender {
	[tvNote_ resignFirstResponder];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	if (calcView_) {	// あれば一旦、破棄する
		[calcView_ hide];
		[calcView_ removeFromSuperview];  // これでCalcView.deallocされる
		calcView_ = nil;
	}
	self.tableView.scrollEnabled = NO; // スクロール禁止
	//self.navigationItem.leftBarButtonItem.enabled = NO;
	if (appDelegate_.app_is_iPad) {
		//iPad：キー操作でキーボードを隠すことができるから[Done]ボタン不要
	} else {
		// 左[Cancel] 無効にする
		self.navigationItem.leftBarButtonItem.enabled = NO;
		// 右[Done]
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] 
												   initWithBarButtonSystemItem:UIBarButtonSystemItemDone
												   target:self action:@selector(noteDone:)];
	}
}

//  テキストが変更される「直前」に呼び出される。これにより入力文字数制限を行っている。
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range 
 replacementText:(NSString *)zReplace
{
	// senderは、MtextView だけ
    NSMutableString *zText = [textView.text mutableCopy];
    [zText replaceCharactersInRange:range withString:zReplace];
	// 置き換えた後の長さをチェックする
	if ([zText length] <= TEXTVIEW_MAXLENGTH) {
		appDelegate_.app_UpdateSave = YES; // 変更あり
		self.navigationItem.rightBarButtonItem.enabled = appDelegate_.app_UpdateSave;
		return YES;
	} else {
		return NO;
	}
}

//- (BOOL)textViewShouldEndEditing:(UITextView *)textView
- (void)textViewDidEndEditing:(UITextView *)textView
{
	self.tableView.scrollEnabled = YES; // スクロール許可
	//self.navigationItem.leftBarButtonItem.enabled = YES;
	if (appDelegate_.app_is_iPad) {
		//iPad：キー操作でキーボードを隠すことができるから[Done]ボタン不要
	} else {
		// 左[Cancel] 有効にする
		self.navigationItem.leftBarButtonItem.enabled = YES;
		// 右[Save]
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] 
												   initWithBarButtonSystemItem:UIBarButtonSystemItemSave
												   target:self action:@selector(saveClose:)];
	}
}


#pragma mark - <AZDialDelegate>
- (void)dialChanged:(id)sender  dial:(NSInteger)dial
{
	if (sender==dialStock_) {
		lbStock_.text = GstringFromNumber([NSNumber numberWithInteger:dial]);
	}
	else if (sender==dialNeed_) {
		lbNeed_.text = GstringFromNumber([NSNumber numberWithInteger:dial]);
	}
#ifdef WEIGHT_DIAL
	else if (sender==dialWeight_) {
		lbWeight_.text = GstringFromNumber([NSNumber numberWithInteger:dial]);
	}
#endif
}

- (void)dialDone:(id)sender  dial:(NSInteger)dial
{
	if (sender==dialStock_) {
		if ([e3target_.stock longValue] != dial) { // 変更あり
			lbStock_.text = GstringFromNumber([NSNumber numberWithInteger:dial]);
			e3target_.stock = [NSNumber numberWithInteger:dial];
			appDelegate_.app_UpdateSave = YES; // 変更あり
			self.navigationItem.rightBarButtonItem.enabled = appDelegate_.app_UpdateSave;
		}
	}
	else if (sender==dialNeed_) {
		if ([e3target_.need longValue] != dial) { // 変更あり
			lbNeed_.text = GstringFromNumber([NSNumber numberWithInteger:dial]);
			e3target_.need = [NSNumber numberWithInteger:dial];
			appDelegate_.app_UpdateSave = YES; // 変更あり
			self.navigationItem.rightBarButtonItem.enabled = appDelegate_.app_UpdateSave;
		}
	}
#ifdef WEIGHT_DIAL
	else if (sender==dialWeight_) {
		if ([e3target_.weight longValue] != dial) { // 変更あり
			lbWeight_.text = GstringFromNumber([NSNumber numberWithInteger:dial]);
			e3target_.weight = [NSNumber numberWithInteger:dial];
			appDelegate_.app_UpdateSave = YES; // 変更あり
			self.navigationItem.rightBarButtonItem.enabled = appDelegate_.app_UpdateSave;
		}
	}
#endif
}


@end

