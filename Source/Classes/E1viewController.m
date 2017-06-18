//
//  E1viewController.m
//  iPack E1 Title
//
//  Created by 松山 和正 on 09/12/03.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "E1viewController.h"

//#import "HTTPServer.h"
//#import "MyHTTPConnection.h"
//#import "localhostAddresses.h"


#define ACTIONSEET_TAG_DELETEPACK		901
#define ACTIONSEET_TAG_BarMenu			910
#define ACTIONSEET_TAG_MENU					929

#define ALERT_TAG_HTTPServerStop	109
#define ALERT_TAG_SupportSite			118
#define ALERT_TAG_DELETEPACK		127
#define ALERT_TAG_CloudReset			136


@interface E1viewController ()
<NSFetchedResultsControllerDelegate, UIActionSheetDelegate	,UIPopoverControllerDelegate, AZStoreDelegate>
{
    //__weak IBOutlet UITableView*    _tableView;      self.tableView

    NSManagedObjectContext		*mMoc;
    NSFetchedResultsController	*mFetchedE1;
    HTTPServer								*mHttpServer;
    UIAlertView								*mHttpServerAlert;
    NSDictionary							*mAddressDic;
    
    E1edit							*e1editView_;
    //InformationView			*informationView_;
    
    UIPopoverController	*popOver_;
    NSIndexPath*				indexPathEdit_;	//[1.1]ポインタ代入注意！copyするように改善した。
    
    AppDelegate		*appDelegate_;
    
    BOOL					bInformationOpen_;	//[1.0.2]InformationViewを初回自動表示するため
    NSUInteger			actionDeleteRow_;		//[1.1]削除するRow
    BOOL					bOptWeightRound_;
    BOOL					bOptShowTotalWeight_;
    BOOL					bOptShowTotalWeightReq_;
    NSInteger			section0Rows_; // E1レコード数　＜高速化＞
    CGPoint				contentOffsetDidSelect_; // didSelect時のScrollView位置を記録
    //SKProduct			*productUnlock_;
}

//- (void)actionInformation;
//- (void)actionSetting;
//- (void)azAction;
- (void)httpInfoUpdate:(NSNotification *)notification;
- (void)e1add;
- (void)e1editView:(NSIndexPath *)indexPath;
@end


@implementation E1viewController


#pragma mark - Delegate
/*
- (void)refreshE1view
{
	contentOffsetDidSelect_.y = 0;  // 直前のdidSelectRowAtIndexPath位置に戻らないようにクリアしておく
	//[self viewWillAppear:YES];		// Setting変更後、全域再描画が必要になるので、このようにした。
	[self viewDidAppear:YES];
}*/


#pragma mark - CoreData - iCloud

- (void)refetcheAllData
{
	@try {
		if (mFetchedE1 == nil) 
		{
			// Create and configure a fetch request with the Book entity.
			NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
			NSEntityDescription *entity = [NSEntityDescription entityForName:@"E1" 
													  inManagedObjectContext:mMoc];
			[fetchRequest setEntity:entity];
			// Sorting
			NSSortDescriptor *sortRow = [[NSSortDescriptor alloc] initWithKey:@"row" ascending:YES];
			NSArray *sortArray = [[NSArray alloc] initWithObjects:sortRow, nil];
			[fetchRequest setSortDescriptors:sortArray];
			// Create and initialize the fetch results controller.
			mFetchedE1 = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest 
															 managedObjectContext:mMoc 
															   sectionNameKeyPath:nil cacheName:@"E1nodes"];
		}
		
		NSError *error = nil;
		// 読み込み
		if (![mFetchedE1 performFetch:&error]) {
			// Update to handle the error appropriately.
			//NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			GA_TRACK_ERROR([error description]);
			return; //exit(-1);  // Fail
		}
		NSLog(@"refetcheAllData: fetchedE1_=%@", mFetchedE1);
		
		// 高速化のため、ここでE1レコード数（行数）を求めてしまう
		section0Rows_ = 0;
		if (0 < [[mFetchedE1 sections] count]) {
			id <NSFetchedResultsSectionInfo> sectionInfo = [[mFetchedE1 sections] objectAtIndex:0];
			section0Rows_ = [sectionInfo numberOfObjects];
		}
		[self.tableView reloadData];
	}
	@catch (NSException *exception) {
		//NSLog(@"refetcheAllData: ERROR: exception: %@:%@", [exception name], [exception reason]);
		GA_TRACK_ERROR([exception description]);
	}
}

- (void)refreshAllViews:(NSNotification*)note 
{	// iCloud-CoreData に変更があれば呼び出される
	NSUbiquitousKeyValueStore *kvs = [NSUbiquitousKeyValueStore defaultStore];
	//[kvs synchronize]; <<<変化通知により同期済みであるから不要
	if (appDelegate_.ppPaid_SwitchAd==NO  &&  [kvs boolForKey:STORE_PRODUCTID_AdOff]) 
	{	// iCloud OFF --> ON
		appDelegate_.ppPaid_SwitchAd = YES;
		//[appDelegate_ managedObjectContextReset]; // iCloud対応の moc再生成する。
//		appDelegate_.ppOptShowAd = NO;
		[kvs setBool:NO forKey:KV_OptAdvertising];
		[appDelegate_ AdRefresh:NO];
	}
	
	//moc_ = [EntityRelation getMoc]; //購入後、再生成された場合のため
	mMoc = [[MocFunctions sharedMocFunctions] getMoc];
	contentOffsetDidSelect_.y = 0;  // 直前のdidSelectRowAtIndexPath位置に戻らないようにクリアしておく
	[self viewWillAppear:YES];	//この中で、refetcheAllData:が呼ばれる
	[appDelegate_ AdViewWillRotate:self.interfaceOrientation];	// AdOFF-->ONのとき回転補正が必要
}

- (void)deleteBlankData
{	//[1.0.1]末尾の「新しい・・」空レコードがあれば削除する
	id <NSFetchedResultsSectionInfo> sectionInfo = [[mFetchedE1 sections] objectAtIndex:0];
	BOOL bRefetch = NO;
	NSArray *arE1 = [sectionInfo objects];
	if (0 < [arE1 count]) {
		E1 *e1last = [arE1 lastObject];
		if (0 < [e1last.childs count]) {
			//NSArray *arE2 = [e1last.childs allObjects];
			for (E2 *e2 in [e1last.childs allObjects]) {
				if (0 < [e2.childs count]) {
					//NSArray *arE3 = [e2.childs allObjects];
					for (E3 *e3 in [e2.childs allObjects]) {
						//NSLog(@"name=%@ note=%@ stock=%d need=%d weight=%d", e3.name, e3.note,
						//	  [e3.stock integerValue], [e3.need integerValue], [e3.weight integerValue]);
						if ([e3.name length]<=0 && [e3.note length]<=0
							&& [e3.stock integerValue]<=0
							&& [e3.need integerValue]==(-1)		//(-1)Add行なら削除。 [SAVE]押せば少なくとも(0)になる
							&& [e3.weight integerValue]<=0
							) {
							// 「新しいアイテム」かつ「未編集」 なので削除する
							e3.parent = nil; // e2とのリンクを切る
							[mMoc deleteObject:e3];
							bRefetch = YES;
						}
					}
				}
				//NSLog(@"e2.name=[%@]  e2.childs=[%@]", e2.name, e2.childs);
				if ([e2.name length]<=0 && [e2.childs count]<=0) {
					//配下E3なし & 「新しいグループ」 なので削除する
					e2.parent = nil; // e1とのリンクを切る
					[mMoc deleteObject:e2];
					bRefetch = YES;
				}
			}
		}
		if ([e1last.name length]<=0 && [e1last.childs count]<=0) {
			//配下E2なし & 「新しいプラン」 なので削除する
			[mMoc deleteObject:e1last];
			bRefetch = YES;
		}
		if (bRefetch) {
			NSError *error = nil;
			if (![mMoc save:&error]) {
				NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			}
			error = nil;
			if (![mFetchedE1 performFetch:&error]) {
				NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
				return; //exit(-1);  // Fail
			}
			id <NSFetchedResultsSectionInfo> sectionInfo = [[mFetchedE1 sections] objectAtIndex:0];
			section0Rows_ = [sectionInfo numberOfObjects];
			// 再描画
			[self.tableView reloadData];
		}
	}
}


#pragma mark - Action

