//
//  SpPOST.h
//  AzPacking
//
//  Created by 松山 和正 on 10/03/01.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>

#define GAE_Name		@"azpackplan"
#ifdef DEBUG
#define GAE_Version		@"2"
#else
#define GAE_Version		@"2"	//[2.0]
#endif

#define DEBUG_userPass  @"DebugXX3486181m"

void alertMsgBox( NSString *title, NSString *msg, NSString *buttonTitle );
NSMutableURLRequest *requestSpPOST( NSString *PzBody );
NSString *postCmdAddUserPass( NSString *PzPostCmd );
//NSString *postCmdAddLanguage( NSString *PzPostCmd );

