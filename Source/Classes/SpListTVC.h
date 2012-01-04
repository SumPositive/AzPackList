//
//  SpListTVC.h
//  AzPacking
//
//  Created by 松山 和正 on 10/01/27.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class E1;

@interface SpListTVC : UITableViewController //<UIActionSheetDelegate> 
{

@private
	NSMutableArray		*RaTags;
	NSString			*RzSort;
	//----------------------------------------------viewDidLoadでnil, dealloc時にrelese
	//NSAutoreleasePool	*RautoPool;		// [0.6]autorelease独自解放のため
	NSMutableArray		*RaSharePlans;
	NSURLConnection		*RurlConnection;
	NSMutableData		*RdaResponse;
	//----------------------------------------------Owner移管につきdealloc時のrelese不要
	//----------------------------------------------assign
	AppDelegate		*appDelegate_;
	//BOOL				MbOptShouldAutorotate;
	//NSString			*MzUserPass;
	BOOL				MbSearchOver;
	BOOL				MbSearching;
	NSInteger			MiConnectTag;	// (0)Non (1)Search (2)Append (3)Download (4)Delete
}

@property (nonatomic, retain) NSArray					*RaTags;
@property (nonatomic, retain) NSString					*RzSort;

@end
