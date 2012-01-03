//
//  ClipVieCon.h
//  AzPack
//
//  Created by 松山 和正 on 09/12/03.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
// InterfaceBuilderを使わずに作ったViewController

#import <UIKit/UIKit.h>

@interface ClipVieCon : UIViewController
{
	BOOL bnewObj;
	int newRow;

	UITextView *tvClip;
}

@property (nonatomic, retain) UITextView	*tvClip;

@end

