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


@interface AZStoreVC : UIViewController <UITableViewDelegate, UITableViewDataSource, 
																		UITextFieldDelegate, UIActionSheetDelegate,
																		SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (nonatomic, assign) id							delegate;
@property (nonatomic, retain, readonly) NSSet	*productIDs;

- (IBAction)ibBuClose:(UIButton *)button;

@end


@protocol AZStoreVCdelegate <NSObject>
#pragma mark - <AZStoreDelegate>
- (void)azStorePurchesed:(NSString*)productID;
@end

