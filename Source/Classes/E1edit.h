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
{
	
@private
	E1			*Re1target;  // IはInstance、aはassign を示す
	NSInteger	PiAddRow;    // (>=0)Add  (-1)Edit
#ifdef AzPAD
	id									delegate;
	UIPopoverController*	selfPopover;  // 自身を包むPopover  閉じる為に必要
#endif
	//----------------------------------------------------------------viewDidLoadでnil, dealloc時にrelese
	//----------------------------------------------------------------Owner移管につきdealloc時のrelese不要
	UITextField		*MtfName;  // self.viewがOwner
	UITextView		*MtvNote;  // self.viewがOwner
	//----------------------------------------------------------------assign
	AppDelegate		*appDelegate;
}

@property (nonatomic, retain) E1 *Re1target;
@property NSInteger PiAddRow;
#ifdef AzPAD
@property (nonatomic, assign) id									delegate;
@property (nonatomic, retain) UIPopoverController*	selfPopover;
#endif

@end

