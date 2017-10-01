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
#import "PadRootVC.h"
#import "Elements.h"
#import "MocFunctions.h"
#import "FileCsv.h"
#import "E1viewController.h"
//#import <FirebaseCore/FirebaseCore.h>


//iOS6以降、回転対応のためサブクラス化が必要になった。
@implementation AzNavigationController
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{	//iOS6以降
	//トップビューの向きを返す
	return self.topViewController.supportedInterfaceOrientations;
}
- (BOOL)shouldAutorotate
{	//iOS6以降
    return YES;
}
@end


@interface AppDelegate (PrivateMethods) // メソッドのみ記述：ここに変数を書くとグローバルになる。他に同じ名称があると不具合発生する
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;

#define FREE_AD_OFFSET_Y			200.0	// iAdを上に隠すため
- (void)AdRefresh;
- (void)AdRemove;
//- (void)AdMobWillRotate:(UIInterfaceOrientation)toInterfaceOrientation;
//- (void)iAdWillRotate:(UIInterfaceOrientation)toInterfaceOrientation;
@end


@implementation AppDelegate
@synthesize window = __window;
//@synthesize managedObjectContext = __moc;
@synthesize mainNC = __mainNC;
@synthesize mainSVC = __mainSVC;
@synthesize padRootVC = __padRootVC;
@synthesize clipE3objects = __clipE3objects;		// [Cut][Copy]されたE3をPUSHスタックする。[Paste]でPOPする
@synthesize dropboxSaveE1selected = __dropboxSaveE1selected;
@synthesize ppOptAutorotate = __OptAutorotate;
@synthesize ppOptShowAd = __OptShowAd;				//Setting選択フラグ
@synthesize ppIsPad = __IsPad;
@synthesize ppChanged = __Changed;
//@synthesize ppPaid_SwitchAd = __Paid_SwitchAd;		//Store購入済フラグ
@synthesize ppBagSwing = __BagSwing;		//YES=PadRootVC:が表示されたとき、バッグを振る。
@synthesize ppEnabled_iCloud = __Enabled_iCloud;		// persistentStoreCoordinator:にて設定
@synthesize popoverButtonItem = popoverButtonItem_;

#pragma mark - Application lifecycle

