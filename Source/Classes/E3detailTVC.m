//
//  E3detailTVC.m
//  AzPacking
//
//  Created by 松山 和正 on 10/01/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
#import "E3detailTVC.h"


#import "Global.h"
#import "AppDelegate.h"
#import "Elements.h"
#import "E3viewController.h"
#import "selectGroupTVC.h"
#import "editLabelNumberVC.h"
#import "CalcView.h"
//#import "WebSiteVC.h"
#import "PatternImageView.h"

//#import "GoogleService.h"
#import "CameraVC.h"


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
- (void)viewDesignPhoto;
- (void)viewDesign;
- (void)alertWeightOver;
@end

@implementation E3detailTVC
{
@private
	UILabel		*mLbGroup;	// .tag = E2.row　　　以下全てcellがOwnerになる
	UITextField	*mTfName;
	UITextField	*mTfKeyword;	//[1.1]Shopping keyword
	UITextView	*mTvNote;
	UILabel		*lbStock_;
	UILabel		*lbNeed_;
	UILabel		*lbWeight_;
	AZDial			*dialStock_;
	AZDial			*dialNeed_;
	AZDial			*dialWeight_;
	
	CalcView				*mCalcView;
	
	// Picasa Photo
	UILabel				*mLbPhotoMsg;
	UIImageView		*mIvIconPicasa;
	UIActivityIndicatorView	*mActivityIndicator_on_IconPicasa;
	UIButton				*mBuCamera;
	UIImageView		*mIvPhoto;
	UIScrollView			*mSvPhoto;

	// Shop Photo
	UIImageView		*mIvIconShop;
	UIActivityIndicatorView	*mActivityIndicator_on_IconShop;
	//UIImageView		*mIvShop;
	//UIScrollView			*mSvShop;
	UIWebView				*mWebViewShop;
	
	AppDelegate		*mAppDelegate;
	float						mTableViewContentY;
}
@synthesize e2array = pE2array;
@synthesize e3array = pE3array;
@synthesize e3target = pE3target;
@synthesize addE2section = pAddE2section;
@synthesize addE3row = pAddE3row;
@synthesize sharePlanList = pSharePlanList;
@synthesize delegate = pDelegate;
@synthesize selfPopover = pSelfPopover;



#pragma mark - View lifecicle

