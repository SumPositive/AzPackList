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


@interface AppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate
									,ADBannerViewDelegate	,GADBannerViewDelegate> 

@property (nonatomic, retain) UIWindow		*window;
@property (nonatomic, retain) UINavigationController		*mainNC;		//for iPhone
@property (nonatomic, retain) UISplitViewController		*mainSVC;	//for iPad
@property (nonatomic, retain) PadRootVC	*padRootVC;  //解放されないようにretain
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, retain) NSMutableArray *clipE3objects_;  // 外部から参照されるため
@property (nonatomic, retain) E1			*dropboxSaveE1selected;

@property (nonatomic, assign) BOOL	app_opt_Autorotate;
@property (nonatomic, assign) BOOL	app_opt_Ad;	// YES=広告表示する

@property (nonatomic, assign, readonly) BOOL	app_is_iPad;	// YES=iPad
@property (nonatomic, assign) BOOL	app_UpdateSave;			// YES=変更あり
@property (nonatomic, assign) BOOL	app_pid_UnLock;			// YES=購入済み（スポンサー）


- (NSString *)applicationDocumentsDirectory;
- (void) managedObjectContextReset;

- (void)AdRefresh;
- (void)AdRefresh:(BOOL)bCanVisible;
- (void)AdViewWillRotate:(UIInterfaceOrientation)toInterfaceOrientation;

@end

