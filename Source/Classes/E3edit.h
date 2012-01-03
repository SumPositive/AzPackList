//
//  E3edit.h
//  iPack
//
//  Created by 松山 和正 on 09/12/06.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface E3edit : UIViewController <UITextFieldDelegate, UITextViewDelegate, UIPickerViewDelegate> {

	NSMutableArray *Pe2array;
	NSMutableArray *Pe3array;
	E1 *Pe1selected;
	E2 *Pe2selected;  // Edit時は IaE3target.parent と同値であるが、Add時にはこれを頼りにする必要がある。 
	E3 *Pe3target;
	BOOL PbAddObj;

@private
	UIPickerView *MpvGroup;
	UIButton	*MbuGroup;
	UITextField *MtfName;
	UITextField *MtfSpec;
	UITextField *MtfWeight;
	UITextField *MtfStock;
	UITextField *MtfRequired;
	UITextView	*MtvNote;
}

@property (nonatomic, retain) NSMutableArray *Pe2array;
@property (nonatomic, retain) NSMutableArray *Pe3array;
@property (nonatomic, retain) E1 *Pe1selected;
@property (nonatomic, retain) E2 *Pe2selected;
@property (nonatomic, retain) E3 *Pe3target;
@property BOOL PbAddObj;

@end