// UITableViewインスタンス生成時のイニシャライザ　viewDidLoadより先に1度だけ通る
- (id)initWithStyle:(UITableViewStyle)style 
{
	if ((self = [super initWithStyle:UITableViewStyleGrouped])) {  // セクションありテーブル
		// 初期化成功
		mAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		mAppDelegate.ppChanged = NO;
		pSharePlanList = NO;
		mTableViewContentY = -1;

		// 背景テクスチャ・タイルペイント
	/*	if (mAppDelegate.ppIsPad  OR  IOS_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0") ) {
			UIView* view = self.tableView.backgroundView;
			if (view) {
				PatternImageView *tv = [[PatternImageView alloc] initWithFrame:view.frame
																  patternImage:[UIImage imageNamed:@"Tx-Back"]]; // タイルパターン生成
				[view addSubview:tv];
			}
			self.contentSizeForViewInPopover = GD_POPOVER_SIZE_E3edit;
			//[1.1]//[self.tableView setScrollEnabled:NO]; // スクロール禁止
		}
		else {
			self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Tx-Back"]];
		}*/
		
		[self setPreferredContentSize:GD_POPOVER_SIZE_E3edit];
		[self.tableView setBackgroundView:nil];	//iOS6//これで次行が有効になる。
		self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Tx-Back"]];
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
	
	if (pSharePlanList==NO) {
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

	self.navigationItem.rightBarButtonItem.enabled = mAppDelegate.ppChanged;

	// 電卓が出ておれば消す
	if (mCalcView && [mCalcView isShow]) {
		[mCalcView hide]; //　ここでは隠すだけ。 removeFromSuperviewするとアニメ無く即消えてしまう。
	}
	
	// 画面表示に関係する Option Setting を取得する
	//NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	[self viewDesign]; // 下層で回転して戻ったときに再描画が必要
	// テーブルビューを更新します。
    [self.tableView reloadData];
}

- (IBAction)handlePinchGesture:(UIGestureRecognizer *)sender 
{
	CGFloat factor = [(UIPinchGestureRecognizer *)sender scale];
	mSvPhoto.zoomScale = factor;
}

- (void)viewDesignPhoto
{
	CGRect rcPhoto;
	if (mAppDelegate.ppIsPad) { // iPad  TableView(Grouped)両端の余白:-20
		//rcPhoto = CGRectMake(8, 44-4, self.tableView.bounds.size.width-16-60, 480);
		rcPhoto = CGRectMake(4, 44-4, self.preferredContentSize.width-8-60, 400);
	}
	else if (self.tableView.frame.size.width < 400) {	// iPhone縦
		rcPhoto = CGRectMake(4, 40, 320-8-20, 320);
	}
	else {		// iPhone横
		rcPhoto = CGRectMake(4, 40, 480-8-20, 320);
	}
	
	// Icons
	mIvIconPicasa.frame = CGRectMake(4, 4, 32, 32);
	mActivityIndicator_on_IconPicasa.frame = mIvIconPicasa.bounds;
	mBuCamera.frame = CGRectMake(rcPhoto.origin.x+rcPhoto.size.width-40, 0, 44, 44);
	mLbPhotoMsg.frame = CGRectMake(4+32+4, 4, mBuCamera.frame.origin.x-4-32-4, 36);
	//mLbPhotoMsg.backgroundColor = [UIColor brownColor];

	if (mIvPhoto==nil OR mSvPhoto==nil)  {
		return; //　Cell生成前に呼ばれたとき
	}
	
	// Photo 表示位置調整
	mSvPhoto.frame = rcPhoto;
	//DEBUG_LOG_RECT(mSvPhoto.frame, @"mSvPhoto.frame");	
	// 全体表示するためにスケール調整
	CGFloat fw = mSvPhoto.frame.size.width / 640;
	CGFloat fh = mSvPhoto.frame.size.height / 640;
	if (fw < fh) {
		mSvPhoto.minimumZoomScale = fw;
		mSvPhoto.zoomScale = fw;
	} else {
		mSvPhoto.minimumZoomScale = fh;
		mSvPhoto.zoomScale = fh;
	}

	if (mWebViewShop) {
		// Shop 表示位置調整
		rcPhoto.origin.y = 4;
		mWebViewShop.frame = rcPhoto;
	}
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{	// Zoom対象になるUIImageViewを返す
	if (scrollView==mSvPhoto) {
		return mIvPhoto;
	}
	return nil;
}

- (void)viewDesign
{
	// 回転によるリサイズ
	CGRect rect;
	float fWidth = self.tableView.frame.size.width;
	
	rect = mLbGroup.frame;
	rect.size.width = fWidth - 80;
	mLbGroup.frame = rect;
	
	rect = mTfName.frame;
	rect.size.width = fWidth - 60;
	mTfName.frame = rect;
	
	rect = mTvNote.frame;
	rect.size.width = fWidth - 60;
	mTvNote.frame = rect;
	
	rect = mTfKeyword.frame;
	rect.size.width = fWidth - 60;
	mTfKeyword.frame = rect;
	
	rect = dialStock_.frame;
	rect.size.width = fWidth - 80;
	[dialStock_ setFrame:rect]; 	//NG//mDialStock.frame = rect;
	[dialNeed_ setFrame:rect];
	[dialWeight_ setFrame:rect];

	[self viewDesignPhoto];
}

- (void)performNameFirstResponder
{
	if (mTfName && [mTfName.text length]<=0) {			// ブランクならば、
		[mTfName becomeFirstResponder];  // キーボード表示  NG/iPadでは効かなかった。0.5秒後にするとOK
	}
}

// ビューが最後まで描画された後やアニメーションが終了した後にこの処理が呼ばれる
- (void)viewDidAppear:(BOOL)animated 
{
    [super viewDidAppear:animated];
	[self.navigationController setToolbarHidden:YES animated:NO]; //[2.0.2]ツールバー廃止
	//[self.navigationController setToolbarHidden:YES animated:animated]; // ツールバー消す
	[self.tableView flashScrollIndicators]; // Apple基準：スクロールバーを点滅させる
	
//	if (mAppDelegate.ppOptShowAd) {
//		// 各viewDidAppear:にて「許可/禁止」を設定する
//		[mAppDelegate AdRefresh:YES];  //iPhoneは消すことにした。
//	}
	
	//この時点で MtfName は未生成だから、0.5秒後に処理する
	[self performSelector:@selector(performNameFirstResponder) withObject:nil afterDelay:0.5f]; // 0.5秒後に呼び出す
}

// ビューが非表示にされる前や解放される前ににこの処理が呼ばれる
- (void)viewWillDisappear:(BOOL)animated 
{
	if (mAppDelegate.ppIsPad) {
		//
	} else {
		if (mCalcView) {	// あれば破棄する
			[mCalcView hide];
			[mCalcView removeFromSuperview];  // これでCalcView.deallocされる
			//[McalcView release]; +1残っているが、viewが破棄されるときにreleseされるので、ここは不要
			mCalcView = nil;
		}
	}
	[super viewWillDisappear:animated];
}


#pragma mark  View Rotate

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

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{	// ユーザインタフェースの回転前に呼ばれる。 ＜＜OS 3.0以降の推奨メソッド＞＞
	// この開始時に消す。　　この時点で self.view.frame は回転していない。
	if (mCalcView && [mCalcView isShow]) {
		[mCalcView hide]; //　ここでは隠すだけ。 removeFromSuperviewするとアニメ無く即消えてしまう。
	}
	
	[mAppDelegate AdRefresh];	//広告生成のみ
	[mAppDelegate AdViewWillRotate:orientation];
}

// ユーザインタフェースの回転の最後の半分が始まる前にこの処理が呼ばれる　＜＜このタイミングで配置転換すると見栄え良い＞＞
//DEP//- (void)willAnimateSecondHalfOfRotationFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation duration:(NSTimeInterval)duration
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{	// ユーザインタフェースの回転後に呼ばれる
	//[self.tableView reloadData];
	[self viewDesign]; // cell生成の後
}

- (void)dealloc    // 生成とは逆順に解放するのが好ましい
{
	if (mWebViewShop) {
		[mWebViewShop stopLoading];
		mWebViewShop.delegate = nil; // これしないと落ちます
		mWebViewShop = nil;
	}
	pSelfPopover = nil;
}


#pragma mark - iCloud
- (void)refreshAllViews:(NSNotification*)note 
{	// iCloud-CoreData に変更があれば呼び出される
	@synchronized(note)
	{
		[self viewWillAppear:YES];
		[mActivityIndicator_on_IconPicasa stopAnimating];
	}
}


#pragma mark - Action

- (void)cancelClose:(id)sender 
{	// E3は、Cancel時、新規ならば破棄、修正ならば復旧、させる
	if (pE3target && pSharePlanList==NO) {  // Sample表示のときrollbackすると、一時表示用のE1まで消えてしまうので回避する。
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
		[pE3target.managedObjectContext rollback]; // 前回のSAVE以降を取り消す
		
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

	if (mAppDelegate.ppIsPad) {
		if (pSelfPopover) {
			[pSelfPopover dismissPopoverAnimated:YES];
		}
	} else {
		[self.navigationController popViewControllerAnimated:YES];	// < 前のViewへ戻る
	}
}

// 編集フィールドの値を e3target_ にセットする
- (void)saveClose:(id)sender 
{
	if (pSharePlanList) return; // [Save]ボタンを消しているので通らないハズだが、念のため。
	
	if (mAppDelegate.ppIsPad) {
	} else {
		//[McalcView hide]; // 電卓が出ておれば消す
		if (mCalcView) {	// あれば破棄する
			[mCalcView save]; // 有効値あれば保存
		}
	}
	
	NSInteger lWeight = [pE3target.weight integerValue];  // MlbWeight.text integerValue];
	NSInteger lStock = [pE3target.stock integerValue];  // MlbStock.text integerValue];
	NSInteger lNeed = [pE3target.need integerValue];  // MlbNeed.text integerValue];
	//[0.2c]プラン総重量制限
	if (0 < lWeight) {  // longオーバーする可能性があるため商は求めない
		if (AzMAX_PLAN_WEIGHT / lWeight < lStock OR AzMAX_PLAN_WEIGHT / lWeight < lNeed) {
			[self alertWeightOver];
			return;
		}
	}
	
	//Pe3target,Pe2selected は ManagedObject だから更新すれば ManagedObjectContext に反映される
	// PICKER 指定したコンポーネントで選択された行のインデックスを返す。
	NSInteger newSection = mLbGroup.tag;
	if ([pE2array count]<=newSection) {
		NSLog(@"*** OVER newSection=%ld", (long)newSection);
		return;
	}
	E2 *e2objNew = [pE2array objectAtIndex:newSection];
	
	if (pAddE2section< 0 && 0 <= newSection)
	{	// Edit mode のときだけ、グループ移動による「旧グループの再集計」が必要になる
		NSInteger oldSection = [pE3target.parent.row integerValue];  // Edit mode
		
		if (oldSection != newSection) 
		{	// グループに変化があれば、
			// E2セクション(Group)の変更あり  self.e3section ==>> newSection
			NSInteger oldRow = [pE3target.row integerValue];	// 元ノードのrow　最後のrow更新処理で、ie3nodeRow以降を更新する。
			
			NSInteger newRow = (-1);
			// Add行に追加する （Add行は1つ下へ）
			for (E3* e3 in [pE3array objectAtIndex:newSection]) {
				if ([e3.need integerValue]==(-1)) { // Add行
					newRow = [e3.row integerValue];
				}
			}
			if (newRow<0) {	// 万一、Add行がバグで削除されたときのため
				newRow = [[pE3array objectAtIndex:newSection] count];  // セクション末尾
			}
			
			E2 *e2objOld = [pE2array objectAtIndex:oldSection];
			//--------------------------------------------------(1)MutableArrayの移動
			[[pE3array objectAtIndex:oldSection] removeObjectAtIndex:oldRow];
			[[pE3array objectAtIndex:newSection] insertObject:pE3target atIndex:newRow];
			
			// 異セクション間の移動　＜＜親(.e2selected)の変更が必要＞＞
			// 移動元セクション（親）から子を削除する
			[e2objOld removeChildsObject:pE3target];	// 元の親ノードにある子登録を抹消する
			// e2objOld 子が無くなったので再集計する
			[e2objOld setValue:[e2objOld valueForKeyPath:@"childs.@sum.noGray"] forKey:@"sumNoGray"];
			[e2objOld setValue:[e2objOld valueForKeyPath:@"childs.@sum.noCheck"] forKey:@"sumNoCheck"];
			[e2objOld setValue:[e2objOld valueForKeyPath:@"childs.@sum.weightStk"] forKey:@"sumWeightStk"];
			[e2objOld setValue:[e2objOld valueForKeyPath:@"childs.@sum.weightNed"] forKey:@"sumWeightNed"];
			// 異動先セクション（親）へ子を追加する
			[e2objNew addChildsObject:pE3target];	// 新しい親ノードに子登録する
			// e2objNew の再集計は、変更を含めて最後に実施
			
			// 元のrow付け替え処理　 異セクション間での移動： 双方のセクションで変化あったrow以降、全て更新
			NSInteger i;
			E3 *e3obj;
			for (i = oldRow ; i < [[pE3array objectAtIndex:oldSection] count] ; i++) {
				e3obj = [[pE3array objectAtIndex:oldSection] objectAtIndex:i];
				e3obj.row = [NSNumber numberWithInteger:i];
			}
			// Add行に追加
			pE3target.row = [NSNumber numberWithInteger:newRow];  
			// Add行以下のrow付け替え処理
			for (i = newRow ; i < [[pE3array objectAtIndex:newSection] count] ; i++) {
				e3obj = [[pE3array objectAtIndex:newSection] objectAtIndex:i];
				e3obj.row = [NSNumber numberWithInteger:i];
			}
		}
	}
	
	if( 50 < [mTfName.text length] ){
		// 長さが50超ならば、0文字目から50文字を切り出して保存　＜以下で切り出すとフリーズする＞
		[pE3target setValue:[mTfName.text substringWithRange:NSMakeRange(0, 50)] forKey:@"name"];
	}
	else if ([mTfName.text length]<=0) {
		// 品名未定ならば代入する　＜＜[Save]ボタンを押したのだから、削除されないようにする
		pE3target.name = NSLocalizedString(@"Untitled", nil);
	}
	else {
		pE3target.name = mTfName.text;
	}
	
	if( 50 < [mTfKeyword.text length] ){
		// 長さが50超ならば、0文字目から50文字を切り出して保存　＜以下で切り出すとフリーズする＞
		[pE3target setValue:[mTfKeyword.text substringWithRange:NSMakeRange(0, 50)] forKey:@"shopKeyword"];
	} else {
		pE3target.shopKeyword = mTfKeyword.text;
	}
	
	NSString *zNote;
	zNote = mTvNote.text;
	if( TEXTVIEW_MAXLENGTH < [zNote length] ){
		// 長さがTEXTVIEW_MAXLENGTH超ならば、0文字目からTEXTVIEW_MAXLENGTH文字を切り出して保存　＜以下で切り出すとフリーズする＞
		[pE3target setValue:[zNote substringWithRange:NSMakeRange(0, TEXTVIEW_MAXLENGTH)] forKey:@"note"];
	} else {
		[pE3target setValue:zNote forKey:@"note"];
	}
	
	[pE3target setValue:[NSNumber numberWithInteger:lWeight] forKey:@"weight"];  // 最小値が0でないとエラー発生
	[pE3target setValue:[NSNumber numberWithInteger:lStock] forKey:@"stock"];
	[pE3target setValue:[NSNumber numberWithInteger:lNeed] forKey:@"need"];
	[pE3target setValue:[NSNumber numberWithInteger:(lWeight*lStock)] forKey:@"weightStk"];
	[pE3target setValue:[NSNumber numberWithInteger:(lWeight*lNeed)] forKey:@"weightNed"];
	[pE3target setValue:[NSNumber numberWithInteger:(lNeed-lStock)] forKey:@"lack"]; // 不足数
	[pE3target setValue:[NSNumber numberWithInteger:((lNeed-lStock)*lWeight)] forKey:@"weightLack"]; // 不足重量
	
	NSInteger iNoGray = 0;
	if (0 < lNeed) iNoGray = 1;
	[pE3target setValue:[NSNumber numberWithInteger:iNoGray] forKey:@"noGray"]; // NoGray:有効(0<必要数)アイテム
	
	NSInteger iNoCheck = 0;
	if (0 < lNeed && lStock < lNeed) iNoCheck = 1;
	[pE3target setValue:[NSNumber numberWithInteger:iNoCheck] forKey:@"noCheck"]; // NoCheck:不足アイテム
	
	if (0 <= pAddE2section&& 0 <= pAddE3row) {
		/*(V0.4)addE3row_ に新規追加する。 addE3row_以下を先にずらすこと。
		 // 新規のとき、末尾になるように行番号を付与する
		 NSInteger rows = [[Pe3array objectAtIndex:newSection] count]; // 追加するセクションの現在行数
		 [Pe3target setValue:[NSNumber numberWithInteger:rows] forKey:@"row"];
		 // 親(E2)のchilesにe3editを追加する
		 [e2objNew addChildsObject:Pe3target];
		 */
		
		//(V0.4)addE3row_以下について、.row++ して、addE3row_を空ける。
		//		NSArray *aE3s = [NSArray arrayWithArray:[Pe3array objectAtIndex:newSection]];
		for (E3 *e3 in [pE3array objectAtIndex:newSection]) {
			if (pAddE3row <= [e3.row integerValue]) {
				e3.row = [NSNumber numberWithInteger:[e3.row integerValue]+1]; // +1
			}
		}
		//(V0.4)addE3row_に追加する。
		pE3target.row = [NSNumber numberWithInteger:pAddE3row];
		// E2-E3 Link
		pE3target.parent = e2objNew;
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
	
	if (pSharePlanList==NO) {  // SpMode=YESならば[SAVE]ボタンを非表示にしたので通らないハズだが、念のため。
		// SAVE : e3edit,e2list は ManagedObject だから更新すれば ManagedObjectContext に反映されている
		NSError *err = nil;
		if (![pE3target.managedObjectContext save:&err]) {
			NSLog(@"Unresolved error %@, %@", err, [err userInfo]);
			//abort();
		}
	}

//	// Photo
//	if ([pE3target.photoUrl hasPrefix:PHOTO_URL_UUID_PRIFIX]) {	// 写真あるがアップされていません
//		E4photo *e4 = pE3target.e4photo;
//		if (e4.photoData) {
//			// 写真DATAあるがＵＲＬ:UUIDにつき、Picasaアップする
//			[GoogleService photoUploadE3:pE3target];
//		}
//	}
	
	if (mAppDelegate.ppIsPad) {
		//[(PadNaviCon*)self.navigationController dismissPopoverSaved];  // SAVE: PadNaviCon拡張メソッド
		if (pSelfPopover) {
			if ([pDelegate respondsToSelector:@selector(refreshE3view)]) {	// メソッドの存在を確認する
				[pDelegate refreshE3view];// 親の再描画を呼び出す
			}
			[pSelfPopover dismissPopoverAnimated:YES];
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
	if (pSelfPopover) {	//dismissPopoverCancel
		if (mCalcView && [mCalcView isShow]) {
			[mCalcView cancel];  //　ラベル表示を元に戻す
		}
		[pSelfPopover dismissPopoverAnimated:YES];
	}
}


- (void)actionWebTitle:(NSString*)zTitle  Url:(NSString*)zUrl
{
	/*	WebSiteVC *web = [[WebSiteVC alloc] initWithBookmarkDelegate:self];	// [Bookmark] <webSiteBookmarkUrl:>
	 web.title = nil;
	 web.Rurl = zUrl;
	 web.RzDomain = nil;*/
	
	AZWebView *wv = [[AZWebView alloc] init];
	wv.ppBookmarkDelegate = self;
	wv.title = zTitle;
	wv.ppUrl = zUrl;
	wv.ppDomain = [NSSet setWithObjects:
				   @".amazon.co.jp",
				   @".amazon.com",
				   @".amazon.cn",
				   @".javari.jp",					//Amazon
				   @".doubleclick.net",		//Google
				   @".rakuten.ne.jp",
				   @".rakuten.co.jp",
				   @".apple.com",
				   @".azukid.com",
				   @".tumblr.com",
				   @"azukisoft.seesaa.net",
				   nil]; //許可ドメインを列記する
	
	if (mAppDelegate.ppIsPad) {
		UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:wv];
		nc.modalPresentationStyle = UIModalPresentationPageSheet;  // 背景Viewが保持される
		nc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;//	UIModalTransitionStyleFlipHorizontal
		//[mAppDelegate.mainSVC presentModalViewController:nc animated:YES];  //回転する
		[mAppDelegate.mainSVC presentViewController:nc animated:YES completion:nil];  //回転する
	} else {
		[self.navigationController pushViewController:wv animated:YES];
	}
}

- (void)actionWebSearchTitle:(NSString*)zTitle  URL:(NSString*)zUrl
{
	if ([mTfKeyword.text length]<=0) {
		mTfKeyword.text = mTfName.text;
		mAppDelegate.ppChanged = YES; // 変更あり
		self.navigationItem.rightBarButtonItem.enabled = mAppDelegate.ppChanged;
		
		mTfKeyword.text = azStringNoEmoji( mTfKeyword.text ); // 絵文字を除去する
		
	/*	// 絵文字を除去する
		NSMutableString *zKey = [NSMutableString new];
		for (NSUInteger i = 0; i < [mTfKeyword.text length]; i++)
		{
			// UNICODE(UTF-16)文字を順に取り出します。
			unichar code = [mTfKeyword.text characterAtIndex:i];
			// UNICODE(UTF-16)絵文字範囲 http://ja.wikipedia.org/wiki/SoftBank%E7%B5%B5%E6%96%87%E5%AD%97
			if ((0x20E0<=code && code<=0x2FFF) OR (0xD830<=code && code<=0xDFFF))
			{
				//NSLog(@"\\u%04x <<<", code);
				i++;
			} 
			else {
				//NSLog(@"\\u%04x", code);
				[zKey appendFormat:@"%C", code];
			}
		}
		NSLog(@"actionWebTitle: zKey=%@", zKey);
	 */
	}
	
	/* GstringPercentEscape()
	// 日本語を含むURLをUTF8でエンコーディングする
	// stringByAddingPercentEscapesUsingEncoding:はダメ　＜＜"(0×20)"#%><[\]^`{|}" しかエスケープしないため。
	// エスケープさせない「コマンド使用」など文字を記述
	static const CFStringRef charactersToLeaveUnescaped = NULL;  //コマンドを含まない文字列を変換するため
	// 通常ではエスケープされないが、してほしい文字を記述
	static const CFStringRef legalURLCharactersToBeEscaped = CFSTR("!*'();:@&=+$,./?%#[]");  //全てエスケープさせるため
	// __bridge_transfer : CオブジェクトをARC管理オブジェクトにする
	NSString *zKeyword = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(
																							   kCFAllocatorDefault,	
																							   (__bridge CFStringRef)mTfKeyword.text,
																							   charactersToLeaveUnescaped,
																							   legalURLCharactersToBeEscaped,
																							   kCFStringEncodingUTF8);
	NSLog(@"Escape: zKeyword {%@}", zKeyword);
	*/
	
	NSString *zKeyword = azStringPercentEscape( mTfKeyword.text );
	
/*	
	WebSiteVC *web = [[WebSiteVC alloc] initWithBookmarkDelegate:self];	// [Bookmark] <webSiteBookmarkUrl:>
	web.title = zTitle;
	web.Rurl = [zUrl stringByAppendingString:zKeyword];
	web.RzDomain = zDomain;
	zKeyword = nil;
*/

	[self actionWebTitle:zTitle Url:[zUrl stringByAppendingString:zKeyword]];
	zKeyword = nil;
}

- (void)actionCamera
{	
	// CameraVC へ 　　＜＜＜ UIImagePickerController:を使わないカメラ。　将来の機能アップ時に利用するかも
	CameraVC *cam = [[CameraVC alloc] init];
	cam.imageView = mIvPhoto;
	cam.e3target = pE3target;
	[self.navigationController pushViewController:cam animated:YES];
	
/*	// 標準カメラにした。
	UIImagePickerControllerSourceType stype = UIImagePickerControllerSourceTypeCamera;
	if ([UIImagePickerController isSourceTypeAvailable:stype]) {
		UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
		ipc.delegate = self;		// <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
		ipc.sourceType = stype;
		ipc.videoQuality = UIImagePickerControllerQualityTypeHigh;
		ipc.allowsEditing = YES;  // NO=最大解像度になってしまう　　YES=640x640になる
		if (appDelegate_.app_is_iPad) {
			[selfPopover_ presentPopoverFromRect:mIvPhoto.frame
									  inView:self.navigationController.view
										permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		} else {
			[self presentModalViewController:ipc animated:YES];
		}
	} else {
		// 使用できない
		alertBox(NSLocalizedString(@"Camera Non",nil), nil, @"OK");
		mBuCamera.hidden = YES;
	}*/
}
/*
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	if (appDelegate_.app_is_iPad) {
		[selfPopover_ dismissPopoverAnimated:YES];
	} else {
		[self dismissModalViewControllerAnimated:YES];
	}
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(queue, ^{		// 非同期マルチスレッド処理

		UIImage *img = [info objectForKey:UIImagePickerControllerEditedImage];  // 640x640
		if (img) {
			mIvPhoto.image = img;
			NSLog(@"***** mIvPhoto.image.size=(%.0f, %.0f)", mIvPhoto.image.size.width, mIvPhoto.image.size.height);
			E4photo *e4 = e3target_.e4photo;
			if (!e4) {
				e4 = (E4photo *)[NSEntityDescription insertNewObjectForEntityForName:@"E4photo"
															  inManagedObjectContext:e3target_.managedObjectContext];
				e3target_.e4photo = e4; //LINK
			}
			e4.photoData = UIImageJPEGRepresentation(img, 0.9);  //NG//UIImagePNGRepresentation(img);
			NSLog(@"***** [e4.photoData length]= %u Bytes", [e4.photoData length]);
			e3target_.photoUrl = [NSString stringWithFormat:GS_PHOTO_UUID_PREFIX @"%@", uuidString()];
			appDelegate_.app_UpdateSave = YES; // 変更あり
			self.navigationItem.rightBarButtonItem.enabled = YES;
		}

		dispatch_async(dispatch_get_main_queue(), ^{	// 終了後の処理
			[self.tableView reloadData];
			//[self viewDesignPhoto];
		});
	});


}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	if (appDelegate_.app_is_iPad) {
		[picker.parentViewController dismissModalViewControllerAnimated:YES];
	} else {
		[self dismissModalViewControllerAnimated:YES];
	}
}
*/


#pragma mark - CalcRoll

- (void)showCalc:(UILabel *)pLabel 
		  forKey:(NSString *)zKey 
		forTitle:(NSString *)zTitle
		 withRow:(NSInteger)iRow
		 withMax:(NSInteger)iMax
{
	if (mCalcView) {	// あれば一旦、破棄する
		[mCalcView hide];
		[mCalcView removeFromSuperview];  // これでCalcView.deallocされる
		//[McalcView release]; +1残っているが、viewが破棄されるときにreleseされるので、ここは不要
		mCalcView = nil;
	}
	[mTfName resignFirstResponder]; // ファーストレスポンダでなくす ⇒ キーボード非表示
	[mTvNote resignFirstResponder]; // ファーストレスポンダでなくす ⇒ キーボード非表示
	[mTfKeyword resignFirstResponder]; // ファーストレスポンダでなくす ⇒ キーボード非表示
	
	CGRect rect = self.tableView.bounds;
	CGFloat fTableTopY = 0;
	//テンキー表示位置 ＜＜とりあえず力ずくで位置合わせした。
	mTableViewContentY = self.tableView.contentOffset.y; // Hide時に元の表示に戻すため
	if (mAppDelegate.ppIsPad) {
		//rect.origin.y = 400;  //全体が見えるようにした + (iRow-3)*60;  
		fTableTopY = -45 + (iRow-3)*60;
		rect.origin.y = self.tableView.bounds.size.height - 210;
	} else {
		if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
			// 横
			fTableTopY = 154 + (iRow-3)*60;
			rect.origin.y = 57;
		}
		else {
			// 縦
			//fTableTopY = 65 + (iRow-3)*60;
			//rect.origin.y = 65;
//			if (mAppDelegate.ppOptShowAd) {	//広告表示中
//				fTableTopY = (500 - self.tableView.bounds.size.height) + 50 + (iRow-3)*60;
//				rect.origin.y = self.tableView.bounds.size.height - 401;
//			} else {
				fTableTopY = (500 - self.tableView.bounds.size.height) + (iRow-3)*60;
				rect.origin.y = self.tableView.bounds.size.height - 401 + 50;
//			}
		}
	}
	// テーブルを少し上げてテンキーで隠れないようにする
	// アニメ準備
	CGContextRef context = UIGraphicsGetCurrentContext();
	[UIView beginAnimations:nil context:context];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.3]; // 出は早く
	// アニメ終了位置
	self.tableView.contentOffset = CGPointMake(0, fTableTopY);
	// アニメ実行
	[UIView commitAnimations];
	
	mCalcView = [[CalcView alloc] initWithFrame:rect];
	mCalcView.Rlabel = pLabel;  // MlbAmount.tag にはCalc入力された数値(long)が記録される
	mCalcView.Rentity = pE3target;
	mCalcView.RzKey = zKey;
	mCalcView.delegate = self;
	mCalcView.maxValue = iMax;
	//[self.view addSubview:calcView_];
	[self.navigationController.view addSubview:mCalcView];
	[mCalcView show];
}

#pragma mark  <CalcView delegate>
// @protocolでない非形式プロトコル（カテゴリ）方式によるデリゲート
- (void)calcViewWillAppear	// CalcViewが現れる直前に呼び出される
{
	[self.tableView setScrollEnabled:NO]; // スクロール禁止
}

- (void)calcViewWillDisappear	// CalcViewが隠れるときに呼び出される
{
	[self.tableView setScrollEnabled:YES]; // スクロール許可
	if (0 <= mTableViewContentY) {
		// AzPacking Original 元の位置に戻す
		self.tableView.contentOffset = CGPointMake(0, mTableViewContentY);
	}
	[dialStock_ setDial:[pE3target.stock integerValue] animated:YES];
	[dialNeed_ setDial:[pE3target.need integerValue] animated:YES];
#ifdef WEIGHT_MAX
	[dialWeight_ setDial:[pE3target.weight integerValue] animated:YES];
#else
	[self viewWillAppear:NO]; // スライドバーを再描画するため
#endif
	
	self.navigationItem.rightBarButtonItem.enabled = mAppDelegate.ppChanged;
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
    return 1;
}



// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	switch (section) {
		case 0:
			return 6;
//		case 1:	
//			return 6;
	}
	return 0;
}

// TableView セクションタイトルを応答
//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
//{
//	switch (section) {
//		case 1:	
//			return NSLocalizedString(@"Product Bookmark", nil);
//	}
//	return nil;
//}

// TableView セクションフッタを応答
//- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section 
//{
//	if (section==1) {
//		NSString *zz = NSLocalizedString(@"Product Bookmark Footer", nil);
//		return [zz stringByAppendingString:	@"\n\n"
//																	@"AzukiSoft Project\n"
//																	COPYRIGHT
//																	@"\n\n\n\n\n"];
//	}
//	return nil;
//}

// セルの高さを指示する
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if (indexPath.section==0) {
		switch (indexPath.row) {
			case 2:
				if (mAppDelegate.ppIsPad) {
					return 150; // Note
				}
				return 110; // Note
				
			case 3:
			case 4:
			case 5:
				return 58;
//			case 6:	// Picasa
//				if (pE3target.e4photo) { //＜＜E4photo ロードで待たされる！
//					//if (e3target_.photoUrl) {
//					if (mAppDelegate.ppIsPad) {
//						return 40+400+8;
//					} else {
//						return 40+320+8;
//					}
//				}
//				break;
		}
	} 
//	else if (indexPath.section==1) {
//		switch (indexPath.row) {
//			case 0:	// Shop Bookmark
//				if (10<[pE3target.shopUrl length]) {
//					if (mAppDelegate.ppIsPad) {
//						return 4+400+4;
//					} else {
//						return 4+320+4;
//					}
//				}
//				break;
//		}
//	}
	
	if (mAppDelegate.ppIsPad) {
		return 50;
	}
	return 44; // デフォルト：44ピクセル
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{	// セル生成。 この時点では、cell.contentView.frameが無効である。willDisplayCell:にて有効になっている。　
	// contentView内容は、willDisplayCell:に実装する。
	
    NSString *zCellIndex = [NSString stringWithFormat:@"E3detail%d:%d", (int)indexPath.section, (int)indexPath.row];

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:zCellIndex];
	if (cell==nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault  reuseIdentifier:zCellIndex];
		if (pSharePlanList) {
			// 選択禁止
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.selectionStyle = UITableViewCellSelectionStyleNone; // 選択時ハイライトなし
		} else {
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;	// > ディスクロージャマーク
		}
		cell.showsReorderControl = NO; // Move禁止
	}
	
	if (indexPath.section==0) {
		if (3 <= indexPath.row && indexPath.row <= 5) {  // stock, need, weight
			if (cell.accessoryView==nil) {
				// Calcボタン ------------------------------------------------------------------
				UIButton *bu = [UIButton buttonWithType:UIButtonTypeCustom]; // autorelease
				bu.frame = CGRectMake(0,16, 44,44);
				[bu setImage:[UIImage imageNamed:@"Icon44-Calc.png"] forState:UIControlStateNormal];
				//[bu setImage:[UIImage imageNamed:@"Icon-ClipOn.png"] forState:UIControlStateHighlighted];
				//buClip.showsTouchWhenHighlighted = YES;
				bu.tag = indexPath.section * GD_SECTION_TIMES + indexPath.row;
				[bu addTarget:self action:@selector(cellButtonCalc:) forControlEvents:UIControlEventTouchUpInside];
				//[buCopy release]; buttonWithTypeにてautoreleseされるため不要。UIButtonにinitは無い。
				cell.accessoryType = UITableViewCellAccessoryNone;
				cell.selectionStyle = UITableViewCellSelectionStyleNone; // 選択時ハイライトなし
				cell.accessoryView = bu;
			}
		}
		switch (indexPath.row) {
			case 0: // Group
				if (mLbGroup==nil) {
					UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5,3, 100,12)];
					label.text = NSLocalizedString(@"Group", nil);
					label.textColor = [UIColor grayColor];
					label.backgroundColor = [UIColor clearColor];
					label.font = [UIFont systemFontOfSize:12];
					[cell.contentView addSubview:label]; //[label release];
					
					if (mAppDelegate.ppIsPad) {
						mLbGroup = [[UILabel alloc] initWithFrame:
									CGRectMake(20,18, self.tableView.frame.size.width-60,24)];
						mLbGroup.font = [UIFont systemFontOfSize:20];
					} else {
						mLbGroup = [[UILabel alloc] initWithFrame:
									CGRectMake(20,18, self.tableView.frame.size.width-60,16)];
						mLbGroup.font = [UIFont systemFontOfSize:14];
					}
					// cell.frame.size.width ではダメ。初期幅が常に縦になっているため
					// selectGroupTVC が MlbGroup を参照、変更する
					if (pAddE2section< 0) {
						// Edit Mode
						mLbGroup.tag = [pE3target.parent.row integerValue]; // E2.row
						mLbGroup.text = pE3target.parent.name;
					} else {
						// Add Mode
						mLbGroup.tag = pAddE2section; // E2.row
						mLbGroup.text = [[pE2array objectAtIndex:pAddE2section] valueForKey:@"name"];
					}
					if ([mLbGroup.text length] <= 0) { // (未定)
						mLbGroup.text = NSLocalizedString(@"(New Index)", nil);
					}
					mLbGroup.backgroundColor = [UIColor clearColor]; // [UIColor grayColor]; //範囲チェック用
					[cell.contentView addSubview:mLbGroup]; //[MlbGroup release];
				}
				break;
			case 1: // Name
				if (mTfName==nil) {
					UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5,3, 100,12)];
					label.font = [UIFont systemFontOfSize:12];
					label.text = NSLocalizedString(@"Item name", nil);
					label.textColor = [UIColor grayColor];
					label.backgroundColor = [UIColor clearColor];
					[cell.contentView addSubview:label]; //[label release];
					
					if (mAppDelegate.ppIsPad) {
						mTfName = [[UITextField alloc] initWithFrame:
								   CGRectMake(20,18, self.tableView.frame.size.width-60,24)];
						mTfName.font = [UIFont systemFontOfSize:20];
					} else {
						mTfName = [[UITextField alloc] initWithFrame:
								   CGRectMake(20,18, self.tableView.frame.size.width-60,20)];
						mTfName.font = [UIFont systemFontOfSize:16];
					}
					mTfName.placeholder = NSLocalizedString(@"(New Goods)", nil);
					mTfName.keyboardType = UIKeyboardTypeDefault;
					mTfName.autocapitalizationType = UITextAutocapitalizationTypeSentences;
					mTfName.returnKeyType = UIReturnKeyDone; // ReturnキーをDoneに変える
					mTfName.backgroundColor = [UIColor clearColor]; //[UIColor grayColor]; //範囲チェック用
					mTfName.delegate = self; // textFieldShouldReturn:を呼び出すため
					[cell.contentView addSubview:mTfName]; //[MtfName release];
					cell.accessoryType = UITableViewCellAccessoryNone; // なし
				}
				mTfName.text = pE3target.name; // (未定)表示しない。Editへ持って行かれるため
				break;
			case 2: // Note
				if (mTvNote==nil) {
					UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5,3, 100,12)];
					label.text = NSLocalizedString(@"Note", nil);
					label.textColor = [UIColor grayColor];
					label.backgroundColor = [UIColor clearColor];
					label.font = [UIFont systemFontOfSize:12];
					[cell.contentView addSubview:label]; //[label release];
					
					if (mAppDelegate.ppIsPad) {
						mTvNote = [[UITextView alloc] initWithFrame:
								   CGRectMake(20,15, self.tableView.frame.size.width-60,130)];
						mTvNote.font = [UIFont systemFontOfSize:20];
					} else {
						mTvNote = [[UITextView alloc] initWithFrame:
								   CGRectMake(20,15, self.tableView.frame.size.width-60,95)];
						mTvNote.font = [UIFont systemFontOfSize:16];
					}
					mTvNote.textAlignment = NSTextAlignmentLeft;
					mTvNote.keyboardType = UIKeyboardTypeDefault;
					mTvNote.returnKeyType = UIReturnKeyDefault;  //改行有効にする
					mTvNote.backgroundColor = [UIColor clearColor];
					//MtvNote.backgroundColor = [UIColor grayColor]; //範囲チェック用
					mTvNote.delegate = self;
					[cell.contentView addSubview:mTvNote]; //[MtvNote release];
					cell.accessoryType = UITableViewCellAccessoryNone; // なし
				}
				if (pE3target.note == nil) {
					mTvNote.text = @"";  // TextViewは、(nil) と表示されるので、それを消すため。
				} else {
					mTvNote.text = pE3target.note;
				}
				break;
			case 3: // Stock Qty.
				if (lbStock_==nil) {
#ifdef DEBUG
					//cell.backgroundColor = [UIColor grayColor]; //範囲チェック用
#endif
					UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(120,2, 90,20)];
					label.text = NSLocalizedString(@"StockQty", nil);
					label.textAlignment = NSTextAlignmentLeft;
					label.textColor = [UIColor grayColor];
					label.backgroundColor = [UIColor clearColor];
					label.font = [UIFont systemFontOfSize:14];
					[cell.contentView addSubview:label]; //[label release];
					
					lbStock_ = [[UILabel alloc] initWithFrame:CGRectMake(10, 2, 94, 20)];
					//CGRectMake(self.tableView.frame.size.width-30-90,1, 90,20)];
					lbStock_.backgroundColor = [UIColor clearColor];
					lbStock_.textAlignment = NSTextAlignmentCenter;
					lbStock_.font = [UIFont systemFontOfSize:24];
					[cell.contentView addSubview:lbStock_];
					
					dialStock_ = [[AZDial alloc] initWithFrame:CGRectZero 
													  delegate:self  dial:0  min:0  max:9999  step:1  stepper:YES];
					dialStock_.backgroundColor = [UIColor clearColor];
					[cell.contentView addSubview:dialStock_];
				}
				break;
			case 4: // Need
				if (lbNeed_==nil) {
					UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(120,2, 90,20)];
					label.text = NSLocalizedString(@"Need Qty", nil);
					label.textAlignment = NSTextAlignmentLeft;
					label.textColor = [UIColor grayColor];
					label.backgroundColor = [UIColor clearColor];
					label.font = [UIFont systemFontOfSize:14];
					[cell.contentView addSubview:label]; //[label release];
					
					lbNeed_ = [[UILabel alloc] initWithFrame:CGRectMake(10, 2, 94, 20)];
					//CGRectMake(self.tableView.frame.size.width/2-OFSX2,1, 90,20)];
					lbNeed_.backgroundColor = [UIColor clearColor];
					lbNeed_.textAlignment = NSTextAlignmentCenter;
					lbNeed_.font = [UIFont systemFontOfSize:24];
					[cell.contentView addSubview:lbNeed_];
					
					dialNeed_ = [[AZDial alloc] initWithFrame:CGRectZero
													 delegate:self  dial:0  min:0  max:9999  step:1  stepper:YES];
					dialNeed_.backgroundColor = [UIColor clearColor];
					[cell.contentView addSubview:dialNeed_];
				}
				// 配置は、willDisplayCell: にて
				break;
			case 5: // Weight
				if (lbWeight_==nil) {
					UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(120,2, 90,20)];
					label.text = NSLocalizedString(@"One Weight", nil);
					label.textAlignment = NSTextAlignmentLeft;
					label.textColor = [UIColor grayColor];
					label.backgroundColor = [UIColor clearColor];
					label.font = [UIFont systemFontOfSize:14];
					label.adjustsFontSizeToFitWidth = YES;
					label.minimumScaleFactor = 0.5f;
					label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
					[cell.contentView addSubview:label];
					
					lbWeight_ = [[UILabel alloc] initWithFrame:CGRectMake(10, 2, 94, 20)];
					//CGRectMake(self.tableView.frame.size.width/2-OFSX2,1, 90,20)];
					lbWeight_.backgroundColor = [UIColor clearColor];
					lbWeight_.textAlignment = NSTextAlignmentCenter;
					lbWeight_.font = [UIFont systemFontOfSize:24];
					[cell.contentView addSubview:lbWeight_];
					
					dialWeight_ = [[AZDial alloc] initWithFrame:CGRectZero
													   delegate:self  dial:0  min:0  max:WEIGHT_MAX  step:10  stepper:YES];
					dialWeight_.backgroundColor = [UIColor clearColor];
					//[mDialWeight setStepperMagnification:10.0];
					[cell.contentView addSubview:dialWeight_];
				}
				break;
