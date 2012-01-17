//
//  SpAppendVC.h
//
//  Created by 松山 和正 on 10/01/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class E1;

@interface SpAppendVC : UIViewController <UITextFieldDelegate, UITextViewDelegate>

@property (nonatomic, retain) E1	*Re1selected;
@property (nonatomic, retain) UIPopoverController*	selfPopover;

@end
