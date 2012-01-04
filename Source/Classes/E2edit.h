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
{
	
@private
	E1 *Re1selected;  // Edit時は IaE2target.parent と同値であるが、Add時にはこれを頼りにする必要がある。 
	E2 *Re2target;
	NSInteger PiAddRow;  // (>=0)Add  (-1)Edit
	BOOL	PbSharePlanList;	// SharePlan プレビューモード

	// E2viewが左ペインにあるとき、E2editをPopover内包するために使う。
	id									delegate;
	UIPopoverController*	selfPopover;  // 自身を包むPopover  閉じる為に必要
	
	//----------------------------------------------viewDidLoadでnil, dealloc時にrelese
	//----------------------------------------------Owner移管につきdealloc時のrelese不要
	UITextField *MtfName;
	UITextView	*MtvNote;
	//----------------------------------------------assign
	AppDelegate		*appDelegate_;
}

@property (nonatomic, retain) E1 *Re1selected;
@property (nonatomic, retain) E2 *Re2target;
@property (nonatomic, assign) NSInteger PiAddRow;
@property (nonatomic, assign) BOOL	PbSharePlanList;

@property (nonatomic, assign) id									delegate;
@property (nonatomic, retain) UIPopoverController*	selfPopover;

@end