//- (void)actionE1deleteCell:(NSIndexPath*)indexPath
- (void)actionE1deleteCell:(NSUInteger)uiRow
{
	// ＜注意＞ 選択行は、[self.tableView indexPathForSelectedRow] では得られない！didSelect直後に選択解除しているため。
	//         そのため、pppIndexPathActionDelete を使っている。
	// ＜注意＞ CoreDataモデルは、エンティティ間の削除ルールは双方「無効にする」を指定。（他にするとフリーズ）
	// 削除対象の ManagedObject をチョイス
	NSLog(@"actionE1deleteCell: fetchedE1_=%@", mFetchedE1);
	NSLog(@"uiRow=%ld", (long)uiRow);
	NSIndexPath *ixp = [NSIndexPath indexPathForRow:uiRow inSection:0];
	E1 *e1objDelete = [mFetchedE1 objectAtIndexPath:ixp];
	// CoreDataモデル：削除ルール「無効にする」につき末端ノードより独自に削除する
	for (E2 *e2obj in [e1objDelete.childs allObjects]) {
		for (E3 *e3obj in [e2obj.childs allObjects]) {
			[mMoc deleteObject:e3obj];
		}
		[mMoc deleteObject:e2obj];
	}
	// 注意！performFetchするまで RrFetchedE1 は不変、削除もされていない！
	// 削除行の次の行以下 E1.row 更新
	for (NSUInteger i= uiRow + 1 ; i < section0Rows_ ; i++) {  // .row + 1 削除行の次から
		ixp = [NSIndexPath indexPathForRow:i inSection:0];
		E1 *e1obj = [mFetchedE1 objectAtIndexPath:ixp];
		e1obj.row = [NSNumber numberWithInteger:i-1];     // .row--; とする
	}
	// E1 削除
	[mMoc deleteObject:e1objDelete];
	section0Rows_--; // この削除により1つ減
	// SAVE　＜＜万一システム障害で落ちてもデータが残るようにコマメに保存する方針＞＞
	NSError *error = nil;
	if (![mMoc save:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		exit(-1);  // Fail
	}
	// 上で並び替えられた結果を再フィッチする（performFetch）  コンテキスト変更したときは再抽出する
	//NSError *error = nil;
	if (![mFetchedE1 performFetch:&error]) {
		NSLog(@"%@", error);
		exit(-1);  // Fail
	}
	// テーブルビューから選択した行を削除します。
	// ＜高速化＞　改めて削除後のE1レコード数（行数）を求める
	section0Rows_ = 0;
	if (0 < [[mFetchedE1 sections] count]) {
		id <NSFetchedResultsSectionInfo> sectionInfo = [[mFetchedE1 sections] objectAtIndex:0];
		section0Rows_ = [sectionInfo numberOfObjects];
	}
	[self.tableView reloadData];
}

- (void)actionImportSharedPackList
{
	if (appDelegate_.ppIsPad) {
		if ([popOver_ isPopoverVisible]) return; //[1.0.6-Bug01]同時タッチで落ちる⇒既に開いておれば拒否
	}
	
	SpSearchVC *vc = [[SpSearchVC alloc] init];
	
	if (appDelegate_.ppIsPad) {
	/*	popOver_ = nil;
		UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:vc];
		popOver_ = [[UIPopoverController alloc] initWithContentViewController:nc];
		popOver_.delegate = self;	// popoverControllerDidDismissPopover:を呼び出してもらうため
		indexPathEdit_ = nil;
		NSIndexPath *idx = [NSIndexPath indexPathForRow:0 inSection:1];  //<<<<< Shared PackList セル位置をセット
		CGRect rcArrow = [self.tableView rectForRowAtIndexPath:idx];
		rcArrow.origin.x = 150;		rcArrow.size.width = 1;
		rcArrow.origin.y += 10;	rcArrow.size.height -= 20;
		[popOver_ presentPopoverFromRect:rcArrow  inView:self.view
				permittedArrowDirections:UIPopoverArrowDirectionLeft  animated:YES];*/
		
		UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:vc];
		nc.modalPresentationStyle = UIModalPresentationFormSheet;
		nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;  //UIModalTransitionStyleCrossDissolve;
		[self presentViewController:nc animated:YES completion:nil];
	}
	else {
//		if (appDelegate_.ppOptShowAd) {
//			[appDelegate_ AdRefresh:NO];	//広告禁止
//		}
		[vc setHidesBottomBarWhenPushed:YES]; // 現在のToolBar状態をPushした上で、次画面では非表示にする
		[self.navigationController pushViewController:vc animated:YES];
	}
}

- (void)actionImportDropbox
{
//	AZDropboxVC *vc = [[AZDropboxVC alloc] initWithAppKey:DBOX_APPKEY 
//												appSecret: DBOX_SECRET
//													 root: kDBRootAppFolder
//												 rootPath: @"/" 
//													 mode: AZDropboxDownload 
//												extension: GD_EXTENSION 
//												 delegate: appDelegate_];
//	assert(vc);
//	if (appDelegate_.ppIsPad) {
//		UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:vc];
//		nc.modalPresentationStyle = UIModalPresentationFormSheet;
//		nc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
//		[self presentViewController:nc animated:YES completion:nil];
//	}
//	else {
//		if (appDelegate_.ppOptShowAd) {
//			[appDelegate_ AdRefresh:NO];	//広告禁止
//		}
//		[vc setHidesBottomBarWhenPushed:YES]; // 現在のToolBar状態をPushした上で、次画面では非表示にする
//		[self.navigationController pushViewController:vc animated:YES];
//	}

/*	// 未認証の場合、認証処理後、AppDelegate:handleOpenURL:から呼び出される
	if ([[DBSession sharedSession] isLinked]) 
	{	// Dropbox 認証済み
		//DropboxVC *vc = [[DropboxVC alloc] initWithE1:nil];  // nil=Download
		//AZDropboxVC *vc = [[AZDropboxVC alloc] initWithMode:AZDropboxDownload
		//										  extension:GD_EXTENSION delegate:appDelegate_];
	}
	else {
		// Dropbox 未認証
		appDelegate_.dropboxSaveE1selected = nil;	// 取込専用
		//[[DBSession sharedSession] link];
	}*/
}

- (void)actionImportGoogle
{
//	GDocDownloadTVC *vc = [[GDocDownloadTVC alloc] init];
//
//	if (appDelegate_.ppIsPad) {
//		UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:vc];
//		nc.modalPresentationStyle = UIModalPresentationFormSheet;
//		nc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
//		[self presentViewController:nc animated:YES completion:nil];
//		// Download成功後の再描画は、NFM_REFRESH_ALL_VIEWS 通知により処理される
//	} 
//	else {
//		if (appDelegate_.ppOptShowAd) {
//			[appDelegate_ AdRefresh:NO];	//広告禁止
//		}
//		[vc setHidesBottomBarWhenPushed:YES]; // 現在のToolBar状態をPushした上で、次画面では非表示にする
//		vc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
//		[self.navigationController pushViewController:vc animated:YES];
//	}
}

