//
//  PadRootVC.h
//  AzPacking
//
//  Created by Sum Positive on 11/05/07.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


//右ペインに実装されるViewControllerが備えるべきメソッド　　＜＜即ちプロトコル＞＞
@protocol DetailViewController
- (void)showPopoverButtonItem:(UIBarButtonItem *)barButtonItem;
- (void)hidePopoverButtonItem:(UIBarButtonItem *)barButtonItem;
@end


@interface PadRootVC : UIViewController <UISplitViewControllerDelegate>

@property (nonatomic, retain) UIBarButtonItem			*popoverButtonItem;

@end
