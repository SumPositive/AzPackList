//
//  AZStore.m
//
//  Created by Sum Positive on 11/10/06.
//  Copyright (c) 2011 Azukid. All rights reserved.
//

#import "Global.h"
#import "AZStoreVC.h"


@interface AZStoreVC (PrivateMethods)
@end

@implementation AZStoreVC
{
	UIAlertView						*alertActivity_;
	UIActivityIndicatorView	*alertActivityIndicator_;
	
	BOOL							unLock_;
	NSMutableArray			*products_;
}
@synthesize delegate = delegate_;
@synthesize productIDs = productIDs_;

#define SK_INIT				@"Init"
#define SK_NoSALE		@"NoSale"
#define SK_CLOSED		@"Closed"


#pragma mark - Alert

- (void)alertActivityOn:(NSString*)zTitle
{
	[alertActivity_ setTitle:zTitle];
	[alertActivity_ show];
	[alertActivityIndicator_ setFrame:CGRectMake((alertActivity_.bounds.size.width-50)/2, alertActivity_.frame.size.height-75, 50, 50)];
	[alertActivityIndicator_ startAnimating];
}

- (void)alertActivityOff
{
	[alertActivityIndicator_ stopAnimating];
	[alertActivity_ dismissWithClickedButtonIndex:alertActivity_.cancelButtonIndex animated:YES];
}

- (void)alertCommError
{
	alertBox(NSLocalizedString(@"SK CommError", nil), NSLocalizedString(@"SK CommError msg", nil), @"OK");
}


#pragma mark - IBAction

- (IBAction)ibBuClose:(UIButton *)button
{
	[self dismissModalViewControllerAnimated:YES];
}