//			case 6: // Picasa Photo
//				if (mLbPhotoMsg==nil) {
//					// Status Label
//					mLbPhotoMsg = [[UILabel alloc] initWithFrame:CGRectMake(5+24+5,2, 100,30)];
//					mLbPhotoMsg.font = [UIFont systemFontOfSize:12];
//					mLbPhotoMsg.textColor = [UIColor grayColor];
//					mLbPhotoMsg.numberOfLines = 2;
//					mLbPhotoMsg.backgroundColor = [UIColor clearColor];
//					[cell.contentView addSubview:mLbPhotoMsg];
//					// IconPicasa 
//					mIvIconPicasa = [[UIImageView alloc] init];
//					mIvIconPicasa.contentMode = UIViewContentModeScaleAspectFit;
//					mIvIconPicasa.frame = CGRectMake(4, 6, 32, 32);
//					[cell.contentView addSubview:mIvIconPicasa];
//					mActivityIndicator_on_IconPicasa = [[UIActivityIndicatorView alloc]
//														initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
//					mActivityIndicator_on_IconPicasa.frame = mIvIconPicasa.bounds;
//					[mIvIconPicasa addSubview:mActivityIndicator_on_IconPicasa];
//					// Camera ボタン
//					mBuCamera = [UIButton buttonWithType:UIButtonTypeCustom];
//					mBuCamera.frame = CGRectMake(0,0, 44,44);
//					[mBuCamera setImage:[UIImage imageNamed:@"Icon24-Camera"] forState:UIControlStateNormal];
//					[mBuCamera setImage:[UIImage imageNamed:@"Icon32-Picasa"] forState:UIControlStateHighlighted];
//					[mBuCamera addTarget:self action:@selector(actionCamera) forControlEvents:UIControlEventTouchUpInside];
//					cell.accessoryType = UITableViewCellAccessoryNone;
//					cell.selectionStyle = UITableViewCellSelectionStyleNone; // 選択時ハイライトなし
//					[cell.contentView addSubview:mBuCamera];  //cell.accessoryView = bu;
//					// Image 640x480
//					mIvPhoto = [[UIImageView alloc] init];
//					mIvPhoto.contentMode = UIViewContentModeScaleAspectFit;
//					mIvPhoto.frame = CGRectMake(0, 0, 640, 640); // 固定
//					mIvPhoto.clipsToBounds = YES;
//					// Scroll
//					mSvPhoto = [[UIScrollView alloc] init];
//					mSvPhoto.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//					[mSvPhoto addSubview:mIvPhoto];
//					mSvPhoto.delegate = self;
//					mSvPhoto.contentSize = mIvPhoto.frame.size; // 固定
//					mSvPhoto.zoomScale = 1.0;
//					mSvPhoto.minimumZoomScale = 1.0;
//					mSvPhoto.maximumZoomScale = 4.0;
//					[cell.contentView addSubview:mSvPhoto];
//					// 写真ズーム：　ピンチアウト操作
//					UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc]
//															  initWithTarget:self action:@selector(handlePinchGesture:)];
//					[cell.contentView addGestureRecognizer:pinchGesture];
//					
//					//cell.imageView.image = nil;
//					//cell.textLabel.text = nil;
//				}
//				//DEBUG_LOG_RECT(cell.contentView.frame, @"willDisplayCell: cell.contentView.frame");
//				//[mActivityIndicator_on_IconPicasa stopAnimating];
//				E4photo *e4 = pE3target.e4photo;
//				if (e4.photoData) {		// 写真データあり
//					mIvPhoto.image = [UIImage imageWithData: e4.photoData];
//					if ([pE3target.photoUrl hasPrefix:@"http"]) {	// Picasaアップ済み
//						mIvIconPicasa.image = [UIImage imageNamed:@"Icon32-Picasa"];
//						mLbPhotoMsg.text = NSLocalizedString(@"Google Photo Uploaded", nil);
//					} else {		// アップ待ち　リトライ
//						mIvIconPicasa.image = [UIImage imageNamed:@"Icon32-PicasaBlack"];
//						if (mAppDelegate.ppChanged) {
//							mLbPhotoMsg.text = NSLocalizedString(@"Google Photo UploadWait", nil);
//						} else {
//							[mActivityIndicator_on_IconPicasa startAnimating];
//							mLbPhotoMsg.text = NSLocalizedString(@"Google Uploading", nil);
//						}
//					}
//				}
//				else {	// e3target_.photoUrl==nil; 写真データなし
//					mIvPhoto.image = nil;
////					if ([pE3target.photoUrl hasPrefix:@"http"]) {	// Picasaアップ済み  ダウンロード待ち
////						//cell.imageView.image = [UIImage imageNamed:@"Icon32-PicasaBlack"];
////						mIvIconPicasa.image = [UIImage imageNamed:@"Icon32-PicasaBlack"];
////						[mActivityIndicator_on_IconPicasa startAnimating];
////						mLbPhotoMsg.text = NSLocalizedString(@"Google Downloading", nil);
////						// 写真キャッシュに無いのでダウンロードする
////						if ([GoogleService photoService]==nil) {	// Google未Login
////							mLbPhotoMsg.text = NSLocalizedString(@"Google Photo NoLogin", nil);
////							[mActivityIndicator_on_IconPicasa stopAnimating];
////						} else {
////							[GoogleService photoDownloadE3:pE3target errorLabel:mLbPhotoMsg]; //非同期処理
////							// スクロールして繰り返して呼び出された場合、処理中ならば拒否するようになっている。
////						}
////					}
////					else if ([pE3target.photoUrl hasPrefix:PHOTO_URL_UUID_PRIFIX]) {	// 写真あるがアップされていません
////						mIvIconPicasa.image = [UIImage imageNamed:@"Icon32-PicasaBlack"];
////						mLbPhotoMsg.text = NSLocalizedString(@"Google Photo NoUpload", nil);
////					}
////					else {	// Picasaアップなし　撮影してください
////						mIvIconPicasa.image = [UIImage imageNamed:@"Icon32-Picasa"];
////						mLbPhotoMsg.text = NSLocalizedString(@"Google Photo", nil);
////					} 
//				}
//				// この時点では、cell.contentView.frameが無効である。willDisplayCell:にて有効になっている。
//				// よって、viewDesignPhoto:による配置は、willDisplayCell:へ
//				// [self viewDesignPhoto];
//				break;
		}
	}
