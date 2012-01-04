//
//  InformationView.h
//  iPack
//
//  Created by 松山 和正 on 10/01/04.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface InformationView : UIViewController  <MFMailComposeViewControllerDelegate, UIAlertViewDelegate>

// 公開メソッド
//- (id)initWithFrame:(CGRect)rect;
//- (void)show;
- (id)init;
- (void)hide;

@end
