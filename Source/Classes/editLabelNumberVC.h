//
//  editLabelNumberVC.h
//  AzPacking
//
//  Created by 松山 和正 on 10/01/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface editLabelNumberVC : UIViewController <UITextFieldDelegate>
{
	
@private
	UILabel		*RlbStock;
	UILabel		*RlbNeed;
	UILabel		*RlbWeight;
	NSInteger	PiFirstResponder; // 初期フォーカス位置 (0)Stock (1)Need (2)Weight
	
	//----------------------------------------------viewDidLoadでnil, dealloc時にrelese
	//----------------------------------------------Owner移管につきdealloc時のrelese不要
	UITextField	*MtfStock; // self.viewがOwner
	UITextField	*MtfNeed;
	UITextField	*MtfWeight;
	UILabel *MlabelStock;
	UILabel *MlabelNeed;
	UILabel *MlabelWeight;
	//----------------------------------------------assign
	//BOOL MbOptShouldAutorotate;
}

@property (nonatomic, retain) UILabel *RlbStock;
@property (nonatomic, retain) UILabel *RlbNeed;
@property (nonatomic, retain) UILabel *RlbWeight;
@property NSInteger	PiFirstResponder;
@end
