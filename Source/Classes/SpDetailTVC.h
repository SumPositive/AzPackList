//
//  SpDetailTVC.h
//  AzPacking
//
//  Created by 松山 和正 on 10/01/27.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class E1;

@interface SpDetailTVC : UITableViewController //<UIActionSheetDelegate> 
{
	
@private
	NSString			*RzSharePlanKey;
	BOOL				PbOwner;
	//----------------------------------------------viewDidLoadでnil, dealloc時にrelese
	//NSAutoreleasePool	*RautoPool;		// [0.6]autorelease独自解放のため
	NSURLConnection	*RurlConnection;
	NSMutableData		*RdaResponse;
	E1							*Re1add;

	//----------------------------------------------Owner移管につきdealloc時のrelese不要
	//----------------------------------------------assign
	AppDelegate		*appDelegate_;
	BOOL				MbOptTotlWeightRound;
	BOOL				MbOptShowTotalWeight;
	BOOL				MbOptShowTotalWeightReq;
	NSInteger		MiConnectTag;	// (0)Non (1)Search (2)Append (3)Download (4)Delete
}

@property (nonatomic, retain) NSString					*RzSharePlanKey;
@property (nonatomic, assign) BOOL						PbOwner;

@end
