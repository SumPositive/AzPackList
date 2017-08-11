//
//  AZStoreTVC.m
//
//  Created by Sum Positive on 11/10/06.
//  Copyright (c) 2011 Azukid. All rights reserved.
//
#undef  NSLocalizedString		//⇒ AZLocalizedString  AZClass専用にすること

#import "AZStoreTVC.h"


@interface AZStoreTVC ()
<UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate,
UIAlertViewDelegate, SKProductsRequestDelegate,
SKPaymentTransactionObserver, VerificationControllerDelegate>
{
    UITextField						*mTfGiftCode;
    UIAlertView						*mAlertActivity;
    UIActivityIndicatorView	*       mAlertActivityIndicator;
    SKProductsRequest		*       mProductRequest;
    
    BOOL								mIsPad;
    NSSet								*mProductIDs;
    NSMutableArray				*mProducts;
    
    NSString							*mGiftDetail;	//=nil; 招待パスなし
    NSString							*mGiftProductID;
    NSString							*mGiftSecretKey;//1615AzPackList
    NSString							*mPurchasedProductID;
}

//- (void)configureCell:(E2listCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end


@implementation AZStoreTVC
@synthesize delegate;
@synthesize ppSharedSecret;

#define SK_INIT				@"Init"
#define SK_BAN				@"Ban"
#define SK_NoSALE		@"NoSale"
#define SK_CLOSED		@"Closed"

#define TAG_ActivityIndicator			109
#define TAG_GoAppStore					118

#define TAG_BU_RESTORE				200 //〜299  =200 + indexPath.row;
#define TAG_BU_BUY						300	//〜399  =300 + indexPath.row;


#pragma mark - Alert

- (void)alertActivityOn:(NSString*)zTitle
{
	[mAlertActivity setTitle:zTitle];
	[mAlertActivity show];
	[mAlertActivityIndicator setFrame:CGRectMake((mAlertActivity.bounds.size.width-50)/2, mAlertActivity.frame.size.height-130, 50, 50)];
	[mAlertActivityIndicator startAnimating];
}

- (void)alertActivityOff
{
	[mAlertActivityIndicator stopAnimating];
	[mAlertActivity dismissWithClickedButtonIndex:mAlertActivity.cancelButtonIndex animated:YES];
}
/*
- (void)alertCommError
{
	alertBox(AZLocalizedString(@"AZStore CommError", nil), AZLocalizedString(@"AZStore CommError msg", nil), @"OK");
}*/


#pragma mark - Action

- (void)actionBack:(id)sender
{
	if (mIsPad) {
		[self dismissViewControllerAnimated:YES completion:nil];
	} else {
		[self.navigationController popViewControllerAnimated:YES];	// < 前のViewへ戻る
	}
}

- (void)cellActionRestore
{	// [Restore] [購入済み復元]
	GA_TRACK_METHOD
	// インジケータ開始
	[self	alertActivityOn:AZLocalizedString(@"AZStore Progress",nil)];
	[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)cellActionBuy:(SKProduct*)product
{	// [Buy] [購入]
	GA_TRACK_METHOD
	if (product) {
		// インジケータ開始
		[self	alertActivityOn:AZLocalizedString(@"AZStore Progress",nil)];
		// アドオン購入処理開始
		[[SKPaymentQueue defaultQueue] addTransactionObserver: self]; //<SKPaymentTransactionObserver>
		SKPayment *payment = [SKPayment paymentWithProduct: product];
		[[SKPaymentQueue defaultQueue] addPayment:payment];
	}
	else {
		// 販売停止中
		//[mProducts replaceObjectAtIndex:idx withObject:SK_NoSALE];
		[self.tableView reloadData];
	}
}

// productID の購入確定処理
- (void)actPurchasedProductID:(NSString*)productID
{
	GA_TRACK_METHOD
	// AZClass規則： 購入済み記録は、standardUserDefaults:へ最優先に記録し判定に使用すること。
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setBool:YES  forKey:productID];  //YES=購入済み
	[userDefaults synchronize];
	// 他デバイス同期のため KVS が有効ならばKVSへも記録する
	NSUbiquitousKeyValueStore *kvs = [NSUbiquitousKeyValueStore defaultStore];
	if (kvs) {
		[kvs setBool:YES  forKey:productID];  //YES=購入済み
		[kvs synchronize]; // 保存同期
	}
	
	if ([self.delegate respondsToSelector:@selector(azStorePurchesed:)]) {
		[self.delegate azStorePurchesed: productID];	// 呼び出し側にて、再描画など実施
	}
	// 再表示
	[self.tableView reloadData];
}