/*[2.0]廃止
- (void)actionImportYourPC
{
	if (appDelegate_.app_is_iPad) {
		if ([popOver_ isPopoverVisible]) return; //[1.0.6-Bug01]同時タッチで落ちる⇒既に開いておれば拒否
	}
	if (appDelegate_.app_opt_Ad) {
		[appDelegate_ AdRefresh:NO];	//広告禁止
	}
	// HTTP Server Start
	if (alertHttpServer_ == nil) {
		alertHttpServer_ = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"HttpSv RESTORE", nil) 
													  message:NSLocalizedString(@"HttpSv Wait", nil) 
													 delegate:self 
											cancelButtonTitle:nil  //@"CANCEL" 
											otherButtonTitles:NSLocalizedString(@"HttpSv stop", nil) , nil];
	}
	alertHttpServer_.tag = ALERT_TAG_HTTPServerStop;
	[alertHttpServer_ show];
	//[MalertHttpServer release];
	// if (httpServer) return; <<< didSelectRowAtIndexPath:直後に配置してダブルクリック回避している。
	NSString *root = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
	httpServer_ = [HTTPServer new];
	[httpServer_ setType:@"_http._tcp."];
	[httpServer_ setConnectionClass:[MyHTTPConnection class]];
	[httpServer_ setDocumentRoot:[NSURL fileURLWithPath:root]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(httpInfoUpdate:) name:@"LocalhostAdressesResolved" object:nil];
	[localhostAddresses performSelectorInBackground:@selector(list) withObject:nil];
	[httpServer_ setPort:8080];
	[httpServer_ setBackup:NO]; // RESTORE Mode
	[httpServer_ setManagedObjectContext:moc_];
	[httpServer_ setAddRow:section0Rows_];
	NSError *error;
	if(![httpServer_ start:&error])
	{
		NSLog(@"Error starting HTTP Server: %@", error);
		//[RhttpServer release];
		httpServer_ = nil;
	}
	// Upload成功後、CSV LOAD する  ＜＜連続リストアできるように httpResponseForMethod 内で処理＞＞
}

- (void)actionImportPasteBoard
{
	if (appDelegate_.app_is_iPad) {
		if ([popOver_ isPopoverVisible]) return; //[1.0.6-Bug01]同時タッチで落ちる⇒既に開いておれば拒否
	}
	// ヘッダーチェック
	if ([[UIPasteboard generalPasteboard].string hasPrefix:GD_CSV_HEADER_ID]==NO) {
		if ([[UIPasteboard generalPasteboard].string hasPrefix:CRYPT_HEADER]==NO) {
			UIAlertView *alert = [[UIAlertView alloc] 
								  initWithTitle:NSLocalizedString(@"PBoard Paste NG1",nil)
								  message:nil //NSLocalizedString(@"PBoard Paste NG1",nil)
								  delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
			[alert show];
			return;
		}
	}
	// ペーストボードから取り込んで追加する
	UIAlertView *alert = [[UIAlertView alloc] init];
	alert.title = NSLocalizedString(@"Please Wait",nil);
	[alert show];
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(queue, ^{
		FileCsv *fcsv = [[FileCsv alloc] init];
		NSString *zErr = [fcsv zLoadPasteboard];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[alert dismissWithClickedButtonIndex:0 animated:NO]; // 閉じる
			if (zErr==nil) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"PBoard Paste",nil)
												   message:NSLocalizedString(@"PBoard Paste OK",nil)
												  delegate:nil 
										 cancelButtonTitle:nil 
										 otherButtonTitles:@"OK", nil];
				[alert show];
				// 再表示
				[self viewWillAppear:YES]; // Fech データセットさせるため
			}
			else {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"PBoard Error",nil)
												   message: zErr
												  delegate:nil 
										 cancelButtonTitle:nil 
										 otherButtonTitles:@"OK", nil];
				[alert show];
			}
		});
	});
}
*/

- (void)actionInformation
{
/*	AZInformationVC *vc = [[AZInformationVC alloc] init];

	if (appDelegate_.app_is_iPad) {
		UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:vc];
		nc.modalPresentationStyle = UIModalPresentationFormSheet;
		nc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		[self presentViewController:nc animated:YES completion:nil];
	}
	else {
		if (appDelegate_.app_opt_Ad) {
			// 各viewDidAppear:にて「許可/禁止」を設定する
			[appDelegate_ AdRefresh:NO];	//広告禁止
		}
		[vc setHidesBottomBarWhenPushed:YES]; // 現在のToolBar状態をPushした上で、次画面では非表示にする
		[self.navigationController pushViewController:vc animated:YES];
	}*/
	
	// このアプリについて
	AZAboutVC *vc = [[AZAboutVC alloc] init];
	vc.ppImgIcon = [UIImage imageNamed:@"About_Icon57Round"];
	vc.ppProductTitle = NSLocalizedString(@"Product Title",nil);
	vc.ppProductSubtitle = @"PackList  (.azp)";
	vc.ppSupportSite = @"http://packlist.azukid.com/";
	vc.ppCopyright = COPYRIGHT;
	vc.ppAuthor = @"Sum Positive";
	//vc.hidesBottomBarWhenPushed = YES; //以降のタブバーを消す
	//[self.navigationController pushViewController:vc animated:YES];
	if (appDelegate_.ppIsPad) {
		UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:vc];
		nc.modalPresentationStyle = UIModalPresentationFormSheet; // iPad画面1/4サイズ
		nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
		[self presentViewController:nc animated:YES completion:nil];
	} else {
//		if (appDelegate_.ppOptShowAd) {	// 各viewDidAppear:にて「許可/禁止」を設定する
//			[appDelegate_ AdRefresh:NO];	//広告禁止
//		}
		[vc setHidesBottomBarWhenPushed:YES]; // 現在のToolBar状態をPushした上で、次画面では非表示にする
		[self.navigationController pushViewController:vc animated:YES];
	}
}

- (void)actionSetting
{
	SettingTVC *vc = [[SettingTVC alloc] init];
	
	if (appDelegate_.ppIsPad) {
		UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:vc];
		nc.modalPresentationStyle = UIModalPresentationFormSheet;
		nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
		[self presentViewController:nc animated:YES completion:nil];
	}
	else {
//		if (appDelegate_.ppOptShowAd) {
//			// 各viewDidAppear:にて「許可/禁止」を設定する
//			[appDelegate_ AdRefresh:NO];	//広告禁止
//		}
		[vc setHidesBottomBarWhenPushed:YES]; // 現在のToolBar状態をPushした上で、次画面では非表示にする
		[self.navigationController pushViewController:vc animated:YES];
	}
}

- (void)actionAZStore
{
	// あずき商店
	AZStoreTVC *vc = [[AZStoreTVC alloc] init];
	// 商品IDリスト
	NSSet *pids = [NSSet setWithObjects:STORE_PRODUCTID_AdOff, nil]; // 商品が複数ある場合は列記
	[vc setProductIDs:pids];
	[vc	setGiftDetail:NSLocalizedString(@"STORE GiftDetail", nil)
			productID:STORE_PRODUCTID_AdOff
			secretKey:@"1615AzPackList"]; //[1.2]にあるsecretKeyに一致すること
	
	// クラッキング対策：非消費型でもレシートチェックが必要になった。
	// [Manage In-App Purchase]-[View or generate a shared secret]-[Generate]から取得した文字列をセットする
	vc.ppSharedSecret = @"062e76976c5a468a82bda70683326208";
	
	if (appDelegate_.ppIsPad) {
		UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:vc];
		nc.modalPresentationStyle = UIModalPresentationFormSheet;
		nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
		[self presentViewController:nc animated:YES completion:nil];
	}
	else {
//		if (appDelegate_.ppOptShowAd) {
//			// 各viewDidAppear:にて「許可/禁止」を設定する
//			[appDelegate_ AdRefresh:NO];	//広告禁止
//		}
		[vc setHidesBottomBarWhenPushed:YES]; // 現在のToolBar状態をPushした上で、次画面では非表示にする
		[self.navigationController pushViewController:vc animated:YES];
	}
}

- (void)actionCloudReset
{
	GA_TRACK_METHOD
	
#ifdef xxxxxxxxxxxxxxxx
	[[MocFunctions sharedMocFunctions] stopRelease];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *cloudURL = [fileManager URLForUbiquityContainerIdentifier:nil];
	NSString *file = nil;
	NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:[cloudURL path]];
	while (file = [enumerator nextObject]) {
		[fileManager removeItemAtPath:file error:nil];
		NSLog(@"iCloud Removed %@", file);
	}
	// MOC 初期生成
	[[MocFunctions sharedMocFunctions] start];
#else
	// iCloud Stack Clear
	[[MocFunctions sharedMocFunctions] iCloudAllClear];
#endif
	[self refetcheAllData];
}


#pragma mark - <AZStoreDelegate>
- (void)azStorePurchesed:(NSString*)productID
{	//既に呼び出し元にて、[userDefaults setBool:YES  forKey:productID]　登録済み
	GA_TRACK_EVENT(@"AZStore", @"azStorePurchesed", productID,1);
	if ([productID isEqualToString:STORE_PRODUCTID_AdOff]) {
		appDelegate_.ppPaid_SwitchAd = YES; //広告スイッチ 購入済み
		NSUbiquitousKeyValueStore *kvs = [NSUbiquitousKeyValueStore defaultStore];
		[kvs setBool:YES  forKey: STORE_PRODUCTID_AdOff];
		[kvs synchronize];
		// 再フィッチ＆画面リフレッシュ通知  ＜＜＜＜ E1viewController:refetcheAllData: にて iCloud OFF --> ON している。
		[[NSNotificationCenter defaultCenter] postNotificationName: NFM_REFRESH_ALL_VIEWS
															object:self userInfo:nil];
	}
}


