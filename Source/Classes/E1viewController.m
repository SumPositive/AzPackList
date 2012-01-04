//
//  E1viewController.m
//  iPack E1 Title
//
//  Created by 松山 和正 on 09/12/03.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "Global.h"
#import "AppDelegate.h"
#import "Elements.h"
#import "E1viewController.h"
#import "E1edit.h"
#import "E2viewController.h"
#import "E3viewController.h"
#import "GooDocsTVC.h"
#import "SettingTVC.h"
#import "InformationView.h"
#import "WebSiteVC.h"
#import "HTTPServer.h"
#import "MyHTTPConnection.h"
#import "localhostAddresses.h"
#import "FileCsv.h"
#import "SpSearchVC.h"
#import "DropboxVC.h"


#define ACTIONSEET_TAG_DELETEPACK	901
#define ACTIONSEET_TAG_BarMenu		910
#define ACTIONSEET_TAG_MENU			929

#define ALERT_TAG_HTTPServerStop	109
#define ALERT_TAG_SupportSite		118


@interface E1viewController (PrivateMethods)
- (void)azInformationView;
- (void)azSettingView;
- (void)azAction;
- (void)httpInfoUpdate:(NSNotification *)notification;
- (void)e1add;
- (void)e1editView:(NSIndexPath *)indexPath;
@end


@implementation E1viewController
{
@public		// 外部公開 ＜＜使用禁止！@propertyで外部公開すること＞＞
@protected	// 自クラスおよびサブクラスから参照できる（無指定時のデフォルト）
@private	// 自クラス内からだけ参照できる
	NSManagedObjectContext		*Rmoc;
	//----------------------------------------------------------------viewDidLoadでnil, dealloc時にrelese
	NSFetchedResultsController	*RfetchedE1;
	HTTPServer					*RhttpServer;
	UIAlertView					*RalertHttpServer;
	NSDictionary				*MdicAddresses;
	//UIActivityIndicatorView *activityIndicator_;
	//----------------------------------------------------------------Owner移管につきdealloc時のrelese不要
	E1edit						*Me1editView;		// self.navigationControllerがOwnerになる
	UIBarButtonItem		*MbuInfo;
	InformationView		*MinformationView;  // self.view.windowがOwnerになる

	UIPopoverController*	Mpopover;
	NSIndexPath*				MindexPathEdit;	//[1.1]ポインタ代入注意！copyするように改善した。
	
	//----------------------------------------------------------------assign
	AppDelegate		*appDelegate_;
	BOOL			MbInformationOpen;	//[1.0.2]InformationViewを初回自動表示するため
	//NSIndexPath	  *MindexPathActionDelete; //NG//ポインタ危険
	NSUInteger		MactionDeleteRow;		//[1.1]削除するRow
	BOOL MbAzOptTotlWeightRound;
	BOOL MbAzOptShowTotalWeight;
	BOOL MbAzOptShowTotalWeightReq;
	NSInteger MiSection0Rows; // E1レコード数　＜高速化＞
	CGPoint		McontentOffsetDidSelect; // didSelect時のScrollView位置を記録
}
//@synthesize Rmoc;


#pragma mark - Delegate

- (void)refreshE1view
{
	McontentOffsetDidSelect.y = 0;  // 直前のdidSelectRowAtIndexPath位置に戻らないようにクリアしておく
	//[self viewWillAppear:YES];		// Setting変更後、全域再描画が必要になるので、このようにした。
	[self viewDidAppear:YES];
}


#pragma mark - CoreData - iCloud

- (void)refetcheAllData
{
	if (RfetchedE1 == nil) 
	{
		// Create and configure a fetch request with the Book entity.
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"E1" 
												  inManagedObjectContext:Rmoc];
		[fetchRequest setEntity:entity];
		// Sorting
		NSSortDescriptor *sortRow = [[NSSortDescriptor alloc] initWithKey:@"row" ascending:YES];
		NSArray *sortArray = [[NSArray alloc] initWithObjects:sortRow, nil];
		[fetchRequest setSortDescriptors:sortArray];
		[sortArray release];
		[sortRow release];
		// Create and initialize the fetch results controller.
		RfetchedE1 = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest 
														 managedObjectContext:Rmoc 
														   sectionNameKeyPath:nil cacheName:@"E1nodes"];
		[fetchRequest release];
	}
	
	// 読み込み
	NSError *error = nil;
	if (![RfetchedE1 performFetch:&error]) {
		// Update to handle the error appropriately.
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		return; //exit(-1);  // Fail
	}
	NSLog(@"RfetchedE1=%@", RfetchedE1);
	
	// 高速化のため、ここでE1レコード数（行数）を求めてしまう
    MiSection0Rows = 0;
	if (0 < [[RfetchedE1 sections] count]) {
		id <NSFetchedResultsSectionInfo> sectionInfo = [[RfetchedE1 sections] objectAtIndex:0];
		MiSection0Rows = [sectionInfo numberOfObjects];
		
		//[1.0.1]末尾の「新しい・・」空レコードがあれば削除する
		BOOL bRefetch = NO;
		NSArray *arE1 = [sectionInfo objects];
		if (arE1 && 0<[arE1 count]) {
			E1 *e1last = [arE1 lastObject];
			if (0 < [e1last.childs count]) {
				NSArray *arE2 = [e1last.childs allObjects];
				for (E2 *e2 in arE2) {
					if (0 < [e2.childs count]) {
						NSArray *arE3 = [e2.childs allObjects];
						for (E3 *e3 in arE3) {
							//NSLog(@"name=%@ note=%@ stock=%d need=%d weight=%d", e3.name, e3.note,
							//	  [e3.stock integerValue], [e3.need integerValue], [e3.weight integerValue]);
							if ([e3.name length]<=0 && [e3.note length]<=0
								&& [e3.stock integerValue]<=0
								&& [e3.need integerValue]==(-1)		//(-1)Add行なら削除。 [SAVE]押せば少なくとも(0)になる
								&& [e3.weight integerValue]<=0
								) {
								// 「新しいアイテム」かつ「未編集」 なので削除する
								e3.parent = nil;
								[Rmoc deleteObject:e3];
								bRefetch = YES;
							}
						}
					}
					if ([e2.name length]<=0 && [e2.childs count]<=0) {
						//配下E3なし & 「新しいグループ」 なので削除する
						e2.parent = nil;
						[Rmoc deleteObject:e2];
						bRefetch = YES;
					}
				}
			}
			if ([e1last.name length]<=0 && [e1last.childs count]<=0) {
				//配下E2なし & 「新しいプラン」 なので削除する
				[Rmoc deleteObject:e1last];
				bRefetch = YES;
			}
			if (bRefetch) {
				NSError *err = nil;
				if (![Rmoc save:&err]) {
					NSLog(@"Unresolved error %@, %@", err, [err userInfo]);
				}
				error = nil;
				if (![RfetchedE1 performFetch:&error]) {
					NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
					return; //exit(-1);  // Fail
				}
				id <NSFetchedResultsSectionInfo> sectionInfo = [[RfetchedE1 sections] objectAtIndex:0];
				MiSection0Rows = [sectionInfo numberOfObjects];
			}
		}
	}
	
	[self.tableView reloadData];
}