#pragma mark - View lifecycle

- (id)init
{
	self = [super initWithStyle:UITableViewStyleGrouped];  // セクションあり
	if (self) {
		// 初期化成功
		GA_TRACK_PAGE(@"AZStore");
		//NG//mIsPad = [[[UIDevice currentDevice] model] hasPrefix:@"iPad"];
		//NG//iPad上でiPhoneモードのとき、iPhoneにならない。
		mIsPad = iS_iPAD;  //iPad上でiPhoneモードのとき、iPhoneになる。
	/*	if (mIsPad) {
			//self.view.backgroundColor = //通常、iPadでは無効になっている。
			if ([self.tableView respondsToSelector:@selector(setBackgroundView:)]) {
				self.tableView.backgroundView = nil;	//これでbackgroundColorが有効になる。
			}
		}*/
		
		[self.tableView setBackgroundView:nil];	//これでbackgroundColorが有効になる。
		// 背景色　小豆色 RGB(152,81,75) #98514B
		self.tableView.backgroundColor = [UIColor colorWithRed:152/180.0f
																	green:81/180.0f
																	blue:75/180.0f
																	alpha:1.0f];
	}
	return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.title = AZLocalizedString(@"AZStore",nil);
	
	// alertActivityOn/Off のための準備
	mAlertActivity = [[UIAlertView alloc] initWithTitle:@"" message:@"\n\n" delegate:self 
									  cancelButtonTitle:AZLocalizedString(@"Cancel", nil) 
									  otherButtonTitles:nil]; // deallocにて解放
	mAlertActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	mAlertActivityIndicator.frame = CGRectMake(0, 0, 50, 50);
	[mAlertActivity addSubview:mAlertActivityIndicator];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	
	//NSLog(@"self.navigationController.viewControllers={%@}", self.navigationController.viewControllers);
	if ([self.navigationController.viewControllers count]==1) {	// viewDidLoad:では未設定であり判断できない
		// 最初のPushViewには <Back ボタンが無いので、左側に追加する ＜＜ iPadの場合
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
												 initWithTitle:AZLocalizedString(@"<Back", nil)
												 style:UIBarButtonItemStylePlain
												 target:self action:@selector(actionBack:)];
	}

	mProducts = [[NSMutableArray alloc] initWithObjects:SK_INIT, nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	
	if ([self.ppSharedSecret length]<10) {
		GA_TRACK_ERROR(@"AZStore .ppSharedSecret NG：非消費型でもレシートチェックが必要になった。");
		// 購入が禁止されています。
		//[mProducts replaceObjectAtIndex:0 withObject:SK_BAN];
		//[self.tableView reloadData];
		//return;
		abort();
	}
	
	// Products 一覧表示
	if ([SKPaymentQueue canMakePayments] && mProductIDs) { // 課金可能であるか確認する
		// 課金可能
		[self alertActivityOn:AZLocalizedString(@"AZStore Progress",nil)];
		// 商品情報リクエスト 
		mProductRequest = [[SKProductsRequest alloc] initWithProductIdentifiers: mProductIDs];
		mProductRequest.delegate = self;		//viewDidUnloadにて、cancel, nil している。さもなくば落ちる
		[mProductRequest start];  //---> productsRequest:didReceiveResponse:が呼び出される
	} else {
		// 購入が禁止されています。
		[mProducts replaceObjectAtIndex:0 withObject:SK_BAN];
		[self.tableView reloadData];
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
	return YES;	// FormSheet窓対応
}

#pragma mark unload
- (void)viewDidUnload		//＜＜実験では、呼ばれなかった！
{
    [super viewDidUnload];
}

- (void)unloadStore
{	// 必ず最後に呼ばれる
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self]; // これが無いと、しばらくすると落ちる
	if (mProductRequest) {
		[mProductRequest cancel];			// 中断
		mProductRequest.delegate = nil;  // これないと、通信中に閉じると落ちる
	}
}

