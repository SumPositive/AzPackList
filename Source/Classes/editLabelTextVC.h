//
//  editLabelTextVC.h
//  AzPacking
//
//  Created by 松山 和正 on 10/01/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface editLabelTextVC : UIViewController <UITextViewDelegate>

@property (nonatomic, retain) UILabel *Rlabel;
@property NSInteger	PiMaxLength;
@property NSInteger	PiSuffixLength;
@end