- (void)toE2fromE1:(E1*)e1obj  withIndex:(NSIndexPath *)indexPath 
{	// 次回の画面復帰のための状態記録
	
	// E2 へドリルダウン
	E2viewController *e2view = [[E2viewController alloc] init];

	if (appDelegate_.ppIsPad) {
		e2view.title = NSLocalizedString(@"Product Title",nil);
	} else {
		if ([e1obj.name length]<=0) {
			e2view.title = NSLocalizedString(@"(New Pack)", nil);
		} else {
			e2view.title = e1obj.name;
		}
	}
	
	e2view.e1selected = e1obj;
	e2view.sharePlanList = NO;
	
	if (appDelegate_.ppIsPad) {
		//Split Right
		E3viewController* e3view = [[E3viewController alloc] init];
		// 以下は、E3viewControllerの viewDidLoad 後！、viewWillAppear の前に処理されることに注意！
		//e3view.title = e1obj.name;  //  self.title;  // NSLocalizedString(@"Items", nil);
		e3view.e1selected = e1obj; // E1
		e3view.firstSection = 0;
		e3view.sortType = (-1);
		e3view.sharePlanList = NO;
        
        //[0]Left  GROUP:e2view
        e2view.delegateE3viewController = e3view;		// E2からE3を更新するため
        //[[appDelegate_.mainSVC.viewControllers objectAtIndex:0] pushViewController:e2view animated:YES];
        AzNavigationController *leftNvc = appDelegate_.mainSVC.viewControllers.firstObject;
        //leftNvc.modalTransitionStyle = UIModalTransitionStylePartialCurl;
        [leftNvc pushViewController:e2view animated:YES];
        
		//[1]Right  ITEM:e3view
		//[[appDelegate_.mainSVC.viewControllers objectAtIndex:1] pushViewController:e3view animated:YES];
        AzNavigationController *rightNvc = appDelegate_.mainSVC.viewControllers[1];
        [rightNvc pushViewController:e3view animated:YES];
        
		//[e3view release];
	} else {
		[self.navigationController pushViewController:e2view animated:YES];
	}
	
	//[e2view release];
}

- (void)e1add 
{
	// ContextにE1ノードを追加する　E1edit内でCANCELならば削除している
	//E1 *e1newObj = [NSEntityDescription insertNewObjectForEntityForName:@"E1" inManagedObjectContext:moc_];
	E1 *e1newObj = [[MocFunctions sharedMocFunctions] insertAutoEntity:@"E1"];
	//[1.0.1]「新しい・・方式」として名称未定のまま先に進めるようにした
	e1newObj.name = nil; //(未定)  NSLocalizedString(@"New Pack",nil);
	e1newObj.row = [NSNumber numberWithInteger:section0Rows_]; // 末尾に追加：行番号(row) ＝ 現在の行数 ＝ 現在の最大行番号＋1
	
	//[1.0.3]E1新規追加と同時にE2にも1レコード追加する。空のまま戻れば、viewWillAppearにて削除される
	//[1.0.3]特にPADの場合、タテにするとE1の次にE3が表示されるので、新しい目次が少なくとも1つ必要になる。
	//E2 *e2newObj = [NSEntityDescription insertNewObjectForEntityForName:@"E2" inManagedObjectContext:moc_];
	E2 *e2newObj = [[MocFunctions sharedMocFunctions] insertAutoEntity:@"E2"];
	e2newObj.row = [NSNumber numberWithInt:0];
	e2newObj.name = nil; //(未定)
	e2newObj.parent = e1newObj; // 親子リンク
	
	// SAVE
	if ([[MocFunctions sharedMocFunctions] commit]==NO) return;
	// E2:Groupへ
	NSIndexPath* ip = [NSIndexPath indexPathForRow:[e1newObj.row integerValue]  inSection:0];
	[self toE2fromE1:e1newObj withIndex:ip]; // 次回の画面復帰のための状態記録をしてからＥ２へドリルダウンする
}


// E1edit View Call
- (void)e1editView:(NSIndexPath *)indexPath
{
	if (section0Rows_ <= indexPath.row) return;  // Addボタン行などの場合パスする

	if (appDelegate_.ppIsPad) {
		if ([popOver_ isPopoverVisible]) return; //[1.0.6-Bug01]同時タッチで落ちる⇒既に開いておれば拒否
	}
	
	// E1 : NSManagedObject
	E1 *e1obj = [mFetchedE1 objectAtIndexPath:indexPath];
	
	e1editView_ = [[E1edit alloc] init]; // popViewで戻れば解放されているため、毎回alloc必要。
	e1editView_.title = NSLocalizedString(@"Edit Plan",nil);
	e1editView_.e1target = e1obj;
	e1editView_.addRow = (-1); // Edit mode.
	
	if (appDelegate_.ppIsPad) {
		//[Mpopover release], 
		popOver_ = nil;
		//Mpopover = [[PadPopoverInNaviCon alloc] initWithContentViewController:Me1editView];
		UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:e1editView_];
		popOver_ = [[UIPopoverController alloc] initWithContentViewController:nc];
	//	[nc release];
		popOver_.delegate = self;	// popoverControllerDidDismissPopover:を呼び出してもらうため
		//MindexPathEdit = indexPath;
		//[MindexPathEdit release], 
		indexPathEdit_ = [indexPath copy];
		CGRect rc = [self.tableView rectForRowAtIndexPath:indexPath];
		rc.origin.x = rc.size.width - 65;	rc.size.width = 1;
		rc.origin.y += 10;	rc.size.height -= 20;
		[popOver_ presentPopoverFromRect:rc
								  inView:self.view  permittedArrowDirections:UIPopoverArrowDirectionRight  animated:YES];
		e1editView_.selfPopover = popOver_;  //[Mpopover release]; //(retain)  内から閉じるときに必要になる
		//e1editView_.delegate = self;		// refresh callback
	}
	else {
		[e1editView_ setHidesBottomBarWhenPushed:YES]; // 現在のToolBar状態をPushした上で、次画面では非表示にする
		[self.navigationController pushViewController:e1editView_ animated:YES];
	}
	//[Me1editView release]; // self.navigationControllerがOwnerになる
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (alertView.tag) {
		case ALERT_TAG_HTTPServerStop:
//			[mHttpServer stop];
//			//[RhttpServer release];
//			mHttpServer = nil;
//			[[NSNotificationCenter defaultCenter] removeObserver:self name:@"LocalhostAdressesResolved" object:nil];
//			// 再表示
//			//[self.tableView reloadData]; これだけではダメ
//			[self viewWillAppear:YES]; // Fech データセットさせるため
			break;
			
		case ALERT_TAG_SupportSite:
			if (buttonIndex == 1) { // OK
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://packlist.tumblr.com/"]];
			}
			break;

		case ALERT_TAG_DELETEPACK: // E1削除
			if (buttonIndex == 1) //OK 
			{	//========== E1 削除実行 ==========
				NSLog(@"MactionDeleteRow=%ld", (long)actionDeleteRow_);
				[self actionE1deleteCell:actionDeleteRow_];
			}
			break;
		case ALERT_TAG_CloudReset:
			[self actionCloudReset];
			break;
	}
}


// UIActionSheetDelegate 処理部
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// buttonIndexは、actionSheetの上から順に(0〜)付与されるようだ。
	switch (actionSheet.tag) {
		case ACTIONSEET_TAG_DELETEPACK: // E1削除
			if (buttonIndex == actionSheet.destructiveButtonIndex) 
			{	//========== E1 削除実行 ==========
				NSLog(@"MactionDeleteRow=%ld", (long)actionDeleteRow_);
				[self actionE1deleteCell:actionDeleteRow_];
			}
			break;
			
/*		case ACTIONSEET_TAG_MENU:
			switch (buttonIndex) {
				case 0: // SharePlan Search
					[self	actionImportSharedPackList];
					break;
					
				case 1: // Restore from Google
					[self actionImportGoogle];
					break;
					
				case 2: // Restore from YourPC
					[self actionImportYourPC];
					break;
					
				case 3: // PasteBoard
					[self actionImportPasteBoard];
					break;
			}
			break;*/
	}
}

// HTTP Server Address Display
- (void)httpInfoUpdate:(NSNotification *) notification
{
	NSLog(@"httpInfoUpdate:");
	
	if(notification)
	{
		//[MdicAddresses release], 
		mAddressDic = nil;
		mAddressDic = [[notification object] copy];
		NSLog(@"MdicAddresses: %@", mAddressDic);
	}
	
	if(mAddressDic == nil)
	{
		return;
	}
	
//	NSString *info;
//	UInt16 port = [mHttpServer port];
//	
//	NSString *localIP = nil;
//	localIP = [mAddressDic objectForKey:@"en0"];
//	if (!localIP)
//	{
//		localIP = [mAddressDic objectForKey:@"en1"];
//	}
//	
//	if (!localIP)
//		info = NSLocalizedString(@"HttpSv NoConnection", nil);
//	else
//		info = [NSString stringWithFormat:@"%@\n\nhttp://%@:%d", 
//				NSLocalizedString(@"HttpSv Addr", nil), localIP, port];
//	
//	/*	NSString *wwwIP = [addresses objectForKey:@"www"];
//	 if (wwwIP)
//	 info = [info stringByAppendingFormat:@"Web: %@:%d\n", wwwIP, port];
//	 else
//	 info = [info stringByAppendingString:@"Web: Unable to determine external IP\n"]; */
//	
//	//displayInfo.text = info;
//	if (mHttpServerAlert) {
//		mHttpServerAlert.message = info;
//		[mHttpServerAlert show];
//	}
}


