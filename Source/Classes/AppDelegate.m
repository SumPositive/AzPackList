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
#import "EntityRelation.h"
#import "FileCsv.h"
#import "padRootVC.h"
#import "E1viewController.h"
#import "E2viewController.h"
#import "DropboxVC.h"
#import "AZStoreVC.h"


@interface AppDelegate (PrivateMethods) // メソッドのみ記述：ここに変数を書くとグローバルになる。他に同じ名称があると不具合発生する
#define FREE_AD_OFFSET_Y			200.0
- (void)AdRefresh;
- (void)AdMobWillRotate:(UIInterfaceOrientation)toInterfaceOrientation;
- (void)AdAppWillRotate:(UIInterfaceOrientation)toInterfaceOrientation;
@end


@implementation AppDelegate
{
@public		// 外部公開 ＜＜使用禁止！@propertyで外部公開すること＞＞
@protected	// 自クラスおよびサブクラスから参照できる（無指定時のデフォルト）
@private	// 自クラス内からだけ参照できる
	NSManagedObjectModel				*moModel_;
	NSPersistentStoreCoordinator		*persistentStoreCoordinator_;
	
	ADBannerView				*iAdView_;
	GADBannerView				*adMobView_;
	BOOL								adCanVisible_;		//YES:表示可能な状況　 NO:表示してはいけない状況
	
	// Clip Borad
	NSMutableArray				*clipE3objects_; //(V0.4.4) [Cut][Copy]されたE3をPUSHスタックする。[Paste]でPOPする

	UIAlertView						*alertProgress_;
	UIActivityIndicatorView	*alertIndicator_;
}
@synthesize window = window_;
@synthesize managedObjectContext = moc_;
@synthesize mainNC = mainNC_;
@synthesize mainSVC = mainSVC_;
@synthesize padRootVC = padRootVC_;
@synthesize clipE3objects_;
@synthesize dropboxSaveE1selected = dropboxSaveE1selected_;
@synthesize app_is_iPad = app_is_iPad_;
@synthesize app_UpdateSave = app_UpdateSave_;
@synthesize app_opt_Autorotate = app_opt_Autorotate_;
@synthesize app_opt_Ad = app_opt_Ad_;
@synthesize app_pid_UnLock = app_pid_UnLock_;




#pragma mark - Application lifecycle

