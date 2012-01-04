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
	<NSFetchedResultsControllerDelegate, UIActionSheetDelegate	,UIPopoverControllerDelegate>

//@property (nonatomic, retain) NSManagedObjectContext *Rmoc;

//- (void)setPopover:(UIPopoverController*)pc;
- (void)refreshE1view;

@end