//	else if (indexPath.section==1) {		//------------------------------------------------------- Product information
//		switch (indexPath.row) {
//			case 0: // Shop Photo
//				if (mActivityIndicator_on_IconShop==nil) {
//					// Icon Shop 
//					cell.imageView.image = [UIImage imageNamed:@"Icon-Store-32"];
//					mActivityIndicator_on_IconShop = [[UIActivityIndicatorView alloc]
//														initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
//					[cell.imageView  addSubview:mActivityIndicator_on_IconShop];
//				}
//				if (10<[pE3target.shopUrl length]) {
//					//[mActivityIndicator_on_IconShop stopAnimating]; webViewDidStartLoad:にて開始
//					cell.textLabel.font = [UIFont systemFontOfSize:12];
//					cell.textLabel.numberOfLines = 10;
//					cell.textLabel.lineBreakMode = NSLineBreakByCharWrapping; //単語の途中でも改行する
//					cell.textLabel.text = [NSString stringWithFormat:@"%@\nURL{%@}", 
//										   NSLocalizedString(@"Product Bookmark URL", nil), pE3target.shopUrl];
//					//cell.textLabel.text = nil;
//					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
//					cell.selectionStyle = UITableViewCellSelectionStyleBlue;
//					// WebView
//					if (mWebViewShop==nil) {
//						mWebViewShop = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 320, 640)]; // 固定
//						mWebViewShop.scalesPageToFit = YES;  //.frameに収める ＜＜iPhoneサイトには効果なしだが、PCサイトは縮小される
//						mWebViewShop.delegate = self;	// 読み込み終了にて[mActivityIndicator_on_IconShop stopAnimating];するため
//						mWebViewShop.userInteractionEnabled = NO;		// 操作禁止
//						mWebViewShop.hidden = YES; //非表示にしてURLを見せる、読み込み成功時に表示する
//						[cell.contentView addSubview:mWebViewShop];
//						// 「URLから読み込む」
//						NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:pE3target.shopUrl]];
//						[mWebViewShop loadRequest:request];
//					}
//					// 配置は、willDisplayCell: にて
//				} else {
//					cell.textLabel.font = [UIFont systemFontOfSize:12];
//					cell.textLabel.numberOfLines = 2;
//					cell.textLabel.text = NSLocalizedString(@"Product Bookmark msg", nil);
//					cell.textLabel.textColor = [UIColor grayColor];
//					cell.accessoryType = UITableViewCellAccessoryNone;
//					cell.selectionStyle = UITableViewCellSelectionStyleNone; // 選択時ハイライトなし
//				}
//				break;
//				
//			case 1: // Shop Search keyword
//				if (mTfKeyword==nil) {
//					UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5,3, 300,12)];
//					label.font = [UIFont systemFontOfSize:12];
//					label.text = NSLocalizedString(@"Shop Keyword", nil);
//					label.textColor = [UIColor grayColor];
//					label.backgroundColor = [UIColor clearColor];
//					[cell.contentView addSubview:label];
//					
//					if (mAppDelegate.ppIsPad) {
//						mTfKeyword = [[UITextField alloc] initWithFrame:
//									  CGRectMake(20,18, self.tableView.frame.size.width-60,24)];
//						mTfKeyword.font = [UIFont systemFontOfSize:20];
//					} else {
//						mTfKeyword = [[UITextField alloc] initWithFrame:
//									  CGRectMake(20,18, self.tableView.frame.size.width-60,20)];
//						mTfKeyword.font = [UIFont systemFontOfSize:16];
//					}
//					mTfKeyword.placeholder = NSLocalizedString(@"Shop Keyword placeholder", nil);
//					mTfKeyword.keyboardType = UIKeyboardTypeDefault;
//					mTfKeyword.autocapitalizationType = UITextAutocapitalizationTypeSentences;
//					mTfKeyword.returnKeyType = UIReturnKeyDone; // ReturnキーをDoneに変える
//					mTfKeyword.backgroundColor = [UIColor clearColor]; //[UIColor grayColor]; //範囲チェック用
//					mTfKeyword.delegate = self; // textFieldShouldReturn:を呼び出すため
//					[cell.contentView addSubview:mTfKeyword]; //[MtfKeyword release];
//					mTfKeyword.text = pE3target.shopKeyword; // (未定)表示しない。Editへ持って行かれるため
//					cell.accessoryType = UITableViewCellAccessoryNone; // なし
//					cell.tag = 00;
//				}
//				break;
//				
//			case 2:
//			case 3:
//			case 4:
//			case 5:
//				if (cell.imageView.image==nil) {
//					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
//					cell.selectionStyle = UITableViewCellSelectionStyleBlue; // 選択時ハイライト
//					int iShop = (int)(indexPath.row - 2);
//					NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0]; // ja, en, zh-Hans
//					
//					if ([language hasPrefix:@"ja"]) {
//						switch (iShop) {
//							case 0: 
//								cell.imageView.image = [UIImage imageNamed:@"Icon32-Amazon"];
//								cell.textLabel.text = NSLocalizedString(@"Shop Amazon.co.jp", nil);	
//								cell.tag = 01;		break;
//							case 1: 
//								cell.imageView.image = [UIImage imageNamed:@"Icon32-Rakuten"];
//								cell.textLabel.text = NSLocalizedString(@"Shop Rakuten", nil);				
//								cell.tag = 11;		break;
//							case 2: 
//								cell.imageView.image = [UIImage imageNamed:@"Icon32-Amazon"];
//								cell.textLabel.text = NSLocalizedString(@"Shop Amazon.com", nil);	
//								cell.tag = 02;		break;
//							case 3: 
//								cell.imageView.image = [UIImage imageNamed:@"Icon32-Amazon"];
//								cell.textLabel.text = NSLocalizedString(@"Shop Amazon.cn", nil);	
//								cell.tag = 03;		break;
//						}
//					} 
//					else if ([language hasPrefix:@"zh"]) {  // zh-Hans or zh-H
//						switch (iShop) {
//							case 0: 
//								cell.imageView.image = [UIImage imageNamed:@"Icon32-Amazon"];
//								cell.textLabel.text = NSLocalizedString(@"Shop Amazon.cn", nil);	
//								cell.tag = 03;		break;
//							case 1: 
//								cell.imageView.image = [UIImage imageNamed:@"Icon32-Amazon"];
//								cell.textLabel.text = NSLocalizedString(@"Shop Amazon.com", nil);	
//								cell.tag = 02;		break;
//							case 2: 
//								cell.imageView.image = [UIImage imageNamed:@"Icon32-Amazon"];
//								cell.textLabel.text = NSLocalizedString(@"Shop Amazon.co.jp", nil);	
//								cell.tag = 01;		break;
//							case 3: 
//								cell.imageView.image = [UIImage imageNamed:@"Icon32-Rakuten"];
//								cell.textLabel.text = NSLocalizedString(@"Shop Rakuten", nil);				
//								cell.tag = 11;		break;
//						}
//					} 
//					else {							// en, other
//						switch (iShop) {
//							case 0: 
//								cell.imageView.image = [UIImage imageNamed:@"Icon32-Amazon"];
//								cell.textLabel.text = NSLocalizedString(@"Shop Amazon.com", nil);	
//								cell.tag = 02;		break;
//							case 1: 
//								cell.imageView.image = [UIImage imageNamed:@"Icon32-Amazon"];
//								cell.textLabel.text = NSLocalizedString(@"Shop Amazon.cn", nil);	
//								cell.tag = 03;		break;
//							case 2: 
//								cell.imageView.image = [UIImage imageNamed:@"Icon32-Amazon"];
//								cell.textLabel.text = NSLocalizedString(@"Shop Amazon.co.jp", nil);	
//								cell.tag = 01;		break;
//							case 3: 
//								cell.imageView.image = [UIImage imageNamed:@"Icon32-Rakuten"];
//								cell.textLabel.text = NSLocalizedString(@"Shop Rakuten", nil);				
//								cell.tag = 11;		break;
//						}
//					}
//				}
//				break;
//		}
//	}
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{	// セルが表示される直前に「毎回」呼び出される。 セルの生成時と更新時に描画するものはcellForRowAtIndexPath:へ
	// この時点で、cell.contentView.frameが有効になっている。
	
	if (indexPath.section==0) {
		switch (indexPath.row) {
			case 3:
			case 4:
			case 5: {
				CGFloat fDialWidth = self.tableView.frame.size.width-80;
				if (mAppDelegate.ppIsPad) {
					fDialWidth -= 40;  // 両端の余白が増えるため
				}
				CGRect rc = CGRectMake(10,16, fDialWidth,44);
				switch (indexPath.row) {
					case 3: // Stock Qty.
						dialStock_.frame = rc;
						[dialStock_ setDial:[pE3target.stock integerValue] animated:YES];
						lbStock_.text = GstringFromNumber(pE3target.stock); // 3桁コンマ付加
						break;
					case 4: // Need
						dialNeed_.frame = rc;
						[dialNeed_ setDial:[pE3target.need integerValue] animated:YES];
						lbNeed_.text = GstringFromNumber(pE3target.need);	// 3桁コンマ付加
						break;
					case 5: // Weight
						dialWeight_.frame = rc;
						[dialWeight_ setDial:[pE3target.weight integerValue] animated:YES];
						lbWeight_.text = GstringFromNumber(pE3target.weight);		// 3桁コンマ付加
						break;
				}
			} break;
				
//			case 6: {
//				// この時点では、cell.contentView.frameが有効になっている。
//				[self viewDesignPhoto];	// mIvPhoto:配置
//			} break;
		}
	}
//	else if (indexPath.section==1 && indexPath.row==0) {
//		// この時点では、cell.contentView.frameが有効になっている。
//		[self viewDesignPhoto];		// mWebViewShop:配置
//	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];	// 選択状態を解除する

	[mTfName resignFirstResponder]; // キーボード非表示
	[mTvNote resignFirstResponder]; // キーボード非表示
	[mTfKeyword resignFirstResponder]; // キーボード非表示
	
	if (indexPath.section==0) {
		switch (indexPath.row) {
			case 0: { // Group
				// selectGroupTVC へ
				selectGroupTVC *selectGroup = [[selectGroupTVC alloc] init];
				selectGroup.RaE2array = pE2array;
				selectGroup.RlbGroup = mLbGroup; // .tag=E2.row  .text=E2.name
				[self.navigationController pushViewController:selectGroup animated:YES];
			}	break;
				
			case 1: { // Name
				[mTfName becomeFirstResponder]; // ファーストレスポンダにする ⇒ キーボード表示
			} break;
				
			case 2: { // Note
				[mTvNote becomeFirstResponder]; // ファーストレスポンダにする ⇒ キーボード表示
			} break;
				
//			case 6: // Picasa Photo
//				//右ボタンにした//[self actionCamera];
//				break;
		}
	}
//	else if (indexPath.section==1) {
//		switch (indexPath.row) {
//			case 0: // Shop Photo
//				if (10<[pE3target.shopUrl length]) {
//					// WebViewを開ける
//					[self actionWebTitle: nil  Url: pE3target.shopUrl];
//				}
//				break;
//				
//			case 1: // Shop Search keyword
//				[mTfKeyword becomeFirstResponder];
//				break;
//				
//			case 2: // Shop
//			case 3: // Shop
//			case 4: // Shop
//			case 5: { // Shop
//				UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
//				switch (cell.tag) {
//					case 00: // Name
//					{
//						[mTfKeyword becomeFirstResponder]; // ファーストレスポンダにする ⇒ キーボード表示
//					} break;
//					
//					// アフェリエイトTAGは、WebSiteVC:stringAddTagUrl: にて付加している。
//					case 01: // Amazon.co.jp
//					{
//						NSString *zUrl;
//						if (mAppDelegate.ppIsPad) {
//							// PCサイト　　　　URL表示するようになったので長くする＜＜TAGが見えないように
//							// アソシエイトリンク作成方法⇒ https://affiliate.amazon.co.jp/gp/associates/help/t121/a1
//							//サーチ（全商品）
//							//ttp://www.amazon.co.jp/gp/search?ie=UTF8&keywords=[SEARCH_PARAMETERS]&tag=[ASSOCIATE_TAG]&index=blended&linkCode=ure&creative=6339	
//							zUrl = @"http://www.amazon.co.jp/gp/search?ie=UTF8&index=blended&linkCode=ure&creative=6339&keywords=";
//						} else {
//							// モバイルサイト　　　　　"ie=UTF8" が無いと日本語キーワードが化ける
//							//www.amazon.co.jp/gp/aw/s/ref=is_s_?__mk_ja_JP=%83J%83%5E%83J%83i&k=[SEARCH_PARAMETERS]&url=search-alias%3Daps
//							zUrl = @"http://www.amazon.co.jp/gp/aw/s/ref=is_s_?ie=UTF8&__mk_ja_JP=%83J%83%5E%83J%83i&url=search-alias%3Daps&k=";
//						}
//						[self actionWebSearchTitle:NSLocalizedString(@"Shop Amazon.co.jp", nil) URL:zUrl];
//					} break;
//					
//					case 02: // Amazon.com
//					{
//						NSString *zUrl;
//						if (mAppDelegate.ppIsPad) {
//							// PCサイト
//							//ttp://www.amazon.com/s/?tag=azuk-20&creative=392009&campaign=212361&link_code=wsw&_encoding=UTF-8&search-alias=aps&field-keywords=LEGO&Submit.x=16&Submit.y=14&Submit=Go
//							zUrl = @"http://www.amazon.com/s/?_encoding=UTF-8&link_code=wsw&search-alias=aps&creative=392009&field-keywords=";
//						} else {
//							// モバイルサイト
//							//www.amazon.com/gp/aw/s/ref=is_box_?k=LEGO
//							zUrl = @"http://www.amazon.com/gp/aw/s/ref=is_box_?_encoding=UTF-8&link_code=wsw&search-alias=aps&k=";
//						}
//						[self actionWebSearchTitle:NSLocalizedString(@"Shop Amazon.com", nil) URL:zUrl];
//					} break;
//					
//					case 03: // Amazon.cn
//					{
//						NSString *zUrl;
//						if (mAppDelegate.ppIsPad) {
//							// PCサイト
//							//ttp://www.amazon.cn/s/ref=nb_sb_noss/?tag=azukid-23&link_code=wsw&_encoding=UTF-8&search-alias=aps&field-keywords=TEST&Submit.x=13&Submit.y=7&Submit=Go
//							zUrl = @"http://www.amazon.cn/s/?_encoding=UTF-8&link_code=wsw&search-alias=aps&field-keywords=";
//						} else {
//							// モバイルサイト
//							//www.amazon.cn/gp/aw/s/ref=is_box_?k=LEGO
//							zUrl = @"http://www.amazon.cn/gp/aw/s/ref=is_box_?_encoding=UTF-8&link_code=wsw&search-alias=aps&k=";
//						}
//						[self actionWebSearchTitle:NSLocalizedString(@"Shop Amazon.cn", nil) URL:zUrl];
//					} break;
//
//					case 11: // 楽天 Search
//					{			// アフィリエイトID(β版): &afid=0e4c9297.0f29bc13.0e4c9298.6adf8529
//						NSString *zUrl;
//						if (mAppDelegate.ppIsPad) {
//							// PCサイト
//							zUrl = @"http://search.rakuten.co.jp/search/mall/?sv=2&p=0&sitem=";
//						} else {
//							// モバイルサイト
//							//http://search.rakuten.co.jp/search/spmall?sv=2&p=0&sitem=SG7&submit=商品検索&scid=af_ich_link_search&scid=af_ich_link_search
//							zUrl = @"http://search.rakuten.co.jp/search/spmall/?sv=2&p=0&sitem=";
//						}
//						[self actionWebSearchTitle:NSLocalizedString(@"Shop Rakuten", nil) URL:zUrl];
//					} break;
//					
//					case 21: // ケンコーコム Search
//					{			// アフィリエイトID
//						NSString *zUrl = @"http://sp.kenko.com/";
//						[self actionWebSearchTitle:NSLocalizedString(@"Shop Kenko.com", nil) URL:zUrl];
//					} break;
//				}
//			} break;
//		}
//	}
}


