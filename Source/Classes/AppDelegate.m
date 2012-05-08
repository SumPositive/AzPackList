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
#import "padRootVC.h"
#import "Elements.h"
#import "EntityRelation.h"
#import "FileCsv.h"
#import "E1viewController.h"


#define CoreData_iCloud_SYNC		NO	// YES or NO


@interface AppDelegate (PrivateMethods) // メソッドのみ記述：ここに変数を書くとグローバルになる。他に同じ名称があると不具合発生する
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;

#define FREE_AD_OFFSET_Y			200.0	// iAdを上に隠すため
- (void)AdRefresh;
- (void)AdRemove;
- (void)AdMobWillRotate:(UIInterfaceOrientation)toInterfaceOrientation;
- (void)iAdWillRotate:(UIInterfaceOrientation)toInterfaceOrientation;
@end


@implementation AppDelegate
@synthesize window = window_;
@synthesize managedObjectContext = moc_;
@synthesize mainNC = mainNC_;
@synthesize mainSVC = mainSVC_;
@synthesize padRootVC = padRootVC_;
@synthesize clipE3objects = clipE3objects_;		// [Cut][Copy]されたE3をPUSHスタックする。[Paste]でPOPする
@synthesize dropboxSaveE1selected = __dropboxSaveE1selected;
//@synthesize picasaBox = picasaBox_;
@synthesize app_opt_Autorotate = app_opt_Autorotate_;
@synthesize app_opt_Ad = app_opt_Ad_;				//Setting選択フラグ
@synthesize app_is_iPad = app_is_iPad_;
@synthesize app_UpdateSave = app_UpdateSave_;
@synthesize app_pid_SwitchAd = app_pid_SwitchAd_;		//Store購入済フラグ
@synthesize app_BagSwing = app_BagSwing_;		//YES=PadRootVC:が表示されたとき、バッグを振る。
@synthesize app_enable_iCloud = app_enable_iCloud_;		// persistentStoreCoordinator:にて設定

#pragma mark - Application lifecycle

//static BOOL cleanUbiquitousFolder__ = YES;

//[1.1]メール添付ファイル"*.packlist" をタッチしてモチメモを選択すると、launchOptions にファイルの URL (file://…というスキーマ) で渡される。
//- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
- (void)applicationDidFinishLaunching:(UIApplication *)application
{
	GA_INIT_TRACKER(@"UA-30305032-7", 10, nil);	//-7:PackList2
	GA_TRACK_EVENT(@"Device", @"model", [[UIDevice currentDevice] model], 0);
	GA_TRACK_EVENT(@"Device", @"systemVersion", [[UIDevice currentDevice] systemVersion], 0);

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
							  @"NO",	UD_OptCrypt,
							  @"NO",	UD_Crypt_Switch,
							  nil];
	[userDefaults registerDefaults:azOptDef];	// 未定義のKeyのみ更新される
	[userDefaults synchronize]; // plistへ書き出す
	app_opt_Autorotate_ = [userDefaults boolForKey:UD_OptShouldAutorotate];
	
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
	if ([kvs objectForKey: STORE_PRODUCTID_AdOff]==nil)		[kvs setBool:NO  forKey: STORE_PRODUCTID_AdOff];
	if (kvs==nil) {
		GA_TRACK_EVENT_ERROR(@"KVS==nil",0);
	}
	[kvs synchronize]; // 最新同期
	
	app_opt_Ad_ = [kvs boolForKey:KV_OptAdvertising];
	app_pid_SwitchAd_ = [kvs boolForKey:STORE_PRODUCTID_AdOff];
	//NSLog(@"app_pid_SwitchAd_=%d", app_pid_SwitchAd_);
	
	if (app_pid_SwitchAd_==NO && [userDefaults boolForKey:UD_OptCrypt]) {
		[userDefaults setBool:NO forKey:UD_Crypt_Switch];
	}
	[userDefaults setBool:app_pid_SwitchAd_ forKey:UD_OptCrypt];
	
#ifdef AzMAKE_SPLASHFACE
	app_opt_Ad_ = NO;
