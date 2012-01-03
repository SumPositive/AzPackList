//
//  E2viewController.h
//  iPack E2 Section
//
//  Created by 松山 和正 on 09/12/04.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

@class E1;
@class E2edit;
@class HTTPServer;
#ifdef AzPAD
@class E3viewController;
#endif

@interface E2viewController : UITableViewController 	<UIActionSheetDelegate, MFMailComposeViewControllerDelegate
#ifdef AzPAD
	, UIPopoverControllerDelegate
#endif
>
{
@private
	E1		*Re1selected;
	BOOL	PbSharePlanList;	// SharePlan プレビューモード
#ifdef AzPAD
	UIPopoverController*	menuPopover;  //[MENU]にて自身を包むPopover  閉じる為に必要
																	// setPopover:にてセットされる
#endif
	//----------------------------------------------viewDidLoadでnil, dealloc時にrelese
	//NSAutoreleasePool	*RautoPool;		// [0.6]autorelease独自解放のため
	NSMutableArray		*RaE2array;   // Rrは local alloc につき release 必須を示す
	HTTPServer			*RhttpServer;
	UIAlertView			*RalertHttpServer;
	NSDictionary		*MdicAddresses;
	//----------------------------------------------Owner移管につきdealloc時のrelese不要
	E2edit				*Me2editView;				// self.navigationControllerがOwnerになる
#ifdef AzPAD
	//UINavigationController*		MnaviRightE3;		// 右側(E3)
	E3viewController*				delegateE3viewController;
	UIPopoverController*			Mpopover;
	NSIndexPath*						MindexPathEdit;	//[1.1]ポインタ代入注意！copyするように改善した。
#endif
	//----------------------------------------------assign
	AppDelegate		*appDelegate;
	NSIndexPath	  *MindexPathActionDelete;	//[1.1]ポインタ代入注意！copyするように改善した。
	//BOOL MbOptShouldAutorotate;
	BOOL MbAzOptTotlWeightRound;
	BOOL MbAzOptShowTotalWeight;
	BOOL MbAzOptShowTotalWeightReq;
	NSInteger MiSection0Rows; // E2レコード数　＜高速化＞
	CGPoint		McontentOffsetDidSelect; // didSelect時のScrollView位置を記録
}

@property (nonatomic, retain) E1	*Re1selected;
@property (nonatomic, assign) BOOL	PbSharePlanList;

#ifdef AzPAD
@property (nonatomic, assign) E3viewController*			delegateE3viewController;
- (void)setPopover:(UIPopoverController*)pc;
- (void)refreshE2view;
#endif

@end