- (void)refetcheAllData:(NSNotification*)note 
{	// iCloud-CoreData に変更があれば呼び出される
	if (note) {
		[self refetcheAllData];
	}
}

- (void)refreshAllViews:(NSNotification*)note 
{	// iCloud-CoreData に変更があれば呼び出される
	//[self.tableView reloadData];
	//[self viewWillAppear:YES];
	if (note) {
		[self viewDidAppear:YES];
	}
}


#pragma mark - Action

- (void)azInformationView
{
	if (appDelegate_.app_is_iPad) {
		if ([Mpopover isPopoverVisible]) return; //[1.0.6-Bug01]同時タッチで落ちる⇒既に開いておれば拒否
		
		if (MinformationView) {
			[MinformationView release], MinformationView = nil;
		}
		MinformationView = [[InformationView alloc] init];  //[1.0.2]Pad対応に伴いControllerにした。
		//MinformationView.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
		
		[Mpopover release], Mpopover = nil;
		//Mpopover = [[PadPopoverInNaviCon alloc] initWithContentViewController:MinformationView];
		Mpopover = [[UIPopoverController alloc] initWithContentViewController:MinformationView];
		//Mpopover.popoverContentSize = CGSizeMake(320, 510);
		Mpopover.delegate = nil;	// 不要
		CGRect rcArrow;
		if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) { //iPad初期、常にタテになる。原因不明
			rcArrow = CGRectMake(0, 1027-60, 32,32);
		} else {
			rcArrow = CGRectMake(0, 768-60, 32,32);
		}
		[Mpopover presentPopoverFromRect:rcArrow  inView:self.navigationController.view  
				permittedArrowDirections:UIPopoverArrowDirectionDown  animated:YES];
	} 
	else {
		if (self.interfaceOrientation != UIInterfaceOrientationPortrait) return; // 正面でなければ禁止
		// ヨコ非対応につき正面以外は、hideするようにした。
		/*	if (MinformationView==nil) { // self.view.windowが解放されるまで存在しているため
		 //MinformationView = [[InformationView alloc] initWithFrame:[self.view.window bounds]];
		 //[self.view.window addSubview:MinformationView]; //回転しないが、.viewから出すとToolBarが隠れない
		 MinformationView = [[InformationView alloc] init];  //[1.0.2]Pad対応に伴いControllerにした。
		 MinformationView.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		 [self.navigationController pushViewController:MinformationView animated:YES];
		 [MinformationView release]; // addSubviewにてretain(+1)されるため、こちらはrelease(-1)して解放
		 }
		 [MinformationView show];
		 */
		// モーダル UIViewController
		if (MinformationView) {
			[MinformationView release], MinformationView = nil;
		}
		MinformationView = [[InformationView alloc] init];  //[1.0.2]Pad対応に伴いControllerにした。
		MinformationView.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
		[self presentModalViewController:MinformationView animated:YES];
		//[MinformationView release];
	}
}

- (void)azSettingView
{
	if (appDelegate_.app_is_iPad) {
		if ([Mpopover isPopoverVisible]) return; //[1.0.6-Bug01]同時タッチで落ちる⇒既に開いておれば拒否
	}

	SettingTVC *vi = [[SettingTVC alloc] init];

	if (appDelegate_.app_is_iPad) {
		[Mpopover release], Mpopover = nil;
		//Mpopover = [[PadPopoverInNaviCon alloc] initWithContentViewController:vi];
		Mpopover = [[UIPopoverController alloc] initWithContentViewController:vi];
		//Mpopover.popoverContentSize = CGSizeMake(480, 400);
		Mpopover.delegate = nil;	// 不要
		CGRect rcArrow;
		if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
			rcArrow = CGRectMake(768-32, 1027-60, 32,32);
		} else {
			rcArrow = CGRectMake(1024-320-32, 768-60, 32,32);
		}
		[Mpopover presentPopoverFromRect:rcArrow	inView:self.navigationController.view  
				permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
	} else {
		//vi.hidesBottomBarWhenPushed = YES; // 現在のToolBar状態をPushした上で、次画面では非表示にする
		[vi setHidesBottomBarWhenPushed:YES];
		[self.navigationController pushViewController:vi animated:YES];
	}
	[vi release];
	
	if (appDelegate_.app_is_Ad) {
		// 各viewDidAppear:にて「許可/禁止」を設定する
		[appDelegate_ AdRefresh:NO];	//広告禁止
	}
}


//- (void)actionE1deleteCell:(NSIndexPath*)indexPath
- (void)actionE1deleteCell:(NSUInteger)uiRow
{
	// ＜注意＞ 選択行は、[self.tableView indexPathForSelectedRow] では得られない！didSelect直後に選択解除しているため。
	//         そのため、pppIndexPathActionDelete を使っている。
	// ＜注意＞ CoreDataモデルは、エンティティ間の削除ルールは双方「無効にする」を指定。（他にするとフリーズ）
	// 削除対象の ManagedObject をチョイス
	NSLog(@"RfetchedE1=%@", RfetchedE1);
	NSLog(@"uiRow=%ld", (long)uiRow);
	NSIndexPath *ixp = [NSIndexPath indexPathForRow:uiRow inSection:0];
	E1 *e1objDelete = [RfetchedE1 objectAtIndexPath:ixp];
	// CoreDataモデル：削除ルール「無効にする」につき末端ノードより独自に削除する
	for (E2 *e2obj in e1objDelete.childs) {
		for (E3 *e3obj in e2obj.childs) {
			[Rmoc deleteObject:e3obj];
		}
		[Rmoc deleteObject:e2obj];
	}
	// 注意！performFetchするまで RrFetchedE1 は不変、削除もされていない！
	// 削除行の次の行以下 E1.row 更新
	for (NSUInteger i= uiRow + 1 ; i < MiSection0Rows ; i++) {  // .row + 1 削除行の次から
		ixp = [NSIndexPath indexPathForRow:i inSection:0];
		E1 *e1obj = [RfetchedE1 objectAtIndexPath:ixp];
		e1obj.row = [NSNumber numberWithInteger:i-1];     // .row--; とする
	}
	// E1 削除
	[Rmoc deleteObject:e1objDelete];
	MiSection0Rows--; // この削除により1つ減
	// SAVE　＜＜万一システム障害で落ちてもデータが残るようにコマメに保存する方針＞＞
	NSError *error = nil;
	if (![Rmoc save:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		exit(-1);  // Fail
	}
	// 上で並び替えられた結果を再フィッチする（performFetch）  コンテキスト変更したときは再抽出する
	//NSError *error = nil;
	if (![RfetchedE1 performFetch:&error]) {
		NSLog(@"%@", error);
		exit(-1);  // Fail
	}
	// テーブルビューから選択した行を削除します。
	// ＜高速化＞　改めて削除後のE1レコード数（行数）を求める
	MiSection0Rows = 0;
	if (0 < [[RfetchedE1 sections] count]) {
		id <NSFetchedResultsSectionInfo> sectionInfo = [[RfetchedE1 sections] objectAtIndex:0];
		MiSection0Rows = [sectionInfo numberOfObjects];
	}
	[self.tableView reloadData];
}

- (void)actionImportSharedPackList
{
	if (appDelegate_.app_is_iPad) {
		if ([Mpopover isPopoverVisible]) return; //[1.0.6-Bug01]同時タッチで落ちる⇒既に開いておれば拒否
	}
	
	if (appDelegate_.app_is_Ad) {
		[appDelegate_ AdRefresh:NO];	//広告禁止
	}
	
	SpSearchVC *vc = [[SpSearchVC alloc] init];
	
	if (appDelegate_.app_is_iPad) {
		[Mpopover release], Mpopover = nil;
		//Mpopover = [[PadPopoverInNaviCon alloc] initWithContentViewController:vc];
		UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:vc];
		Mpopover = [[UIPopoverController alloc] initWithContentViewController:nc];
		[nc release];
		Mpopover.delegate = self;	// popoverControllerDidDismissPopover:を呼び出してもらうため
		[MindexPathEdit release], MindexPathEdit = nil;
		
		CGRect rcArrow;
		if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
			rcArrow = CGRectMake(768/2-10, 1027-60, 20,20);
		} else {
			rcArrow = CGRectMake((1024-320)/2-10, 768-60, 20,20);
		}
		[Mpopover presentPopoverFromRect:rcArrow  inView:self.navigationController.view
				permittedArrowDirections:UIPopoverArrowDirectionDown  animated:YES];
	} else {
		//vc.hidesBottomBarWhenPushed = YES; // 現在のToolBar状態をPushした上で、次画面では非表示にする
		[vc setHidesBottomBarWhenPushed:YES];
		[self.navigationController pushViewController:vc animated:YES];
	}
	[vc release];
}

