//
//  AppDelegate.m
//  iPack
//
//  Created by 松山 和正 on 09/12/03.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//
// MainWindow.xlb を使用しない

#import "Global.h"
#import "AppDelegate.h"
#import "Elements.h"
#import "FileCsv.h"
#import "E1viewController.h"
#import "E2viewController.h"
#import "DropboxVC.h"

#ifdef AzPAD
#import "padRootVC.h"
#endif


@interface AppDelegate (PrivateMethods) // メソッドのみ記述：ここに変数を書くとグローバルになる。他に同じ名称があると不具合発生する
#ifdef FREE_AD
#define FREE_AD_OFFSET_Y			200.0
- (void)AdRefresh;
- (void)AdMobWillRotate:(UIInterfaceOrientation)toInterfaceOrientation;
- (void)AdAppWillRotate:(UIInterfaceOrientation)toInterfaceOrientation;
#endif
@end

@implementation AppDelegate
//@synthesize window;
@synthesize window = window_;
@synthesize managedObjectContext = moc_;
@synthesize mainVC;
@synthesize RaClipE3objects;
@synthesize AppShouldAutorotate, AppUpdateSave;
@synthesize dropboxSaveE1selected = dropboxSaveE1selected_;
@synthesize AppEnabled_iCloud = AppEnabled_iCloud_;
@synthesize AppEnabled_Dropbox = AppEnabled_Dropbox_;

#ifdef AzPAD
@synthesize padRootVC;
#else
#endif


- (void)dealloc 
{
#ifdef FREE_AD
	MbAdCanVisible = NO;  // 以後、Ad表示禁止
	if (MbannerView) {
		[MbannerView cancelBannerViewAction];	// 停止
		MbannerView.delegate = nil;							// 解放メソッドを呼び出さないようにする
		// autoreleaseかつmainVCへaddSubしているので解放は不要
	}
	
	if (RoAdMobView) {
		RoAdMobView.delegate = nil;  //受信STOP  ＜＜これが無いと破棄後に呼び出されて落ちる場合がある
		// autoreleaseかつmainVCへaddSubしているので解放は不要
	}
#endif
	
	AzRETAIN_CHECK(@"AppDelegate RaClipE3objects", RaClipE3objects, 1)
	[RaClipE3objects release];

	AzRETAIN_CHECK(@"AppDelegate mainVC", mainVC, 1)
	mainVC.delegate = nil;
	[mainVC release], mainVC = nil;
	AzRETAIN_CHECK(@"AppDelegate window", window, 1)
	[window release];
	
#ifdef AzPAD
	[padRootVC release], padRootVC = nil;
#else
	//	AzRETAIN_CHECK(@"AppDelegate RaComebackIndex", RaComebackIndex, 1)
	//	[RaComebackIndex release];
#endif

    [moc_ release];
    [persistentStoreCoordinator_ release];
    [moModel_ release];
	[super dealloc];
}


#pragma mark - Application lifecycle

