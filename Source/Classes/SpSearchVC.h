//
//  SpSearchVC.h
//
//  Created by 松山 和正 on 10/01/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SpSearchVC : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource>
{
	
@private
	//----------------------------------------------viewDidLoadでnil, dealloc時にrelese
	//NSArray				*RaPickerSource;
	NSArray				*RaSegSortSource;
	//----------------------------------------------Owner移管につきdealloc時のrelese不要
	UIPickerView		*Mpicker;
	UISegmentedControl	*MsegSort;
	UIButton			*MbuSearch;
	//----------------------------------------------assign
	AppDelegate		*appDelegate_;
	//BOOL				MbOptShouldAutorotate;
}

@end