//[1.1]メール添付ファイル"*.packlist" をタッチしてモチメモを選択すると、launchOptions にファイルの URL (file://…というスキーマ) で渡される。
//- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
- (void)applicationDidFinishLaunching:(UIApplication *)application
{
	GA_INIT_TRACKER(@"UA-30305032-7", 10, nil);	//-7:PackList2
	GA_TRACK_EVENT(@"Device", @"model", [[UIDevice currentDevice] model], 0);
	GA_TRACK_EVENT(@"Device", @"systemVersion", [[UIDevice currentDevice] systemVersion], 0);

	// MainWindow    ＜＜MainWindow.xlb を使用しないため、ここで生成＞＞
	__window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
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
	__OptAutorotate = [userDefaults boolForKey:UD_OptShouldAutorotate];
	
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
	
    __OptShowAd = NO; //2.1.3//基本無料ADなし　　 //[kvs boolForKey:KV_OptAdvertising];
	
//    if (__OptShowAd) {
//        [FIRApp configure];
//    }
	
	//-------------------------------------------------初期化
	__Changed = NO;
	mAdCanVisible = NO;			// 現在状況、(NO)表示禁止  (YES)表示可能
	if (__clipE3objects==nil) {
		__clipE3objects = [NSMutableArray array];	//　[Clip Board] クリップボード初期化
	}

	//-------------------------------------------------デバイス、ＯＳ確認
	__IsPad = iS_iPAD;
//	NSLog(@"__IsPad=%d,  app_is_Ad_=%d,  app_pid_AdOff_=%d", __IsPad, __OptShowAd, __Paid_SwitchAd);
	
	//-------------------------------------------------Moc初期化
	[[MocFunctions sharedMocFunctions] initialize];
	

	//-------------------------------------------------
	if (self.ppIsPad) {
        // Left[0]
		__padRootVC = [[PadRootVC alloc] init]; // retainされる
		AzNavigationController* naviLeft = [[AzNavigationController alloc]
											initWithRootViewController:__padRootVC];
		// Right[0]
		E1viewController *e1viewCon = [[E1viewController alloc] init];
		AzNavigationController* naviRight = [[AzNavigationController alloc] initWithRootViewController:e1viewCon];
		
		// e1viewCon を splitViewCon へ登録
		__mainSVC = [[UISplitViewController alloc] init];
		__mainSVC.viewControllers = @[naviLeft, naviRight];
		__mainSVC.delegate = self; //<UISplitViewControllerDelegate>
        __mainSVC.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible; //iOS9// タテ2分割が可能になった
		// mainVC を window へ登録
		//[__window addSubview:__mainSVC.view];
		//[__window setRootViewController: __mainSVC];	//iOS6以降、こうしなければ回転しない。
        self.window.rootViewController = __mainSVC;
	}
	else {
		E1viewController *e1viewCon = [[E1viewController alloc] init];
		//e1viewCon.Rmoc = self.managedObjectContext; ＜＜待ちを減らすため、E1viewController:内で生成するように改めた。
		// e1viewCon を naviCon へ登録
		__mainNC = [[AzNavigationController alloc] initWithRootViewController:e1viewCon];
		// mainVC を window へ登録
		//[__window addSubview:__mainNC.view];
		//[__window setRootViewController: __mainNC];	//iOS6以降、こうしなければ回転しない。
        NSLog(@"height=%lf", [[UIScreen mainScreen] bounds].size.height);
        self.window.rootViewController = __mainNC;  //[UIViewController new];
	}
	
	//Pad// iOS4以降を前提としてバックグランド機能に任せて前回復帰処理しないことにした。
	[self.window makeKeyAndVisible];	// 表示開始
	
//	// Dropbox 標準装備
//	DBSession* dbSession = [[DBSession alloc]
//							 initWithAppKey:DBOX_APPKEY
//							 appSecret:DBOX_SECRET
//							root:kDBRootAppFolder]; // either kDBRootAppFolder or kDBRootDropbox
//	[DBSession setSharedSession:dbSession];

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
		
//		// 広告表示に変化があれば、広告スペースを調整する
//		__OptShowAd = [kvs boolForKey:KV_OptAdvertising];
//		[self AdRefresh:__OptShowAd];

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
		if ([[[url pathExtension] lowercaseString] isEqualToString:GD_EXTENSION] || [[[url pathExtension] lowercaseString] isEqualToString:@"packlist"])
		{	// ファイル・タッチ対応
//			UIAlertView *alert = [[UIAlertView alloc] init];
//			alert.title = NSLocalizedString(@"Please Wait",nil);
//			[alert show];
            [SVProgressHUD showWithStatus:NSLocalizedString(@"Please Wait",nil)];
            
			dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
			dispatch_async(queue, ^{
				// 一時CSVファイルから取り込んで追加する
				FileCsv *fcsv = [[FileCsv alloc] init];
				NSString *zErr = [fcsv zLoadURL:url];
				
				dispatch_async(dispatch_get_main_queue(), ^{
//					[alert dismissWithClickedButtonIndex:0 animated:NO]; // 閉じる
                    [SVProgressHUD dismiss];
					if (zErr==nil) {
//						UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Download successful",nil)  //ダウンロード成功
//														   message:NSLocalizedString(@"Added Plan",nil)  //プランを追加しました
//														  delegate:nil 
//												 cancelButtonTitle:nil 
//												 otherButtonTitles:@"OK", nil];
//						[alert show];
                        [AZAlert target:nil
                                  title:NSLocalizedString(@"Download successful",nil)  //ダウンロード成功
                                message:NSLocalizedString(@"Added Plan",nil)  //プランを追加しました
                                b1title:@"OK"
                                b1style:UIAlertActionStyleDefault
                               b1action:nil];
					} 
					else {
						GA_TRACK_EVENT_ERROR(zErr,0);
//						UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Download Fail",nil)  //ダウンロード失敗
//														   message: zErr
//														  delegate:nil 
//												 cancelButtonTitle:nil 
//												 otherButtonTitles:@"OK", nil];
//						[alert show];
                        [AZAlert target:nil
                                  title:NSLocalizedString(@"Download Fail",nil)  //ダウンロード失敗
                                message:zErr
                                b1title:@"OK"
                                b1style:UIAlertActionStyleDefault
                               b1action:nil];
					}
					// 再表示
					if (__IsPad) {
						UIViewController *vc = [__mainSVC.viewControllers  objectAtIndex:1]; //[1]Right
						if ([vc respondsToSelector:@selector(viewWillAppear:)]) {
							[vc viewWillAppear:YES];
						}
					} else {
						if ([__mainNC.visibleViewController respondsToSelector:@selector(viewWillAppear:)]) {
							[__mainNC.visibleViewController viewWillAppear:YES];
						}
					}
				});
			});
			return YES;
		}
		else {
//			UIAlertView *alv = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"AlertExtension", nil)
//														   message:NSLocalizedString(@"AlertExtensionMsg", nil)
//														  delegate:nil
//												 cancelButtonTitle:nil
//												 otherButtonTitles:NSLocalizedString(@"Roger", nil), nil];
//			[alv	show];
            [AZAlert target:nil
                      title:NSLocalizedString(@"AlertExtension", nil)
                    message:NSLocalizedString(@"AlertExtensionMsg", nil)
                    b1title:NSLocalizedString(@"Roger", nil)
                    b1style:UIAlertActionStyleDefault
                   b1action:nil];
		}
	}