#endif
	
	//-------------------------------------------------初期化
	app_UpdateSave_ = NO;
	mAdCanVisible = NO;			// 現在状況、(NO)表示禁止  (YES)表示可能
	if (clipE3objects_==nil) {
		clipE3objects_ = [NSMutableArray array];	//　[Clip Board] クリップボード初期化
	}

	//-------------------------------------------------デバイス、ＯＳ確認
	if ([[[UIDevice currentDevice] systemVersion] compare:@"5.0"]==NSOrderedAscending) { // ＜ "5.0"
		// iOS5.0より前
		alertBox(@"! STOP !", @"Need more iOS 5.0", nil);
		GA_TRACK_EVENT_ERROR(@"STOP < iOS 5.0",0);
		exit(0);
	}
	//app_is_iPad_ = [[[UIDevice currentDevice] model] hasPrefix:@"iPad"];	// iPad
	app_is_iPad_ = iS_iPAD;
	NSLog(@"app_is_iPad_=%d,  app_is_Ad_=%d,  app_pid_AdOff_=%d", app_is_iPad_, app_opt_Ad_, app_pid_SwitchAd_);
	
/*	// iCloud完全クリアする　＜＜＜同期矛盾が生じたときや構造変更時に使用
	//[[NSFileManager defaultManager] removeItemAtURL:cloudURL error:nil];
	if (cleanUbiquitousFolder__) {
		cleanUbiquitousFolder__ = NO;
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSURL *cloudURL = [fileManager URLForUbiquityContainerIdentifier:nil];
		NSString *file = nil;     
		NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:[cloudURL path]];  
		while (file = [enumerator nextObject]) {
			[fileManager removeItemAtPath:file error:nil];
			NSLog(@"Removed %@", file);
		}
		//return;
	}*/
	
	
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
	
	// Photo Picasa
	//picasaBox_ = [[AZPicasa alloc] init];
	
	return;  // YES;  //iOS4
}

- (void)kvsValueChange:(NSNotification*)note 
{	// iCloud-KVS に変化があれば呼び出される
	@synchronized(note)
	{
		NSUbiquitousKeyValueStore *kvs = [NSUbiquitousKeyValueStore defaultStore];
		[kvs synchronize]; // 最新同期
		
		// 別デバイスで設定変更したとき、表示に影響ある設定について再描画する
		
		// 広告表示に変化があれば、広告スペースを調整する
		app_opt_Ad_ = [kvs boolForKey:KV_OptAdvertising];
		[self AdRefresh:app_opt_Ad_];

		// 再フィッチ＆画面リフレッシュ通知  ＜＜＜＜ E1viewController:refreshAllViews: にて iCloud OFF --> ON している。
		[[NSNotificationCenter defaultCenter] postNotificationName: NFM_REFRESH_ALL_VIEWS
															object:self userInfo:nil];
	}
}

