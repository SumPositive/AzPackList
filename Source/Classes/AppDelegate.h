//
//  AppDelegate.h
//  iPack
//
//  Created by 松山 和正 on 09/12/03.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//
#import <iAd/iAd.h>
#import "GADBannerView.h"
#import "AZDropboxVC.h"		//<AZDropboxDelegate>

@class PadRootVC;
@class E1;


@interface AppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate
						,ADBannerViewDelegate ,GADBannerViewDelegate, AZDropboxDelegate> 
{
@private	// 自クラス内からだけ参照できる
	NSManagedObjectModel				*mCoreModel;
	NSPersistentStoreCoordinator		*mCorePsc;
	
	ADBannerView				*miAdView;
	GADBannerView				*mAdMobView;
	BOOL								mAdCanVisible;		//YES:表示可能な状況　 NO:表示してはいけない状況
	
	// Clip Borad
	//NSMutableArray				*clipE3objects; //(V0.4.4) [Cut][Copy]されたE3をPUSHスタックする。[Paste]でPOPする
	
	//UIAlertView						*mAlertProgress;
	//UIActivityIndicatorView	*mAlertIndicator;
}

@property (nonatomic, retain) UIWindow		*window;
@property (nonatomic, retain) UINavigationController		*mainNC;		//for iPhone
@property (nonatomic, retain) UISplitViewController		*mainSVC;	//for iPad
@property (nonatomic, retain) PadRootVC	*padRootVC;  //解放されないようにretain
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, retain) NSMutableArray	*clipE3objects;  // 外部から参照されるため
@property (nonatomic, retain) E1							*dropboxSaveE1selected;

@property (nonatomic, assign) BOOL	app_opt_Autorotate;
@property (nonatomic, assign) BOOL	app_opt_Ad;	// YES=広告表示する

@property (nonatomic, assign, readonly) BOOL	app_is_iPad;	// YES=iPad
@property (nonatomic, assign) BOOL	app_UpdateSave;			// YES=変更あり
@property (nonatomic, assign) BOOL	app_BagSwing;
@property (nonatomic, assign, readonly) BOOL	app_enable_iCloud;		// YES=iCloud同期中

// Product ID
@property (nonatomic, assign) BOOL	app_pid_SwitchAd;			// YES=購入済み（スポンサー）


//- (void)storeReset;

- (NSString *)applicationDocumentsDirectory;
//- (void) managedObjectContextReset;

- (void)AdRefresh;
- (void)AdRefresh:(BOOL)bCanVisible;
- (void)AdViewWillRotate:(UIInterfaceOrientation)toInterfaceOrientation;

@end

