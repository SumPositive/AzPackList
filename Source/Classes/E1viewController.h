//
//  E1viewController.h
//  iPack E1 Title
//
//  Created by 松山 和正 on 09/12/03.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@class E1edit;
@class InformationView;
@class HTTPServer;

@interface E1viewController : UITableViewController 
	<NSFetchedResultsControllerDelegate, UIActionSheetDelegate
#ifdef AzPAD
	,UIPopoverControllerDelegate
#endif
>
{
@public		// 外部公開 ＜＜使用禁止！@propertyで外部公開すること＞＞
@protected	// 自クラスおよびサブクラスから参照できる（無指定時のデフォルト）
@private	// 自クラス内からだけ参照できる
	NSManagedObjectContext		*Rmoc;
	//----------------------------------------------------------------viewDidLoadでnil, dealloc時にrelese
	NSFetchedResultsController	*RfetchedE1;
	HTTPServer					*RhttpServer;
	UIAlertView					*RalertHttpServer;
	NSDictionary				*MdicAddresses;
	//UIActivityIndicatorView *activityIndicator_;
	//----------------------------------------------------------------Owner移管につきdealloc時のrelese不要
	E1edit						*Me1editView;		// self.navigationControllerがOwnerになる
	UIBarButtonItem		*MbuInfo;
	InformationView		*MinformationView;  // self.view.windowがOwnerになる
#ifdef AzPAD
	UIPopoverController*	Mpopover;
	NSIndexPath*				MindexPathEdit;	//[1.1]ポインタ代入注意！copyするように改善した。
#endif
	
	//----------------------------------------------------------------assign
	AppDelegate		*appDelegate;
	BOOL			MbInformationOpen;	//[1.0.2]InformationViewを初回自動表示するため
	//NSIndexPath	  *MindexPathActionDelete; //NG//ポインタ危険
	NSUInteger		MactionDeleteRow;		//[1.1]削除するRow
	BOOL MbAzOptTotlWeightRound;
	BOOL MbAzOptShowTotalWeight;
	BOOL MbAzOptShowTotalWeightReq;
	NSInteger MiSection0Rows; // E1レコード数　＜高速化＞
	CGPoint		McontentOffsetDidSelect; // didSelect時のScrollView位置を記録
}

//@property (nonatomic, retain) NSManagedObjectContext *Rmoc;

#ifdef AzPAD
//- (void)setPopover:(UIPopoverController*)pc;
- (void)refreshE1view;
#endif

@end