#pragma mark - View lifestyle

// UITableViewインスタンス生成時のイニシャライザ　viewDidLoadより先に1度だけ通る
- (id)initWithStyle:(UITableViewStyle)style 
{
	self = [super initWithStyle:UITableViewStyleGrouped];  // セクションあり
	if (self) {
		// 初期化成功
		appDelegate_ = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		e1editView_ = nil;		// e1addで生成 [self.navigationController pushViewController:]
		//informationView_ = nil; // azInformationViewで生成 [self.view.window addSubview:]
		
		// 背景テクスチャ・タイルペイント
	/*	if (appDelegate_.ppIsPad){
			//self.view.backgroundColor = //iPadでは無効になったため
			UIView* view = self.tableView.backgroundView;
			if (view) {
				PatternImageView *tv = [[PatternImageView alloc] initWithFrame:view.frame
																  patternImage:[UIImage imageNamed:@"Tx-Back"]]; // タイルパターン生成
				[view addSubview:tv];
			}
		} else {
			self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Tx-Back"]];
		}*/
		
		[self.tableView setBackgroundView:nil];	//iOS6//これで次行が有効になる。
		self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Tx-Back"]];

		// インストールやアップデート後、1度だけ処理する
		NSString *zNew = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]; //（リリース バージョン）は、ユーザーに公開した時のレベルを表現したバージョン表記
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSString* zDef = [defaults valueForKey:UD_CurrentVersion];
		if (zDef==nil || ![zDef isEqualToString:zNew]) {
			[defaults setValue:zNew forKey:UD_CurrentVersion];
			bInformationOpen_ = YES; // Informationを自動オープンする
		} else {
			bInformationOpen_ = NO;
		}
	}
	return self;
}

// IBを使わずにviewオブジェクトをプログラム上でcreateするときに使う
//（viewDidLoadは、nibファイルでロードされたオブジェクトを初期化するために使う）
- (void)loadView
{	//【Tips】ここでaddSubviewするオブジェクトは全てautoreleaseにすること。メモリ不足時には自動的に解放後、改めてここを通るので、初回同様に生成するだけ。
	[super loadView];
	
	// Set up NEXT Left [Back] buttons.
	self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]
											  initWithTitle:@"Top"   //NSLocalizedString(@"Back", nil)
											  style:UIBarButtonItemStylePlain
											  target:nil  action:nil];
	
	// Set up Right [Edit] buttons.
#ifdef AzMAKE_SPLASHFACE
	// No Button 国別で文字が変わるため
	UIActivityIndicatorView *actInd = [[UIActivityIndicatorView alloc]
										initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	CGRect rc = self.navigationController.view.frame;
	actInd.frame = CGRectMake((rc.size.width-50)/2, (rc.size.height-50)/2, 50, 50);
	[self.navigationController.view addSubview:actInd];
	[actInd startAnimating];
#else
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	self.tableView.allowsSelectionDuringEditing = YES; // 編集モードに入ってる間にユーザがセルを選択できる
#endif	
	
//	if (appDelegate_.ppOptShowAd) {
//		UIImageView* iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Icon24-Free.png"]];
//		UIBarButtonItem* bui = [[UIBarButtonItem alloc] initWithCustomView:iv];
//		self.navigationItem.leftBarButtonItem	= bui;
//	}

	// ToolBar表示は、viewWillAppearにて回転方向により制御している。
}

- (void)viewDidLoad 
{ //iCloud
	[super viewDidLoad];

//    [self.tableView setBackgroundView:nil];	//iOS6//これで次行が有効になる。
//    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Tx-Back"]];
//
//    // Set up NEXT Left [Back] buttons.
//    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]
//                                             initWithTitle:@"Top"   //NSLocalizedString(@"Back", nil)
//                                             style:UIBarButtonItemStylePlain
//                                             target:nil  action:nil];
//
//    if (appDelegate_.ppIsPad) {
//        // CANCELボタンを左側に追加する  Navi標準の戻るボタンでは cancel:処理ができないため
//        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
//                                                 initWithTitle:NSLocalizedString(@"Back", nil)
//                                                 style:UIBarButtonItemStylePlain
//                                                 target:self action:@selector(actionBack:)];
//    }
//
//    // Set up Right [Edit] buttons.
//#ifdef AzMAKE_SPLASHFACE
//    // No Button 国別で文字が変わるため
//    UIActivityIndicatorView *actInd = [[UIActivityIndicatorView alloc]
//                                       initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
//    CGRect rc = self.navigationController.view.frame;
//    actInd.frame = CGRectMake((rc.size.width-50)/2, (rc.size.height-50)/2, 50, 50);
//    [self.navigationController.view addSubview:actInd];
//    [actInd startAnimating];
//#else
//    self.navigationItem.rightBarButtonItem = self.editButtonItem;
//    self.tableView.allowsSelectionDuringEditing = YES; // 編集モードに入ってる間にユーザがセルを選択できる
//#endif

	/*** NFM_REFRESH_ALL_VIEWS に一元化
	// observe the app delegate telling us when it's finished asynchronously setting up the persistent store
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refetcheAllData:)
												 name:NFM_REFETCH_ALL_DATA
											   object:nil];  //=nil: 全てのオブジェクトからの通知を受ける　*/
	
	// listen to our app delegates notification that we might want to refresh our detail view
    [[NSNotificationCenter defaultCenter] addObserver:self			// viewDidUnload:にて removeObserver:必須
											 selector:@selector(refreshAllViews:) 
												 name:NFM_REFRESH_ALL_VIEWS
											   object:nil];  //=nil: 全てのオブジェクトからの通知を受ける
}
- (void)actionBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated 
{
	[super viewWillAppear:animated];

	// 画面表示に関係する Option Setting を取得する
	//NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSUbiquitousKeyValueStore *kvs = [NSUbiquitousKeyValueStore defaultStore];
	//[kvs synchronize]; <<<変化通知により同期済みであるから不要
	bOptWeightRound_ = [kvs boolForKey:KV_OptWeightRound]; // YES=四捨五入 NO=切り捨て
	bOptShowTotalWeight_ = [kvs boolForKey:KV_OptShowTotalWeight];
	bOptShowTotalWeightReq_ = [kvs boolForKey:KV_OptShowTotalWeightReq];
	
	self.title = NSLocalizedString(@"Product Title",nil);
	
	if (mMoc==nil) {
		mMoc = [[MocFunctions sharedMocFunctions] getMoc];
	}
	
	// CoreData 読み込み
	[self refetcheAllData];	//この中で処理済み [self.tableView reloadData];
	// この後、viewDidAppear:にて[self deleteBlankData];によりE3クリーン処理している。
	
	if (0 < contentOffsetDidSelect_.y) {
		// app.Me3dateUse=nil のときや、メモリ不足発生時に元の位置に戻すための処理。
		// McontentOffsetDidSelect は、didSelectRowAtIndexPath にて記録している。
		self.tableView.contentOffset = contentOffsetDidSelect_;
	}
}

// ビューが最後まで描画された後やアニメーションが終了した後にこの処理が呼ばれる
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	
	[self.navigationController setToolbarHidden:YES animated:NO]; //[2.0.2]ツールバー廃止
/*	if (appDelegate_.app_is_iPad) {
		[self.navigationController setToolbarHidden:NO animated:animated]; // ツールバー表示する
	} else {
		[self.navigationController setToolbarHidden:YES animated:animated]; // ツールバー消す
	}*/

	[self.tableView flashScrollIndicators]; // Apple基準：スクロールバーを点滅させる
	
	//【Tips】タテから始まるとき、willRotateToInterfaceOrientation:を通らずに、ここを通る　⇒ AdRefresh：にて初期タテ配置となる
	//【Tips】ヨコから始まるとき、ここよりもloadView：よりも先に willRotateToInterfaceOrientation: を通る ⇒ willRotateにてヨコ配置となる
//	[appDelegate_ AdRefresh:appDelegate_.ppOptShowAd];	//広告
//	[appDelegate_ AdViewWillRotate:self.interfaceOrientation];

	// アップデート直後、1回だけInformation表示する
	if (bInformationOpen_) {	//initWithStyleにて判定処理している
		bInformationOpen_ = NO;	// 以後、自動初期表示しない。
		[self actionInformation];  //[1.0.2]最初に表示する。バックグランド復帰時には通らない
	}
	
	// viewWillAppear:だと「リフレッシュ通知」で呼び出されるため、E1が表示されている、ここでE3クリーン処理する。
	[self deleteBlankData];	// refetcheAllDataの後、E3に有効レコードが無ければ削除する。E2,E1も遡って配下が無ければ削除する。
}

