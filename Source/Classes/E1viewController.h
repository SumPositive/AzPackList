//
//  E1viewController.h
//  iPack E1 Title
//
//  Created by 松山 和正 on 09/12/03.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AZStoreTVC.h"	//<AZStoreDelegate>
#import "AZAboutVC.h"
#import "AZDropboxVC.h"
#import "Global.h"
#import "AppDelegate.h"

#import "Elements.h"
#import "MocFunctions.h"
#import "E1edit.h"
#import "E2viewController.h"
#import "E3viewController.h"
#import "SettingTVC.h"
#import "FileCsv.h"
#import "SpSearchVC.h"
#import "PatternImageView.h"
//#import "GDocDownloadTVC.h"

@class E1edit;
@class AppDelegate;
@class SKProduct;
@class HTTPServer;


@interface E1viewController : UITableViewController 
	<NSFetchedResultsControllerDelegate, UIActionSheetDelegate	,UIPopoverControllerDelegate, AZStoreDelegate>
{
@private
	NSManagedObjectContext		*mMoc;
	NSFetchedResultsController	*mFetchedE1;
	HTTPServer								*mHttpServer;
	UIAlertView								*mHttpServerAlert;
	NSDictionary							*mAddressDic;
	
	E1edit							*e1editView_;	
	//InformationView			*informationView_;
	
	UIPopoverController	*popOver_;
	NSIndexPath*				indexPathEdit_;	//[1.1]ポインタ代入注意！copyするように改善した。
	
	AppDelegate		*appDelegate_;

	BOOL					bInformationOpen_;	//[1.0.2]InformationViewを初回自動表示するため
	NSUInteger			actionDeleteRow_;		//[1.1]削除するRow
	BOOL					bOptWeightRound_;
	BOOL					bOptShowTotalWeight_;
	BOOL					bOptShowTotalWeightReq_;
	NSInteger			section0Rows_; // E1レコード数　＜高速化＞
	CGPoint				contentOffsetDidSelect_; // didSelect時のScrollView位置を記録
	//SKProduct			*productUnlock_;
}

//- (void)refreshE1view;

@end
