//
//  E3viewFunction.h
//  iPack
//
//  Created by 松山 和正 on 09/12/20.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class E1;
@class E2;

@interface E3viewFunction : UITableViewController <UIActionSheetDelegate> {
	NSManagedObjectContext *managedObjectContext;
	NSFetchedResultsController *fetchedE1;
	NSMutableArray *e2list;
	NSMutableArray *e3list;
	E1 *e1selected;  //grandParent;
	NSInteger iFunction;
	BOOL AzOptDisclosureButtonToEditable;  // ディスクロージャボタンから編集可能にする
	UIBarButtonItem *buGrayHideShow;
	
	BOOL mbFirstView; // 最初にだけソートするために使用
	NSInteger miGrayTag;
}

@property (nonatomic,retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic,retain) NSFetchedResultsController *fetchedE1;
@property (nonatomic,retain) NSMutableArray *e2list;
@property (nonatomic,retain) NSMutableArray *e3list;
@property (nonatomic,retain) E1 *e1selected; //grandParent;
@property (nonatomic,retain) UIBarButtonItem *buGrayHideShow;

@property NSInteger iFunction;
@property BOOL AzOptDisclosureButtonToEditable;
@property BOOL mbFirstView;
@property NSInteger miGrayTag;

- (void)viewComeback:(NSArray *)selectionArray;  // 再現復帰処理用
- (void)e3editView:(NSIndexPath *)indexPath;

@end