// URLスキーマ呼び出し： packlist://
// info.plist "CFBundleURLTypes" 定義
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url 
{
	if ([url isFileURL]) {	// .packlist OR .azp ファイルをタッチしたとき、
		NSLog(@"File loaded into [url path]=%@", [url path]);
		if ([[[url pathExtension] lowercaseString] isEqualToString:GD_EXTENSION]) 
		{	// ファイル・タッチ対応
			UIAlertView *alert = [[UIAlertView alloc] init];
			alert.title = NSLocalizedString(@"Please Wait",nil);
			[alert show];
			
			dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
			dispatch_async(queue, ^{
				// 一時CSVファイルから取り込んで追加する
				FileCsv *fcsv = [[FileCsv alloc] init];
				NSString *zErr = [fcsv zLoadURL:url];
				
				dispatch_async(dispatch_get_main_queue(), ^{
					[alert dismissWithClickedButtonIndex:0 animated:NO]; // 閉じる
					if (zErr==nil) {
						UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Download successful",nil)  //ダウンロード成功
														   message:NSLocalizedString(@"Added Plan",nil)  //プランを追加しました
														  delegate:nil 
												 cancelButtonTitle:nil 
												 otherButtonTitles:@"OK", nil];
						[alert show];
					} 
					else {
						GA_TRACK_EVENT_ERROR(zErr,0);
						UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Download Fail",nil)  //ダウンロード失敗
														   message: zErr
														  delegate:nil 
												 cancelButtonTitle:nil 
												 otherButtonTitles:@"OK", nil];
						[alert show];
					}
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
				});
			});
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
			// Dropbox を開ける
			AZDropboxMode mode;
			if (__dropboxSaveE1selected) {
				mode = AZDropboxUpload;
			} else {
				mode = AZDropboxDownload;
			}
			//DropboxVC *vc = [[DropboxVC alloc] initWithE1:__dropboxSaveE1selected];
			AZDropboxVC *vc = [[AZDropboxVC alloc] initWithMode:mode extension:GD_EXTENSION delegate:self];
			if (mode==AZDropboxUpload) {
				[vc setUpFileName:__dropboxSaveE1selected.name];
				[vc setCryptHidden:NO Enabled:app_pid_SwitchAd_];
			}
			if (app_is_iPad_) {
				//認証して戻ったときAppDelegate内で再現させるため座標情報が不要なFormSheetにしている。
				UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:vc];
				nc.modalPresentationStyle = UIModalPresentationFormSheet;
				nc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
				[mainSVC_ presentModalViewController:nc animated:YES];
			} 
			else {
				if (app_opt_Ad_) {
					[self AdRefresh:NO];	//広告禁止
				}
				[vc setHidesBottomBarWhenPushed:YES]; // 現在のToolBar状態をPushした上で、次画面では非表示にする
				[mainNC_ pushViewController:vc animated:YES];
			}
        }
        return YES;
    }
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
	//NG//[self applicationWillTerminate:application];＜＜NSNotificationCenterが破棄されてしまう。
}


- (void)applicationWillEnterForeground:(UIApplication *)application 
{	//iOS4: アプリケーションがバックグラウンドから復帰する直前に呼ばれる
	NSLog(@"applicationWillEnterForeground");
	[self applicationWillTerminate:application];
}


- (void)applicationDidBecomeActive:(UIApplication *)application 
{	//iOS4: アプリケーションがアクティブになったら呼ばれる
	NSLog(@"applicationDidBecomeActive");
}


// saves changes in the application's managed object context before the application terminates.
- (void)applicationWillTerminate:(UIApplication *)application 
{	// バックグラウンド実行中にアプリが終了された場合に呼ばれる。
	// ただしアプリがサスペンド状態の場合アプリを終了してもこのメソッドは呼ばれない。
	// iOS3互換のためにはここが必要。　iOS4以降、applicationDidEnterBackground から呼び出される。
	NSLog(@"applicationWillTerminate ***");
    
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	//--------------------------------------------------[Clip Board] クリップボード クリア処理
	if (clipE3objects_ && 0 < [clipE3objects_ count]) {
		for (E3 *e3 in clipE3objects_) {
			if (e3.parent == nil) {
				// [Cut]されたE3なので削除する
				[moc_ deleteObject:e3];
			}
		}
	}
	if (moc_ && [moc_ hasChanges]) { //未保存があれば保存する
		NSError *error;
        if (![moc_ save:&error]) {
			GA_TRACK_EVENT_ERROR([error localizedDescription],0);
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			assert(NO); //DEBUGでは落とす
        } 
	}
}

- (void)dealloc 
{
	mAdCanVisible = NO;  // 以後、Ad表示禁止
	[self AdRemove];
	
	mainNC_.delegate = nil;		mainNC_ = nil;
	mainSVC_.delegate = nil;	mainSVC_ = nil;
	padRootVC_ = nil;
}


#pragma mark - iCloud

- (void)mergeiCloudChanges:(NSNotification*)note forContext:(NSManagedObjectContext*)moc 
{
	// マージ処理
    [moc mergeChangesFromContextDidSaveNotification:note]; 
	
	//NSLog(@"NSNotification: POST: RefreshAllViews");
	NSLog(@"mergeiCloudChanges: RefreshAllViews: userInfo=%@", [note userInfo]);

	[[NSNotificationCenter defaultCenter] postNotificationName:NFM_REFRESH_ALL_VIEWS
														object:self userInfo:[note userInfo]];
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

	/*// Main thread
	dispatch_async(dispatch_get_main_queue(), ^{
		[self mergeiCloudChanges:notification forContext:moc];
	});*/

}


