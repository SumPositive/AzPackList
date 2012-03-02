//
//  Elements.m
//  iPack
//
//  Created by 松山 和正 on 09/12/03.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Elements.h"

//---------------------------------------------------------------------------------------E4photo		//5//
@implementation E4photo
	@dynamic photoData;		//5//
@end

//---------------------------------------------------------------------------------------E1 Title
@implementation E1
	@dynamic row;
	@dynamic name;
	@dynamic note;
	@dynamic sumNoGray;		// Data Model Version.3
	@dynamic sumNoCheck;	// Data Model Version.2
	@dynamic sumWeightStk;
	@dynamic sumWeightNed;
	@dynamic childs;
@end

//---------------------------------------------------------------------------------------E2 Section
@implementation E2
	@dynamic row;
	@dynamic name;
	@dynamic note;
	@dynamic sumNoGray;		// Data Model Version.3
	@dynamic sumNoCheck;	// Data Model Version.2
	@dynamic sumWeightStk;
	@dynamic sumWeightNed;
	@dynamic parent;
	@dynamic childs;
@end

//---------------------------------------------------------------------------------------E3 Item
@implementation E3
	@dynamic row;
	@dynamic name;
	@dynamic note;
	@dynamic stock;
	@dynamic need;		//(V0.4) (-1)Add専用行  (0)Gray  (1〜9999)Items
	@dynamic lack;
	@dynamic noGray;		// Data Model Version.3
	@dynamic noCheck;	// Data Model Version.2
	@dynamic weight;
	@dynamic weightStk;
	@dynamic weightNed;
	@dynamic weightLack;
	@dynamic shopKeyword;	// Data Model Version.4
	@dynamic shopNote;			// Data Model Version.4
	@dynamic photoUrl;			//5//
	@dynamic parent;
	@dynamic e4photo;			//5//
@end

// END