//	else if ([[DBSession sharedSession] handleOpenURL:url]) { //OAuth結果：urlに認証キーが含まれる
//        return YES;
//    }
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
	NSManagedObjectContext *moc = [[MocFunctions sharedMocFunctions] getMoc];
	if (__clipE3objects && 0 < [__clipE3objects count]) {
		for (E3 *e3 in __clipE3objects) {
			if (e3.parent == nil) {
				// [Cut]されたE3なので削除する
				[moc deleteObject:e3];
			}
		}
	}
	if (moc && [moc hasChanges]) { //未保存があれば保存する
		NSError *error;
        if (![moc save:&error]) {
			GA_TRACK_ERROR([error description]);
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			assert(NO); //DEBUGでは落とす
        } 
	}
}

- (void)dealloc 
{
	mAdCanVisible = NO;  // 以後、Ad表示禁止
	[self AdRemove];
	
	__mainNC.delegate = nil;		__mainNC = nil;
	__mainSVC.delegate = nil;	__mainSVC = nil;
	__padRootVC = nil;
	popoverButtonItem_ = nil;
}



#pragma mark - <UISplitViewControllerDelegate>
////[Index]Popoverが開いたときに呼び出される
//- (void)splitViewController:(UISplitViewController*)svc
//          popoverController:(UIPopoverController*)pc
//  willPresentViewController:(UIViewController *)aViewController
//{
//    //NSLog(@"aViewController=%@", aViewController);
//    AzNavigationController* nc = (AzNavigationController*)aViewController;
//    E2viewController* vc = (E2viewController*)nc.visibleViewController;
//    if ([vc respondsToSelector:@selector(setPopover:)]) {
//        [vc setPopover:pc];    //内側から閉じるため
//    }
//    return;
//}
//
////タテになって左ペインが隠れる前に呼び出される
//- (void)splitViewController:(UISplitViewController*)svc
//     willHideViewController:(UIViewController *)aViewController
//          withBarButtonItem:(UIBarButtonItem*)barButtonItem
//       forPopoverController:(UIPopoverController*)pc        //左ペインが内包されるPopover
//{
//    barButtonItem.title = NSLocalizedString(@"Index button", nil);
//    //self.popoverController = pc;
//    popoverButtonItem_ = barButtonItem;
//    AzNavigationController *navi = [svc.viewControllers objectAtIndex:1];
//    UIViewController <DetailViewController> *detailVC = (UIViewController <DetailViewController> *)navi.visibleViewController;
//    if ([detailVC respondsToSelector:@selector(showPopoverButtonItem:)]) {
//        [detailVC showPopoverButtonItem:popoverButtonItem_];
//    }
//}
//
////ヨコになって左ペインが現れる前に呼び出される
//- (void)splitViewController:(UISplitViewController*)svc
//     willShowViewController:(UIViewController *)aViewController
//  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
//{
//    AzNavigationController *navi = [svc.viewControllers objectAtIndex:1];
//    UIViewController <DetailViewController> *detailVC = (UIViewController <DetailViewController> *)navi.visibleViewController;
//    if ([detailVC respondsToSelector:@selector(hidePopoverButtonItem:)]) {
//        [detailVC hidePopoverButtonItem:popoverButtonItem_];
//    }
//    //self.popoverController = nil;
//    popoverButtonItem_ = nil;
//}
//
//- (BOOL)splitViewController:(UISplitViewController *)splitViewController
//        collapseSecondaryViewController:(UIViewController *)secondaryViewController
//        ontoPrimaryViewController:(UIViewController *)primaryViewController {
//    return YES;
//}



