//
//  E1edit.h
//  iPack
//
//  Created by 松山 和正 on 09/12/03.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
// InterfaceBuilderを使わずに作ったViewController

#import <UIKit/UIKit.h>

@interface E1edit : UIViewController  <UITextFieldDelegate, UITextViewDelegate>

@property (nonatomic, retain) E1 *Re1target;
@property NSInteger PiAddRow;

@property (nonatomic, assign) id									delegate;
@property (nonatomic, retain) UIPopoverController*	selfPopover;

@end

