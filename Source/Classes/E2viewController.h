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
@class E3viewController;

@interface E2viewController : UITableViewController 	<UIActionSheetDelegate, MFMailComposeViewControllerDelegate
	, UIPopoverControllerDelegate>
{
@private
	UIPopoverController*	menuPopover_;  //[MENU]にて自身を包むPopover  閉じる為に必要
	// setPopover:にてセットされる
	
	NSMutableArray		*e2array_;   // Rrは local alloc につき release 必須を示す
	HTTPServer			*httpServer_;
	UIAlertView			*alertHttpServer_;
	NSDictionary		*dicAddresses_;
	E2edit				*e2editView_;				// self.navigationControllerがOwnerになる
	
	UIPopoverController*			popOver_;
	NSIndexPath*						indexPathEdit_;	//[1.1]ポインタ代入注意！copyするように改善した。
	
	AppDelegate		*appDelegate_;
	NSIndexPath	  *indexPathActionDelete_;	//[1.1]ポインタ代入注意！copyするように改善した。
	
	BOOL optWeightRound_;
	BOOL optShowTotalWeight_;
	BOOL optShowTotalWeightReq_;
	NSInteger section0Rows_; // E2レコード数　＜高速化＞
	CGPoint		contentOffsetDidSelect_; // didSelect時のScrollView位置を記録
}

@property (nonatomic, retain) E1					*e1selected;
@property (nonatomic, assign) BOOL			sharePlanList;
@property (nonatomic, assign) E3viewController*			delegateE3viewController;

- (void)setPopover:(UIPopoverController*)pc;
- (void)refreshE2view;

@end