- (void)dealloc
{
	[self unloadStore];
}


#pragma mark - Method - set
/*
- (void)setTitle:(NSString *)title {  NG ＜＜無限ループになる
	self.title = title;
}*/

- (void)setProductIDs:(NSSet *)pids {
	assert(0<[pids count]);
	// ここでリクエスト処理すると表示が遅くなるため、viewDidAppear:にて処理する。
	mProductIDs = pids;
}

- (void)setGiftDetail:(NSString *)detail productID:(NSString*)pid secretKey:(NSString*)skey 
{
	if (detail && pid && skey) {
		mGiftDetail = detail;
		mGiftProductID = pid;
		mGiftSecretKey = skey;
	} else {
		mGiftDetail = nil;
		mGiftProductID = nil;
		mGiftSecretKey = nil;
	}
}


#pragma mark - <UIAlertViewDelegate>
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex==alertView.cancelButtonIndex) {
		[self unloadStore];
		[self alertActivityOff];
		[self actionBack:nil];	// 戻る
	}
}


#pragma mark - <UITableViewDataSource>
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section) {
		case 0:	return [mProducts count];
		case 1:	return 1;
		case 2:	return 5;
	}
	return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
	switch (section) {
		case 0:	return AZLocalizedString(@"AZStore Products Header", nil);
		//case 1:	return AZLocalizedString(@"AZStore Gift Header", nil);
		case 2:	return AZLocalizedString(@"AZStore AzukiSoft Header", nil);
	}
	return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	switch (section) {
		case 0:	return AZLocalizedString(@"AZStore Products Footer", nil);
		//case 1:	return AZLocalizedString(@"AZStore Gift Footer", nil);
		case 2:	return @"\n" AZClass_COPYRIGHT @"\n\n";	//広告スペースを考慮
	}
	return nil;
}

