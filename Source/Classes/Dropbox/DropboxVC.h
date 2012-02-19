//
//  DropboxVC.h
//  AzPacking
//
//  Created by Sum Positive on 11/11/03.
//  Copyright (c) 2011 AzukiSoft. All rights reserved.
//
// "Security.framework" が必要
//
#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>
#import <DropboxSDK/JSON.h>
#import "Elements.h"
//#import "FileJson.h"

#define DBOX_APPKEY			@"jngoip8t4z187ot"	// PackList
#define DBOX_SECRET			@"l6rho4qt0jpiarq"
#define DBOX_EXTENSION		@"azp"

@interface DropboxVC : UIViewController <UITableViewDelegate, UITableViewDataSource, 
										UITextFieldDelegate, DBRestClientDelegate, UIActionSheetDelegate, UIAlertViewDelegate>
{
	IBOutlet UIButton		*ibBuClose;		//iPadで使用
	IBOutlet UIButton		*ibBuSave;
	IBOutlet UITextField	*ibTfName;
	IBOutlet UILabel			*ibLbEncrypt;
	IBOutlet UISwitch		*ibSwEncrypt;

	IBOutlet UISegmentedControl	*ibSegSort;
	IBOutlet UITableView	*ibTableView;

	DBRestClient					*restClient;
	NSMutableArray				*mMetadatas;
	UIActivityIndicatorView	*mActivityIndicator;
	UIAlertView						*mAlert;
	NSIndexPath					*mDidSelectRowAtIndexPath;

	E1									*e1upload_;
	NSString							*overWriteRev_;
	NSString							*deletePath_;
	
	//FileJson							*fileJson_;
	//NSMutableArray				*errorMsgs_;
}

//@property (nonatomic, assign) id				delegate;
//@property (nonatomic, retain) E1				*Re1selected;	//=nil:取込専用（保存関係を非表示にする）

- (IBAction)ibBuClose:(UIButton *)button;
- (IBAction)ibBuSave:(UIButton *)button;
- (IBAction)ibSwEncrypt:(UISwitch *)sender;
- (IBAction)ibSegSort:(UISegmentedControl *)segment;

- (id)initWithE1:(E1*)e1upload;

@end
