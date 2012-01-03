//
//  selectGroupTVC.h
//  AzPacking
//
//  Created by 松山 和正 on 10/02/02.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface selectGroupTVC : UITableViewController 
{
	
@private
	NSMutableArray	*RaE2array;	// E2(Group) List.
	UILabel			*RlbGroup;	// .tag に E2.row が入る。 選択時、.tag .text に書き込んで返す。

	//----------------------------------------------viewDidLoadでnil, dealloc時にrelese
	//----------------------------------------------Owner移管につきdealloc時のrelese不要
	//----------------------------------------------assign
	//BOOL MbOptShouldAutorotate;
}

@property (nonatomic, retain) NSMutableArray	*RaE2array;
@property (nonatomic, retain) UILabel			*RlbGroup;	

@end