#pragma mark - <AZDropboxDelegate>
//- (NSString*)azDropboxBeforeUpFilePath:(NSString*)filePath crypt:(BOOL)crypt
//{    //Up前処理＜UPするファイルを準備する＞
//    // ファイルへ書き出す
//    if (__dropboxSaveE1selected) {
//        FileCsv *fcsv = [[FileCsv alloc] initWithTmpFilePath:filePath];
//        return [fcsv zSaveTmpFile:__dropboxSaveE1selected crypt:crypt];
//    } else {
//        return NSLocalizedString(@"Dropbox NoFile", nil);
//    }
//}
//
//- (NSString*)azDropboxDownAfterFilePath:(NSString*)filePath
//{    //Down後処理＜DOWNしたファイルを読み込むなど＞
//    // ファイルから読み込む
//    FileCsv *fcsv = [[FileCsv alloc] initWithTmpFilePath:filePath];
//    return  [fcsv zLoadTmpFile];
//}
//
////結果　　ここで、成功後の再描画など行う
//- (void)azDropboxUpResult:(NSString*)result
//{    //=nil:Up成功
//    return;
//}
//- (void)azDropboxDownResult:(NSString*)result
//{    //=nil:Down成功
//    if (result==nil) {
//        // 再読み込み 通知発信---> E1viewController
//        [[NSNotificationCenter defaultCenter] postNotificationName:NFM_REFRESH_ALL_VIEWS
//                                                            object:self userInfo:nil];
//    }
//}


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
//	if (__OptShowAd==NO && mAdMobView==nil) return;
//	
//	//----------------------------------------------------- AdMob  ＜＜loadView:に入れると起動時に生成失敗すると、以後非表示が続いてしまう。
//	if (__OptShowAd && mAdMobView==nil) {
//		// iPhone タテ下部に表示固定、ヨコ非表示
//		mAdMobView = [[GADBannerView alloc] init];
//		// Adパラメータ初期化
//		mAdMobView.alpha = 0;	// 現在状況、(0)非表示  (1)表示中
//		mAdMobView.tag = 0;		// 広告受信状況  (0)なし (1)あり
//		mAdMobView.delegate = self;
//		if (__IsPad) {
//			mAdMobView.adUnitID = AdMobID_PackPAD;	//iPad//
//			mAdMobView.frame = CGRectMake( 0, 800,  GAD_SIZE_300x250.width, GAD_SIZE_300x250.height);
//			mAdMobView.rootViewController = __mainSVC;
//			[__mainSVC.view addSubview:mAdMobView];
//		} else {
//			mAdMobView.adUnitID = AdMobID_PackList;	//iPhone//
//			//mAdMobView.frame = CGRectMake( 0, 500, GAD_SIZE_320x50.width, GAD_SIZE_320x50.height);
//			mAdMobView.frame = CGRectMake( 0, self.window.frame.size.height+GAD_SIZE_320x50.height,
//										  GAD_SIZE_320x50.width, GAD_SIZE_320x50.height);
//			mAdMobView.rootViewController = __mainNC;
//			[__mainNC.view addSubview:mAdMobView];
//		}
//		//【Tips】初期配置は、常にタテ位置にすること。　ヨコのときだけwillRotateToInterfaceOrientation：などの回転通知が届く。
//		[self AdMobWillRotate:UIInterfaceOrientationPortrait]; 
//
//		// リクエスト
//		GADRequest *request = [GADRequest request];
//		//[request setTesting:YES];
//		[mAdMobView loadRequest:request];	
//	}
	
