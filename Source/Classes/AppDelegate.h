//
//  AppDelegate.h
//  iPack
//
//  Created by 松山 和正 on 09/12/03.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//
//#import <iAd/iAd.h>
//#import "GADBannerView.h"
//#import <GoogleMobileAds/GoogleMobileAds.h>
//#import "AZDropboxVC.h"		//<AZDropboxDelegate>


//iOS6以降、回転対応のためサブクラス化が必要になった。
@interface AzNavigationController : UINavigationController
@end


@class PadRootVC;
@class E1;
@interface AppDelegate : NSObject
					<UIApplicationDelegate, UITabBarControllerDelegate, UISplitViewControllerDelegate>
{
@private	// 自クラス内からだけ参照できる
	//ADBannerView				*miAdView;
//	GADBannerView				*mAdMobView;
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
//@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, retain) NSMutableArray	*clipE3objects;  // 外部から参照されるため
@property (nonatomic, retain) E1							*dropboxSaveE1selected;

@property (nonatomic, assign) BOOL	ppOptAutorotate;
@property (nonatomic, assign) BOOL	ppOptShowAd;	// YES=広告表示する

@property (nonatomic, assign, readonly) BOOL	ppIsPad;	// YES=iPad
@property (nonatomic, assign) BOOL	ppChanged;			// YES=変更あり
@property (nonatomic, assign) BOOL	ppBagSwing;
@property (nonatomic, assign, readonly) BOOL	ppEnabled_iCloud;		// YES=iCloud同期中

// Product ID
@property (nonatomic, assign) BOOL	ppPaid_SwitchAd;			// YES=購入済み（スポンサー）

// Methods
- (void)AdRefresh;
- (void)AdRefresh:(BOOL)bCanVisible;
- (void)AdViewWillRotate:(UIInterfaceOrientation)toInterfaceOrientation;


@property (nonatomic, retain) UIBarButtonItem			*popoverButtonItem;

@end


//右ペインに実装されるViewControllerが備えるべきメソッド　　＜＜即ちプロトコル＞＞
@protocol DetailViewController
- (void)showPopoverButtonItem:(UIBarButtonItem *)barButtonItem;
- (void)hidePopoverButtonItem:(UIBarButtonItem *)barButtonItem;
@end