- (void)actionImportDropbox
{
	// 未認証の場合、認証処理後、AppDelegate:handleOpenURL:から呼び出される
	if ([[DBSession sharedSession] isLinked]) 
	{	// Dropbox 認証済み
		if (appDelegate_.app_is_iPad) {
			DropboxVC *vc = [[DropboxVC alloc] initWithNibName:@"DropboxVC-iPad" bundle:nil];
			vc.Re1selected = nil; // 取込専用
			[self presentModalViewController:vc animated:YES];
		} else {
			DropboxVC *vc = [[DropboxVC alloc] initWithNibName:@"DropboxVC" bundle:nil];
			vc.Re1selected = nil; // 取込専用
			[self presentModalViewController:vc animated:YES];
		}
	} else {
		// Dropbox 未認証
		appDelegate_.dropboxSaveE1selected = nil;	// 取込専用
		[[DBSession sharedSession] link];
	}
}

- (void)actionImportGoogle
{
	if (appDelegate_.app_is_iPad) {
		if ([Mpopover isPopoverVisible]) return; //[1.0.6-Bug01]同時タッチで落ちる⇒既に開いておれば拒否
	}

	GooDocsView *goodocs = [[GooDocsView alloc] init];
	// 以下は、GooDocsViewの viewDidLoad 後！、viewWillAppear の前に処理されることに注意！
	goodocs.Rmoc = Rmoc;
	goodocs.PiSelectedRow = MiSection0Rows;  // Downloadの結果、新規追加される.row ＝ 現在のPlan行数
	goodocs.Re1selected = nil; // DownloadのときはE1未選択であるから
	goodocs.PbUpload = NO;
	goodocs.title = NSLocalizedString(@"Import Google", nil);

	if (appDelegate_.app_is_iPad) {
		[Mpopover release], Mpopover = nil;
		//Mpopover = [[PadPopoverInNaviCon alloc] initWithContentViewController:goodocs];
		UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:goodocs];
		Mpopover = [[UIPopoverController alloc] initWithContentViewController:nc];
		[nc release];
		Mpopover.delegate = self;	// popoverControllerDidDismissPopover:を呼び出してもらうため
		[MindexPathEdit release], MindexPathEdit = nil;
		CGRect rcArrow;
		if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
			rcArrow = CGRectMake(768/2-10, 1027-60, 20,20);
		} else {
			rcArrow = CGRectMake((1024-320)/2-10, 768-60, 20,20);
		}
		[Mpopover presentPopoverFromRect:rcArrow	  inView:self.navigationController.view
				permittedArrowDirections:UIPopoverArrowDirectionDown  animated:YES];
		goodocs.selfPopover = Mpopover;
		goodocs.delegate = self; //Download後の再描画のため
	} 
	else {
		[goodocs setHidesBottomBarWhenPushed:YES]; // 現在のToolBar状態をPushした上で、次画面では非表示にする
		goodocs.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		[self.navigationController pushViewController:goodocs animated:YES];

		if (appDelegate_.app_is_Ad) {
			[appDelegate_ AdRefresh:NO];	//広告禁止
		}
	}
	[goodocs release];
}

- (void)actionImportYourPC
{
	if (appDelegate_.app_is_Ad) {
		[appDelegate_ AdRefresh:NO];	//広告禁止
	}
	// HTTP Server Start
	if (RalertHttpServer == nil) {
		RalertHttpServer = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"HttpSv RESTORE", nil) 
													  message:NSLocalizedString(@"HttpSv Wait", nil) 
													 delegate:self 
											cancelButtonTitle:nil  //@"CANCEL" 
											otherButtonTitles:NSLocalizedString(@"HttpSv stop", nil) , nil];
	}
	RalertHttpServer.tag = ALERT_TAG_HTTPServerStop;
	[RalertHttpServer show];
	//[MalertHttpServer release];
	// if (httpServer) return; <<< didSelectRowAtIndexPath:直後に配置してダブルクリック回避している。
	NSString *root = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
	RhttpServer = [HTTPServer new];
	[RhttpServer setType:@"_http._tcp."];
	[RhttpServer setConnectionClass:[MyHTTPConnection class]];
	[RhttpServer setDocumentRoot:[NSURL fileURLWithPath:root]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(httpInfoUpdate:) name:@"LocalhostAdressesResolved" object:nil];
	[localhostAddresses performSelectorInBackground:@selector(list) withObject:nil];
	[RhttpServer setPort:8080];
	[RhttpServer setBackup:NO]; // RESTORE Mode
	[RhttpServer setManagedObjectContext:Rmoc];
	[RhttpServer setAddRow:MiSection0Rows];
	NSError *error;
	if(![RhttpServer start:&error])
	{
		NSLog(@"Error starting HTTP Server: %@", error);
		[RhttpServer release];
		RhttpServer = nil;
	}
	// Upload成功後、CSV LOAD する  ＜＜連続リストアできるように httpResponseForMethod 内で処理＞＞
}