//[1.1]メール添付ファイル"*.packlist" をタッチしてモチメモを選択すると、launchOptions にファイルの URL (file://…というスキーマ) で渡される。
//- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
- (void)applicationDidFinishLaunching:(UIApplication *)application
{    
	// MainWindow    ＜＜MainWindow.xlb を使用しないため、ここで生成＞＞
	window_ = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	// 端末毎の設定
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	//-------------------------------------------------Option Setting Defult
	// User Defaultsを使い，キー値を変更したり読み出す前に，NSUserDefaultsクラスのインスタンスメソッド
	// registerDefaultsメソッドを使い，初期値を指定します。
	// [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
	// ここで，appDefaultsは環境設定で初期値となるキー・バリューペアのNSDictonaryオブジェクトです。
	// このメソッドは，すでに同じキーの環境設定が存在する場合，上書きしないので，環境設定の初期値を定めることに使えます。
	NSDictionary *azOptDef = [NSDictionary dictionaryWithObjectsAndKeys: // コンビニエンスコンストラクタにつきrelease不要
							  @"YES",	UD_OptShouldAutorotate,		// 回転
							  @"NO",	UD_OptPasswordSave,
							  nil];
	[userDefaults registerDefaults:azOptDef];	// 未定義のKeyのみ更新される
	[userDefaults synchronize]; // plistへ書き出す
	
	// iCloud-KVS： 全端末共用（同期）設定
	NSUbiquitousKeyValueStore *kvs = [NSUbiquitousKeyValueStore defaultStore];
	[kvs synchronize]; // 最新同期
	// 全端末共通、初期値セット
	if ([kvs objectForKey: KV_OptWeightRound]==nil)				[kvs setBool:YES forKey: KV_OptWeightRound];
	if ([kvs objectForKey: KV_OptShowTotalWeight]==nil)		[kvs setBool:YES forKey: KV_OptShowTotalWeight];
	if ([kvs objectForKey: KV_OptShowTotalWeightReq]==nil)[kvs setBool:NO  forKey: KV_OptShowTotalWeightReq];
	if ([kvs objectForKey: KV_OptItemsGrayShow]==nil)			[kvs setBool:YES forKey: KV_OptItemsGrayShow];
	if ([kvs objectForKey: KV_OptCheckingAtEditMode]==nil)	[kvs setBool:NO  forKey: KV_OptCheckingAtEditMode];
	if ([kvs objectForKey: KV_OptSearchItemsNote]==nil)		[kvs setBool:YES forKey: KV_OptSearchItemsNote];
	if ([kvs objectForKey: KV_OptAdvertising]==nil)					[kvs setBool:YES forKey: KV_OptAdvertising];
	// AZStore PID  ＜＜productIdentifier をそのままKEYにする
	if ([kvs objectForKey: SK_PID_UNLOCK]==nil)						[kvs setBool:NO  forKey: SK_PID_UNLOCK];
	[kvs synchronize]; // 最新同期
	
	app_opt_Autorotate_ = [kvs boolForKey:UD_OptShouldAutorotate];
	app_opt_Ad_ = [kvs boolForKey:KV_OptAdvertising];
	app_pid_UnLock_ = [kvs boolForKey:SK_PID_UNLOCK];
	
#ifdef DEBUG
	app_pid_UnLock_ = NO;	// 購入中止で YES に変えてテストするため
#endif
	
	//-------------------------------------------------初期化
	app_UpdateSave_ = NO;
	adCanVisible_ = NO;			// 現在状況、(NO)表示禁止  (YES)表示可能
	clipE3objects_ = [NSMutableArray array];	//　[Clip Board] クリップボード初期化

	//-------------------------------------------------デバイス、ＯＳ確認
	if ([[[UIDevice currentDevice] systemVersion] compare:@"5.0"]==NSOrderedAscending) { // ＜ "5.0"
		// iOS5.0より前
		alertBox(@"! STOP !", @"Need more iOS 5.0", nil);
		exit(0);
	}
	app_is_iPad_ = [[[UIDevice currentDevice] model] hasPrefix:@"iPad"];	// iPad
	NSLog(@"app_is_iPad_=%d,  app_is_Ad_=%d,  app_is_sponsor_=%d", app_is_iPad_, app_opt_Ad_, app_pid_UnLock_);
	
	//-------------------------------------------------
	if (app_is_iPad_) {
		padRootVC_ = [[PadRootVC alloc] init]; // retainされる
		UINavigationController* naviLeft = [[UINavigationController alloc]
											initWithRootViewController:padRootVC_];
		
		E1viewController *e1viewCon = [[E1viewController alloc] init];
		UINavigationController* naviRight = [[UINavigationController alloc] initWithRootViewController:e1viewCon];
		
		// e1viewCon を splitViewCon へ登録
		//mainVC = [[PadSplitVC alloc] init]; タテ2分割のための実装だったがRejectされたので没
		mainSVC_ = [[UISplitViewController alloc] init];
		mainSVC_.viewControllers = [NSArray arrayWithObjects:naviLeft, naviRight, nil];
		mainSVC_.delegate = padRootVC_;
		// mainVC を window へ登録
		[window_ addSubview:mainSVC_.view];
	}
	else {
		E1viewController *e1viewCon = [[E1viewController alloc] init];
		//e1viewCon.Rmoc = self.managedObjectContext; ＜＜待ちを減らすため、E1viewController:内で生成するように改めた。
		// e1viewCon を naviCon へ登録
		mainNC_ = [[UINavigationController alloc] initWithRootViewController:e1viewCon];
		// mainVC を window へ登録
		[window_ addSubview:mainNC_.view];
	}
	
	//Pad// iOS4以降を前提としてバックグランド機能に任せて前回復帰処理しないことにした。
	[window_ makeKeyAndVisible];	// 表示開始
	
	// Dropbox 標準装備
	DBSession* dbSession = [[DBSession alloc]
							 initWithAppKey:DBOX_APPKEY
							 appSecret:DBOX_SECRET
							root:kDBRootAppFolder]; // either kDBRootAppFolder or kDBRootDropbox
	[DBSession setSharedSession:dbSession];

	// 初期生成
	[EntityRelation setMoc:[self managedObjectContext]];
	
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
			//[alert release];
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
			//[alert release];
			// 再表示
			if (app_is_iPad_) {
				UIViewController *vc = [mainSVC_.viewControllers  objectAtIndex:1]; //[1]Right
				if ([vc respondsToSelector:@selector(viewWillAppear:)]) {
					[vc viewWillAppear:YES];
				}
			} else {
				if ([mainNC_.visibleViewController respondsToSelector:@selector(viewWillAppear:)]) {
					[mainNC_.visibleViewController viewWillAppear:YES];
				}
			}
			return YES;
		}
		else {
			UIAlertView *alv = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"AlertExtension", nil)
														   message:NSLocalizedString(@"AlertExtensionMsg", nil)
														  delegate:nil
												 cancelButtonTitle:nil
												 otherButtonTitles:NSLocalizedString(@"Roger", nil), nil];
			[alv	show];
		}
	}
    else if ([[DBSession sharedSession] handleOpenURL:url]) {
        if ([[DBSession sharedSession] isLinked]) 
		{	// Dropbox 認証成功
            NSLog(@"App linked successfully!");
			// DropboxTVC を開ける
			DropboxVC *vc;
			if (app_is_iPad_) {
				vc = [[DropboxVC alloc] initWithNibName:@"DropboxVC-iPad" bundle:nil];
				vc.Re1selected = dropboxSaveE1selected_;
				[mainSVC_ presentModalViewController:vc animated:YES];
			} else {
				vc = [[DropboxVC alloc] initWithNibName:@"DropboxVC" bundle:nil];
				vc.Re1selected = dropboxSaveE1selected_;
				[mainNC_ presentModalViewController:vc animated:YES];
			}
        }
        return YES;
    }
	//else if (app_is_sponsor_==NO) {
	//	alertBox( NSLocalizedString(@"Dropbox NGAPP",nil), NSLocalizedString(@"Dropbox NGAPP msg",nil), @"OK");
	//	return NO;
	//}
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
	if (self.clipE3objects_ && 0 < [self.clipE3objects_ count]) {
		for (E3 *e3 in self.clipE3objects_) {
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

- (void)dealloc 
{
	adCanVisible_ = NO;  // 以後、Ad表示禁止
	if (iAdView_) {
		[iAdView_ cancelBannerViewAction];	// 停止
		iAdView_.delegate = nil;							// 解放メソッドを呼び出さないようにする
		// autoreleaseかつmainVCへaddSubしているので解放は不要
	}
	
	if (adMobView_) {
		adMobView_.delegate = nil;  //受信STOP  ＜＜これが無いと破棄後に呼び出されて落ちる場合がある
		// autoreleaseかつmainVCへaddSubしているので解放は不要
	}
	
	mainNC_.delegate = nil;		mainNC_ = nil;
	mainSVC_.delegate = nil;	mainSVC_ = nil;
	padRootVC_ = nil;
}


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
						   stringByAppendingPathComponent:@"AzPackList.sqlite"];	//【重要】リリース後変更禁止
	NSLog(@"storePath=%@", storePath);
	
    persistentStoreCoordinator_ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
	
	if (app_pid_UnLock_) {  // (IOS_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0"))
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
							@"com.azukid.AzPackList.sqlog", NSPersistentStoreUbiquitousContentNameKey,	//【重要】リリース後変更禁止
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
- (NSManagedObjectContext *) managedObjectContext 
{
    if (moc_ != nil) {
        return moc_;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
	NSManagedObjectContext* moc = nil;
	
    if (coordinator != nil) {
		if (app_pid_UnLock_) {  // (IOS_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0"))
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

- (void) managedObjectContextReset 
{	// iCloud OFF--->ON したときのため。
	moc_ = nil;
	persistentStoreCoordinator_ = nil;
	// 再生成
	[EntityRelation setMoc:[self managedObjectContext]];
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

- (void)AdRefresh:(BOOL)bCanVisible
{
	NSLog(@"=== AdRefresh:(%d)", bCanVisible);
	adCanVisible_ = bCanVisible;
	[self AdRefresh];
}

//- (void)AdShowApple:(BOOL)bApple AdMob:(BOOL)bMob
- (void)AdRefresh
{
	//----------------------------------------------------- AdMob  ＜＜loadView:に入れると起動時に生成失敗すると、以後非表示が続いてしまう。
	if (adMobView_==nil) {
		// iPhone タテ下部に表示固定、ヨコ非表示
		adMobView_ = [[GADBannerView alloc] init];
		// Adパラメータ初期化
		adMobView_.alpha = 0;	// 現在状況、(0)非表示  (1)表示中
		adMobView_.tag = 0;		// 広告受信状況  (0)なし (1)あり
		adMobView_.delegate = self;
		if (app_is_iPad_) {
			adMobView_.adUnitID = AdMobID_PackPAD;	//iPad//
			adMobView_.frame = CGRectMake( 0, 800,  GAD_SIZE_300x250.width, GAD_SIZE_300x250.height);
			adMobView_.rootViewController = mainSVC_;
			[mainSVC_.view addSubview:adMobView_];
		} else {
			adMobView_.adUnitID = AdMobID_PackList;	//iPhone//
			adMobView_.frame = CGRectMake( 0, 500, GAD_SIZE_320x50.width, GAD_SIZE_320x50.height);
			adMobView_.rootViewController = mainNC_;
			[mainNC_.view addSubview:adMobView_];
		}
		//【Tips】初期配置は、常にタテ位置にすること。　ヨコのときだけwillRotateToInterfaceOrientation：などの回転通知が届く。
		[self AdMobWillRotate:UIInterfaceOrientationPortrait]; 

		// リクエスト
		GADRequest *request = [GADRequest request];
		//[request setTesting:YES];
		[adMobView_ loadRequest:request];	
	}
	
	//----------------------------------------------------- iAd: AdMobの上層になるように後からaddSubviewする
	if (iAdView_==nil && [[[UIDevice currentDevice] systemVersion] compare:@"4.0"]!=NSOrderedAscending) { // !<  (>=) "4.0"
		assert(NSClassFromString(@"ADBannerView"));
		iAdView_ = [[ADBannerView alloc] init];		//WithFrame:CGRectZero 
		// Adパラメータ初期化
		iAdView_.alpha = 0;		// 現在状況、(0)非表示  (1)表示中
		iAdView_.tag = 0;		// 広告受信状況  (0)なし (1)あり
		iAdView_.delegate = self;
		if (app_is_iPad_) {
			[mainSVC_.view addSubview:iAdView_];
		} else {
			[mainNC_.view addSubview:iAdView_];
		}
		//【Tips】初期配置は、常にタテ位置にすること。　ヨコのときだけwillRotateToInterfaceOrientation：などの回転通知が届く。
		[self AdAppWillRotate:UIInterfaceOrientationPortrait]; 
	}
	
	NSLog(@"=== AdRefresh: Can[%d] iAd[%d⇒%d] AdMob[%d⇒%d]", adCanVisible_, (int)iAdView_.tag, (int)iAdView_.alpha, 
		  (int)adMobView_.tag, (int)adMobView_.alpha);
	//if (MbAdCanVisible && MbannerView.alpha==MbannerView.tag && RoAdMobView.alpha==RoAdMobView.tag) {
	if (adCanVisible_) {
		if (iAdView_.alpha==iAdView_.tag && adMobView_.alpha==adMobView_.tag) {
			NSLog(@"   = 変化なし =");
			return; // 変化なし
		}
		if (iAdView_.alpha==1 && iAdView_.alpha==iAdView_.tag) {
			NSLog(@"   = iAd 優先ON = 変化なし =");
			return; // 変化なし
		}
	} else {
		if (iAdView_.alpha==0 && adMobView_.alpha==0) {
			NSLog(@"   = OFF = 変化なし =");
			return; // 変化なし
		}
	}
	
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:1.2];
	
	if (app_is_iPad_) {
		if (iAdView_) {
			CGRect rc = iAdView_.frame;
			if (adCanVisible_ && iAdView_.tag==1) {
				if (iAdView_.alpha==0) {
					rc.origin.y += FREE_AD_OFFSET_Y;
					iAdView_.frame = rc;
					iAdView_.alpha = 1;
				}
			} else {
				if (iAdView_.alpha==1) {
					rc.origin.y -= FREE_AD_OFFSET_Y;	//(-)上に隠す
					iAdView_.frame = rc;
					iAdView_.alpha = 0;
				}
			}
		}
		
		if (adMobView_) {
			if (adMobView_.tag==1) { //AdMob常時表示なので、MbAdCanVisible判定不要
				adMobView_.alpha = 1;
			} else {
				adMobView_.alpha = 0;
			}
		}
	}
	else {
		if (iAdView_) {
			CGRect rc = iAdView_.frame;
			if (adCanVisible_ && iAdView_.tag==1) {
				if (iAdView_.alpha==0) {
					rc.origin.y -= FREE_AD_OFFSET_Y;
					iAdView_.frame = rc;
					iAdView_.alpha = 1;
				}
			} else {
				if (iAdView_.alpha==1) {
					rc.origin.y += FREE_AD_OFFSET_Y;	//(+)下へ隠す
					iAdView_.frame = rc;
					iAdView_.alpha = 0;
				}
			}
		}
		
		if (adMobView_) {
			CGRect rc = adMobView_.frame;
			if (adCanVisible_ && adMobView_.tag==1 && iAdView_.alpha==0) { //iAdが非表示のときだけAdMob表示
				if (adMobView_.alpha==0) {
					rc.origin.y = 480 - 50;		//AdMobはヨコ向き常に非表示 ＜＜これはタテの配置なのでヨコだと何もしなくても範囲外で非表示になる
					adMobView_.frame = rc;
					adMobView_.alpha = 1;
				}
			} else {
				if (adMobView_.alpha==1) {
					rc.origin.y = 480 + 10; // 下部へ隠す
					adMobView_.frame = rc;
					adMobView_.alpha = 0;	//[1.0.1]3GS-4.3.3においてAdで電卓キーが押せない不具合報告あり。未確認だがこれにて対応
				}
				// リクエスト
				GADRequest *request = [GADRequest request];
				[adMobView_ loadRequest:request];	
				/*		// 破棄する ＜＜通信途絶してから復帰した場合、再生成するまで受信できないため。再生成する機会を増やす。
				 RoAdMobView.delegate = nil;
				 [RoAdMobView release], RoAdMobView = nil; */
			}
		}
	}

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
	if (adMobView_==nil) return;

	if (app_is_iPad_) {
		if (adMobView_) {
			if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {	// タテ
				adMobView_.frame = CGRectMake(
											   768-45-GAD_SIZE_300x250.width,
											   1024-64-GAD_SIZE_300x250.height,
											   GAD_SIZE_300x250.width, GAD_SIZE_300x250.height);
			} else {	// ヨコ
				adMobView_.frame = CGRectMake(
											   10,
											   768-64-GAD_SIZE_300x250.height,
											   GAD_SIZE_300x250.width, GAD_SIZE_300x250.height);
			}
		}
	} else {
		//iPhoneでは、タテ配置固定のみ。これによりヨコでは常に範囲外で非表示にしている。
	}
}

- (void)AdAppWillRotate:(UIInterfaceOrientation)toInterfaceOrientation
{	// 非表示中でも回転対応すること。表示するときの出発位置のため
	if (iAdView_==nil) return;

	// iOS4.2以降の仕様であるが、以前のOSでは落ちる！！！
	if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
		iAdView_.currentContentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
	} else {
		iAdView_.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
	}

	if (app_is_iPad_) {
		if (adCanVisible_ && iAdView_.alpha==1) {
			iAdView_.frame = CGRectMake(0, 40,  0,0);	// 表示
		} else {
			iAdView_.frame = CGRectMake(0, 40 - FREE_AD_OFFSET_Y,  0,0);  // 上に隠す
		}
	} else {
		if (adCanVisible_ && iAdView_.alpha==1) {	// 表示
			if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
				iAdView_.frame = CGRectMake(0, 320-32,  0,0);	//ヨコ：下部に表示
			} else {
				iAdView_.frame = CGRectMake(0, 480-50,  0,0);	//タテ：下部に表示
			}
		} else {
			if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
				iAdView_.frame = CGRectMake(0, 320-32 + FREE_AD_OFFSET_Y,  0,0);		//ヨコ：下へ隠す
			} else {
				iAdView_.frame = CGRectMake(0, 480-50 + FREE_AD_OFFSET_Y,  0,0);	//タテ：下へ隠す
			}
		}
	}
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
	if (adMobView_) {
		// リクエスト
		GADRequest *request = [GADRequest request];
		[adMobView_ loadRequest:request];	
/*		//[1.1.0]ネット切断から復帰したとき、このように破棄⇒生成が必要。
		RoAdMobView.alpha = 0; //これが無いと残骸が表示されたままになる。
		RoAdMobView.delegate = nil;								//受信STOP  ＜＜これが無いと破棄後に呼び出されて落ちる
		[RoAdMobView release], RoAdMobView = nil;	// 破棄
		//[1.1.0]この後、AdRefresh:にて生成再開される。
 */
	}
	[self AdRefresh];
}


@end

