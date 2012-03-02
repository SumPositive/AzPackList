//
//  AZStore.m
//
//  Created by Sum Positive on 11/10/06.
//  Copyright (c) 2011 Azukid. All rights reserved.
//

#import "Global.h"
#import "AppDelegate.h"
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
#define SK_BAN				@"Ban"
#define SK_NoSALE		@"NoSale"
#define SK_CLOSED		@"Closed"

#define TAG_ActivityIndicator			109
#define TAG_GoAppStore					208


#pragma mark - UUID　-　passCode生成
// getMacAddress() --> Global.m
#import <CommonCrypto/CommonDigest.h>  // MD5
// 「招待パス」生成　　＜＜これと同じものを Version 1.2 にも実装して「招待パス」表示する
NSString *passCode()
{	// userPass : デバイスID（UDID） & MD5   （UDIDをそのまま利用するのはセキュリティ上好ましくないため）
	//NSString *code = [UIDevice currentDevice].uniqueIdentifier;		// デバイスID文字列 ＜＜iOS5.1以降廃止のため
	// MACアドレスにAzPackList固有文字を絡めて種コード生成
	NSString *code = [NSString stringWithFormat:@"Syukugawa%@1615AzPackList", getMacAddress()];
	NSLog(@"MAC address: code=%@", code);
	// code を MD5ハッシュ化
	const char *cstr = [code UTF8String];	// C文字列化
	unsigned char ucMd5[CC_MD5_DIGEST_LENGTH];	// MD5結果領域 [16]bytes
	CC_MD5(cstr, strlen(cstr), ucMd5);			// MD5生成
	// 16進文字列化 ＜＜ucMd5[0]〜[15]のうち10文字分だけ使用する＞＞
	code = [NSString stringWithFormat: @"%02X%02X%02X%02X%02X",  
			ucMd5[1], ucMd5[5], ucMd5[7], ucMd5[11], ucMd5[13]];	
	AzLOG(@"passCode: code=%@", code);
	return code;
}


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


#pragma mark - Action

- (IBAction)ibBuClose:(UIButton *)button
{
	[self dismissModalViewControllerAnimated:YES];
}

// productID の購入確定処理
- (void)actPurchasedProductID:(NSString*)productID
{
	NSUbiquitousKeyValueStore *kvs = [NSUbiquitousKeyValueStore defaultStore];
	[kvs setBool:YES forKey: productID];
	[kvs synchronize]; //保存
	
	if ([delegate_ respondsToSelector:@selector(azStorePurchesed:)]) {
		[delegate_ azStorePurchesed: productID];	// 呼び出し側にて、再描画など実施
	}
	// 再表示
	[ibTableView reloadData];
}


#pragma mark - View lifecycle

- (id)initWithUnLock:(BOOL)unlock
{
/*	if ([[[UIDevice currentDevice] model] hasPrefix:@"iPad"]) {	// iPad
		self = [super initWithNibName:@"AZStoreVC-iPad" bundle:nil];
	} else {
		self = [super initWithNibName:@"AZStoreVC" bundle:nil];
	}*/
	self = [super initWithNibName:@"AZStoreVC" bundle:nil];
    if (self) {
        // Custom initialization
		unLock_ = unlock;

		// 背景色　小豆色 RGB(152,81,75) #98514B
		self.view.backgroundColor = [UIColor colorWithRed:152/255.0f 
													green:81/255.0f 
													 blue:75/255.0f
													alpha:1.0f];
		self.contentSizeForViewInPopover = GD_POPOVER_iPhoneSIZE;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.title = NSLocalizedString(@"menu Purchase",nil);
	
	if (unLock_) 
	{	// Version 1.2 購入済み
		//ibLbInviteTitle.hidden = YES;
		//ibLbInviteMsg.hidden = YES;
		ibTfInvitePass.enabled = NO;
		ibTfInvitePass.placeholder = NSLocalizedString(@"SK Invitation", nil); // Version 1.2 購入済み
	} else {
		ibTfInvitePass.keyboardType = UIKeyboardTypeASCIICapable;
		ibTfInvitePass.returnKeyType = UIReturnKeyDone;
	}
	
	// alertActivityOn/Off のための準備
	alertActivity_ = [[UIAlertView alloc] initWithTitle:@"" message:@"" delegate:self cancelButtonTitle:nil otherButtonTitles:nil]; // deallocにて解放
	alertActivityIndicator_ = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	alertActivityIndicator_.frame = CGRectMake(0, 0, 50, 50);
	[alertActivity_ addSubview:alertActivityIndicator_];

	AppDelegate *ad = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	if (ad.app_is_iPad) {
		// CANCELボタンを左側に追加する  Navi標準の戻るボタンでは cancel:処理ができないため
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
												 initWithTitle:NSLocalizedString(@"Back", nil)
												 style:UIBarButtonItemStyleBordered
												 target:self action:@selector(actionBack:)];
	}
}