// セルの高さを指示する
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	switch (indexPath.section) {
		case 0:
			return 105;
		
		case 1:
			if (mGiftDetail) {
				return 100;
			} else {
				return 0;
			}
			break;
			
		case 2:
			return 66;
	}
	return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	//NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	//NSUbiquitousKeyValueStore *kvs = [NSUbiquitousKeyValueStore defaultStore];

	if (indexPath.section==0) {
		static NSString *idAZStoreCell = @"AZStoreCell";	//AZStoreCell.xib CustomCell
		AZStoreCell *cell = (AZStoreCell *)[tableView 
											dequeueReusableCellWithIdentifier:idAZStoreCell];
		if (cell == nil) {
			UINib* nib = [UINib nibWithNibName:idAZStoreCell bundle:nil];
			NSArray* array = [nib instantiateWithOwner:nil options:nil];
			cell = (AZStoreCell *) [array objectAtIndex:0];
			cell.delegate = self;
		}
		
		if (0<=indexPath.row && indexPath.row<[mProducts count]) 
		{
			if ([[mProducts objectAtIndex: indexPath.row] isKindOfClass:[SKProduct class]]) 
			{	// 商品あり　　AZStoreCell
				cell.ppProduct = [mProducts objectAtIndex: indexPath.row];
			}
			else if ([[mProducts objectAtIndex: indexPath.row] isEqualToString:SK_INIT])
			{
				cell.ppProduct = nil;
				cell.ppErrTitle = AZLocalizedString(@"AZStore Progress", nil);
			}
			else if ([[mProducts objectAtIndex: indexPath.row] isEqualToString:SK_BAN])
			{
				cell.ppProduct = nil;
				cell.ppErrTitle = AZLocalizedString(@"AZStore Ban", nil);
			}
			else if ([[mProducts objectAtIndex: indexPath.row] isEqualToString:SK_NoSALE])
			{
				cell.ppProduct = nil;
				cell.ppErrTitle = AZLocalizedString(@"AZStore Closed", nil);
			}
			else if ([[mProducts objectAtIndex: indexPath.row] isEqualToString:SK_CLOSED])
			{
				cell.ppProduct = nil;
				cell.ppErrTitle = AZLocalizedString(@"AZStore Closed", nil);
			}
			// 再描画する
			[cell refresh];
			return cell;
		}
	}
	else if (indexPath.section==1) {	//-------------------------------------Gift
		static NSString *idCell = @"Cell";
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:idCell];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
										  reuseIdentifier:idCell];
		}
		// Def.選択不可にする
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.selectionStyle = UITableViewCellSelectionStyleNone; // 選択時ハイライトなし ＜＜選択不可
		if (mGiftDetail) {
			cell.textLabel.text = AZLocalizedString(@"AZStore Gift", nil);
			cell.detailTextLabel.text = mGiftDetail;
			cell.detailTextLabel.numberOfLines = 3;
			if (mTfGiftCode==nil) {
				mTfGiftCode = [[UITextField alloc] initWithFrame:
							   CGRectMake(cell.contentView.bounds.size.width-140, 8, 110, 25)];
				mTfGiftCode.placeholder = @"Gift code";
				mTfGiftCode.borderStyle = UITextBorderStyleRoundedRect;
				mTfGiftCode.keyboardType = UIKeyboardTypeASCIICapable;
				mTfGiftCode.returnKeyType = UIReturnKeyDone;
				mTfGiftCode.autocapitalizationType = UITextAutocapitalizationTypeNone;
				mTfGiftCode.autocorrectionType = NO;
				mTfGiftCode.delegate = self;
				[cell.contentView addSubview:mTfGiftCode];
			}
		}
		return cell;
	}
	else if (indexPath.section==2) {	//-------------------------------------AzukiSoft
		static NSString *idCell = @"Cell";
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:idCell];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
										  reuseIdentifier:idCell];
		}
		cell.detailTextLabel.numberOfLines = 2;
		cell.selectionStyle = UITableViewCellSelectionStyleBlue; // 選択時ハイライト ＜＜選択許可
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		switch (indexPath.row) {
			case 0: {
				cell.imageView.image = [UIImage imageNamed:@"Icon57-PackList"];
				cell.textLabel.text = AZLocalizedString(@"AZStore Ad PackList", nil);
				cell.detailTextLabel.text = AZLocalizedString(@"AZStore Ad PackList detail", nil);
			}	break;
			case 1: {
				cell.imageView.image = [UIImage imageNamed:@"Icon57-PayNote"];
				cell.textLabel.text = AZLocalizedString(@"AZStore Ad PayNote", nil);
				cell.detailTextLabel.text = AZLocalizedString(@"AZStore Ad PayNote detail", nil);
			}	break;
			case 2: {
				cell.imageView.image = [UIImage imageNamed:@"Icon57-Condition"];
				cell.textLabel.text = AZLocalizedString(@"AZStore Ad Condition", nil);
				cell.detailTextLabel.text = AZLocalizedString(@"AZStore Ad Condition detail", nil);
			}	break;
			case 3: {
				cell.imageView.image = [UIImage imageNamed:@"Icon57-CalcRoll"];
				cell.textLabel.text = AZLocalizedString(@"AZStore Ad CalcRoll", nil);
				cell.detailTextLabel.text = AZLocalizedString(@"AZStore Ad CalcRoll detail", nil);
			}	break;
			case 4: {
				cell.imageView.image = [UIImage imageNamed:@"Icon57-SplitPay"];
				cell.textLabel.text = AZLocalizedString(@"AZStore Ad SplitPay", nil);
				cell.detailTextLabel.text = AZLocalizedString(@"AZStore Ad SplitPay detail", nil);
			}	break;
		}
		return cell;
	}
    return nil;
}
/*
// Display customization
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell 
															forRowAtIndexPath:(NSIndexPath *)indexPath
{

}*/