//	//----------------------------------------------------- iAd: AdMobの上層になるように後からaddSubviewする
//	if (__OptShowAd && miAdView==nil
//		&& [[[UIDevice currentDevice] systemVersion] compare:@"4.0"]!=NSOrderedAscending) { // !<  (>=) "4.0"
//		assert(NSClassFromString(@"ADBannerView"));
//		miAdView = [[ADBannerView alloc] init];		//WithFrame:CGRectZero 
//		// Adパラメータ初期化
//		miAdView.alpha = 0;		// 現在状況、(0)非表示  (1)表示中
//		miAdView.tag = 0;		// 広告受信状況  (0)なし (1)あり
//		miAdView.delegate = self;
//		if (__IsPad) {
//			[__mainSVC.view addSubview:miAdView];
//		} else {
//			[__mainNC.view addSubview:miAdView];
//		}
//		//【Tips】初期配置は、常にタテ位置にすること。　ヨコのときだけwillRotateToInterfaceOrientation：などの回転通知が届く。
//		[self iAdWillRotate:UIInterfaceOrientationPortrait]; 
//	}
	
//	if (__OptShowAd) {
//		//NSLog(@"=== AdRefresh: Can[%d] iAd[%d⇒%d] AdMob[%d⇒%d]", adCanVisible_, (int)iAdView_.tag, (int)iAdView_.alpha, 
//		//	  (int)adMobView_.tag, (int)adMobView_.alpha);
//		//if (MbAdCanVisible && MbannerView.alpha==MbannerView.tag && RoAdMobView.alpha==RoAdMobView.tag) {
//		if (mAdCanVisible) {
//			if (mAdMobView.alpha==mAdMobView.tag) {
//				//NSLog(@"   = 変化なし =");
//				return; // 変化なし
//			}
//		} else {
//			if (mAdMobView.alpha==0) {
//				//NSLog(@"   = OFF = 変化なし =");
//				return; // 変化なし
//			}
//		}
//	} 
//	else {
//		mAdCanVisible = NO;	// __OptShowAd==NO につき、Ad非表示にしてから破棄する。
//	}
//	
//	[UIView beginAnimations:nil context:NULL];
//	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
//	[UIView setAnimationDuration:1.2];
//	
//	if (__OptShowAd==NO) {		// AdOffのとき、非表示アニメの後、破棄する
//		[UIView setAnimationDelegate:self];
//		[UIView setAnimationDidStopSelector:@selector(AdRefreshAfter)];
//	}

	if (__IsPad) {
//		if (miAdView) {
//			//CGRect rc = miAdView.frame;
//			if (mAdCanVisible && miAdView.tag==1) {
//				if (miAdView.alpha==0) {
//					//rc.origin.y += FREE_AD_OFFSET_Y;
//					//miAdView.frame = rc;
//					miAdView.alpha = 1;
//				}
//			} else {
//				if (miAdView.alpha==1) {
//					//rc.origin.y -= FREE_AD_OFFSET_Y;	//(-)上に隠す
//					//miAdView.frame = rc;
//					miAdView.alpha = 0;
//				}
//			}
//		}
		
//		if (mAdMobView) {
//			if (UIInterfaceOrientationIsPortrait(__mainSVC.interfaceOrientation)) {
//				mAdMobView.alpha = 0;	//iPadのみ、タテのとき消す
//			} else {
//				if (mAdCanVisible && mAdMobView.tag==1) {
//					if (mAdMobView.alpha==0) {
//						mAdMobView.alpha = 1;
//					}
//				} else {
//					if (__IsPad && __OptShowAd) {
//						mAdMobView.alpha = 1;		// iPadは常時表示
//					}
//					else if (mAdMobView.alpha==1) {
//						mAdMobView.alpha = 0;
//					}
//				}
//			}
//		}
	}
	else {
//		if (miAdView) {
//			//CGRect rc = miAdView.frame;
//			if (mAdCanVisible && miAdView.tag==1) {
//				if (miAdView.alpha==0) {
//					//rc.origin.y -= FREE_AD_OFFSET_Y;
//					//miAdView.frame = rc;
//					miAdView.alpha = 1;
//				}
//			} else {
//				if (miAdView.alpha==1) {
//					//rc.origin.y += FREE_AD_OFFSET_Y;	//(+)下へ隠す
//					//miAdView.frame = rc;
//					miAdView.alpha = 0;
//				}
//			}
//		}
		
//		if (mAdMobView) {
//			//CGRect rc = mAdMobView.frame;
//			if (mAdCanVisible && mAdMobView.tag==1) { //iAdが非表示のときだけAdMob表示
//				if (mAdMobView.alpha==0) {
//					//rc.origin.y = 480 - 50;		//AdMobはヨコ向き常に非表示 ＜＜これはタテの配置なのでヨコだと何もしなくても範囲外で非表示になる
//					//mAdMobView.frame = rc;
//					mAdMobView.alpha = 1;
//				}
//			} else {
//				if (mAdMobView.alpha==1) {
//					//rc.origin.y = 480 + 10; // 下部へ隠す
//					//mAdMobView.frame = rc;
//					mAdMobView.alpha = 0;	//[1.0.1]3GS-4.3.3においてAdで電卓キーが押せない不具合報告あり。未確認だがこれにて対応
//				}
//				// リクエスト
//				GADRequest *request = [GADRequest request];
//				[mAdMobView loadRequest:request];	
//			}
//		}
	}
	// アニメ開始
	[UIView commitAnimations];
}