- (void)actionBack:(id)sender
{
	[self dismissModalViewControllerAnimated:YES];
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
		[products_ replaceObjectAtIndex:0 withObject:SK_BAN];
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
	AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	if (app.app_is_iPad) {
		return (interfaceOrientation == UIInterfaceOrientationPortrait); //タテのみ
	} else {
		// 回転禁止でも、正面は常に許可しておくこと。
		return app.app_opt_Autorotate OR (interfaceOrientation == UIInterfaceOrientationPortrait);
	}
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
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self]; // これが無いと、しばらくすると落ちる
}


#pragma mark - <UITextFieldDelegate>

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	assert(textField==ibTfInvitePass);
	[textField resignFirstResponder]; // キーボードを隠す

	// 招待パス生成
	NSString *pass = passCode(); //16進文字列（英数大文字のみ）
	// 英大文字にしてチェック
	if ([pass length]==10 && [pass isEqualToString: [ibTfInvitePass.text uppercaseString]]) 
	{
		// productID の購入確定処理
		[self actPurchasedProductID: SK_PID_AdOff];
		// OK
		alertBox(NSLocalizedString(@"SK InvitePass OK", nil), nil, @"OK");
	}
	else {
		// NG 招待パスが違う
		alertBox(NSLocalizedString(@"SK InvitePass NG", nil), nil, @"OK");
		ibTfInvitePass.text = @"";
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [products_ count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
	if (section==0) {
		return NSLocalizedString(@"SK License", nil);
	} else {
		return NSLocalizedString(@"SK AzukiSoft", nil);
	}
}

// セルの高さを指示する
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	return 88; // デフォルト：44ピクセル
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
									  reuseIdentifier:CellIdentifier];
    }
	// Def.選択不可にする
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.selectionStyle = UITableViewCellSelectionStyleNone; // 選択時ハイライトなし ＜＜選択不可
	
	if (indexPath.section==0) {
		if (0<=indexPath.row && indexPath.row<[products_ count]) 
		{
			UIActivityIndicatorView *ai = (UIActivityIndicatorView*)[cell.contentView viewWithTag:TAG_ActivityIndicator];
			if (ai) {
				[ai stopAnimating];
			}
			
			if ([[products_ objectAtIndex: indexPath.row] isKindOfClass:[SKProduct class]]) 
			{
				cell.imageView.image = [UIImage imageNamed:@"Icon-Parts-32"];
				SKProduct *prod = [products_ objectAtIndex: indexPath.row];
				if (prod) {
					cell.textLabel.font = [UIFont systemFontOfSize:18];
					cell.textLabel.text = prod.localizedTitle;
					
					NSUbiquitousKeyValueStore *kvs = [NSUbiquitousKeyValueStore defaultStore];
					if ([kvs boolForKey: prod.productIdentifier]) {
						// 購入済み
						cell.detailTextLabel.font = [UIFont systemFontOfSize:14];
						cell.detailTextLabel.textColor = [UIColor blueColor];
						cell.detailTextLabel.text = NSLocalizedString(@"SK Purchased", nil);
					} else {
						cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
						cell.detailTextLabel.font = [UIFont systemFontOfSize:14];
						cell.detailTextLabel.minimumFontSize = 10.0;
						cell.detailTextLabel.textColor = [UIColor brownColor];
						//NSString *zPrice = [prod.price descriptionWithLocale: [NSLocale currentLocale]];
						// Price 金額単位表示する
						NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
						[fmt setNumberStyle:NSNumberFormatterCurrencyStyle]; // 通貨スタイル（先頭に通貨記号が付く）
						[fmt setLocale: prod.priceLocale];  //[NSLocale currentLocale]]; 
						cell.detailTextLabel.text = [NSString stringWithFormat:@"Price: %@\n%@", 
													 [fmt stringFromNumber:prod.price],
													 prod.localizedDescription];
						cell.detailTextLabel.numberOfLines = 3;
						cell.selectionStyle = UITableViewCellSelectionStyleBlue; // 選択時ハイライト ＜＜選択許可
					}
				}
				else {
					// 販売停止中
					cell.imageView.image = [UIImage imageNamed:@"Icon-Stop-32"];
					cell.textLabel.font = [UIFont systemFontOfSize:12];
					cell.textLabel.text = [cell.textLabel.text stringByAppendingString:NSLocalizedString(@"SK No Sale", nil)];
#ifdef DEBUG
					cell.detailTextLabel.text = @"DEBUG1: AppStore Sign Out?";
#endif
				}
			}
			else if ([[products_ objectAtIndex: indexPath.row] isEqualToString:SK_INIT])
			{
				cell.imageView.image = [UIImage imageNamed:@"Icon-Space-44"]; // 44x44
				UIActivityIndicatorView *ai = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
				ai.frame = CGRectMake(0, (cell.frame.size.height-32)/2, 32, 32);
				[cell.contentView addSubview:ai];
				[ai startAnimating];
				ai.tag = TAG_ActivityIndicator;
				cell.textLabel.font = [UIFont systemFontOfSize:12];
				cell.textLabel.text = NSLocalizedString(@"SK Progress", nil);
			}
			else if ([[products_ objectAtIndex: indexPath.row] isEqualToString:SK_BAN])
			{
				cell.imageView.image = [UIImage imageNamed:@"Icon-Stop-32"];
				cell.textLabel.font = [UIFont systemFontOfSize:12];
				cell.textLabel.text = NSLocalizedString(@"SK Ban", nil);
			}
			else if ([[products_ objectAtIndex: indexPath.row] isEqualToString:SK_NoSALE])
			{
				cell.imageView.image = [UIImage imageNamed:@"Icon-Stop-32"];
				cell.textLabel.font = [UIFont systemFontOfSize:12];
				cell.textLabel.text = NSLocalizedString(@"SK No Sale", nil);
#ifdef DEBUG
				cell.detailTextLabel.text = @"DEBUG2: AppStore Sign Out?";
#endif
			}
			else if ([[products_ objectAtIndex: indexPath.row] isEqualToString:SK_CLOSED])
			{
				cell.imageView.image = [UIImage imageNamed:@"Icon-Stop-32"];
				cell.textLabel.font = [UIFont systemFontOfSize:12];
				cell.textLabel.text = NSLocalizedString(@"SK Closed", nil);
#ifdef DEBUG
				cell.detailTextLabel.text = @"DEBUG3: AppStore Sign Out?";
#endif
			}
		}
	} 