#pragma mark - <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES]; // 選択解除

	if (indexPath.section==0) {
		if (0<=indexPath.row && indexPath.row<[mProducts count]) 
		{
			UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
			if (cell.selectionStyle==UITableViewCellSelectionStyleBlue)
			{	// 選択時ハイライト ＜＜選択許可
				SKProduct *prod = [mProducts objectAtIndex: indexPath.row];
				if (prod) {
					[self alertActivityOn:AZLocalizedString(@"AZStore Progress",nil)];
					// アドオン購入処理開始
					[[SKPaymentQueue defaultQueue] addTransactionObserver: self]; //<SKPaymentTransactionObserver>
					SKPayment *payment = [SKPayment paymentWithProduct: prod];
					[[SKPaymentQueue defaultQueue] addPayment:payment];
				}
				else {
					// 販売停止中
					[mProducts replaceObjectAtIndex:indexPath.row withObject:SK_NoSALE];
					[self.tableView reloadData];
				}
			}
			else {
					// 選択不可、　購入済み
			}
		}
	}
	else if (indexPath.section==1) {	//-------------------------------------Gift
		//
		GA_TRACK_EVENT(@"AZStore", @"Gift", @"code", 0);
	}
	else if (indexPath.section==2) {	//-------------------------------------AzukiSoft
		NSString *zAppID = nil;
		switch (indexPath.row) {
			case 0: zAppID = @"495525984"; break;	// PackList
			case 1: zAppID = @"363741814"; break;	// PayNote-iPhone
			case 2: zAppID = @"472914799"; break;	// Condition
			case 3: zAppID = @"385216637"; break;	// CalcRoll
			case 4: zAppID = @"467941202"; break;	// SplitPay
		}
		if (zAppID==nil) return;
		GA_TRACK_EVENT(@"AZStore", @"GoAppStore", zAppID, 0);
		// AppStoreアプリ起動URL　＜＜WebViewでは開けません。
		NSString *zUrl = @"http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=";
		zUrl = [zUrl stringByAppendingString: zAppID];
		zUrl = [zUrl stringByAppendingString: @"&mt=8"];
		// AppStoreアプリを起動　＜シミュレータでは起動しない＞　＜＜AZWebViewでは開けない＞＞
		[[UIApplication sharedApplication] openURL: [NSURL URLWithString: zUrl]];
	}
}


#pragma mark - <SKProductsRequestDelegate> 販売情報

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{	// 商品情報を取得して購入ボタン表示などを整える
	[self alertActivityOff];
/*	if (0 < [response.invalidProductIdentifiers count]) {
		GA_TRACK_EVENT_ERROR(@"Invalid ProductIdentifiers", 0);
		NSLog(@"*** Invalid ProductIdentifiers: アイテムIDが不正");
		[mProducts replaceObjectAtIndex:0 withObject:SK_CLOSED];
		[self.tableView reloadData];
		return;
	}*/
    // 確認できなかったidentifierをログに記録
    for (NSString *identifier in response.invalidProductIdentifiers) {
        NSLog(@"invalid product identifier: %@", identifier);
		GA_TRACK_EVENT_ERROR(identifier, 0);
    }
	
	[mProducts removeAllObjects];
	for (SKProduct *product in response.products) 
	{
		[mProducts addObject:product];
	}	
	[self.tableView reloadData];
}


#pragma mark - <VerificationControllerDelegate>
- (void)verificationResult:(BOOL)result
{
	if (result) {	// OK
		// productID の購入確定処理   ＜＜この中でセル再描画している
		[self actPurchasedProductID: mPurchasedProductID];
	} else {
		GA_TRACK_ERROR(@"AZStore ReceiptNG");
		azAlertBox(	AZLocalizedString(@"AZStore Failed",nil), 
				   AZLocalizedString(@"AZStore ReceiptNG",nil), @"OK" );
	}
	// インジケータ消す
	[self alertActivityOff];
}

