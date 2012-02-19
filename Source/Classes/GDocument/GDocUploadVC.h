//
//  GDocUploadVC.h
//  AzPackList5
//
//  Created by Sum Positive on 12/02/18.
//  Copyright (c) 2012 Azukid. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Elements.h"
#import "GData.h"
#import "GDataDocs.h"

@interface GDocUploadVC : UIViewController <UIActionSheetDelegate>
{	// @Public
	//	IBOutlet UIButton		*ibBuUpload;
	IBOutlet UITextField	*ibTfName;
	IBOutlet UILabel			*ibLbEncrypt;
	IBOutlet UISwitch		*ibSwEncrypt;
}

@property (nonatomic, retain) E1 *Re1selected;

- (IBAction)ibBuUpload:(UIButton *)button;
- (IBAction)ibSwEncrypt:(UISwitch *)sender;

@end