/*	else {
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
	}*/
    return cell;
}


#pragma mark - <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[ibTableView deselectRowAtIndexPath:indexPath animated:YES]; // 選択解除

	if (indexPath.section==0) {
		if (0<=indexPath.row && indexPath.row<[products_ count]) 
		{
			UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
			if (cell.selectionStyle==UITableViewCellSelectionStyleBlue)
			{	// 選択時ハイライト ＜＜選択許可
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
					//alertBox(NSLocalizedString(@"SK Closed",nil), NSLocalizedString(@"SK Closed msg",nil), NSLocalizedString(@"Roger",nil));
					[products_ replaceObjectAtIndex:indexPath.row withObject:SK_NoSALE];
					[ibTableView reloadData];
				}
			}
			else {
					// 選択不可、　購入済み
			}
		}
	}
/*	else {
		// AzukiSoft Information
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"SK GoAppStore",nil)
														message:NSLocalizedString(@"SK GoAppStore msg",nil)
													   delegate:self		// clickedButtonAtIndexが呼び出される
											  cancelButtonTitle:@"＜Back"
											  otherButtonTitles:@"Go AppStore＞", nil];
		alert.tag = TAG_GoAppStore;
		[alert show];
	}*/
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
	[ibTableView reloadData];
}


#pragma mark - <SKPaymentTransactionObserver>  販売処理

// 購入成功時の最終処理　＜＜ここでトランザクションをクリアする。
- (void)paymentCompleate:(SKPaymentTransaction*)tran
{
	// productID の購入確定処理
	[self actPurchasedProductID: tran.payment.productIdentifier];
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
				[self paymentCompleate:tran];
#endif
			} break;
				
			case SKPaymentTransactionStatePurchased:	// 購入完了
			{
				NSLog(@"SKPaymentTransactionStatePurchased: tran=%@", tran);
				[self paymentCompleate:tran];
			} break;
				
			case SKPaymentTransactionStateRestored:		// 購入済み
			{
				NSLog(@"SKPaymentTransactionStateRestored: tran=%@", tran);
				[self paymentCompleate:tran];
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
