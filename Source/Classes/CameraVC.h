//
//  CameraVC.h
//  AzPackList5
//
//  Created by Sum Positive on 12/02/09.
//  Copyright (c) 2012 Azukid. All rights reserved.
//

#import <UIKit/UIKit.h>


@class E3;
@interface CameraVC : UIViewController
{
/*
	IBOutlet UIButton			*ibBuTake;
	IBOutlet UIButton			*ibBuRetry;
	IBOutlet UILabel				*ibLbTorch;
	IBOutlet UISwitch			*ibSwTorch;*/

	IBOutlet UIImageView		*ibImageView;
	IBOutlet UILabel				*ibLbCamera;
}

@property (nonatomic, retain) UIImageView	*imageView;
@property (nonatomic, retain) E3						*e3target;

/*
- (IBAction)ibBuTakeTouch:(UIButton *)button;
- (IBAction)ibBuRetryTouch:(UIButton *)button;
- (IBAction)ibSwTorch:(UISwitch *)sender;
*/

@end
