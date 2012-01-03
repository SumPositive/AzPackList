//
//  AppDelegate.h
//  iPack
//
//  Created by 松山 和正 on 09/12/03.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "Elements.h"

#ifdef AzPAD
#import "padRootVC.h"
#endif

#ifdef FREE_AD
#import <iAd/iAd.h>
#import "GADBannerView.h"
#endif

@interface AppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate
#ifdef FREE_AD
	,ADBannerViewDelegate
	,GADBannerViewDelegate
#endif
> 
{
@public		// 外部公開 ＜＜使用禁止！@propertyで外部公開すること＞＞
@protected	// 自クラスおよびサブクラスから参照できる（無指定時のデフォルト）
@private	// 自クラス内からだけ参照できる
    //NSManagedObjectModel *managedObjectModel__;
    //NSManagedObjectContext *managedObjectContext__;	    
    //NSPersistentStoreCoordinator *persistentStoreCoordinator__;
	NSManagedObjectModel				*moModel_;
	NSPersistentStoreCoordinator		*persistentStoreCoordinator_;
	
    UIWindow *window;
	
#ifdef AzPAD
	//UISplitViewController	*mainVC;
	//PadRootVC					*padRootVC;
#else
    //UINavigationController *mainVC;
#endif
	
#ifdef FREE_AD	//PADも共通
	ADBannerView		*MbannerView;
	GADBannerView		*RoAdMobView;
	BOOL						MbAdCanVisible;		//YES:表示可能な状況　 NO:表示してはいけない状況
#endif
	
	/****************************[1.0.3]Comeback処理を完全廃止した。
	 NSMutableArray		*RaComebackIndex;	// an array of selections for each drill level
	 // i.e.
	 // [0, 1, 3] =	at level 1 drill/navigate through item 0,
	 //				at level 2 drill/navigation through item 1,
	 //				at level 3 drill/navigate through item 3
	 // i.e.
	 // [1, -1, -1] =	at level 1 drill/navigate through item 2,
	 //					no selection at level 2 (it's -1) so stay at level 2
	 */
	
	// Clip Borad
	NSMutableArray		*RaClipE3objects; //(V0.4.4) [Cut][Copy]されたE3をPUSHスタックする。[Paste]でPOPする
	
	//BOOL AppShouldAutorotate;		//[0.8.2]広域参照のため
	//BOOL AppUpdateSave;				//[1.1.0]広域参照のため
	//BOOL AppEnabled_iCloud;
	//BOOL AppEnabled_Dropbox;
}

//@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
//@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
//@property (nonatomic, retain) NSMetadataQuery *ubiquitousQuery;

@property (nonatomic, retain) UIWindow *window;
#ifdef AzPAD
@property (nonatomic, retain) UISplitViewController	*mainVC;
@property (nonatomic, retain) PadRootVC	*padRootVC;  //解放されないようにretain
#else
@property (nonatomic, retain) UINavigationController *mainVC;
//@property (nonatomic, retain) NSMutableArray *RaComebackIndex;  // 外部から参照されるため
#endif

@property (nonatomic, retain) NSMutableArray *RaClipE3objects;  // 外部から参照されるため
@property (nonatomic, assign) BOOL	AppShouldAutorotate;
@property (nonatomic, assign) BOOL	AppUpdateSave;
@property (nonatomic, assign) BOOL	AppEnabled_iCloud;
@property (nonatomic, assign) BOOL	AppEnabled_Dropbox;
@property (nonatomic, retain) E1			*dropboxSaveE1selected;

//- (NSURL *)applicationDocumentsDirectory;
- (NSString *)applicationDocumentsDirectory;

#ifdef FREE_AD
- (void)AdRefresh;
- (void)AdRefresh:(BOOL)bCanVisible;
- (void)AdViewWillRotate:(UIInterfaceOrientation)toInterfaceOrientation;
#endif

@end

