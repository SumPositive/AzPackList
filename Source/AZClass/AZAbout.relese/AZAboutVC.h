//
//  AZAboutVC.h
//
//  Created by Sum Positive on 11/10/06.
//  Copyright (c) 2009 Azukid. All rights reserved.
//
// 旧バージョンの購入済みユーザは、「招待パス」により新バージョン購入済みにする
// 「招待パス」は、UDIDと @"AzPackingOld" のmd5ハッシュの先頭8文字とする
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "UIDevice-Hardware.h"

#import "AZClass.h"
#import "AZWebView.h"


@interface AZAboutVC : UIViewController   <MFMailComposeViewControllerDelegate, UIAlertViewDelegate>
{
	IBOutlet UIImageView		*ibIvIcon;
	IBOutlet UILabel				*ibLbTitle;
	IBOutlet UILabel				*ibLbSubtitle;
	IBOutlet UILabel				*ibLbVersion;
	IBOutlet UILabel				*ibLbCopyright;
	IBOutlet UIButton			*ibBuGoSupport;
	IBOutlet UIButton			*ibBuPostTo;
	IBOutlet UITextView		*ibTvAgree;
	
@private
	BOOL						mIsPad;
	
}

@property (nonatomic, retain) UIImage			*ppImgIcon;
@property (nonatomic, retain) NSString			*ppProductTitle;
@property (nonatomic, retain) NSString			*ppProductSubtitle;  //ローカル名
//@property (nonatomic, retain) NSString			*ppProductYear;
@property (nonatomic, retain) NSString			*ppCopyright;
@property (nonatomic, retain) NSString			*ppAuthor;
@property (nonatomic, retain) NSString			*ppSupportSite;

- (IBAction)ibBuGoSupportBlog:(UIButton *)button;	
- (IBAction)ibBuPostToAuthor:(UIButton *)button;	
//- (IBAction)ibBuClose:(UIButton *)button;	//iPadのみ

@end


