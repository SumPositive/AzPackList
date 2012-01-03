//
//  PadPopoverInNaviCon.m
//  AzPacking
//
//  Created by Sum Positive on 11/05/07.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Global.h"
#import "PadPopoverInNaviCon.h"


@implementation PadNaviCon
@synthesize Mpop;

- (id)initWithRootViewController:(UIViewController*)vc
{
    self = [super initWithRootViewController:vc];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)dismissPopoverCancel
{
	[self.Mpop  dismissPopoverAnimated:YES];
	// Popoverの外側をタッチして閉じたとき、popoverControllerDidDismissPopoverが呼び出される
	// そのときの引数には、nil が入っている = CANCEL
	[self	.Mpop.delegate popoverControllerDidDismissPopover:nil];	// CANCEL
}

- (void)dismissPopoverSaved
{
	[self.Mpop  dismissPopoverAnimated:YES];
	// dismissPopoverAnimatedにより閉じたときには、popoverControllerDidDismissPopoverは呼び出されない
	[self	.Mpop.delegate popoverControllerDidDismissPopover:self.Mpop];	// nil=SAVE
}
@end


@implementation PadPopoverInNaviCon

- (id)initWithContentViewController:(UIViewController*)vc
{
	PadNaviCon* nav = [[PadNaviCon alloc] initWithRootViewController:vc];
    self = [super initWithContentViewController:nav];
	nav.Mpop = self;
	[nav release];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

@end
