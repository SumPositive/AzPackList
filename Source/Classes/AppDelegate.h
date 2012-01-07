//
//  AppDelegate.h
//  iPack
//
//  Created by 松山 和正 on 09/12/03.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "Elements.h"
#import "padRootVC.h"
#import <iAd/iAd.h>
#import "GADBannerView.h"

#import <StoreKit/StoreKit.h>
#define STORE_PRODUCTID_UNLOCK		@"com.azukid.AzPackList.Unlock"		// In-App Purchase ProductIdentifier

@interface AppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate
									,ADBannerViewDelegate	,GADBannerViewDelegate, SKPaymentTransactionObserver> 

@property (nonatomic, retain) UIWindow		*window;
@property (nonatomic, retain) UINavigationController		*mainNC;		//for iPhone
@property (nonatomic, retain) UISplitViewController		*mainSVC;	//for iPad
@property (nonatomic, retain) PadRootVC	*padRootVC;  //解放されないようにretain
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, retain) NSMutableArray *RaClipE3objects;  // 外部から参照されるため
@property (nonatomic, assign) BOOL	AppShouldAutorotate;
@property (nonatomic, assign) BOOL	AppUpdateSave;
//@property (nonatomic, assign) BOOL	AppEnabled_iCloud;
//@property (nonatomic, assign) BOOL	AppEnabled_Dropbox;
@property (nonatomic, retain) E1			*dropboxSaveE1selected;

// 
@property (nonatomic, assign) BOOL	app_is_iPad;				// YES=iPad対応
@property (nonatomic, assign) BOOL	app_is_sponsor;		// YES=購入済み（スポンサー）
@property (nonatomic, assign) BOOL	app_is_Ad;	// YES=広告表示する


- (void)alertProgressOff;
- (void)alertProgressOn:(NSString*)zTitle;

//- (NSURL *)applicationDocumentsDirectory;
- (NSString *)applicationDocumentsDirectory;

- (void)AdRefresh;
- (void)AdRefresh:(BOOL)bCanVisible;
- (void)AdViewWillRotate:(UIInterfaceOrientation)toInterfaceOrientation;

@end

