//
//  AZStoreVC.h
//
//  Created by Sum Positive on 11/10/06.
//  Copyright (c) 2011 Azukid. All rights reserved.
//
// 旧バージョンの購入済みユーザは、「招待パス」により新バージョン購入済みにする
// 「招待パス」は、UDIDと @"AzPackingOld" のmd5ハッシュの先頭8文字とする
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

// ProductID
#define SK_PID_UNLOCK		@"com.azukid.AzPackList.Unlock"		// In-App Purchase ProductIdentifier


@interface AZStoreVC : UIViewController <UITableViewDelegate, UITableViewDataSource, 
																		UITextFieldDelegate, UIActionSheetDelegate,
																		SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
	//IBOutlet UILabel			*ibLbInviteTitle;
	//IBOutlet UILabel			*ibLbInviteMsg;
	IBOutlet UITextField	*ibTfInvitePass;
	//IBOutlet UIButton		*ibBuClose;
	IBOutlet UITableView	*ibTableView;
}

@property (nonatomic, assign) id			delegate;
@property (nonatomic, retain) NSSet	*productIDs;

//- (IBAction)ibBuClose:(UIButton *)button;

- (id)initWithUnLock:(BOOL)unlock;

@end


@protocol AZStoreVCdelegate <NSObject>
#pragma mark - <AZStoreDelegate>
- (void)azStorePurchesed:(NSString*)productID;
@end