// この画面が非表示になる直前に呼ばれる
- (void)viewWillDisappear:(BOOL)animated 
{
	if (appDelegate_.ppIsPad) {
		if ([popOver_ isPopoverVisible]) { //[1.0.6-Bug01]戻る同時タッチで落ちる⇒強制的に閉じるようにした。
			[popOver_ dismissPopoverAnimated:animated];
		}
	}
	
	[super viewWillDisappear:animated];
}


#pragma mark  View 回転

//---------------------------------------------------------------------------回転
// YES を返すと、回転と同時に willRotateToInterfaceOrientation が呼び出され、
//				回転後に didRotateFromInterfaceOrientation が呼び出される。
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if (appDelegate_.ppIsPad) {
		return YES;	// FormSheet窓対応
	}
	else if (appDelegate_.ppOptAutorotate==NO) {	// 回転禁止にしている場合
		return (interfaceOrientation == UIInterfaceOrientationPortrait); // 正面（ホームボタンが画面の下側にある状態）のみ許可
	}
    return YES;
}

// shouldAutorotateToInterfaceOrientation で YES を返すと、回転開始時に呼び出される
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation 
													duration:(NSTimeInterval)duration
{
/*	if (appDelegate_.app_is_iPad) {
		MbuInfo.enabled = YES;
	} else {
		// InformationViewボタン：正面のときだけ有効にする
		MbuInfo.enabled = (toInterfaceOrientation == UIInterfaceOrientationPortrait);
	}*/

	//if (appDelegate_.app_opt_Ad) {
		// 広告非表示でも回転時に位置調整しておく必要あり ＜＜現れるときの開始位置のため＞＞
		// ここが最初の生成となる。この後、loadView: よりも先に willRotateToInterfaceOrientation: を通り、回転位置セットされる。
		[appDelegate_ AdRefresh];	//広告生成のみ
		[appDelegate_ AdViewWillRotate:toInterfaceOrientation];
	//}
}

// 回転した後に呼び出される
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{	// Popoverの位置を調整する　＜＜UIPopoverController の矢印が画面回転時にターゲットから外れてはならない＞＞
	if ([popOver_ isPopoverVisible]) {
		if (indexPathEdit_) { 
			//NSLog(@"MindexPathEdit=%@", MindexPathEdit);
			[self.tableView scrollToRowAtIndexPath:indexPathEdit_ 
								  atScrollPosition:UITableViewScrollPositionMiddle animated:NO]; // YESだと次の座標取得までにアニメーションが終了せずに反映されない
			[popOver_ presentPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPathEdit_]
									  inView:self.view  permittedArrowDirections:UIPopoverArrowDirectionAny  animated:YES];
		} else {
			// Information, Setting などで、回転後のアンカー位置が再現不可なので閉じる
			[popOver_ dismissPopoverAnimated:YES];
			//[Mpopover release], 
			popOver_ = nil;
		}
	}
}

#pragma mark  View Unload

- (void)unloadRelease {	// dealloc, viewDidUnload から呼び出される
	//【Tips】loadViewでautorelease＆addSubviewしたオブジェクトは全てself.viewと同時に解放されるので、ここでは解放前の停止処理だけする。
	//【Tips】デリゲートなどで参照される可能性のあるデータなどは破棄してはいけない。
	// ただし、他オブジェクトからの参照無く、viewWillAppearにて生成されるものは破棄可能
	
	NSLog(@"--- unloadRelease --- E1viewController");
	
	//[activityIndicator_ release], activityIndicator_ = nil;
	
//	if (mHttpServer) {
//		[mHttpServer stop];
//		//[RhttpServer release], 
//		mHttpServer = nil;
//	}
	//[RalertHttpServer release], 
	mHttpServerAlert = nil;
	//[MdicAddresses release], 
	mAddressDic = nil;
	//[RfetchedE1 release],		
	mFetchedE1 = nil;
	
/*	if (informationView_) {
		[informationView_ hide]; // 正面でなければhide
		//[MinformationView release], 
		informationView_ = nil;
	}*/
}

- (void)viewDidUnload 
{	// メモリ不足時、裏側にある場合に呼び出されるので、viewDidLoadで生成したObjを解放する。
	//NSLog(@"--- viewDidUnload ---"); 
	//iCloud
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	// メモリ不足時、裏側にある場合に呼び出される。addSubviewされたOBJは、self.viewと同時に解放される
	[super viewDidUnload];  // TableCell破棄される
	[self unloadRelease];		// その後、AdMob破棄する
	// この後に loadView ⇒ viewDidLoad ⇒ viewWillAppear がコールされる
}

- (void)dealloc    // 生成とは逆順に解放するのが好ましい
{
	[self unloadRelease];

	if (appDelegate_.ppIsPad) {
		popOver_.delegate = nil;	//[1.0.6-Bug01]戻る同時タッチで落ちる⇒delegate呼び出し強制断
		//[Mpopover release], 
		popOver_ = nil;
		//[MindexPathEdit release], 
		indexPathEdit_ = nil;
	}
	//--------------------------------@property (retain)
	//[Rmoc release];
    //[super dealloc];
}


#pragma mark - TableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
#ifdef AzMAKE_SPLASHFACE
    return 0;
#else
	//if (appDelegate_.ppPaid_SwitchAd) {
	//	return 4;	// (3)iCloud Initial
	//}
	return 2;
#endif
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	switch (section) {
		case 0:
			return section0Rows_ + 1; // +1:Add行
//		case 1:
//			return 1;	// Action menu
		case 1:
			return 3;	// menu
		case 2:
			return 1;	// iCloud Initial
	}
	return 0;
}

//// TableView セクションタイトルを応答
//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
//{
//	switch (section) {
//		case 0:
////			if (appDelegate_.ppIsPad  &&  appDelegate_.ppOptShowAd) {
////				if (section0Rows_ <= 0) {
////					return NSLocalizedString(@"Plan Nothing",nil);
////				}
////				return nil;  // @"\n\n";	// iAd上部スペース
////			} else {
//				if (section0Rows_ <= 0) {
//					return NSLocalizedString(@"Plan Nothing",nil);
//				}
//				//[1.0.1]//return NSLocalizedString(@"Plan",nil);
////			}
//			break;
//			
//		case 1:
//			return NSLocalizedString(@"menu Action",nil);
//			break;
//	}
//	return nil;
//}

// TableView セクションフッタを応答
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section 
{
	if (section==1) {
        NSString *zz = NSLocalizedString(@"message01",nil);
        zz = [zz stringByAppendingString:NSLocalizedString(@"message02",nil)];
        zz = [zz stringByAppendingString:@"\n\nAzukiSoft "  COPYRIGHT];
		return zz;
	}
	return nil;
}