//[1.1]メール添付ファイル"*.packlist" をタッチしてモチメモを選択すると、launchOptions にファイルの URL (file://…というスキーマ) で渡される。
//- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
- (void)applicationDidFinishLaunching:(UIApplication *)application
{    
	// MainWindow    ＜＜MainWindow.xlb を使用しないため、ここで生成＞＞
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	//-------------------------------------------------Option Setting Defult
	// User Defaultsを使い，キー値を変更したり読み出す前に，NSUserDefaultsクラスのインスタンスメソッド
	// registerDefaultsメソッドを使い，初期値を指定します。
	// [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
	// ここで，appDefaultsは環境設定で初期値となるキー・バリューペアのNSDictonaryオブジェクトです。
	// このメソッドは，すでに同じキーの環境設定が存在する場合，上書きしないので，環境設定の初期値を定めることに使えます。
	NSDictionary *azOptDef = [NSDictionary dictionaryWithObjectsAndKeys: // コンビニエンスコンストラクタにつきrelease不要
							  @"YES",	GD_OptStartupRestoreLevel,	//Apple仕様に従い常時ONにする。
							  @"YES",	GD_OptShouldAutorotate,		// 回転
							  @"NO",	GD_OptPasswordSave,
							  @"YES",	GD_OptTotlWeightRound,
							  @"NO",	GD_OptItemsQuickSort,
							  @"YES",	GD_OptShowTotalWeight,
							  @"NO",	GD_OptShowTotalWeightReq,
							  @"YES",	GD_OptItemsGrayShow,
							  @"NO",	GD_OptCheckingAtEditMode,
							  @"YES",	GD_OptSearchItemsNote,
							  nil];

	[userDefaults registerDefaults:azOptDef];	// 未定義のKeyのみ更新される
	[userDefaults synchronize]; // plistへ書き出す

	AppShouldAutorotate = [userDefaults boolForKey:GD_OptShouldAutorotate];

	AppEnabled_iCloud_ = NO;
	AppEnabled_Dropbox_ = NO;
#ifdef AzFREE
#else
	if (IOS_VERSION_GREATER_THAN_OR_EQUAL_TO(@"4.0")) {  // iOS 4.0以上
		NSString *dev = [[UIDevice currentDevice] model];
#ifdef AzPAD
		// 有料版 iPad
		AppEnabled_Dropbox_ = [dev isEqualToString:@"iPad"];	// iPad
#else
		// 有料版 iPhone, iPod touch
		AppEnabled_Dropbox_ = ![dev isEqualToString:@"iPad"];  // iPhone, iPod touch
		// 
	/*	if (AppEnabled_Dropbox_==NO) 
		{	// iPhone版をiPadで起動したとき、URL Types を削除する ＜＜Dropboxから戻ったとき呼び出されないようにするため
			NSString *path = [[NSBundle mainBundle] pathForResource:@"Info" ofType: @"plist"];
			NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:path];
			NSLog(@"Info.plist: dict=%@", dict);
			[dict removeObjectForKey:@"CFBundleURLTypes"];
			if ([dict writeToFile:path atomically:YES]==NO) {	＜＜ＮＧ！ 書き換えができない！
				NSLog(@"writeToFile NG");
			}
		}*/
#endif
		if (IOS_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0")) {  // iOS 5.0以上
			AppEnabled_iCloud_ = AppEnabled_Dropbox_;
		}
	}
#endif

	//-------------------------------------------------iCloud初期同期に時間がかかるためインジケータ表示しようとしているが、放置中？
/*	UIView *vi = [[UIView alloc] initWithFrame:window.bounds];

	UIActivityIndicatorView *actInd = [[[UIActivityIndicatorView alloc]
										initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
	CGRect rc = vi.frame;  // self.navigationController.view.frame;
	actInd.frame = CGRectMake((rc.size.width-100)/2, (rc.size.height-100)/2, 100, 100);
	[vi addSubview:actInd];
	[actInd startAnimating];
	
	[window addSubview:vi];
	[vi release];
	[window makeKeyAndVisible];	// 表示開始
*/
	
	//-------------------------------------------------
#ifdef AzPAD
	padRootVC = [[PadRootVC alloc] init]; // retainされる
	UINavigationController* naviLeft = [[UINavigationController alloc]
										initWithRootViewController:padRootVC];
	
	E1viewController *e1viewCon = [[E1viewController alloc] init];
	//e1viewCon.Rmoc = self.managedObjectContext;  //self.メソッド呼び出し ＜CoreData生成：はじまり＞
	UINavigationController* naviRight = [[UINavigationController alloc] initWithRootViewController:e1viewCon];
	[e1viewCon release];

	// e1viewCon を splitViewCon へ登録
	//mainVC = [[PadSplitVC alloc] init]; タテ2分割のための実装だったがRejectされたので没
	mainVC = [[UISplitViewController alloc] init];
	mainVC.viewControllers = [NSArray arrayWithObjects:naviLeft, naviRight, nil];
	mainVC.delegate = padRootVC;
	[naviRight release];
	[naviLeft release];
#else
	E1viewController *e1viewCon = [[E1viewController alloc] init];
	//e1viewCon.Rmoc = self.managedObjectContext; ＜＜待ちを減らすため、E1viewController:内で生成するように改めた。
	// e1viewCon を naviCon へ登録
	mainVC = [[UINavigationController alloc] initWithRootViewController:e1viewCon];
	AzRETAIN_CHECK(@"AppDelegate e1viewCon", e1viewCon, 3)
	[e1viewCon release];
#endif
	// mainVC を window へ登録
	[window addSubview:mainVC.view];
	AzRETAIN_CHECK(@"AppDelegate mainVC", mainVC, 2)
	
	//--------------------------------------------------[Clip Board] クリップボード初期化
	//self.RaClipE3objects = [[NSMutableArray array] retain]; NG/@property (nonatomic, retain)により代入時にretainされているため。
	self.RaClipE3objects = [NSMutableArray array];

	//Pad// iOS4以降を前提としてバックグランド機能に任せて前回復帰処理しないことにした。
	[window makeKeyAndVisible];	// 表示開始
	

#ifdef FREE_AD
	MbAdCanVisible = NO;		// 現在状況、(0)表示禁止  (1)表示可能
#endif //FREE_AD

	if (AppEnabled_Dropbox_) {
		DBSession* dbSession = [[[DBSession alloc]
								 initWithAppKey:DBOX_APPKEY
								 appSecret:DBOX_SECRET
								 root:kDBRootAppFolder] // either kDBRootAppFolder or kDBRootDropbox
								autorelease];
		[DBSession setSharedSession:dbSession];
	}

	return;  // YES;  //iOS4
}

