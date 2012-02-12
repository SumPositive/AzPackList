//
//  GooDocsView.h
//  iPack
//
//  Created by 松山 和正 on 09/12/25.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
/* -----------------------------------------------------------------------------------------------
 * GData API ライブラリの組み込み手順 参照URL:
 * http://hoishing.wordpress.com/2011/08/23/gdata-objective-c-client-setup-in-xcode-4/
 * -----------------------------------------------------------------------------------------------
 */


#import <UIKit/UIKit.h>


@interface GooDocsView : UITableViewController <UITextFieldDelegate, UIActionSheetDelegate> 

@property (nonatomic, retain) NSManagedObjectContext *Rmoc;
@property (nonatomic, retain) E1 *Re1selected;
@property NSInteger PiSelectedRow;
@property BOOL	 PbUpload; 
@property (nonatomic, assign) id									delegate;
@property (nonatomic, retain) UIPopoverController*	selfPopover;

@end