// セルの高さを指示する
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if (appDelegate_.ppIsPad) {
		return 50;
	} else {
		return 44; // デフォルト：44ピクセル
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *zCellDefault = @"CellDefault";
	static NSString *zCellSubtitle = @"CellSubtitle";
  //  static NSString *zCelliAd = @"CelliAd";
    UITableViewCell *cell = nil;

	if (indexPath.section == 0) { //-----------------------------------------------------------Section(0) PackList
		NSInteger rows = section0Rows_ - indexPath.row;
		if (0 < rows) {
			// E1ノードセル
			cell = [tableView dequeueReusableCellWithIdentifier:zCellSubtitle];
			if (cell == nil) {
				cell = [[UITableViewCell alloc] 
						 initWithStyle:UITableViewCellStyleSubtitle
						 reuseIdentifier:zCellSubtitle];
			}
			// E1 : NSManagedObject
			E1 *e1obj = [mFetchedE1 objectAtIndexPath:indexPath];
			
#ifdef DEBUGxxxxx
			if ([e1obj.name length] <= 0) 
				cell.textLabel.text = NSLocalizedString(@"(New Pack)", nil);
			else
				cell.textLabel.text = [NSString stringWithFormat:@"%ld) %@", 
									   (long)[e1obj.row integerValue], e1obj.name];
#else
			if ([e1obj.name length] <= 0) 
				cell.textLabel.text = NSLocalizedString(@"(New Pack)", nil);
			else
				cell.textLabel.text = e1obj.name;
#endif

			if (appDelegate_.ppIsPad) {
				cell.textLabel.font = [UIFont systemFontOfSize:20];
				cell.detailTextLabel.font = [UIFont systemFontOfSize:14];
			} else {
				cell.textLabel.font = [UIFont systemFontOfSize:18];
				cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
			}
			cell.textLabel.textAlignment = NSTextAlignmentLeft;
			cell.textLabel.textColor = [UIColor blackColor];
			
			cell.detailTextLabel.textAlignment = NSTextAlignmentLeft;
			cell.detailTextLabel.textColor = [UIColor brownColor];
			
			// ＜高速化＞ E3(Item)更新時、その親E2のsum属性、さらにその親E1のsum属性を更新することで整合および参照時の高速化を実現した。
			NSInteger lNoGray = [e1obj.sumNoGray integerValue];
			NSInteger lNoCheck = [e1obj.sumNoCheck integerValue];
			// 重量
			double dWeightStk;
			double dWeightReq;
			if (bOptShowTotalWeight_) {
				NSInteger lWeightStk = [e1obj.sumWeightStk integerValue];
				if (bOptWeightRound_) {
					// 四捨五入　＜＜ %.1f により小数第2位が丸められる＞＞ 
					dWeightStk = (double)lWeightStk / 1000.0f;
				} else {
					// 切り捨て                       ↓これで下2桁が0になる
					dWeightStk = (double)(lWeightStk / 100) / 10.0f;
				}
			}
			if (bOptShowTotalWeightReq_) {
				NSInteger lWeightReq = [e1obj.sumWeightNed integerValue];
				if (bOptWeightRound_) {
					// 四捨五入　＜＜ %.1f により小数第2位が丸められる＞＞ 
					dWeightReq = (double)lWeightReq / 1000.0f;
				} else {
					// 切り捨て                       ↓これで下2桁が0になる
					dWeightReq = (double)(lWeightReq / 100) / 10.0f;
				}
			}

			NSString* zNote = e1obj.note;
			if ([e1obj.name length]<=0 && [e1obj.note length]<=0) {
				zNote = NSLocalizedString(@"Name Change",nil);
			}
			
			if (bOptShowTotalWeight_ && bOptShowTotalWeightReq_) {
				cell.detailTextLabel.text = [NSString stringWithFormat:@"%.1f／%.1fKg  %@", 
											 dWeightStk, dWeightReq, zNote];
			} else if (bOptShowTotalWeight_) {
				cell.detailTextLabel.text = [NSString stringWithFormat:@"%.1fKg  %@", 
											 dWeightStk, zNote];
			} else if (bOptShowTotalWeightReq_) {
				cell.detailTextLabel.text = [NSString stringWithFormat:@"／%.1fKg  %@", 
											 dWeightReq, zNote];
			} else {
				cell.detailTextLabel.text = zNote;
			}
			
			if (0 < lNoCheck) 
			{
				UIImageView *imageView1 = [[UIImageView alloc] init];
				UIImageView *imageView2 = [[UIImageView alloc] init];
				imageView1.image = [UIImage imageNamed:@"Icon32-BagYellow.png"];
				imageView2.image = GimageFromString(20,-20,24,[NSString stringWithFormat:@"%ld", (long)lNoCheck]);

                UIGraphicsBeginImageContextWithOptions(imageView1.image.size, NO, 0.0); //[0.4.18]Retina対応

				CGRect rect = CGRectMake(0, 0, imageView1.image.size.width, imageView1.image.size.height);
				[imageView1.image drawInRect:rect];  
				[imageView2.image drawInRect:rect blendMode:kCGBlendModeMultiply alpha:1.0];  
				UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();  
				UIGraphicsEndImageContext();  
				[cell.imageView setImage:resultingImage];
				//[imageView1 release];
				//[imageView2 release];
			} 
			else if (0 < lNoGray) {
				cell.imageView.image = [UIImage imageNamed:@"Icon32-BagBlue.png"];
			}
			else { // 全てGray
				cell.imageView.image = [UIImage imageNamed:@"Icon32-BagGray.png"];
			}
			
			cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton; // ディスクロージャボタン
			cell.showsReorderControl = YES;		// Move有効
		} 
		else {
			// Add iPack ボタンセル
			cell = [tableView dequeueReusableCellWithIdentifier:zCellDefault];
			if (cell == nil) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault      // Default型
											   reuseIdentifier:zCellDefault];
			}

			if (appDelegate_.ppIsPad) {
				cell.textLabel.font = [UIFont systemFontOfSize:18];
			} else {
				cell.textLabel.font = [UIFont systemFontOfSize:14];
			}
			cell.textLabel.textAlignment = NSTextAlignmentCenter; // 中央寄せ
			cell.textLabel.textColor = [UIColor darkGrayColor];
			
			switch (rows) {
				case 0: { // Add
					cell.imageView.image = [UIImage imageNamed:@"Icon24-GreenPlus.png"];
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;	// > ディスクロージャマーク
					cell.showsReorderControl = NO;
					cell.textLabel.text = NSLocalizedString(@"New Pack",nil);
				}	break;
			}
		}
	}
	else { //-----------------------------------------------------------Section(1)Action menu  (2)Old menu
		cell = [tableView dequeueReusableCellWithIdentifier:zCellSubtitle];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
										   reuseIdentifier:zCellSubtitle];
		}

		if (appDelegate_.ppIsPad) {
			cell.textLabel.font = [UIFont systemFontOfSize:18];
			cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
			cell.accessoryType = UITableViewCellAccessoryNone;
		} else {
			cell.textLabel.font = [UIFont systemFontOfSize:14];
			cell.detailTextLabel.font = [UIFont systemFontOfSize:10];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;	// > ディスクロージャマーク
		}
		cell.textLabel.textAlignment = NSTextAlignmentLeft; 
		cell.textLabel.textColor = [UIColor darkGrayColor];
		cell.detailTextLabel.textAlignment = NSTextAlignmentLeft;
		cell.detailTextLabel.textColor = [UIColor grayColor];
		cell.showsReorderControl = NO;

//		if (indexPath.section == 1) { //-----------------------------------------------------------Section 1:行位置変更したなら、Popover矢印位置も変更すること。
//			switch (indexPath.row) {
//				case 0:
//					cell.imageView.image = [UIImage imageNamed:@"Icon32-SharedAdd"];
//					cell.textLabel.text = NSLocalizedString(@"Import SharePlan",nil);
//					cell.detailTextLabel.text = NSLocalizedString(@"Import SharePlan msg",nil);
//					break;
//					
//				case 1:
//					cell.imageView.image = [UIImage imageNamed:@"Icon32-GoogleAdd"];
//					cell.textLabel.text = NSLocalizedString(@"Import Google",nil);
//					cell.detailTextLabel.text = NSLocalizedString(@"Import Google msg",nil);
//					break;
//					
//				case 2:
//					cell.imageView.image = [UIImage imageNamed:@"AZDropbox-32"];
//					cell.textLabel.text = NSLocalizedString(@"Import Dropbox",nil);
//					cell.detailTextLabel.text = NSLocalizedString(@"Import Dropbox msg",nil);
//					break;
//			}
//		}
		if (indexPath.section == 1) { //-----------------------------------------------------------Section 2
			switch (indexPath.row) {
				case 0:
					cell.imageView.image = [UIImage imageNamed:@"Icon-Setting-32"];
					cell.textLabel.text = NSLocalizedString(@"menu Setting",nil);
					cell.detailTextLabel.text = NSLocalizedString(@"menu Setting msg",nil);
					break;
					
				case 1:
					cell.imageView.image = [UIImage imageNamed:@"AZAbout-32"];
					cell.textLabel.text = NSLocalizedString(@"menu Information",nil);
					cell.detailTextLabel.text = NSLocalizedString(@"menu Information msg",nil);
					break;
					
				case 2:
					cell.imageView.image = [UIImage imageNamed:@"AZStore-32"];
					cell.textLabel.text = NSLocalizedString(@"menu Purchase",nil);
					cell.detailTextLabel.text = NSLocalizedString(@"menu Purchase msg",nil);
					break;
			}
		}
		else if (indexPath.section == 2) { //-----------------------------------------------------------Section 3
			// iCloud
			cell.imageView.image = [UIImage imageNamed:@"Icon32-iCloud"];
			cell.textLabel.text = NSLocalizedString(@"iCloud Reset",nil);
			cell.textLabel.textColor = [UIColor redColor];
			cell.detailTextLabel.text = NSLocalizedString(@"iCloud Reset msg",nil);
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
	}
	return cell;
}