// URLスキーマ呼び出し： packlist://
// info.plist "CFBundleURLTypes" 定義
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url 
{
	if ([url isFileURL]) {	// .packlist ファイルをタッチしたとき、
		NSLog(@"File loaded into [url path]=%@", [url path]);
		if ([[[url pathExtension] lowercaseString] isEqualToString:DBOX_EXTENSION]) 
		{	// ファイル・タッチ対応
			UIAlertView *alert = [[UIAlertView alloc] init];
			alert.title = NSLocalizedString(@"Please Wait",nil);
			[alert show];
			// 一時CSVファイルから取り込んで追加する
			//---------------------------------------CSV LOAD Start.
			NSString *zErr = [FileCsv zLoadURL:url];
			//---------------------------------------CSV LOAD End.
			[alert dismissWithClickedButtonIndex:0 animated:NO]; // 閉じる
			[alert release];
			if (zErr) {
				alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Download Fail",nil)  //ダウンロード失敗
												   message:zErr
												  delegate:nil 
										 cancelButtonTitle:nil 
										 otherButtonTitles:@"OK", nil];
			} else {
				alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Download Compleat!",nil)  //ダウンロード成功
												   message:NSLocalizedString(@"Added Plan",nil)  //プランを追加しました
												  delegate:nil 
										 cancelButtonTitle:nil 
										 otherButtonTitles:@"OK", nil];
			}
			[alert show];
			[alert release];
			// 再表示
#ifdef AzPAD
			UIViewController *vc = [mainVC.viewControllers  objectAtIndex:1]; //[1]Right
			if ([vc respondsToSelector:@selector(viewWillAppear:)]) {
				[vc viewWillAppear:YES];
			}
#else
			if ([mainVC.visibleViewController respondsToSelector:@selector(viewWillAppear:)]) {
				[mainVC.visibleViewController viewWillAppear:YES];
			}
#endif
			return YES;
		}
		else {
			UIAlertView *alv = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"AlertExtension", nil)
														   message:NSLocalizedString(@"AlertExtensionMsg", nil)
														  delegate:nil
												 cancelButtonTitle:nil
												 otherButtonTitles:NSLocalizedString(@"Roger", nil), nil] autorelease];
			[alv	show];
		}
	}
    else if ([[DBSession sharedSession] handleOpenURL:url]) {
        if ([[DBSession sharedSession] isLinked]) 
		{	// Dropbox 認証成功
            NSLog(@"App linked successfully!");
			// DropboxTVC を開ける
#ifdef AzPAD
			DropboxVC *vc = [[DropboxVC alloc] initWithNibName:@"DropboxVC-iPad" bundle:nil];
#else
			DropboxVC *vc = [[DropboxVC alloc] initWithNibName:@"DropboxVC" bundle:nil];
#endif
			vc.Re1selected = dropboxSaveE1selected_;
			//[self.window.rootViewController presentModalViewController:vc animated:YES];
			[mainVC presentModalViewController:vc animated:YES];
        }
        return YES;
    }