#pragma mark - CoreData stack
//[1.2.0.0] AzBodyNote[0.8.0.0]に従って実装した。

- (NSManagedObjectModel *)managedObjectModel 
{
    if (mCoreModel != nil) {
        return mCoreModel;
    }
	
	mCoreModel = [NSManagedObjectModel mergedModelFromBundles:nil];
	
	return mCoreModel;
}


- (NSPersistentStoreCoordinator *)persistentStoreCoordinator 
{
    if (mCorePsc != nil) {
        return mCorePsc;
    }
	
	// <Application_Home>/Documents  ＜＜iCloudバックアップ対象
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	// <Application_Home>/Library/Caches　　＜＜iCloudバックアップされない
	//NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);

	NSString *dir = [paths objectAtIndex:0];
	//NSLog(@"<Application_Home> %@", dir);
	
	NSString *storePath = [dir stringByAppendingPathComponent:@"AzPackList.sqlite"];	//【重要】リリース後変更禁止
	NSLog(@"storePath=%@", storePath);
	
    mCorePsc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
	
	app_enable_iCloud_ = NO;
	
	if (CoreData_iCloud_SYNC  && IOS_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0")) {
		 // do this asynchronously since if this is the first time this particular device is syncing with preexisting
		 // iCloud content it may take a long long time to download

		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"iCloud sync",nil)
														message:NSLocalizedString(@"iCloud sync msg",nil)
													   delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
		UIActivityIndicatorView *alertAct = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		alertAct.frame = CGRectMake((alert.frame.size.width-50)/2, 20, 50, 50);
		[alert addSubview:alertAct];
		[alertAct startAnimating];
		if (app_is_iPad_) {
			[mainSVC_.splitViewController.view addSubview:alert];
		} else {
			[mainNC_.navigationController.view addSubview:alert];
		}
		[window_ addSubview:alert];
		
		 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			 NSFileManager *fileManager = [NSFileManager defaultManager];
			 // Migrate datamodel
			 NSDictionary *options = nil;
			 NSURL *storeUrl = [NSURL fileURLWithPath:storePath];
			 // this needs to match the entitlements and provisioning profile
			 NSURL *cloudURL = [fileManager URLForUbiquityContainerIdentifier:nil]; //.entitlementsから自動取得されるようになった。
			 NSLog(@"cloudURL=1=%@", cloudURL);
			 if (cloudURL) {
				 app_enable_iCloud_ = YES;
				 // アプリ内のコンテンツ名付加：["coredata"]　＜＜＜変わると共有できない。
				 cloudURL = [cloudURL URLByAppendingPathComponent:@"coredata"];
				 NSLog(@"cloudURL=2=%@", cloudURL);

				 options = [NSDictionary dictionaryWithObjectsAndKeys:
							[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
							[NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
							cloudURL, NSPersistentStoreUbiquitousContentURLKey,			// iCloudのアプリフォルダパス		//【重要】リリース後変更禁止
							@"AzPackList.sqlog", NSPersistentStoreUbiquitousContentNameKey,	// cloudURL内のフォルダ名	//【重要】リリース後変更禁止
							nil];
			 } else {
				 // iCloud is not available
				 options = [NSDictionary dictionaryWithObjectsAndKeys:
							[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,	// 自動移行
							[NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,			// 自動マッピング推論して処理
							nil];																									// NO ならば、「.xcmappingmodel」を使って移行処理される。
			 }			 
			 NSLog(@"options=%@", options);

			 // prep the store path and bundle stuff here since NSBundle isn't totally thread safe
			 NSPersistentStoreCoordinator* psc = mCorePsc;
			 NSError *error = nil;
			 [psc lock];
			 if (![psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) 
			 {
				 GA_TRACK_EVENT_ERROR([error localizedDescription],0);
				 NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
				 abort();
			 }
			 [psc unlock];
			 
			 // tell the UI on the main thread we finally added the store and then
			 // post a custom notification to make your views do whatever they need to such as tell their
			 // NSFetchedResultsController to -performFetch again now there is a real store
			 dispatch_async(dispatch_get_main_queue(), ^{
				 NSLog(@"asynchronously added persistent store!");
				 [[NSNotificationCenter defaultCenter] postNotificationName:NFM_REFRESH_ALL_VIEWS
																	 object:self userInfo:nil];
				 [alertAct stopAnimating];
				 [alert dismissWithClickedButtonIndex:alert.cancelButtonIndex animated:YES];
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
		 if (![mCorePsc addPersistentStoreWithType:NSSQLiteStoreType 	 configuration:nil 
																   URL:storeUrl  options:options  error:&error])
		 {
			 GA_TRACK_EVENT_ERROR([error localizedDescription],0);
			 NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			 abort();
		 }
	 }

    return mCorePsc;
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
		if (CoreData_iCloud_SYNC  && IOS_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0")) {
			moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
			//moc = [[NSManagedObjectContext alloc] init];
			
			[moc performBlockAndWait:^{
				// even the post initialization needs to be done within the Block
				[moc setPersistentStoreCoordinator: coordinator];

				// iCloudに変化があれば通知を受ける　＜＜初期ミス！ applicationDidEnterBackground:にて破棄してしまっていた。
				[[NSNotificationCenter defaultCenter] addObserver:self 
														 selector:@selector(mergeChangesFrom_iCloud:) 
															 name:NSPersistentStoreDidImportUbiquitousContentChangesNotification 
														   object:coordinator];
				
				// 競合解決方法   Context <<>> SQLite <<>> iCloud
				// NSErrorMergePolicy - マージコンフリクトを起こすとSQLite保存に失敗する（デフォルト）
				// NSMergeByPropertyStoreTrumpMergePolicy - SQLite(Store)を優先にマージする
				// NSMergeByPropertyObjectTrumpMergePolicy - Context(Object)を優先にマージする
				// NSOverwriteMergePolicy - ContextでSQLiteを上書きする		<<<<<<<<<<
				//　NSRollbackMergePolicy　-　Contextの変更を破棄する
				//[moc setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
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

// 保存されたらマージポリシーに沿ってマージしてもらう
- (void)anotherContextDidSave:(NSNotification *)notification
{
    [moc_ mergeChangesFromContextDidSaveNotification:notification];
}
/*
- (void) managedObjectContextReset 
{	// iCloud OFF--->ON したときのため。
	moc_ = nil;
	persistentStoreCoordinator_ = nil;
	// 再生成
	[EntityRelation setMoc:[self managedObjectContext]];
}*/

#pragma mark - Application's documents directory

// Returns the URL to the application's Documents directory.
/*- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}*/
- (NSString *)applicationDocumentsDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}


#pragma mark - <AZDropboxDelegate>
- (NSString*)azDropboxBeforeUpFilePath:(NSString*)filePath crypt:(BOOL)crypt
{	//Up前処理＜UPするファイルを準備する＞
	// ファイルへ書き出す
	if (__dropboxSaveE1selected) {
		FileCsv *fcsv = [[FileCsv alloc] initWithTmpFilePath:filePath];
		return [fcsv zSaveTmpFile:__dropboxSaveE1selected crypt:crypt];
	} else {
		return NSLocalizedString(@"Dropbox NoFile", nil);
	}
}

- (NSString*)azDropboxDownAfterFilePath:(NSString*)filePath
{	//Down後処理＜DOWNしたファイルを読み込むなど＞
	// ファイルから読み込む
	FileCsv *fcsv = [[FileCsv alloc] initWithTmpFilePath:filePath];
	return  [fcsv zLoadTmpFile];
}

- (void)azDropboxDownCompleated
{	//ここで、Down成功後の再描画など行う
	// 再読み込み 通知発信---> E1viewController
	[[NSNotificationCenter defaultCenter] postNotificationName:NFM_REFRESH_ALL_VIEWS
														object:self userInfo:nil];
}


#pragma mark - Ad

- (void)AdRefresh:(BOOL)bCanVisible
{
	//NSLog(@"=== AdRefresh:(%d)", bCanVisible);
	mAdCanVisible = bCanVisible;
	[self AdRefresh];
}

//- (void)AdShowApple:(BOOL)bApple AdMob:(BOOL)bMob
- (void)AdRefresh
{
	if (app_opt_Ad_==NO && mAdMobView==nil && miAdView==nil) return;
	
	//----------------------------------------------------- AdMob  ＜＜loadView:に入れると起動時に生成失敗すると、以後非表示が続いてしまう。
	if (app_opt_Ad_ && mAdMobView==nil) {
		// iPhone タテ下部に表示固定、ヨコ非表示
		mAdMobView = [[GADBannerView alloc] init];
		// Adパラメータ初期化
		mAdMobView.alpha = 0;	// 現在状況、(0)非表示  (1)表示中
		mAdMobView.tag = 0;		// 広告受信状況  (0)なし (1)あり
		mAdMobView.delegate = self;
		if (app_is_iPad_) {
			mAdMobView.adUnitID = AdMobID_PackPAD;	//iPad//
			mAdMobView.frame = CGRectMake( 0, 800,  GAD_SIZE_300x250.width, GAD_SIZE_300x250.height);
			mAdMobView.rootViewController = mainSVC_;
			[mainSVC_.view addSubview:mAdMobView];
		} else {
			mAdMobView.adUnitID = AdMobID_PackList;	//iPhone//
			mAdMobView.frame = CGRectMake( 0, 500, GAD_SIZE_320x50.width, GAD_SIZE_320x50.height);
			mAdMobView.rootViewController = mainNC_;
			[mainNC_.view addSubview:mAdMobView];
		}
		//【Tips】初期配置は、常にタテ位置にすること。　ヨコのときだけwillRotateToInterfaceOrientation：などの回転通知が届く。
		[self AdMobWillRotate:UIInterfaceOrientationPortrait]; 

		// リクエスト
		GADRequest *request = [GADRequest request];
		//[request setTesting:YES];
		[mAdMobView loadRequest:request];	
	}
	
	//----------------------------------------------------- iAd: AdMobの上層になるように後からaddSubviewする
	if (app_opt_Ad_ && miAdView==nil
		&& [[[UIDevice currentDevice] systemVersion] compare:@"4.0"]!=NSOrderedAscending) { // !<  (>=) "4.0"
		assert(NSClassFromString(@"ADBannerView"));
		miAdView = [[ADBannerView alloc] init];		//WithFrame:CGRectZero 
		// Adパラメータ初期化
		miAdView.alpha = 0;		// 現在状況、(0)非表示  (1)表示中
		miAdView.tag = 0;		// 広告受信状況  (0)なし (1)あり
		miAdView.delegate = self;
		if (app_is_iPad_) {
			[mainSVC_.view addSubview:miAdView];
		} else {
			[mainNC_.view addSubview:miAdView];
		}
		//【Tips】初期配置は、常にタテ位置にすること。　ヨコのときだけwillRotateToInterfaceOrientation：などの回転通知が届く。
		[self iAdWillRotate:UIInterfaceOrientationPortrait]; 
	}
	
	if (app_opt_Ad_) {
		//NSLog(@"=== AdRefresh: Can[%d] iAd[%d⇒%d] AdMob[%d⇒%d]", adCanVisible_, (int)iAdView_.tag, (int)iAdView_.alpha, 
		//	  (int)adMobView_.tag, (int)adMobView_.alpha);
		//if (MbAdCanVisible && MbannerView.alpha==MbannerView.tag && RoAdMobView.alpha==RoAdMobView.tag) {
		if (mAdCanVisible) {
			if (miAdView.alpha==miAdView.tag && mAdMobView.alpha==mAdMobView.tag) {
				//NSLog(@"   = 変化なし =");
				return; // 変化なし
			}
			if (miAdView.alpha==1 && miAdView.alpha==miAdView.tag) {
				//NSLog(@"   = iAd 優先ON = 変化なし =");
				return; // 変化なし
			}
		} else {
			if (miAdView.alpha==0 && mAdMobView.alpha==0) {
				//NSLog(@"   = OFF = 変化なし =");
				return; // 変化なし
			}
		}
	} 
	else {
		mAdCanVisible = NO;	// app_opt_Ad_==NO につき、Ad非表示にしてから破棄する。
	}
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:1.2];
	
	if (app_opt_Ad_==NO) {		// AdOffのとき、非表示アニメの後、破棄する
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(AdRefreshAfter)];
	}

	if (app_is_iPad_) {
		if (miAdView) {
			CGRect rc = miAdView.frame;
			if (mAdCanVisible && miAdView.tag==1) {
				if (miAdView.alpha==0) {
					rc.origin.y += FREE_AD_OFFSET_Y;
					miAdView.frame = rc;
					miAdView.alpha = 1;
				}
			} else {
				if (miAdView.alpha==1) {
					rc.origin.y -= FREE_AD_OFFSET_Y;	//(-)上に隠す
					miAdView.frame = rc;
					miAdView.alpha = 0;
				}
			}
		}
		
		if (mAdMobView) {
			if (mAdCanVisible && mAdMobView.tag==1) {
				if (mAdMobView.alpha==0) {
					mAdMobView.alpha = 1;
				}
			} else {
				if (app_is_iPad_ && app_opt_Ad_) {
					mAdMobView.alpha = 1;		// iPadは常時表示
				}
				else if (mAdMobView.alpha==1) {
					mAdMobView.alpha = 0;
				}
			}
		}
	}
	else {
		if (miAdView) {
			CGRect rc = miAdView.frame;
			if (mAdCanVisible && miAdView.tag==1) {
				if (miAdView.alpha==0) {
					rc.origin.y -= FREE_AD_OFFSET_Y;
					miAdView.frame = rc;
					miAdView.alpha = 1;
				}
			} else {
				if (miAdView.alpha==1) {
					rc.origin.y += FREE_AD_OFFSET_Y;	//(+)下へ隠す
					miAdView.frame = rc;
					miAdView.alpha = 0;
				}
			}
		}
		
		if (mAdMobView) {
			CGRect rc = mAdMobView.frame;
			if (mAdCanVisible && mAdMobView.tag==1 && miAdView.alpha==0) { //iAdが非表示のときだけAdMob表示
				if (mAdMobView.alpha==0) {
					rc.origin.y = 480 - 50;		//AdMobはヨコ向き常に非表示 ＜＜これはタテの配置なのでヨコだと何もしなくても範囲外で非表示になる
					mAdMobView.frame = rc;
					mAdMobView.alpha = 1;
				}
			} else {
				if (mAdMobView.alpha==1) {
					rc.origin.y = 480 + 10; // 下部へ隠す
					mAdMobView.frame = rc;
					mAdMobView.alpha = 0;	//[1.0.1]3GS-4.3.3においてAdで電卓キーが押せない不具合報告あり。未確認だがこれにて対応
				}
				// リクエスト
				GADRequest *request = [GADRequest request];
				[mAdMobView loadRequest:request];	
				/*		// 破棄する ＜＜通信途絶してから復帰した場合、再生成するまで受信できないため。再生成する機会を増やす。
				 RoAdMobView.delegate = nil;
				 [RoAdMobView release], RoAdMobView = nil; */
			}
		}
	}
	// アニメ開始
	[UIView commitAnimations];
}

- (void)AdRemove
{	// dealloc:からも呼び出される
	if (mAdMobView) {
		mAdMobView.delegate = nil;
		mAdMobView.rootViewController = nil;
		[mAdMobView removeFromSuperview];
		mAdMobView = nil;
	}
	if (miAdView) {
		[miAdView cancelBannerViewAction];	// 停止
		miAdView.delegate = nil;
		[miAdView removeFromSuperview];
		miAdView = nil;
	}
}

- (void)AdRefreshAfter  // 非表示アニメ終了後に呼び出される
{
	if (app_opt_Ad_==NO) {		// AdOffのとき、非表示アニメの後、破棄する
		[self AdRemove];
	}
}

- (void)AdViewWillRotate:(UIInterfaceOrientation)toInterfaceOrientation
{
	[self AdMobWillRotate:toInterfaceOrientation];	//AdMob
	[self iAdWillRotate:toInterfaceOrientation];			//iAd
}

- (void)AdMobWillRotate:(UIInterfaceOrientation)toInterfaceOrientation
{
	if (mAdMobView==nil) return;

	if (app_is_iPad_) {
		if (mAdMobView) {
			if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {	// タテ
				mAdMobView.frame = CGRectMake(
											   768-45-GAD_SIZE_300x250.width,
											   1024-64-GAD_SIZE_300x250.height,
											   GAD_SIZE_300x250.width, GAD_SIZE_300x250.height);
			} else {	// ヨコ
				mAdMobView.frame = CGRectMake(
											   10,
											   768-64-GAD_SIZE_300x250.height,
											   GAD_SIZE_300x250.width, GAD_SIZE_300x250.height);
			}
		}
	} else {
		//iPhoneでは、タテ配置固定のみ。これによりヨコでは常に範囲外で非表示にしている。
	}
}

- (void)iAdWillRotate:(UIInterfaceOrientation)toInterfaceOrientation
{	// 非表示中でも回転対応すること。表示するときの出発位置のため
	if (miAdView==nil) return;

	// iOS4.2以降の仕様であるが、以前のOSでは落ちる！！！
	if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
		miAdView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
	} else {
		miAdView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
	}

	if (app_is_iPad_) {
		if (mAdCanVisible && miAdView.alpha==1) {
			miAdView.frame = CGRectMake(0, 40,  0,0);	// 表示
		} else {
			miAdView.frame = CGRectMake(0, 40 - FREE_AD_OFFSET_Y,  0,0);  // 上に隠す
		}
	} else {
		if (mAdCanVisible && miAdView.alpha==1) {	// 表示
			if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
				miAdView.frame = CGRectMake(0, 320-32,  0,0);	//ヨコ：下部に表示
			} else {
				miAdView.frame = CGRectMake(0, 480-50,  0,0);	//タテ：下部に表示
			}
		} else {
			if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
				miAdView.frame = CGRectMake(0, 320-32 + FREE_AD_OFFSET_Y,  0,0);		//ヨコ：下へ隠す
			} else {
				miAdView.frame = CGRectMake(0, 480-50 + FREE_AD_OFFSET_Y,  0,0);	//タテ：下へ隠す
			}
		}
	}
}

- (void)adViewDidReceiveAd:(GADBannerView *)bannerView 
{	// AdMob 広告あり
	//NSLog(@"AdMob - adViewDidReceiveAd");
	bannerView.tag = 1;	// 広告受信状況  (0)なし (1)あり
	[self AdRefresh];
}

- (void)adView:(GADBannerView *)bannerView didFailToReceiveAdWithError:(GADRequestError *)error 
{	// AdMob 広告なし
	//NSLog(@"AdMob - adView:didFailToReceiveAdWithError:%@", [error localizedDescription]);
	bannerView.tag = 0;	// 広告受信状況  (0)なし (1)あり
	[self AdRefresh];
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{	// iAd取得できたときに呼ばれる　⇒　表示する
	//NSLog(@"iAd - bannerViewDidLoadAd ===");
	banner.tag = 1;	// 広告受信状況  (0)なし (1)あり
	[self AdRefresh];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{	// iAd取得できなかったときに呼ばれる　⇒　非表示にする
	//NSLog(@"iAd - didFailToReceiveAdWithError");
	banner.tag = 0;	// 広告受信状況  (0)なし (1)あり

	// AdMob 破棄する ＜＜通信途絶してから復帰した場合、再生成するまで受信できないため。再生成する機会を増やす。
	if (mAdMobView) {
		// リクエスト
		GADRequest *request = [GADRequest request];
		[mAdMobView loadRequest:request];	
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

