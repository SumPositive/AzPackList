//
//  SpAppendVC.h
//
//  Created by 松山 和正 on 10/01/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class E1;

@interface SpAppendVC : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource, 
											UITextFieldDelegate, UITextViewDelegate>
{
	
@private
	//--------------------------retain
	E1					*Re1selected;
	UIPopoverController*	selfPopover;  // 自身を包むPopover  閉じる為に必要
	//----------------------------------------------viewDidLoadでnil, dealloc時にrelese
	NSArray				*RaPickerSource;
	UIBarButtonItem		*RbarButtonItemDone;
	NSURLConnection		*RurlConnection;
	NSMutableData		*RdaResponse;
	//----------------------------------------------Owner移管につきdealloc時のrelese不要
	UIPickerView		*Mpicker;
	UITextField			*MtfName;
	UITextView			*MtvNote;
	UITextField			*MtfNickname;
	UILabel				*MlbNickname;
	UIButton			*MbuUpload;
	//----------------------------------------------assign
	AppDelegate		*appDelegate_;
	//BOOL				MbOptShouldAutorotate;
	NSInteger			MiConnectTag;	// (0)Non (1)Search (2)Append (3)Download (4)Delete
}

@property (nonatomic, retain) E1	*Re1selected;
@property (nonatomic, retain) UIPopoverController*	selfPopover;

@end