#ifdef AzSTABLE
	else if (AppEnabled_Dropbox_==NO) {
		alertBox( NSLocalizedString(@"Dropbox NGAPP",nil), NSLocalizedString(@"Dropbox NGAPP msg",nil), @"OK");
		return NO;
	}
#endif
    return NO;
}

- (void)applicationWillResignActive:(UIApplication *)application 
{	//iOS4: アプリケーションがアクティブでなくなる直前に呼ばれる
	/*
	 Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	 Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	 */
	AzLOG(@"applicationWillResignActive");
}


- (void)applicationDidEnterBackground:(UIApplication *)application 
{	//iOS4: アプリケーションがバックグラウンドになったら呼ばれる
	NSLog(@"applicationDidEnterBackground");
	[self applicationWillTerminate:application];
}


- (void)applicationWillEnterForeground:(UIApplication *)application 
{	//iOS4: アプリケーションがバックグラウンドから復帰する直前に呼ばれる
	NSLog(@"applicationWillEnterForeground");
	[self applicationWillTerminate:application];
}


- (void)applicationDidBecomeActive:(UIApplication *)application 
{	//iOS4: アプリケーションがアクティブになったら呼ばれる
	/*
	 Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	 */
	AzLOG(@"applicationDidBecomeActive");
}


// saves changes in the application's managed object context before the application terminates.
- (void)applicationWillTerminate:(UIApplication *)application 
{	// バックグラウンド実行中にアプリが終了された場合に呼ばれる。
	// ただしアプリがサスペンド状態の場合アプリを終了してもこのメソッドは呼ばれない。
	
	// iOS3互換のためにはここが必要。　iOS4以降、applicationDidEnterBackground から呼び出される。
	
	//--------------------------------------------------[Clip Board] クリップボード後処理
	if (self.RaClipE3objects && 0 < [self.RaClipE3objects count]) {
		for (E3 *e3 in self.RaClipE3objects) {
			if (e3.parent == nil) {
				// [Cut]されたE3なので削除する
				[moc_ deleteObject:e3];
				assert(NO); //DEBUGでは落とす
			}
		}
	}
    // Commit!
	NSError *error;
    if (moc_ != nil) {
        if ([moc_ hasChanges] && ![moc_ save:&error]) {
			// Handle error.
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			assert(NO); //DEBUGでは落とす
        } 
    }
}


#pragma mark - Saving

/**
 Performs the save action for the application, which is to send the save:
 message to the application's managed object context.
- (IBAction)saveAction:(id)sender {
	
    NSError *error;
    if (![[self managedObjectContext] save:&error]) {
		// Handle error
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		exit(-1);  // Fail
    }
}
 */


#pragma mark - iCloud

- (void)mergeiCloudChanges:(NSNotification*)note forContext:(NSManagedObjectContext*)moc 
{
    [moc mergeChangesFromContextDidSaveNotification:note]; 
	
    NSNotification* refreshNotification = [NSNotification notificationWithName:NFM_REFRESH_ALL_VIEWS
																		object:self  userInfo:[note userInfo]];
    [[NSNotificationCenter defaultCenter] postNotification:refreshNotification];
	
	NSLog(@"NSNotification: POST: RefreshAllViews");
	//NSLog(@"NSNotification: POST: RefreshAllViews: userInfo=%@", [note userInfo]);
}

// NSNotifications are posted synchronously on the caller's thread
// make sure to vector this back to the thread we want, in this case
// the main thread for our views & controller
- (void)mergeChangesFrom_iCloud:(NSNotification *)notification 
{
	NSManagedObjectContext* moc = [self managedObjectContext];
	
	// this only works if you used NSMainQueueConcurrencyType
	// otherwise use a dispatch_async back to the main thread yourself
	[moc performBlock:^{
        [self mergeiCloudChanges:notification forContext:moc];
    }];
}


#pragma mark - CoreData stack
//[1.2.0.0] AzBodyNote[0.8.0.0]に従って実装した。

