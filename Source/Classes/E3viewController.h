//
//  E3viewController.h
//  iPack
//
//  Created by 松山 和正 on 09/12/06.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PatternImageView.h"


@class E1;
@class E2;

@interface E3viewController : UITableViewController <UISearchBarDelegate>

@property (nonatomic, retain) E1					*e1selected;	//grandParent;
@property (nonatomic, assign) NSInteger	firstSection;
@property (nonatomic, assign) NSInteger	sortType;
@property (nonatomic, assign) BOOL			sharePlanList;

- (void)refreshE3view;

@end