#pragma mark  TableView - Editting
/*
// TableView Editモードの表示
- (void)setEditing:(BOOL)editing animated:(BOOL)animated 
{
	if (editing) {
		// 編集モードに入るとき
	} else {
		// 編集モードから出るとき
	}
	[super setEditing:editing animated:animated];
}*/

// TableView Editボタンスタイル
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
//	if (indexPath.section==0 && indexPath.row==6) return UITableViewCellEditingStyleDelete; // Picasa
//	if (indexPath.section==1 && indexPath.row==0) return UITableViewCellEditingStyleDelete; // Shop
	return UITableViewCellEditingStyleNone; // なし
}

// TableView Editモード処理
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
								forRowAtIndexPath:(NSIndexPath *)indexPath 
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
//		if (indexPath.section==0 && indexPath.row==6) { // Picasa
//			E4photo *e4 = pE3target.e4photo;
//			if (e4) {
//				e4.photoData = nil;
//				// [e3target_.managedObjectContext deleteObject:e4]; リンクを切るだけで削除されるハズ ＜＜未確認
//			}
//			pE3target.e4photo = nil;
//			pE3target.photoUrl = nil;
//			mAppDelegate.ppChanged = YES; // 変更あり
//			self.navigationItem.rightBarButtonItem.enabled = mAppDelegate.ppChanged;
//			[self.tableView reloadData];
//		}
//		else if (indexPath.section==1 && indexPath.row==0) { // Shop
//			if (mWebViewShop) {
//				mWebViewShop.hidden = YES;
//				[mWebViewShop stopLoading];
//				mWebViewShop.delegate = nil; // これしないと落ちます
//				mWebViewShop = nil;
//			}
//			pE3target.shopUrl = nil;
//			mAppDelegate.ppChanged = YES; // 変更あり
//			self.navigationItem.rightBarButtonItem.enabled = mAppDelegate.ppChanged;
//			[self.tableView reloadData];
//		}
    }
}