- (void)AdRemove
{	// dealloc:からも呼び出される
//	if (mAdMobView) {
//		mAdMobView.delegate = nil;
//		mAdMobView.rootViewController = nil;
//		[mAdMobView removeFromSuperview];
//		mAdMobView = nil;
//	}
//	if (miAdView) {
//		[miAdView cancelBannerViewAction];	// 停止
//		miAdView.delegate = nil;
//		[miAdView removeFromSuperview];
//		miAdView = nil;
//	}
}

- (void)AdRefreshAfter  // 非表示アニメ終了後に呼び出される
{
//	if (__OptShowAd==NO) {		// AdOffのとき、非表示アニメの後、破棄する
//		[self AdRemove];
//	}
}

- (void)AdViewWillRotate:(UIInterfaceOrientation)toInterfaceOrientation
{
//	[self AdMobWillRotate:toInterfaceOrientation];	//AdMob
//	[self iAdWillRotate:toInterfaceOrientation];			//iAd
}

- (void)AdMobWillRotate:(UIInterfaceOrientation)toInterfaceOrientation
{
//	if (mAdMobView==nil) return;
//
//	if (__IsPad) {
//		if (mAdMobView) {
//			CGFloat fyOfs = GAD_SIZE_300x250.height+20+66;  // 20=ステータスバー高さ　　66=iAd高さ
//			if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {	// タテ
//				/*mAdMobView.frame = CGRectMake(
//											   768-45-GAD_SIZE_300x250.width,
//											   1024-fyOfs,
//											   GAD_SIZE_300x250.width, GAD_SIZE_300x250.height);*/
//				mAdMobView.alpha = 0;	//[2.0.2]タテ非表示にした。iAdを常時表示にしたため。
//			} else {	// ヨコ
//				mAdMobView.alpha = 1;
//				mAdMobView.frame = CGRectMake(
//											   10,
//											   768-fyOfs,
//											   GAD_SIZE_300x250.width, GAD_SIZE_300x250.height);
//			}
//		}
//	} else {
//		//iPhoneでは、タテ配置固定のみ。これによりヨコでは常に範囲外で非表示にしている。
//	}
}