#pragma mark - View lifecycle
/*
- (id)initWithUnLock:(BOOL)unlock
{
	if ([[[UIDevice currentDevice] model] hasPrefix:@"iPad"]) {	// iPad
		self = [super initWithNibName:@"AZStoreVC-iPad" bundle:nil];
	} else {
		self = [super initWithNibName:@"AZStoreVC" bundle:nil];
	}
    if (self) {
        // Custom initialization
		
		unLock_ = unlock;
    }
    return self;
}
*/
- (void)viewDidLoad
{
    [super viewDidLoad];
	
	if (unLock_) 
	{	// Version 1.2 購入済み
		//ibLbInviteTitle.hidden = YES;
		//ibLbInviteMsg.hidden = YES;
		ibTfInvitePass.enabled = NO;
		ibTfInvitePass.placeholder = NSLocalizedString(@"SK Sponsor", nil); // Version 1.2 購入済み
	} else {
		ibTfInvitePass.keyboardType = UIKeyboardTypeASCIICapable;
		ibTfInvitePass.returnKeyType = UIReturnKeyDone;
	}
	
	// alertActivityOn/Off のための準備
	alertActivity_ = [[UIAlertView alloc] initWithTitle:@"" message:@"" delegate:self cancelButtonTitle:nil otherButtonTitles:nil]; // deallocにて解放
	alertActivityIndicator_ = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	alertActivityIndicator_.frame = CGRectMake(0, 0, 50, 50);
	[alertActivity_ addSubview:alertActivityIndicator_];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	
	products_ = [[NSMutableArray alloc] initWithObjects:SK_INIT, nil];
	//[ibTableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	assert(0<[productIDs_ count]);
	
	// Products 一覧表示
	if ([SKPaymentQueue canMakePayments]) { // 課金可能であるか確認する
		// 課金可能
		// 商品情報リクエスト 
		SKProductsRequest *req = [[SKProductsRequest alloc] initWithProductIdentifiers: productIDs_];
		req.delegate = self;
		[req start];  //---> productsRequest:didReceiveResponse:が呼び出される
	} else {
		// 購入が禁止されています。
		[products_ replaceObjectAtIndex:0 withObject:@"Non"];
		[ibTableView reloadData];
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
	return YES;
}

#pragma mark unload

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc 
{

}


#pragma mark - <UITextFieldDelegate>

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	assert(textField==ibTfInvitePass);

	[self alertActivityOn:NSLocalizedString(@"SK InvitePass", nil)];
	[textField resignFirstResponder]; // キーボードを隠す

	@try {
		// 招待パス処理
		if ([ibTfInvitePass.text length]==7) 
		{
			
			
			// OK
			alertBox(NSLocalizedString(@"SK InvitePass OK", nil), NSLocalizedString(@"SK InvitePass", nil), @"OK");
		}
	}
	@catch (NSException *exception) {
		// NG 招待パスが違う
		alertBox(NSLocalizedString(@"SK InvitePass NG", nil), NSLocalizedString(@"SK InvitePass", nil), @"OK");
	}
	@finally {
		[self alertActivityOff];
	}
	return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range 
replacementString:(NSString *)string 
{
	// senderは、MtfName だけ
    NSMutableString *text = [textField.text mutableCopy];
    [text replaceCharactersInRange:range withString:string];
	// 置き換えた後の長さをチェックする
	if ([text length] <= 16) {
		return YES;
	} else {
		return NO;
	}
}


#pragma mark - <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section==0) {
		return [products_ count];
	} else {
		return 3; // アプリ宣伝
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
	if (section==0) {
		return NSLocalizedString(@"SK Product", nil);
	} else {
		return NSLocalizedString(@"SK AzukiSoft", nil);
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
									  reuseIdentifier:CellIdentifier];
    }
	
	if (indexPath.section==0) {
		if (0<=indexPath.row && indexPath.row<[products_ count]) 
		{
			if ([[products_ objectAtIndex: indexPath.row] isKindOfClass:[SKProduct class]]) 
			{
				cell.imageView.image = [UIImage imageNamed:@"Icon32-ExtParts"];
				SKProduct *prod = [products_ objectAtIndex: indexPath.row];
				if (prod) {
					cell.textLabel.text = prod.localizedTitle;
					cell.detailTextLabel.text = [NSString stringWithFormat:@"%@  %@", 
												 [prod.price descriptionWithLocale: [NSLocale currentLocale]] ,
												 prod.localizedDescription];
					
					if ([prod.productIdentifier isEqualToString: SK_PID_UNLOCK]) {
						
					}
				}
				else {
					// 販売停止中
					cell.textLabel.text = [cell.textLabel.text stringByAppendingString:NSLocalizedString(@"SK No Sale", nil)];
				}
			}
			else if ([[products_ objectAtIndex: indexPath.row] isEqualToString:SK_INIT])
			{
				cell.imageView.image = nil;
				UIActivityIndicatorView *ai = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
				ai.frame = cell.imageView.frame;
				[cell.contentView addSubview:ai];
				cell.textLabel.text = NSLocalizedString(@"SK Progress", nil);
			}
			else if ([[products_ objectAtIndex: indexPath.row] isEqualToString:SK_NoSALE])
			{
				cell.imageView.image = [UIImage imageNamed:@"Icon32-ExtParts"];
				cell.textLabel.text = NSLocalizedString(@"SK No Sale", nil);
			}
			else if ([[products_ objectAtIndex: indexPath.row] isEqualToString:SK_CLOSED])
			{
				cell.imageView.image = [UIImage imageNamed:@"Icon32-ExtParts"];
				cell.textLabel.text = NSLocalizedString(@"SK Closed", nil);
			}
		}
	} 
	else {
		switch (indexPath.row) {
			case 0:
				cell.imageView.image = [UIImage imageNamed:@"Icon32-Setting"];
				cell.textLabel.text = NSLocalizedString(@"CM CalcRoll", nil);
				cell.detailTextLabel.text = NSLocalizedString(@"CM CalcRoll msg", nil);
				break;
			case 1:
				cell.imageView.image = [UIImage imageNamed:@"Icon32-Information"];
				cell.textLabel.text = NSLocalizedString(@"CM Condition", nil);
				cell.detailTextLabel.text = NSLocalizedString(@"CM Condition msg", nil);
				break;
			case 2:
				cell.imageView.image = [UIImage imageNamed:@"Icon32-ExtParts"];
				cell.textLabel.text = NSLocalizedString(@"CM SplitPay", nil);
				cell.detailTextLabel.text = NSLocalizedString(@"CM SplitPay msg", nil);
				break;
			case 3:
				cell.imageView.image = [UIImage imageNamed:@"Icon32-ExtParts"];
				cell.textLabel.text = NSLocalizedString(@"CM PayNote", nil);
				cell.detailTextLabel.text = NSLocalizedString(@"CM PayNote msg", nil);
				break;
		}
	}
    return cell;
}