- (void)actionImportPasteBoard
{
	NSRange range = [[UIPasteboard generalPasteboard].string rangeOfString:GD_PRODUCTNAME];
	if (range.location == NSNotFound) {
		UIAlertView *alert = [[UIAlertView alloc] 
							  initWithTitle:NSLocalizedString(@"PBoard Paste NG1",nil)
							  message:nil //NSLocalizedString(@"PBoard Paste NG1",nil)
							  delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
		[alert show];
		[alert release];
		return;
	}
	// ペーストボードから取り込んで追加する
	UIAlertView *alert = [[UIAlertView alloc] init];
	alert.title = NSLocalizedString(@"Please Wait",nil);
	[alert show];
	//---------------------------------------CSV LOAD Start.
	NSString *zErr = [FileCsv zLoad:nil];  //==nil:PasteBoardから取り込む
	//---------------------------------------CSV LOAD End.
	[alert dismissWithClickedButtonIndex:0 animated:NO]; // 閉じる
	[alert release];
	if (zErr) {
		alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"PBoard Error",nil)
										   message:zErr
										  delegate:nil 
								 cancelButtonTitle:nil 
								 otherButtonTitles:@"OK", nil];
		[alert show];
		[alert release];
		return;
	}
	alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"PBoard Paste",nil)
									   message:NSLocalizedString(@"PBoard Paste OK",nil)
									  delegate:nil 
							 cancelButtonTitle:nil 
							 otherButtonTitles:@"OK", nil];
	[alert show];
	[alert release];
	// 再表示
	[self viewWillAppear:YES]; // Fech データセットさせるため
}


- (void)toE2fromE1:(E1*)e1obj  withIndex:(NSIndexPath *)indexPath 
{	// 次回の画面復帰のための状態記録
	
	// E2 へドリルダウン
	E2viewController *e2view = [[E2viewController alloc] init];

	if (appDelegate_.app_is_iPad) {
		e2view.title = NSLocalizedString(@"Product Title",nil);
	} else {
		if ([e1obj.name length]<=0) {
			e2view.title = NSLocalizedString(@"(New Pack)", nil);
		} else {
			e2view.title = e1obj.name;
		}
	}
	
	e2view.Re1selected = e1obj;
	e2view.PbSharePlanList = NO;
	
	if (appDelegate_.app_is_iPad) {
		//Split Right
		E3viewController* e3view = [[E3viewController alloc] init];
		// 以下は、E3viewControllerの viewDidLoad 後！、viewWillAppear の前に処理されることに注意！
		e3view.title = e1obj.name;  //  self.title;  // NSLocalizedString(@"Items", nil);
		e3view.Re1selected = e1obj; // E1
		e3view.PiFirstSection = 0;
		e3view.PiSortType = (-1);
		e3view.PbSharePlanList = NO;
		//[1]Right
		[[appDelegate_.mainSVC.viewControllers objectAtIndex:1] pushViewController:e3view animated:YES]; 
		//[0]Left
		e2view.delegateE3viewController = e3view;		// E2からE3を更新するため
		[[appDelegate_.mainSVC.viewControllers objectAtIndex:0] pushViewController:e2view animated:YES]; 
		
		[e3view release];
	} else {
		[self.navigationController pushViewController:e2view animated:YES];
	}
	
	[e2view release];
}

- (void)e1add 
{
	// ContextにE1ノードを追加する　E1edit内でCANCELならば削除している
	E1 *e1newObj = [NSEntityDescription insertNewObjectForEntityForName:@"E1" inManagedObjectContext:Rmoc];
	/*
	 Me1editView = [[E1edit alloc] init]; // popViewで戻れば解放されているため、毎回alloc必要。
	 Me1editView.title = NSLocalizedString(@"Add Plan", @"PLAN追加");
	 Me1editView.Re1target = e1newObj;
	 Me1editView.PiAddRow = MiSection0Rows;  // 追加される行番号(row) ＝ 現在の行数 ＝ 現在の最大行番号＋1
	 [Me1editView setHidesBottomBarWhenPushed:YES]; // 現在のToolBar状態をPushした上で、次画面では非表示にする
	 [self.navigationController pushViewController:Me1editView animated:YES];
	 [Me1editView release]; // self.navigationControllerがOwnerになる
	 */
	//[1.0.1]「新しい・・方式」として名称未定のまま先に進めるようにした
	e1newObj.name = nil; //(未定)  NSLocalizedString(@"New Pack",nil);
	e1newObj.row = [NSNumber numberWithInteger:MiSection0Rows]; // 末尾に追加：行番号(row) ＝ 現在の行数 ＝ 現在の最大行番号＋1
	
	//[1.0.3]E1新規追加と同時にE2にも1レコード追加する。空のまま戻れば、viewWillAppearにて削除される
	//[1.0.3]特にPADの場合、タテにするとE1の次にE3が表示されるので、新しい目次が少なくとも1つ必要になる。
	E2 *e2newObj = [NSEntityDescription insertNewObjectForEntityForName:@"E2" inManagedObjectContext:Rmoc];
	e2newObj.row = [NSNumber numberWithInt:0];
	e2newObj.name = nil; //(未定)
	e2newObj.parent = e1newObj; // 親子リンク
	
	// SAVE
	NSError *err = nil;
	if (![Rmoc save:&err]) {
		NSLog(@"Unresolved error %@, %@", err, [err userInfo]);
		return;
	}
	// E2:Groupへ
	NSIndexPath* ip = [NSIndexPath indexPathForRow:[e1newObj.row integerValue]  inSection:0];
	[self toE2fromE1:e1newObj withIndex:ip]; // 次回の画面復帰のための状態記録をしてからＥ２へドリルダウンする
}


