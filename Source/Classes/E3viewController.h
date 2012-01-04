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
@class E3edit;
@class ItemTouchView;
@class E2viewController;

@interface E3viewController : UITableViewController <UIActionSheetDelegate, UISearchBarDelegate
	,UIPopoverControllerDelegate>

//@property (nonatomic, retain) NSMutableArray *RaE2array; // assignにするとスクーロール中に「戻る」とフリーズする。
														// assignだとE3側の処理が完了する前に解放されてしまうようだ。
@property (nonatomic, retain) E1		*Re1selected;	//grandParent;
//@property (nonatomic, retain) E2		*Re2selected;	//parent;
@property (nonatomic, assign) NSInteger	PiFirstSection;
@property (nonatomic, assign) NSInteger	PiSortType;
@property (nonatomic, assign) BOOL		PbSharePlanList;

//- (void)viewComeback:(NSArray *)selectionArray;  // Comeback 再現復帰処理用
- (void)refreshE3view;

@end
