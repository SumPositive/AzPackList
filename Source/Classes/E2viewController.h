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

@property (nonatomic, retain) E1	*Re1selected;
@property (nonatomic, assign) BOOL	PbSharePlanList;

@property (nonatomic, assign) E3viewController*			delegateE3viewController;
- (void)setPopover:(UIPopoverController*)pc;
- (void)refreshE2view;

@end
