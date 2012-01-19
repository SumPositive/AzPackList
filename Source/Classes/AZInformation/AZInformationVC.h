//
//  AZInformationVC.h
//
//  Created by Sum Positive on 11/10/06.
//  Copyright (c) 2011 Azukid. All rights reserved.
//
// 旧バージョンの購入済みユーザは、「招待パス」により新バージョン購入済みにする
// 「招待パス」は、UDIDと @"AzPackingOld" のmd5ハッシュの先頭8文字とする
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>


@interface AZInformationVC : UIViewController   <MFMailComposeViewControllerDelegate, UIAlertViewDelegate>
{
	IBOutlet UILabel		*ibLbVersion;
	IBOutlet UILabel		*ibLbCopyright;
}

- (IBAction)ibBuGoSupportBlog:(UIButton *)button;	
- (IBAction)ibBuPostToAuthor:(UIButton *)button;	
- (IBAction)ibBuClose:(UIButton *)button;	//iPadのみ

- (id)init;

@end


