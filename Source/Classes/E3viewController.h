//
//  E3viewController.h
//  iPack
//
//  Created by 松山 和正 on 09/12/06.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@class E1;
@class E2;
//@class E3edit;
//@class ItemTouchView;
//@class E2viewController;

@interface E3viewController : UITableViewController <UIActionSheetDelegate, UISearchBarDelegate
	,UIPopoverControllerDelegate>

@property (nonatomic, retain) E1					*e1selected;	//grandParent;
@property (nonatomic, assign) NSInteger	firstSection;
@property (nonatomic, assign) NSInteger	sortType;
@property (nonatomic, assign) BOOL			sharePlanList;

- (void)refreshE3view;

@end
