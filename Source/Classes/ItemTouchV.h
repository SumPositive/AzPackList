//
//  ItemTouchView.h
//  AzPacking
//
//  Created by 松山 和正 on 10/01/13.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ItemTouchView : UIView 
{
	UITableView *Pe3view;
	NSIndexPath *Pe3path;
	E3 *Pe3obj;
}

@property (nonatomic, retain) UITableView *Pe3view;
@property (nonatomic, retain) NSIndexPath *Pe3path;
@property (nonatomic, retain) E3 *Pe3obj;

// 公開メソッド
- (id)initWithFrame:(CGRect)rect;
- (void)show;
- (void)hide;

@end
