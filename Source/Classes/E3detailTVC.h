//
//  E3detailTVC.h
//  AzPacking
//
//  Created by 松山 和正 on 10/01/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AZDial.h"

#define WEIGHT_DIAL	1

@class E3;
@class CalcView;

@interface E3detailTVC : UITableViewController <UITextFieldDelegate, UITextViewDelegate, UIPopoverControllerDelegate, 
										UIScrollViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, retain) NSMutableArray		*e2array;
@property (nonatomic, retain) NSMutableArray		*e3array;
@property (nonatomic, retain) E3								*e3target;
@property (nonatomic, assign) NSInteger				addE2section;
@property (nonatomic, assign) NSInteger				addE3row;
@property (nonatomic, assign) BOOL						sharePlanList;
@property (nonatomic, assign) id									delegate;
@property (nonatomic, retain) UIPopoverController*	selfPopover;

// 公開メソッド
- (void)cancelClose:(id)sender ;

@end