//- (void)iAdWillRotate:(UIInterfaceOrientation)toInterfaceOrientation
//{	// 非表示中でも回転対応すること。表示するときの出発位置のため
//	if (miAdView==nil) return;
//
//	// iOS4.2以降の仕様であるが、以前のOSでは落ちる！！！
//	//if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
//	//	miAdView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
//	//} else {
//	//	miAdView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
//	//}
//	//常にタテ用（幅768）にする。
//	//miAdView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
//
//	if (__IsPad) {
//		if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {	//ヨコ
//			miAdView.frame = CGRectMake(0, self.window.frame.size.width-20-66,  0,0);	// 20=ステータスバー高さ
//		} else {	//タテ
//			miAdView.frame = CGRectMake(0, self.window.frame.size.height-20-66,  0,0);
//		}
//	} else {
//		if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
//			miAdView.frame = CGRectMake(0, 320-32,  0,0);	//ヨコ：下部に表示
//		} else {
//			//miAdView.frame = CGRectMake(0, 480-50,  0,0);	//タテ：下部に表示
//			miAdView.frame = CGRectMake(0, self.window.frame.size.height-50,  0,0);	//タテ：下部に表示
//		}
//	/*.alpha=0 だけにし、隠さない
//		if (mAdCanVisible && miAdView.alpha==1) {	// 表示
//			if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
//				miAdView.frame = CGRectMake(0, 320-32,  0,0);	//ヨコ：下部に表示
//			} else {
//				miAdView.frame = CGRectMake(0, 480-50,  0,0);	//タテ：下部に表示
//			}
//		} else {
//			if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
//				miAdView.frame = CGRectMake(0, 320-32 + FREE_AD_OFFSET_Y,  0,0);		//ヨコ：下へ隠す
//			} else {
//				miAdView.frame = CGRectMake(0, 480-50 + FREE_AD_OFFSET_Y,  0,0);	//タテ：下へ隠す
//			}
//		}*/
//	}
//}

//- (void)adViewDidReceiveAd:(GADBannerView *)bannerView 
//{	// AdMob 広告あり
//	//NSLog(@"AdMob - adViewDidReceiveAd");
//	bannerView.tag = 1;	// 広告受信状況  (0)なし (1)あり
//	[self AdRefresh];
//}
//
//- (void)adView:(GADBannerView *)bannerView didFailToReceiveAdWithError:(GADRequestError *)error 
//{	// AdMob 広告なし
//	//NSLog(@"AdMob - adView:didFailToReceiveAdWithError:%@", [error localizedDescription]);
//	bannerView.tag = 0;	// 広告受信状況  (0)なし (1)あり
//	[self AdRefresh];
//}

//- (void)bannerViewDidLoadAd:(ADBannerView *)banner
//{	// iAd取得できたときに呼ばれる　⇒　表示する
//	//NSLog(@"iAd - bannerViewDidLoadAd ===");
//	banner.tag = 1;	// 広告受信状況  (0)なし (1)あり
//	[self AdRefresh];
//}

//- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
//{	// iAd取得できなかったときに呼ばれる　⇒　非表示にする
//	//NSLog(@"iAd - didFailToReceiveAdWithError");
//	banner.tag = 0;	// 広告受信状況  (0)なし (1)あり
//
//	// AdMob 破棄する ＜＜通信途絶してから復帰した場合、再生成するまで受信できないため。再生成する機会を増やす。
//	if (mAdMobView) {
//		// リクエスト
//		GADRequest *request = [GADRequest request];
//		[mAdMobView loadRequest:request];	
///*		//[1.1.0]ネット切断から復帰したとき、このように破棄⇒生成が必要。
//		RoAdMobView.alpha = 0; //これが無いと残骸が表示されたままになる。
//		RoAdMobView.delegate = nil;								//受信STOP  ＜＜これが無いと破棄後に呼び出されて落ちる
//		[RoAdMobView release], RoAdMobView = nil;	// 破棄
//		//[1.1.0]この後、AdRefresh:にて生成再開される。
// */
//	}
//	[self AdRefresh];
//}


@end