// E1edit View Call
- (void)e1editView:(NSIndexPath *)indexPath
{
	if (MiSection0Rows <= indexPath.row) return;  // Addボタン行などの場合パスする

	if (appDelegate_.app_is_iPad) {
		if ([Mpopover isPopoverVisible]) return; //[1.0.6-Bug01]同時タッチで落ちる⇒既に開いておれば拒否
	}
	
	// E1 : NSManagedObject
	E1 *e1obj = [RfetchedE1 objectAtIndexPath:indexPath];
	
	Me1editView = [[E1edit alloc] init]; // popViewで戻れば解放されているため、毎回alloc必要。
	Me1editView.title = NSLocalizedString(@"Edit Plan",nil);
	Me1editView.Re1target = e1obj;
	Me1editView.PiAddRow = (-1); // Edit mode.
	
	if (appDelegate_.app_is_iPad) {
		[Mpopover release], Mpopover = nil;
		//Mpopover = [[PadPopoverInNaviCon alloc] initWithContentViewController:Me1editView];
		UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:Me1editView];
		Mpopover = [[UIPopoverController alloc] initWithContentViewController:nc];
		[nc release];
		Mpopover.delegate = self;	// popoverControllerDidDismissPopover:を呼び出してもらうため
		//MindexPathEdit = indexPath;
		[MindexPathEdit release], MindexPathEdit = [indexPath copy];
		CGRect rc = [self.tableView rectForRowAtIndexPath:indexPath];
		rc.origin.x = rc.size.width - 65;	rc.size.width = 1;
		rc.origin.y += 10;	rc.size.height -= 20;
		[Mpopover presentPopoverFromRect:rc
								  inView:self.view  permittedArrowDirections:UIPopoverArrowDirectionRight  animated:YES];
		Me1editView.selfPopover = Mpopover;  //[Mpopover release]; //(retain)  内から閉じるときに必要になる
		Me1editView.delegate = self;		// refresh callback
	}
	else {
		[Me1editView setHidesBottomBarWhenPushed:YES]; // 現在のToolBar状態をPushした上で、次画面では非表示にする
		[self.navigationController pushViewController:Me1editView animated:YES];
	}
	[Me1editView release]; // self.navigationControllerがOwnerになる
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (alertView.tag) {
		case ALERT_TAG_HTTPServerStop:
			[RhttpServer stop];
			[RhttpServer release];
			RhttpServer = nil;
			[[NSNotificationCenter defaultCenter] removeObserver:self name:@"LocalhostAdressesResolved" object:nil];
			// 再表示
			//[self.tableView reloadData]; これだけではダメ
			[self viewWillAppear:YES]; // Fech データセットさせるため
			break;
			
		case ALERT_TAG_SupportSite:
			if (buttonIndex == 1) { // OK
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://packlist.tumblr.com/"]];
			}
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
				NSLog(@"MactionDeleteRow=%ld", (long)MactionDeleteRow);
				[self actionE1deleteCell:MactionDeleteRow];
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
		[MdicAddresses release], MdicAddresses = nil;
		MdicAddresses = [[notification object] copy];
		NSLog(@"MdicAddresses: %@", MdicAddresses);
	}
	
	if(MdicAddresses == nil)
	{
		return;
	}
	
	NSString *info;
	UInt16 port = [RhttpServer port];
	
	NSString *localIP = nil;
	localIP = [MdicAddresses objectForKey:@"en0"];
	if (!localIP)
	{
		localIP = [MdicAddresses objectForKey:@"en1"];
	}
	
	if (!localIP)
		info = NSLocalizedString(@"HttpSv NoConnection", nil);
	else
		info = [NSString stringWithFormat:@"%@\n\nhttp://%@:%d", 
				NSLocalizedString(@"HttpSv Addr", nil), localIP, port];
	
	/*	NSString *wwwIP = [addresses objectForKey:@"www"];
	 if (wwwIP)
	 info = [info stringByAppendingFormat:@"Web: %@:%d\n", wwwIP, port];
	 else
	 info = [info stringByAppendingString:@"Web: Unable to determine external IP\n"]; */
	
	//displayInfo.text = info;
	if (RalertHttpServer) {
		RalertHttpServer.message = info;
		[RalertHttpServer show];
	}
}


#pragma mark - View表示

// UITableViewインスタンス生成時のイニシャライザ　viewDidLoadより先に1度だけ通る
- (id)initWithStyle:(UITableViewStyle)style 
{
	self = [super initWithStyle:UITableViewStyleGrouped];  // セクションあり
	if (self) {
		// 初期化成功
		appDelegate_ = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		Me1editView = nil;		// e1addで生成 [self.navigationController pushViewController:]
		MinformationView = nil; // azInformationViewで生成 [self.view.window addSubview:]
		
		// インストールやアップデート後、1度だけ処理する
		NSString *zNew = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]; //（リリース バージョン）は、ユーザーに公開した時のレベルを表現したバージョン表記
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSString* zDef = [defaults valueForKey:@"DefVersion"];
		if (zDef==nil || ![zDef isEqualToString:zNew]) {
			[defaults setValue:zNew forKey:@"DefVersion"];
			MbInformationOpen = YES; // Informationを自動オープンする
		} else {
			MbInformationOpen = NO;
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
	self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc]
											  initWithTitle:@"Top"   //NSLocalizedString(@"Back", nil)
											  style:UIBarButtonItemStylePlain
											  target:nil  action:nil] autorelease];
	
	// Set up Right [Edit] buttons.
#ifdef AzMAKE_SPLASHFACE
	// No Button 国別で文字が変わるため
	UIActivityIndicatorView *actInd = [[[UIActivityIndicatorView alloc]
										initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
	CGRect rc = self.navigationController.view.frame;
	actInd.frame = CGRectMake((rc.size.width-50)/2, (rc.size.height-50)/2, 50, 50);
	[self.navigationController.view addSubview:actInd];
	[actInd startAnimating];
#else
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	self.tableView.allowsSelectionDuringEditing = YES; // 編集モードに入ってる間にユーザがセルを選択できる
#endif	
	
	if (appDelegate_.app_is_Ad) {
		UIImageView* iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Icon24-Free.png"]];
		UIBarButtonItem* bui = [[UIBarButtonItem alloc] initWithCustomView:iv];
		self.navigationItem.leftBarButtonItem	= bui;
		[bui release];
		[iv release];
	}
	
	//------------------------------------------Adより上層になるように
	// Tool Bar Button
	UIBarButtonItem *buFlex = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																			 target:nil action:nil] autorelease];
	MbuInfo = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Icon16-Information.png"]
															   style:UIBarButtonItemStylePlain  //Bordered
											   target:self action:@selector(azInformationView)] autorelease];
	/*UIBarButtonItem *buAction = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
																			   target:self action:@selector(azAction)] autorelease];*/
	
	UIBarButtonItem *buSet = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Icon16-Setting.png"]
															  style:UIBarButtonItemStylePlain  //Bordered
															  target:self action:@selector(azSettingView)] autorelease];
	NSArray *buArray = [NSArray arrayWithObjects: MbuInfo, buFlex, buSet, nil];
	[self setToolbarItems:buArray animated:YES];
#ifdef AzMAKE_SPLASHFACE
	MbuInfo.enabled = NO;
	//buAction.enabled = NO;
	buSet.enabled = NO;
#endif

	// ToolBar表示は、viewWillAppearにて回転方向により制御している。
}

- (void)viewDidLoad 
{ //iCloud
	[super viewDidLoad];
	
	// observe the app delegate telling us when it's finished asynchronously setting up the persistent store
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refetcheAllData:)
												 name:NFM_REFETCH_ALL_DATA   object:appDelegate_];
	
	// listen to our app delegates notification that we might want to refresh our detail view
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshAllViews:) 
												 name:NFM_REFRESH_ALL_VIEWS  object:appDelegate_];
}

