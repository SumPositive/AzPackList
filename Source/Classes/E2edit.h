//
//  E2edit.h
//  iPack
//
//  Created by 松山 和正 on 09/12/04.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
// InterfaceBuilderを使わずに作ったViewController

#import <UIKit/UIKit.h>

@interface E2edit : UIViewController  <UITextFieldDelegate, UITextViewDelegate> 

@property (nonatomic, retain) E1						*e1selected;
@property (nonatomic, retain) E2						*e2target;
@property (nonatomic, assign) NSInteger		addRow;
@property (nonatomic, assign) BOOL				sharePlanList;

@property (nonatomic, assign) id									delegate;
@property (nonatomic, retain) UIPopoverController*	selfPopover;

@end