#pragma mark - <SKPaymentTransactionObserver>  販売処理
// 購入成功時の最終処理　＜＜ここでトランザクションをクリアする。
- (void)paymentCompleate:(SKPaymentTransaction*)tran
{	// 複数製品をリストアした場合、製品数だけ呼び出される
	// Compleate !
	[[SKPaymentQueue defaultQueue] finishTransaction:tran]; // 処理完了

	// Important note about In-App Purchase Receipt Validation on iOS
	// レシート検証
	[self	alertActivityOn:AZLocalizedString(@"AZStore Receipt Validation",nil)];
	mPurchasedProductID = tran.payment.productIdentifier;
	if (![[VerificationController sharedInstance] verifyPurchase:tran 
													sharedSecret:self.ppSharedSecret	  target:self]) 
	{
	/*	GA_TRACK_ERROR(@"AZStore ReceiptNG");
		azAlertBox(	AZLocalizedString(@"AZStore Failed",nil), 
				   AZLocalizedString(@"AZStore ReceiptNG",nil), @"OK" );*/
		//[self alertActivityOff];	// インジケータ消す
	}
	// レシート検証結果：　verificationResult:が呼び出される。
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{	// Observer: 
	for (SKPaymentTransaction *tran in transactions)
	{
		switch (tran.transactionState) {
			case SKPaymentTransactionStatePurchasing: // 購入中
				NSLog(@"SKPaymentTransactionStatePurchasing: tran=%@", tran);
				// インジケータ開始
				[self	alertActivityOn:AZLocalizedString(@"AZStore Progress",nil)];
				break;
				
			case SKPaymentTransactionStateFailed: // 購入失敗
			{
				//GA_TRACK_EVENT(@"AZStore", @"SKPaymentTransactionStateFailed", [tran description] , 0);
				NSLog(@"SKPaymentTransactionStateFailed: tran=%@", tran);
				[[SKPaymentQueue defaultQueue] finishTransaction:tran]; // 処理完了
				[self alertActivityOff];	// インジケータ消す
				
				if (tran.error.code == SKErrorUnknown) {
					// クレジットカード情報入力画面に移り、購入処理が強制的に終了したとき
					// 途中で止まった処理を再開する Consumable アイテムにも有効
					[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
				} else {
					GA_TRACK_ERROR(@"SKPaymentTransactionStateFailed")
					azAlertBox(	AZLocalizedString(@"AZStore Failed",nil), nil, @"OK" );
				}
#ifdef DEBUGxxx
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
				GA_TRACK_EVENT(@"AZStore", @"SKPaymentTransactionState: default", [tran description] , 0);
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
	GA_TRACK_ERROR([error description]);
	// インジケータ消す
	[self alertActivityOff];
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue 
{	// 全てのリストア処理が終了
	NSLog(@"paymentQueueRestoreCompletedTransactionsFinished: ");
	// インジケータ消す
	[self alertActivityOff];
}


#pragma mark - <UITextFieldDelegate>
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	assert(textField==mTfGiftCode);
	assert(mGiftProductID);
	assert(mGiftSecretKey);
	[textField resignFirstResponder]; // キーボードを隠す
	
	// 招待パス生成
	NSString *pass = azGiftCode( mGiftSecretKey ); //16進文字列（英数大文字のみ）
	// 英大文字にしてチェック
	if ([pass length]==10 && [pass isEqualToString: [mTfGiftCode.text uppercaseString]]) 
	{
		// productID の購入確定処理
		[self actPurchasedProductID: mGiftProductID];
		// OK
		azAlertBox(AZLocalizedString(@"AZStore Gift OK", nil), nil, @"OK");
	}
	else {
		// NG 招待パスが違う
		azAlertBox(AZLocalizedString(@"AZStore Gift NG", nil), nil, @"OK");
		mTfGiftCode.text = @"";
	}
	return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range 
replacementString:(NSString *)string 
{	// Gift code 最大文字数制限
    NSMutableString *text = [textField.text mutableCopy];
    [text replaceCharactersInRange:range withString:string];
	// 置き換えた後の長さをチェックする
	if ([text length] <= 16) {
		return YES;
	} else {
		return NO;
	}
}


@end