#pragma mark - <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[ibTableView deselectRowAtIndexPath:indexPath animated:YES]; // 選択解除

	if (0<=indexPath.row && indexPath.row<[products_ count]) 
	{
		SKProduct *prod = [products_ objectAtIndex: indexPath.row];
		if (prod) {
			[self alertActivityOn:NSLocalizedString(@"SK Progress",nil)];
			// アドオン購入処理開始　　　　　　　<SKPaymentTransactionObserver>は、AzBodyNoteAppDelegateに実装
			[[SKPaymentQueue defaultQueue] addTransactionObserver: self];
			SKPayment *payment = [SKPayment paymentWithProduct: prod];
			[[SKPaymentQueue defaultQueue] addPayment:payment];
		}
		else {
			// 販売停止中
			alertBox(NSLocalizedString(@"SK Closed",nil), NSLocalizedString(@"SK Closed msg",nil), NSLocalizedString(@"Roger",nil));
			[products_ replaceObjectAtIndex:indexPath.row withObject:SK_NoSALE];
			[ibTableView reloadData];
		}
	}
}


#pragma mark - <SKProductsRequestDelegate> 販売情報

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{	// 商品情報を取得して購入ボタン表示などを整える
	if (0 < [response.invalidProductIdentifiers count]) {
		NSLog(@"*** invalidProductIdentifiers: アイテムIDが不正");
		[products_ replaceObjectAtIndex:0 withObject:SK_CLOSED];
		[ibTableView reloadData];
		return;
	}
	[products_ removeAllObjects];
	for (SKProduct *product in response.products) 
	{
		[products_ addObject:product];
	}	
}


#pragma mark - <SKPaymentTransactionObserver>  販売処理

- (void)purchasedCompleate:(SKPaymentTransaction*)tran
{
	NSUbiquitousKeyValueStore *kvs = [NSUbiquitousKeyValueStore defaultStore];
	[kvs setBool:YES forKey: tran.payment.productIdentifier];
	[kvs synchronize];

	if ([delegate_ respondsToSelector:@selector(azStorePurchesed:)]) {
		[delegate_ azStorePurchesed: tran.payment.productIdentifier];	// 呼び出し側にて、再描画など実施
	}
	
	// Compleate !
	[[SKPaymentQueue defaultQueue] finishTransaction:tran]; // 処理完了
	// インジケータ消す
	[self alertActivityOff];
	alertBox(	NSLocalizedString(@"SK Compleate",nil), NSLocalizedString(@"SK Compleate msg",nil), @"OK" );
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{	// Observer: 
	for (SKPaymentTransaction *tran in transactions)
	{
		switch (tran.transactionState) {
			case SKPaymentTransactionStatePurchasing: // 購入中
				NSLog(@"SKPaymentTransactionStatePurchasing: tran=%@", tran);
				// インジケータ開始
				[self	alertActivityOn:NSLocalizedString(@"SK Progress",nil)];
				break;
				
			case SKPaymentTransactionStateFailed: // 購入失敗
			{
				NSLog(@"SKPaymentTransactionStateFailed: tran=%@", tran);
				[[SKPaymentQueue defaultQueue] finishTransaction:tran]; // 処理完了
				// インジケータ消す
				[self alertActivityOff];
				
				if (tran.error.code == SKErrorUnknown) {
					// クレジットカード情報入力画面に移り、購入処理が強制的に終了したとき
					//alertBox(	NSLocalizedString(@"SK Cancel",nil), [tran.error localizedDescription], @"OK" );
					// 途中で止まった処理を再開する Consumable アイテムにも有効
					[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
				} else {
					alertBox(	NSLocalizedString(@"SK Failed",nil), nil, @"OK" );
				}
#ifdef DEBUG
				// 購入成功と見なしてテストする
				NSLog(@"DEBUG: SKPaymentTransactionStatePurchased: tran=%@", tran);
				[self purchasedCompleate:tran];
#endif
			} break;
				
			case SKPaymentTransactionStatePurchased:	// 購入完了
			{
				NSLog(@"SKPaymentTransactionStatePurchased: tran=%@", tran);
				[self purchasedCompleate:tran];
			} break;
				
			case SKPaymentTransactionStateRestored:		// 購入済み
			{
				NSLog(@"SKPaymentTransactionStateRestored: tran=%@", tran);
				[self purchasedCompleate:tran];
			} break;
				
			default:
				NSLog(@"SKPaymentTransactionState: default: tran=%@", tran);
				break;
		}
	}
}

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions 
{
	[[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{	// リストアの失敗
	NSLog(@"paymentQueue: restoreCompletedTransactionsFailedWithError: ");
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue 
{	// 全てのリストア処理が終了
	NSLog(@"paymentQueueRestoreCompletedTransactionsFinished: ");
}


@end
