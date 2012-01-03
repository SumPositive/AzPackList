//
//  PadPopoverInNaviCon.h
//  AzPacking
//
//  Created by Sum Positive on 11/05/07.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

// UIPopoverController 内に UINavigationController を埋め込むタイプ
// UINavigationController内部から閉じられるように dismissPopoverAnimated を実装した

@interface PadNaviCon : UINavigationController
{
	UIPopoverController* Mpop;
}
@property (nonatomic, assign) UIPopoverController*	Mpop;
- (void)dismissPopoverCancel;
- (void)dismissPopoverSaved;
@end


@interface PadPopoverInNaviCon : UIPopoverController
{
}
@end