// Editモード時の行Edit可否
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath 
{
//	if (indexPath.section==0 && indexPath.row==6) return YES; // 行編集許可 // Picasa
//	if (indexPath.section==1 && indexPath.row==0) return YES; // 行編集許可 // Shop
	return NO;
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


#pragma mark - <UITextFieldDelegete>
//============================================<UITextFieldDelegete>
- (void)nameDone:(id)sender {
	[mTfName resignFirstResponder]; // キーボード非表示
	[mTvNote resignFirstResponder]; // キーボード非表示
	[mTfKeyword resignFirstResponder]; // キーボード非表示
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	if (mCalcView) {	// あれば一旦、破棄する
		[mCalcView hide];
		[mCalcView removeFromSuperview];  // これでCalcView.deallocされる
		mCalcView = nil;
	}
	// スクロールして textField が隠れた状態で resignFirstResponder するとフリースするため
	self.tableView.scrollEnabled = NO; // スクロール禁止
	//self.navigationItem.leftBarButtonItem.enabled = NO;
	if (mAppDelegate.ppIsPad) {
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
		mAppDelegate.ppChanged = YES; // 変更あり
		self.navigationItem.rightBarButtonItem.enabled = mAppDelegate.ppChanged;
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
	if (mAppDelegate.ppIsPad) {
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
	[mTvNote resignFirstResponder];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	if (mCalcView) {	// あれば一旦、破棄する
		[mCalcView hide];
		[mCalcView removeFromSuperview];  // これでCalcView.deallocされる
		mCalcView = nil;
	}
	self.tableView.scrollEnabled = NO; // スクロール禁止
	//self.navigationItem.leftBarButtonItem.enabled = NO;
	if (mAppDelegate.ppIsPad) {
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
		mAppDelegate.ppChanged = YES; // 変更あり
		self.navigationItem.rightBarButtonItem.enabled = mAppDelegate.ppChanged;
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
	if (mAppDelegate.ppIsPad) {
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
	else if (sender==dialWeight_) {
		lbWeight_.text = GstringFromNumber([NSNumber numberWithInteger:dial]);
	}
}

- (void)dialDone:(id)sender  dial:(NSInteger)dial
{
	if (sender==dialStock_) {
		if ([pE3target.stock longValue] != dial) { // 変更あり
			lbStock_.text = GstringFromNumber([NSNumber numberWithInteger:dial]);
			pE3target.stock = [NSNumber numberWithInteger:dial];
			mAppDelegate.ppChanged = YES; // 変更あり
			self.navigationItem.rightBarButtonItem.enabled = mAppDelegate.ppChanged;
		}
	}
	else if (sender==dialNeed_) {
		if ([pE3target.need longValue] != dial) { // 変更あり
			lbNeed_.text = GstringFromNumber([NSNumber numberWithInteger:dial]);
			pE3target.need = [NSNumber numberWithInteger:dial];
			mAppDelegate.ppChanged = YES; // 変更あり
			self.navigationItem.rightBarButtonItem.enabled = mAppDelegate.ppChanged;
		}
	}
	else if (sender==dialWeight_) {
		if ([pE3target.weight longValue] != dial) { // 変更あり
			lbWeight_.text = GstringFromNumber([NSNumber numberWithInteger:dial]);
			pE3target.weight = [NSNumber numberWithInteger:dial];
			mAppDelegate.ppChanged = YES; // 変更あり
			self.navigationItem.rightBarButtonItem.enabled = mAppDelegate.ppChanged;
		}
	}
}


#pragma mark - <AZWebViewBookmarkDelegate>
- (void)azWebViewBookmark:(NSString *)url
{
	pE3target.shopUrl = url;
	mAppDelegate.ppChanged = YES; // 変更あり
	self.navigationItem.rightBarButtonItem.enabled = mAppDelegate.ppChanged;
	// 「URLから読み込む」
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:pE3target.shopUrl]];
	[mWebViewShop loadRequest:request];
	[self.tableView reloadData]; // セル高さ、配置
}

#pragma mark - <UIWebViewDelegate>
- (void)webViewDidStartLoad:(UIWebView *)webView 
{	// ウェブビューがコンテンツの読み込みを始めた後
	[mActivityIndicator_on_IconShop startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView 
{	// ウェブビューがコンテンツの読み込みを完了した後
	[mActivityIndicator_on_IconShop stopAnimating];
	mWebViewShop.hidden = NO;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error 
{	// ウェブビューがコンテンツの読み込みに失敗した場合
	[mActivityIndicator_on_IconShop stopAnimating];
}

/*** ここでは操作禁止にしているので不要
// URL制限する：無制限ならばレーティング"17+"になってしまう！
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request 
 navigationType:(UIWebViewNavigationType)navigationType
{	
	if (navigationType == UIWebViewNavigationTypeLinkClicked) // リンクをクリックしたとき、だけチェックする 
	{
		NSString *zHost = [[request URL] host];
		// 主ドメインからのリンク先で許可するドメイン
		// Amazon
		if ([zHost hasSuffix:@".amazon.co.jp"]) return YES; // 許可ドメイン
		if ([zHost hasSuffix:@".amazon.com"]) return YES; // 許可ドメイン
		if ([zHost hasSuffix:@".javari.jp"]) return YES; // 許可ドメイン
		// 楽天
		if ([zHost hasSuffix:@".rakuten.ne.jp"]) return YES; // 許可ドメイン
		// Azukid support
		if ([zHost hasSuffix:@".tumblr.com"]) return YES; // 許可ドメイン
		if ([zHost hasSuffix:@".seesaa.net"]) return YES; // 許可ドメイン
		if ([zHost hasSuffix:@".apple.com"]) return YES; // 許可ドメイン
		return NO;
	}
	return YES;
}
*/

@end

