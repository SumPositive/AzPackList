//
//  E1viewController.h
//  iPack E1 Title
//
//  Created by 松山 和正 on 09/12/03.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HTTPServer.h"
#import "AZAboutVC.h"
#import "AZStoreTVC.h"	//<AZStoreDelegate>

#import "Elements.h"
#import "EntityRelation.h"
#import "E1edit.h"


@interface E1viewController : UITableViewController 
	<NSFetchedResultsControllerDelegate, UIActionSheetDelegate	,UIPopoverControllerDelegate, AZStoreDelegate>
{
@public		// 外部公開 ＜＜使用禁止！@propertyで外部公開すること＞＞
@protected	// 自クラスおよびサブクラスから参照できる（無指定時のデフォルト）
@private	// 自クラス内からだけ参照できる
	NSManagedObjectContext		*moc_;
	NSFetchedResultsController	*fetchedE1_;
	HTTPServer								*httpServer_;
	UIAlertView								*alertHttpServer_;
	NSDictionary							*dicAddresses_;
	
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
	SKProduct			*productUnlock_;
}

//- (void)refreshE1view;

@end