- (NSManagedObjectModel *)managedObjectModel 
{
    if (moModel_ != nil) {
        return moModel_;
    }
	
	moModel_ = [NSManagedObjectModel mergedModelFromBundles:nil];
	
	return moModel_;
}


- (NSPersistentStoreCoordinator *)persistentStoreCoordinator 
{
    if (persistentStoreCoordinator_ != nil) {
        return persistentStoreCoordinator_;
    }
	
	/*
	 NSURL *storeUrl = [[self applicationDocumentsDirectory] 
					   URLByAppendingPathComponent:@"AzPack.sqlite"];	//【重要】変更禁止＜＜データ移行されなくなる。
	NSLog(@"storeUrl=%@", storeUrl);*/
	NSString *storePath = [[self applicationDocumentsDirectory]
						   stringByAppendingPathComponent:@"AzPack.sqlite"];	//【重要】リリース後変更禁止
	NSLog(@"storePath=%@", storePath);
	
    persistentStoreCoordinator_ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
	
	if (AppEnabled_iCloud_) {  // (IOS_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0"))
		 // do this asynchronously since if this is the first time this particular device is syncing with preexisting
		 // iCloud content it may take a long long time to download
		 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			 NSFileManager *fileManager = [NSFileManager defaultManager];
			 // Migrate datamodel
			 NSDictionary *options = nil;
			 NSURL *storeUrl = [NSURL fileURLWithPath:storePath];
			 // this needs to match the entitlements and provisioning profile
			 NSURL *cloudURL = [fileManager URLForUbiquityContainerIdentifier:nil]; //.entitlementsから自動取得されるようになった。
			 NSLog(@"cloudURL=1=%@", cloudURL);
			 if (cloudURL) {
				 // アプリ内のコンテンツ名付加：["coredata"]　＜＜＜変わると共有できない。
				 cloudURL = [cloudURL URLByAppendingPathComponent:@"coredata"];
				 NSLog(@"cloudURL=2=%@", cloudURL);

				 options = [NSDictionary dictionaryWithObjectsAndKeys:
							[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
							[NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
							@"com.azukid.AzPackingS1.sqlog", NSPersistentStoreUbiquitousContentNameKey,	//【重要】リリース後変更禁止
							cloudURL, NSPersistentStoreUbiquitousContentURLKey,												//【重要】リリース後変更禁止
							nil];
			 } else {
				 // iCloud is not available
				 options = [NSDictionary dictionaryWithObjectsAndKeys:
							[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,	// 自動移行
							[NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,			// 自動マッピング推論して処理
							nil];																									// NO ならば、「マッピングモデル」を使って移行処理される。
			 }			 
			 NSLog(@"options=%@", options);

			 // prep the store path and bundle stuff here since NSBundle isn't totally thread safe
			 NSPersistentStoreCoordinator* psc = persistentStoreCoordinator_;
			 NSError *error = nil;
			 [psc lock];
			 if (![psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) 
			 {
				 NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
				 abort();
			 }
			 [psc unlock];
			 
			 // tell the UI on the main thread we finally added the store and then
			 // post a custom notification to make your views do whatever they need to such as tell their
			 // NSFetchedResultsController to -performFetch again now there is a real store
			 dispatch_async(dispatch_get_main_queue(), ^{
				 NSLog(@"asynchronously added persistent store!");
				 [[NSNotificationCenter defaultCenter] postNotificationName:NFM_REFETCH_ALL_DATA
																	 object:self userInfo:nil];
			 });
		 });
	 } 
	 else {	// iCloudなし
		 NSURL *storeUrl = [NSURL fileURLWithPath:storePath];
		 NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
								  [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
								  [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
								  nil];
		 
		 NSError *error = nil;
		 if (![persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType 	 configuration:nil 
																   URL:storeUrl  options:options  error:&error])
		 {
			 NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			 abort();
		 }
	 }

    return persistentStoreCoordinator_;
}

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContext {
	
    if (moc_ != nil) {
        return moc_;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
	NSManagedObjectContext* moc = nil;
	
    if (coordinator != nil) {
		if (AppEnabled_iCloud_) {  // (IOS_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0"))
			moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
			
			[moc performBlockAndWait:^{
				// even the post initialization needs to be done within the Block
				[moc setPersistentStoreCoordinator: coordinator];
				[[NSNotificationCenter defaultCenter]addObserver:self 
														selector:@selector(mergeChangesFrom_iCloud:) 
															name:NSPersistentStoreDidImportUbiquitousContentChangesNotification 
														  object:coordinator];
			}];
        }
		else {	// iCloudなし
            moc = [[NSManagedObjectContext alloc] init];
            [moc setPersistentStoreCoordinator:coordinator];
        }		
    }
	moc_ = moc;
    return moc_;
}


#pragma mark - Application's documents directory

// Returns the URL to the application's Documents directory.
/*- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}*/
- (NSString *)applicationDocumentsDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}


#pragma mark - Ad

#ifdef FREE_AD  //PDA共通
- (void)AdRefresh:(BOOL)bCanVisible
{
	NSLog(@"=== AdRefresh:(%d)", bCanVisible);
	MbAdCanVisible = bCanVisible;
	[self AdRefresh];
}

//- (void)AdShowApple:(BOOL)bApple AdMob:(BOOL)bMob
- (void)AdRefresh
{
	//----------------------------------------------------- AdMob  ＜＜loadView:に入れると起動時に生成失敗すると、以後非表示が続いてしまう。
	if (RoAdMobView==nil) {
		// iPhone タテ下部に表示固定、ヨコ非表示
		RoAdMobView = [[[GADBannerView alloc] init] autorelease];
		// Adパラメータ初期化
		RoAdMobView.alpha = 0;	// 現在状況、(0)非表示  (1)表示中
		RoAdMobView.tag = 0;		// 広告受信状況  (0)なし (1)あり
		RoAdMobView.delegate = self;
#ifdef AzPAD
		RoAdMobView.adUnitID = AdMobID_PackPAD;	//iPad//
		RoAdMobView.frame = CGRectMake( 0, 0,  GAD_SIZE_300x250.width, GAD_SIZE_300x250.height);
#else
		RoAdMobView.adUnitID = AdMobID_PackList;	//iPhone//
		RoAdMobView.frame = CGRectMake( 0, 0, GAD_SIZE_320x50.width, GAD_SIZE_320x50.height);
#endif
		RoAdMobView.rootViewController = mainVC;
		[mainVC.view addSubview:RoAdMobView];
		//【Tips】初期配置は、常にタテ位置にすること。　ヨコのときだけwillRotateToInterfaceOrientation：などの回転通知が届く。
		[self AdMobWillRotate:UIInterfaceOrientationPortrait]; 

		// リクエスト
		GADRequest *request = [GADRequest request];
		//[request setTesting:YES];
		[RoAdMobView loadRequest:request];	
	}
	
	//----------------------------------------------------- iAd: AdMobの上層になるように後からaddSubviewする
	if (MbannerView==nil && [[[UIDevice currentDevice] systemVersion] compare:@"4.0"]!=NSOrderedAscending) { // !<  (>=) "4.0"
		assert(NSClassFromString(@"ADBannerView"));
		MbannerView = [[[ADBannerView alloc] init] autorelease];		//WithFrame:CGRectZero 
		// Adパラメータ初期化
		MbannerView.alpha = 0;		// 現在状況、(0)非表示  (1)表示中
		MbannerView.tag = 0;		// 広告受信状況  (0)なし (1)あり
		MbannerView.delegate = self;
#ifdef AzPAD
		[mainVC.view addSubview:MbannerView];
#else
		[mainVC.view addSubview:MbannerView];
#endif
		//【Tips】初期配置は、常にタテ位置にすること。　ヨコのときだけwillRotateToInterfaceOrientation：などの回転通知が届く。
		[self AdAppWillRotate:UIInterfaceOrientationPortrait]; 
	}
	
	NSLog(@"=== AdRefresh: Can[%d] iAd[%d⇒%d] AdMob[%d⇒%d]", MbAdCanVisible, (int)MbannerView.tag, (int)MbannerView.alpha, 
		  (int)RoAdMobView.tag, (int)RoAdMobView.alpha);
	//if (MbAdCanVisible && MbannerView.alpha==MbannerView.tag && RoAdMobView.alpha==RoAdMobView.tag) {
	if (MbAdCanVisible) {
		if (MbannerView.alpha==MbannerView.tag && RoAdMobView.alpha==RoAdMobView.tag) {
			NSLog(@"   = 変化なし =");
			return; // 変化なし
		}
		if (MbannerView.alpha==1 && MbannerView.alpha==MbannerView.tag) {
			NSLog(@"   = iAd 優先ON = 変化なし =");
			return; // 変化なし
		}
	} else {
		if (MbannerView.alpha==0 && RoAdMobView.alpha==0) {
			NSLog(@"   = OFF = 変化なし =");
			return; // 変化なし
		}
	}
	
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:1.2];
	
#ifdef AzPAD
	if (MbannerView) {
		CGRect rc = MbannerView.frame;
		if (MbAdCanVisible && MbannerView.tag==1) {
			if (MbannerView.alpha==0) {
				rc.origin.y += FREE_AD_OFFSET_Y;
				MbannerView.frame = rc;
				MbannerView.alpha = 1;
			}
		} else {
			if (MbannerView.alpha==1) {
				rc.origin.y -= FREE_AD_OFFSET_Y;	//(-)上に隠す
				MbannerView.frame = rc;
				MbannerView.alpha = 0;
			}
		}
	}
	
	if (RoAdMobView) {
		if (RoAdMobView.tag==1) { //AdMob常時表示なので、MbAdCanVisible判定不要
			RoAdMobView.alpha = 1;
		} else {
			RoAdMobView.alpha = 0;
		}
	}
#else	//-------------------------------------------
	if (MbannerView) {
		CGRect rc = MbannerView.frame;
		if (MbAdCanVisible && MbannerView.tag==1) {
			if (MbannerView.alpha==0) {
				rc.origin.y -= FREE_AD_OFFSET_Y;
				MbannerView.frame = rc;
				MbannerView.alpha = 1;
			}
		} else {
			if (MbannerView.alpha==1) {
				rc.origin.y += FREE_AD_OFFSET_Y;	//(+)下へ隠す
				MbannerView.frame = rc;
				MbannerView.alpha = 0;
			}
		}
	}
	
	if (RoAdMobView) {
		CGRect rc = RoAdMobView.frame;
		if (MbAdCanVisible && RoAdMobView.tag==1 && MbannerView.alpha==0) { //iAdが非表示のときだけAdMob表示
			if (RoAdMobView.alpha==0) {
				rc.origin.y = 480 - 44 - 50;		//AdMobはヨコ向き常に非表示 ＜＜これはタテの配置なのでヨコだと何もしなくても範囲外で非表示になる
				RoAdMobView.frame = rc;
				RoAdMobView.alpha = 1;
			}
		} else {
			if (RoAdMobView.alpha==1) {
				rc.origin.y = 480 + 10; // 下部へ隠す
				RoAdMobView.frame = rc;
				RoAdMobView.alpha = 0;	//[1.0.1]3GS-4.3.3においてAdで電卓キーが押せない不具合報告あり。未確認だがこれにて対応
			}
			// リクエスト
			GADRequest *request = [GADRequest request];
			[RoAdMobView loadRequest:request];	
	/*		// 破棄する ＜＜通信途絶してから復帰した場合、再生成するまで受信できないため。再生成する機会を増やす。
			RoAdMobView.delegate = nil;
			[RoAdMobView release], RoAdMobView = nil; */
		}
	}
#endif
	// アニメ開始
	[UIView commitAnimations];
}

- (void)AdViewWillRotate:(UIInterfaceOrientation)toInterfaceOrientation
{
	[self AdMobWillRotate:toInterfaceOrientation];	//AdMob
	[self AdAppWillRotate:toInterfaceOrientation];		//iAd
}

- (void)AdMobWillRotate:(UIInterfaceOrientation)toInterfaceOrientation
{
	if (RoAdMobView==nil) return;
#ifdef AzPAD
	if (RoAdMobView) {
		if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {	// タテ
			RoAdMobView.frame = CGRectMake(
										   768-45-GAD_SIZE_300x250.width,
										   1024-64-GAD_SIZE_300x250.height,
										   GAD_SIZE_300x250.width, GAD_SIZE_300x250.height);
		} else {	// ヨコ
			RoAdMobView.frame = CGRectMake(
										   10,
										   768-64-GAD_SIZE_300x250.height,
										   GAD_SIZE_300x250.width, GAD_SIZE_300x250.height);
		}
	}
#else
	//iPhoneでは、タテ配置固定のみ。これによりヨコでは常に範囲外で非表示にしている。
#endif
}

- (void)AdAppWillRotate:(UIInterfaceOrientation)toInterfaceOrientation
{	// 非表示中でも回転対応すること。表示するときの出発位置のため
	if (MbannerView==nil) return;

	if ([[[UIDevice currentDevice] systemVersion] compare:@"4.2"]==NSOrderedAscending) { // ＜ "4.2"
		// iOS4.2より前
		if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
			MbannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifier480x32;
		} else {
			MbannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifier320x50;
		}
	} else {
		// iOS4.2以降の仕様であるが、以前のOSでは落ちる！！！
		if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
			MbannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
		} else {
			MbannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
		}
	}
#ifdef AzPAD
	if (MbAdCanVisible && MbannerView.alpha==1) {
		MbannerView.frame = CGRectMake(0, 40,  0,0);	// 表示
	} else {
		MbannerView.frame = CGRectMake(0, 40 - FREE_AD_OFFSET_Y,  0,0);  // 上に隠す
	}
#else
	if (MbAdCanVisible && MbannerView.alpha==1) {	// 表示
		if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
			MbannerView.frame = CGRectMake(0, 320-32,  0,0);	//ヨコ：下部に表示
		} else {
			MbannerView.frame = CGRectMake(0, 480-44-50,  0,0);	//タテ：下部に表示
		}
	} else {
		if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
			MbannerView.frame = CGRectMake(0, 320-32 + FREE_AD_OFFSET_Y,  0,0);		//ヨコ：下へ隠す
		} else {
			MbannerView.frame = CGRectMake(0, 480-44-50 + FREE_AD_OFFSET_Y,  0,0);	//タテ：下へ隠す
		}
	}