// ディスクロージャボタンが押されたときの処理
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	[self e1editView:indexPath];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView 
		   editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if (indexPath.section == 0) {
		NSInteger rows = section0Rows_ - indexPath.row;
		if (0 < rows) {
			return UITableViewCellEditingStyleDelete;
		}
	}
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];	// 非選択状態に戻す

	// didSelect時のScrollView位置を記録する（viewWillAppearにて再現するため）
	contentOffsetDidSelect_ = [tableView contentOffset];

	if (indexPath.section == 0) {
		NSInteger rows = section0Rows_ - indexPath.row;
		if (0 < rows) {
			if (self.editing) {
				[self e1editView:indexPath];
			} else {
				// E1 : NSManagedObject
				E1 *e1obj = [mFetchedE1 objectAtIndexPath:indexPath];
				[self toE2fromE1:e1obj withIndex:indexPath]; // 次回の画面復帰のための状態記録をしてからＥ２へドリルダウンする
			}
		}
		else {
			switch (rows) {
				case 0: { // Add
					[self e1add]; // 追加される.row ＝ 現在のPlan行数
				}	break;
			}
		}
	}
//	else if (indexPath.section == 1) {
//		switch (indexPath.row) {
//			case 0: // SharePlan Search
//				[self	actionImportSharedPackList];
//				break;
//				
//			case 1: // Google
//				[self actionImportGoogle];
//				break;
//
//			case 2: // Dropbox
//				[self actionImportDropbox];
//				break;
//		}
//	}
	else if (indexPath.section == 1) {
		switch (indexPath.row) {
			case 0: // Setting
				[self actionSetting];
				break;
				
			case 1: // Information
				[self actionInformation];
				break;
				
			case 2: // Purchase
				[self actionAZStore];
				break;
		}
	}
//	else if (indexPath.section == 3) {
//		// iCloud Reset
//		UIAlertView *av = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"iCloud Reset", nil)
//													 message: NSLocalizedString(@"iCloud Reset msg", nil)
//													delegate:self
//										   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
//										   otherButtonTitles:NSLocalizedString(@"RESET", nil), nil];
//		av.tag = ALERT_TAG_CloudReset;
//		[av show];
//	}
}

#pragma mark  TableView - Edit Move

// TableView Editモードの表示
- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
    // この後、self.editing = YES になっている。
	// [self.tableView reloadData]だとアニメ効果が消される。　(OS 3.0 Function)を使って解決した。
	NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 1)]; // [0]セクションから1個
	[self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade]; // (OS 3.0 Function)
}

// TableView Editモード処理
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle				forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		// 削除コマンド警告　==>> (void)actionSheet にて処理
		//NG//MindexPathActionDelete = indexPath;  retainが必要になる
		actionDeleteRow_ = indexPath.row;
		// 削除コマンド警告
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		NSString *title = [NSString stringWithFormat:@"%@\n%@",
						   cell.textLabel.text, NSLocalizedString(@"DELETE Pack caution", nil)];
		if (appDelegate_.ppIsPad) {
			//[2.0.1] iPadだとCancelボタンが表示されないためUIActionSheetにした。
			UIAlertView *av = [[UIAlertView alloc] initWithTitle: title
														 message:@"" 
														delegate:self 
											   cancelButtonTitle:NSLocalizedString(@"Cancel", nil) 
											   otherButtonTitles:NSLocalizedString(@"DELETE Pack", nil), nil];
			av.tag = ALERT_TAG_DELETEPACK;
			[av show];
		} else {
			UIActionSheet *action = [[UIActionSheet alloc] 
									 initWithTitle: title
									 delegate:self 
									 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
									 destructiveButtonTitle:NSLocalizedString(@"DELETE Pack", nil)
									 otherButtonTitles:nil];
			action.tag = ACTIONSEET_TAG_DELETEPACK;
			//[2.0]ToolBar非表示（TabBarも無い）　＜＜ToolBar無しでshowFromToolbarするとFreeze＞＞
			[action showInView:self.view]; //windowから出すと回転対応しない
			//BUG//[action release]; autoreleaseにした
		}
	}
}


- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	// スワイプにより1行だけが編集モードに入るときに呼ばれる。
	// このオーバーライドにより、setEditting が呼び出されないようにしている。 Add行を出さないため
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	// スワイプにより1行だけが編集モードに入り、それが解除されるときに呼ばれる。
	// このオーバーライドにより、setEditting が呼び出されないようにしている。 Add行を出さないため
}

/*セクションありのとき、これ未定義の方が見栄え良い
// Editモード時の行Edit可否
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0 && indexPath.row < MiSection0Rows) return YES; // 行編集許可
	return NO; // 行編集禁止
}
*/

// Editモード時の行移動の可否　　＜＜最終行のAdd専用行を移動禁止にしている＞＞
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if (indexPath.section==0 && indexPath.row < section0Rows_) return YES;
	return NO;  // 最終行のAdd行は移動禁止
}

// Editモード時の行移動「先」を返す　　＜＜最終行のAdd専用行への移動ならば1つ前の行を返している＞＞
- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)oldPath 
															toProposedIndexPath:(NSIndexPath *)newPath {
    NSIndexPath *target = newPath;
    // Add行が異動先になった場合、その1つ前の通常行を返すことにより、Add行への移動禁止となる。
	NSInteger rows = section0Rows_ - 1; // 移動可能な行数（Add行を除く）
	// セクション０限定仕様
	if (newPath.section != 0 || rows < newPath.row  ) {
        target = [NSIndexPath indexPathForRow:rows inSection:0];
    }
    return target;
}

// Editモード時の行移動処理　　＜＜CoreDataにつきArrayのように削除＆挿入ではダメ。ソート属性(row)を書き換えることにより並べ替えている＞＞
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)oldPath 
												  toIndexPath:(NSIndexPath *)newPath {
	// CoreDataは順序を保持しないため 属性"ascend"を昇順ソート表示している
	// この 属性"ascend"の値を行異動後に更新するための処理

	// e1だけNSFetchedResultsControllerを使っているので、e2,e3とは異なる
	// E1 : NSManagedObject
	E1 *e1obj = [mFetchedE1 objectAtIndexPath:oldPath];
	e1obj.row = [NSNumber numberWithInteger:newPath.row];  // 指定セルを先に移動
	// 移動行間のE1エンティティ属性(row)を書き換える
	NSInteger i;
    NSIndexPath *ip = nil;
	if (oldPath.row < newPath.row) {
		// 後(下)へ移動
		for ( i=oldPath.row ; i < newPath.row ; i++) {
			ip = [NSIndexPath indexPathForRow:(NSUInteger)i+1 inSection:newPath.section];
			e1obj = [mFetchedE1 objectAtIndexPath:ip];
			e1obj.row = [NSNumber numberWithInteger:i];
		}
	} else {
		// 前(上)へ移動
		for (i = newPath.row ; i < oldPath.row ; i++) {
			ip = [NSIndexPath indexPathForRow:(NSUInteger)i inSection:newPath.section];
			e1obj = [mFetchedE1 objectAtIndexPath:ip];
			e1obj.row = [NSNumber numberWithInteger:i+1];
		}
	}
	// SAVE　＜＜万一システム障害で落ちてもデータが残るようにコマメに保存する方針である＞＞
	NSError *error = nil;
	if (![mMoc save:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		exit(-1);  // Fail
	}
	// 上で並び替えられた結果を再フィッチする（performFetch）  コンテキスト変更したときは再抽出する
	//NSError *error = nil;
	if (![mFetchedE1 performFetch:&error]) {
		NSLog(@"%@", error);
		exit(-1);  // Fail
	}
}

#pragma mark - delegate UIPopoverController
- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{	// Popoverの外部をタップして閉じる前に通知
	// 内部(SAVE)から、dismissPopoverAnimated:で閉じた場合は呼び出されない。
	//[1.0.6]Cancel: 今更ながら、insert後、saveしていない限り、rollbackだけで十分であることが解った。

	UINavigationController* nc = (UINavigationController*)[popoverController contentViewController];
	if ( [[nc visibleViewController] isMemberOfClass:[E1edit class]] ) {	// E1edit のときだけ、
		if (appDelegate_.ppChanged) { // E1editにて、変更あるので閉じさせない
			azAlertBox(NSLocalizedString(@"Cancel or Save",nil), 
					 NSLocalizedString(@"Cancel or Save msg",nil), NSLocalizedString(@"Roger",nil));
			return NO; 
		}
	}
	[mMoc rollback]; // 前回のSAVE以降を取り消す。＜＜サンプルの一時取込をクリアするために必要
	return YES; // 閉じることを許可
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{	// [Cancel][Save][枠外タッチ]何れでも閉じるときここを通る
	//[self refreshE1view];
	[self refreshAllViews:nil];
	return;
}



@end