- (void)viewWillAppear:(BOOL)animated 
{
	[super viewWillAppear:animated];

	// 画面表示に関係する Option Setting を取得する
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	MbAzOptTotlWeightRound = [defaults boolForKey:GD_OptTotlWeightRound]; // YES=四捨五入 NO=切り捨て
	MbAzOptShowTotalWeight = [defaults boolForKey:GD_OptShowTotalWeight];
	MbAzOptShowTotalWeightReq = [defaults boolForKey:GD_OptShowTotalWeightReq];
	
	self.title = NSLocalizedString(@"Product Title",nil);
	
	if (Rmoc==nil) {
		Rmoc = [appDelegate_ managedObjectContext];
	}
	// CoreData 読み込み
	[self refetcheAllData];	//この中で処理済み [self.tableView reloadData];
	
	if (0 < McontentOffsetDidSelect.y) {
		// app.Me3dateUse=nil のときや、メモリ不足発生時に元の位置に戻すための処理。
		// McontentOffsetDidSelect は、didSelectRowAtIndexPath にて記録している。
		self.tableView.contentOffset = McontentOffsetDidSelect;
	}
}

// ビューが最後まで描画された後やアニメーションが終了した後にこの処理が呼ばれる
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	
	if (appDelegate_.app_is_iPad) {
		[self.navigationController setToolbarHidden:NO animated:animated]; // ツールバー表示する
	} else {
		if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) { // ヨコ
			[self.navigationController setToolbarHidden:YES animated:animated]; // ツールバー消す
		} else {
			[self.navigationController setToolbarHidden:NO animated:animated]; // ツールバー表示する
		}
	}
	
	[self.tableView flashScrollIndicators]; // Apple基準：スクロールバーを点滅させる

	if (MbInformationOpen) {	//initWithStyleにて判定処理している
		MbInformationOpen = NO;	// 以後、自動初期表示しない。
		[self azInformationView];  //[1.0.2]最初に表示する。バックグランド復帰時には通らない
	}
	
	if (appDelegate_.app_is_Ad) {
		//【Tips】タテから始まるとき、willRotateToInterfaceOrientation:を通らずに、ここを通る　⇒ AdRefresh：にて初期タテ配置となる
		//【Tips】ヨコから始まるとき、ここよりもloadView：よりも先に willRotateToInterfaceOrientation: を通る ⇒ willRotateにてヨコ配置となる
		[appDelegate_ AdRefresh:YES];	//広告許可
	}
}