#endif
}

- (void)adViewDidReceiveAd:(GADBannerView *)bannerView 
{	// AdMob 広告あり
	NSLog(@"AdMob - adViewDidReceiveAd");
	bannerView.tag = 1;	// 広告受信状況  (0)なし (1)あり
	[self AdRefresh];
}

- (void)adView:(GADBannerView *)bannerView didFailToReceiveAdWithError:(GADRequestError *)error 
{	// AdMob 広告なし
	NSLog(@"AdMob - adView:didFailToReceiveAdWithError:%@", [error localizedDescription]);
	bannerView.tag = 0;	// 広告受信状況  (0)なし (1)あり
	[self AdRefresh];
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{	// iAd取得できたときに呼ばれる　⇒　表示する
	NSLog(@"iAd - bannerViewDidLoadAd ===");
	banner.tag = 1;	// 広告受信状況  (0)なし (1)あり
	[self AdRefresh];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{	// iAd取得できなかったときに呼ばれる　⇒　非表示にする
	NSLog(@"iAd - didFailToReceiveAdWithError");
	banner.tag = 0;	// 広告受信状況  (0)なし (1)あり

	// AdMob 破棄する ＜＜通信途絶してから復帰した場合、再生成するまで受信できないため。再生成する機会を増やす。
	if (RoAdMobView) {
		// リクエスト
		GADRequest *request = [GADRequest request];
		[RoAdMobView loadRequest:request];	
/*		//[1.1.0]ネット切断から復帰したとき、このように破棄⇒生成が必要。
		RoAdMobView.alpha = 0; //これが無いと残骸が表示されたままになる。
		RoAdMobView.delegate = nil;								//受信STOP  ＜＜これが無いと破棄後に呼び出されて落ちる
		[RoAdMobView release], RoAdMobView = nil;	// 破棄
		//[1.1.0]この後、AdRefresh:にて生成再開される。
 */
	}
	[self AdRefresh];
}

#endif


@end