// この画面が非表示になる直前に呼ばれる
- (void)viewWillDisappear:(BOOL)animated 
{
	if (appDelegate_.app_is_iPad) {
		if ([Mpopover isPopoverVisible]) { //[1.0.6-Bug01]戻る同時タッチで落ちる⇒強制的に閉じるようにした。
			[Mpopover dismissPopoverAnimated:animated];
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
	if (appDelegate_.app_is_iPad) {
		return YES;  // 現在の向きは、self.interfaceOrientation で取得できる
	} else {
		if (appDelegate_.AppShouldAutorotate==NO) {
			// 回転禁止にしている場合
			[self.navigationController setToolbarHidden:NO animated:YES]; // ツールバー表示する
			if (interfaceOrientation == UIInterfaceOrientationPortrait)
			{ // 正面（ホームボタンが画面の下側にある状態）
				return YES; // この方向だけ常に許可する
			}
			return NO; // その他、禁止
		}
		
		// 回転許可
		if (UIInterfaceOrientationIsPortrait(interfaceOrientation))
		{	// タテ
			[self.navigationController setToolbarHidden:NO animated:YES]; // ツールバー表示する
		} else {
			[self.navigationController setToolbarHidden:YES animated:YES]; // ツールバー消す
			if (MinformationView) {
				[MinformationView hide]; // 正面でなければhide
				[MinformationView release], MinformationView = nil;
			}
		}
		return YES;  // 現在の向きは、self.interfaceOrientation で取得できる
	}
}

// shouldAutorotateToInterfaceOrientation で YES を返すと、回転開始時に呼び出される
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation 
													duration:(NSTimeInterval)duration
{
	if (appDelegate_.app_is_iPad) {
		MbuInfo.enabled = YES;
	} else {
		// InformationViewボタン：正面のときだけ有効にする
		MbuInfo.enabled = (toInterfaceOrientation == UIInterfaceOrientationPortrait);
	}

	if (appDelegate_.app_is_Ad) {
		// 広告非表示でも回転時に位置調整しておく必要あり ＜＜現れるときの開始位置のため＞＞
		// ここが最初の生成となる。この後、loadView: よりも先に willRotateToInterfaceOrientation: を通り、回転位置セットされる。
		[appDelegate_ AdRefresh];	//広告生成のみ
		[appDelegate_ AdViewWillRotate:toInterfaceOrientation];
	}
}

// 回転した後に呼び出される
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{	// Popoverの位置を調整する　＜＜UIPopoverController の矢印が画面回転時にターゲットから外れてはならない＞＞
	if ([Mpopover isPopoverVisible]) {
		if (MindexPathEdit) { 
			//NSLog(@"MindexPathEdit=%@", MindexPathEdit);
			[self.tableView scrollToRowAtIndexPath:MindexPathEdit 
								  atScrollPosition:UITableViewScrollPositionMiddle animated:NO]; // YESだと次の座標取得までにアニメーションが終了せずに反映されない
			[Mpopover presentPopoverFromRect:[self.tableView rectForRowAtIndexPath:MindexPathEdit]
									  inView:self.view  permittedArrowDirections:UIPopoverArrowDirectionAny  animated:YES];
		} else {
			// Information, Setting などで、回転後のアンカー位置が再現不可なので閉じる
			[Mpopover dismissPopoverAnimated:YES];
			[Mpopover release], Mpopover = nil;
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
	
	if (RhttpServer) {
		[RhttpServer stop];
		[RhttpServer release], RhttpServer = nil;
	}
	[RalertHttpServer release], RalertHttpServer = nil;
	[MdicAddresses release], MdicAddresses = nil;
	[RfetchedE1 release],		RfetchedE1 = nil;
	
	if (MinformationView) {
		[MinformationView hide]; // 正面でなければhide
		[MinformationView release], MinformationView = nil;
	}
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

	if (appDelegate_.app_is_iPad) {
		Mpopover.delegate = nil;	//[1.0.6-Bug01]戻る同時タッチで落ちる⇒delegate呼び出し強制断
		[Mpopover release], Mpopover = nil;
		[MindexPathEdit release], MindexPathEdit = nil;
	}
	//--------------------------------@property (retain)
	[Rmoc release];
    [super dealloc];
}


#pragma mark - TableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
#ifdef AzMAKE_SPLASHFACE
    return 0;
#else
	return 2; // (0)PackList　　(1)Action menu
#endif
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	switch (section) {
		case 0:
			return MiSection0Rows + 1; // +1:Add行
		case 1:
			if (appDelegate_.AppEnabled_Dropbox) {
				return 5;	//Action menu
			}
			return 4;	//Action menu
	}
	return 0;
}

// TableView セクションタイトルを応答
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
	switch (section) {
		case 0:
			if (appDelegate_.app_is_iPad  &&  appDelegate_.app_is_Ad) {
				if (MiSection0Rows <= 0) {
					return [NSString stringWithFormat:@"\n\n\n%@", 
							NSLocalizedString(@"Plan Nothing",nil)];
				}
				return @"\n\n";	// iAd上部スペース
			} else {
				if (MiSection0Rows <= 0) {
					return NSLocalizedString(@"Plan Nothing",nil);
				}
				//[1.0.1]//return NSLocalizedString(@"Plan",nil);
			}
			break;
			
		case 1:
			return NSLocalizedString(@"Action menu",nil);
			break;
	}
	return nil;
}

// TableView セクションフッタを応答
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section 
{
	switch (section) {
		case 1: {
			NSString *zz = @"";  //NSLocalizedString(@"iCloud OFF",nil);＜＜Stableリリースするまで保留。
			if (appDelegate_.AppEnabled_iCloud) {
				zz = NSLocalizedString(@"iCloud ON",nil); //@"<<< Will syncronize with iCloud >>>";
			}
			if (appDelegate_.app_is_iPad) {
				return [zz stringByAppendingString:@"\n\n\n\n\n\n\n\n\nAzukiSoft Project\n©1995-2011 Azukid\n\n\n\n"];
			} else {
				return [zz stringByAppendingString:@"\n\n\n\nAzukiSoft Project\n©1995-2011 Azukid\n"];
			}
		} break;
	}
	return nil;
}


// セルの高さを指示する
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if (appDelegate_.app_is_iPad) {
		return 50;
	} else {
		return 44; // デフォルト：44ピクセル
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *zCellDefault = @"CellDefault";
	static NSString *zCellSubtitle = @"CellSubtitle";
  //  static NSString *zCelliAd = @"CelliAd";
    UITableViewCell *cell = nil;

	if (indexPath.section == 0) { //-----------------------------------------------------------Section(0) PackList
		NSInteger rows = MiSection0Rows - indexPath.row;
		if (0 < rows) {
			// E1ノードセル
			cell = [tableView dequeueReusableCellWithIdentifier:zCellSubtitle];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] 
						 initWithStyle:UITableViewCellStyleSubtitle
						 reuseIdentifier:zCellSubtitle] autorelease];
			}
			// E1 : NSManagedObject
			E1 *e1obj = [RfetchedE1 objectAtIndexPath:indexPath];
			
#ifdef DEBUG
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

			if (appDelegate_.app_is_iPad) {
				cell.textLabel.font = [UIFont systemFontOfSize:20];
				cell.detailTextLabel.font = [UIFont systemFontOfSize:14];
			} else {
				cell.textLabel.font = [UIFont systemFontOfSize:18];
				cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
			}
			cell.textLabel.textAlignment = UITextAlignmentLeft;
			cell.textLabel.textColor = [UIColor blackColor];
			
			cell.detailTextLabel.textAlignment = UITextAlignmentLeft;
			cell.detailTextLabel.textColor = [UIColor brownColor];
			
			// ＜高速化＞ E3(Item)更新時、その親E2のsum属性、さらにその親E1のsum属性を更新することで整合および参照時の高速化を実現した。
			NSInteger lNoGray = [e1obj.sumNoGray integerValue];
			NSInteger lNoCheck = [e1obj.sumNoCheck integerValue];
			// 重量
			double dWeightStk;
			double dWeightReq;
			if (MbAzOptShowTotalWeight) {
				NSInteger lWeightStk = [e1obj.sumWeightStk integerValue];
				if (MbAzOptTotlWeightRound) {
					// 四捨五入　＜＜ %.1f により小数第2位が丸められる＞＞ 
					dWeightStk = (double)lWeightStk / 1000.0f;
				} else {
					// 切り捨て                       ↓これで下2桁が0になる
					dWeightStk = (double)(lWeightStk / 100) / 10.0f;
				}
			}
			if (MbAzOptShowTotalWeightReq) {
				NSInteger lWeightReq = [e1obj.sumWeightNed integerValue];
				if (MbAzOptTotlWeightRound) {
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
			
			if (MbAzOptShowTotalWeight && MbAzOptShowTotalWeightReq) {
				cell.detailTextLabel.text = [NSString stringWithFormat:@"%.1f／%.1fKg  %@", 
											 dWeightStk, dWeightReq, zNote];
			} else if (MbAzOptShowTotalWeight) {
				cell.detailTextLabel.text = [NSString stringWithFormat:@"%.1fKg  %@", 
											 dWeightStk, zNote];
			} else if (MbAzOptShowTotalWeightReq) {
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

				if (UIGraphicsBeginImageContextWithOptions != NULL) { // iOS4.0以上
					UIGraphicsBeginImageContextWithOptions(imageView1.image.size, NO, 0.0); //[0.4.18]Retina対応
				} else { // Old
					UIGraphicsBeginImageContext(imageView1.image.size);
				}

				CGRect rect = CGRectMake(0, 0, imageView1.image.size.width, imageView1.image.size.height);
				[imageView1.image drawInRect:rect];  
				[imageView2.image drawInRect:rect blendMode:kCGBlendModeMultiply alpha:1.0];  
				UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();  
				UIGraphicsEndImageContext();  
				[cell.imageView setImage:resultingImage];
				AzRETAIN_CHECK(@"E1 lNoCheck:imageView1", imageView1, 1)
				[imageView1 release];
				AzRETAIN_CHECK(@"E1 lNoCheck:imageView2", imageView2, 1)
				[imageView2 release];
				AzRETAIN_CHECK(@"E1 lNoCheck:resultingImage", resultingImage, 2) //=2:releaseするとフリーズ
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
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault      // Default型
											   reuseIdentifier:zCellDefault] autorelease];
			}

			if (appDelegate_.app_is_iPad) {
				cell.textLabel.font = [UIFont systemFontOfSize:18];
			} else {
				cell.textLabel.font = [UIFont systemFontOfSize:14];
			}
			cell.textLabel.textAlignment = UITextAlignmentCenter; // 中央寄せ
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
	else { //-----------------------------------------------------------Section(1) Action menu
		cell = [tableView dequeueReusableCellWithIdentifier:zCellSubtitle];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
										   reuseIdentifier:zCellSubtitle] autorelease];
		}

		if (appDelegate_.app_is_iPad) {
			cell.textLabel.font = [UIFont systemFontOfSize:18];
			cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
			cell.accessoryType = UITableViewCellAccessoryNone;
		} else {
			cell.textLabel.font = [UIFont systemFontOfSize:14];
			cell.detailTextLabel.font = [UIFont systemFontOfSize:10];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;	// > ディスクロージャマーク
		}
		cell.textLabel.textAlignment = UITextAlignmentLeft; 
		cell.textLabel.textColor = [UIColor darkGrayColor];
		cell.detailTextLabel.textAlignment = UITextAlignmentLeft;
		cell.detailTextLabel.textColor = [UIColor grayColor];
		cell.showsReorderControl = NO;

		NSInteger iRow = indexPath.row;
		if (appDelegate_.AppEnabled_Dropbox==NO && 1<=iRow) iRow++; // Dropbox無効
		switch (iRow) {
			case 0:
				cell.imageView.image = [UIImage imageNamed:@"Icon32-SharedAdd"];
				cell.textLabel.text = NSLocalizedString(@"Import SharePlan",nil);
				cell.detailTextLabel.text = NSLocalizedString(@"Import SharePlan msg",nil);
				break;
				
			case 1:
				cell.imageView.image = [UIImage imageNamed:@"Dropbox-130x44"];
				cell.textLabel.text = NSLocalizedString(@"Import Dropbox",nil);
				cell.detailTextLabel.text = NSLocalizedString(@"Import Dropbox msg",nil);
				break;
				
			case 2:
				cell.imageView.image = [UIImage imageNamed:@"Icon32-GoogleAdd"];
				cell.textLabel.text = NSLocalizedString(@"Import Google",nil);
				cell.detailTextLabel.text = NSLocalizedString(@"Import Google msg",nil);
				break;
				
			case 3:
				cell.imageView.image = [UIImage imageNamed:@"Icon32-NearPcAdd"];
				cell.textLabel.text = NSLocalizedString(@"Import YourPC",nil);
				cell.detailTextLabel.text = NSLocalizedString(@"Import YourPC msg",nil);
				break;
				
			case 4:
				cell.imageView.image = [UIImage imageNamed:@"Icon32-PasteAdd"];
				cell.textLabel.text = NSLocalizedString(@"Import PasteBoard",nil);
				cell.detailTextLabel.text = NSLocalizedString(@"Import PasteBoard msg",nil);
				break;
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
		NSInteger rows = MiSection0Rows - indexPath.row;
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
	McontentOffsetDidSelect = [tableView contentOffset];

	if (indexPath.section == 0) {
		NSInteger rows = MiSection0Rows - indexPath.row;
		if (0 < rows) {
			if (self.editing) {
				[self e1editView:indexPath];
			} else {
				// E1 : NSManagedObject
				E1 *e1obj = [RfetchedE1 objectAtIndexPath:indexPath];
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
	else if (indexPath.section == 1) {
		NSInteger iRow = indexPath.row;
		if (appDelegate_.AppEnabled_Dropbox==NO && 1<=iRow) iRow++; // Dropbox無効
		switch (iRow) {
			case 0: // SharePlan Search
				[self	actionImportSharedPackList];
				break;
				
			case 1: // Restore from Dropbox
				[self actionImportDropbox];
				break;
				
			case 2: // Restore from Google
				[self actionImportGoogle];
				break;
				
			case 3: // Restore from YourPC
				[self actionImportYourPC];
				break;
				
			case 4: // PasteBoard
				[self actionImportPasteBoard];
				break;
		}
	}
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
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
											forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		// 削除コマンド警告　==>> (void)actionSheet にて処理
		//NG//MindexPathActionDelete = indexPath;  retainが必要になる
		MactionDeleteRow = indexPath.row;
		// 削除コマンド警告
		UIActionSheet *action = [[[UIActionSheet alloc] 
								  initWithTitle:NSLocalizedString(@"CAUTION", nil)
								  delegate:self 
								  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
								  destructiveButtonTitle:NSLocalizedString(@"DELETE Pack", nil)
								  otherButtonTitles:nil] autorelease];
		action.tag = ACTIONSEET_TAG_DELETEPACK;
		if (self.interfaceOrientation == UIInterfaceOrientationPortrait 
			OR self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
			// タテ：ToolBar表示
			[action showFromToolbar:self.navigationController.toolbar]; // ToolBarがある場合
		} else {
			// ヨコ：ToolBar非表示（TabBarも無い）　＜＜ToolBar無しでshowFromToolbarするとFreeze＞＞
			[action showInView:self.view]; //windowから出すと回転対応しない
		}
		//BUG//[action release]; autoreleaseにした
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
	if (indexPath.section==0 && indexPath.row < MiSection0Rows) return YES;
	return NO;  // 最終行のAdd行は移動禁止
}

// Editモード時の行移動「先」を返す　　＜＜最終行のAdd専用行への移動ならば1つ前の行を返している＞＞
- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)oldPath 
															toProposedIndexPath:(NSIndexPath *)newPath {
    NSIndexPath *target = newPath;
    // Add行が異動先になった場合、その1つ前の通常行を返すことにより、Add行への移動禁止となる。
	NSInteger rows = MiSection0Rows - 1; // 移動可能な行数（Add行を除く）
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
	E1 *e1obj = [RfetchedE1 objectAtIndexPath:oldPath];
	e1obj.row = [NSNumber numberWithInteger:newPath.row];  // 指定セルを先に移動
	// 移動行間のE1エンティティ属性(row)を書き換える
	NSInteger i;
    NSIndexPath *ip = nil;
	if (oldPath.row < newPath.row) {
		// 後(下)へ移動
		for ( i=oldPath.row ; i < newPath.row ; i++) {
			ip = [NSIndexPath indexPathForRow:(NSUInteger)i+1 inSection:newPath.section];
			e1obj = [RfetchedE1 objectAtIndexPath:ip];
			e1obj.row = [NSNumber numberWithInteger:i];
		}
	} else {
		// 前(上)へ移動
		for (i = newPath.row ; i < oldPath.row ; i++) {
			ip = [NSIndexPath indexPathForRow:(NSUInteger)i inSection:newPath.section];
			e1obj = [RfetchedE1 objectAtIndexPath:ip];
			e1obj.row = [NSNumber numberWithInteger:i+1];
		}
	}
	// SAVE　＜＜万一システム障害で落ちてもデータが残るようにコマメに保存する方針である＞＞
	NSError *error = nil;
	if (![Rmoc save:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		exit(-1);  // Fail
	}
	// 上で並び替えられた結果を再フィッチする（performFetch）  コンテキスト変更したときは再抽出する
	//NSError *error = nil;
	if (![RfetchedE1 performFetch:&error]) {
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
		if (appDelegate_.AppUpdateSave) { // E1editにて、変更あるので閉じさせない
			alertBox(NSLocalizedString(@"Cancel or Save",nil), 
					 NSLocalizedString(@"Cancel or Save msg",nil), NSLocalizedString(@"Roger",nil));
			return NO; 
		}
	}
	[Rmoc rollback]; // 前回のSAVE以降を取り消す。＜＜サンプルの一時取込をクリアするために必要
	return YES; // 閉じることを許可
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{	// [Cancel][Save][枠外タッチ]何れでも閉じるときここを通る
	[self refreshE1view];
	return;
}

@end

