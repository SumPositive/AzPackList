//
//  E2viewController.m
//  iPack E2 Section
//
//  Created by 松山 和正 on 09/12/04.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Global.h"
#import "AppDelegate.h"
#import "Elements.h"
#import "E2viewController.h"
#import "E3viewController.h"
#import "E2edit.h"
#import "GooDocsTVC.h"
#import "SettingTVC.h"
#import "ExportServerVC.h"
#import "HTTPServer.h"
#import "MyHTTPConnection.h"
#import "localhostAddresses.h"
#import "FileCsv.h"
#import "WebSiteVC.h"
#import "SpAppendVC.h"
#import "DropboxVC.h"

#ifdef AzPAD
//#import "PadPopoverInNaviCon.h"
#endif


#define ACTIONSEET_TAG_DELETEGROUP	901 // 適当な重複しない識別数値を割り当てている
#define ACTIONSEET_TAG_MENU			910

#define ALERT_TAG_TESTDATA			109
#define ALERT_TAG_HTTPServerStop	118
#define ALERT_TAG_ALLZERO			127


@interface E2viewController (PrivateMethods)
- (void)allZero;
- (void)addTestData;
- (void)httpInfoUpdate:(NSNotification *)notification;
- (void)azAction;
- (void)azSettingView;
- (void)e2adde2add;
- (void)e2editView:(NSIndexPath *)indexPath;
- (void)fromE2toE3:(NSInteger)iSection;
@end

@implementation E2viewController
@synthesize Re1selected;
@synthesize PbSharePlanList;
#ifdef AzPAD
@synthesize delegateE3viewController;
#endif


#pragma mark - Delegate

#ifdef AzPAD
- (void)setPopover:(UIPopoverController*)pc
{
	menuPopover = pc;
	menuPopover.delegate = self;	//枠外タッチでpopoverControllerDidDismissPopover：を呼び出すため。
}

- (void)refreshE2view
{
	if (MindexPathEdit)
	{
		// E2 再描画
		NSArray* ar = [NSArray arrayWithObject:MindexPathEdit];
		[self.tableView reloadRowsAtIndexPaths:ar withRowAnimation:NO];
		// E3 再描画
		[self fromE2toE3:MindexPathEdit.row];
	}
}
#endif


#pragma mark - Action

- (void)azSettingView
{
	SettingTVC *vi = [[SettingTVC alloc] init];
	[vi setHidesBottomBarWhenPushed:YES]; // 現在のToolBar状態をPushした上で、次画面では非表示にする
	[self.navigationController pushViewController:vi animated:YES];
	[vi release];
}

/*
- (void)azAction
{
	UIActionSheet *as = [[[UIActionSheet alloc] init] autorelease];
	as.delegate = self;
	as.tag = ACTIONSEET_TAG_MENU;
	[as addButtonWithTitle:NSLocalizedString(@"All ZERO",nil)];				// (0)
	as.destructiveButtonIndex = 0;	// 赤色(注意)ボタン
	[as addButtonWithTitle:NSLocalizedString(@"Email send",nil)];				// (1)[1.1]
	[as addButtonWithTitle:NSLocalizedString(@"SharePlan Append",nil)];	// (2)[0.7]
	[as addButtonWithTitle:NSLocalizedString(@"Backup Google",nil)];		// (3)
	[as addButtonWithTitle:NSLocalizedString(@"Backup YourPC",nil)];		// (4)
	[as addButtonWithTitle:NSLocalizedString(@"Copied to PasteBoard",nil)];	// (5)
	[as addButtonWithTitle:NSLocalizedString(@"Cancel",nil)];				// (6)
	as.cancelButtonIndex = 6;		// キャンセル
#ifdef AzPAD
	//if (!menuPopover) {
	if (![menuPopover isPopoverVisible]) {
		[as addButtonWithTitle:@"Dummy"];	// (6) Pad:なぜか？これが無いとCancelが出ない
	}
#else
#ifdef AzDEBUG
	[as addButtonWithTitle:@"Test ADD 10x10"];	// (7)
#endif
#endif
	[as showFromToolbar:self.navigationController.toolbar];
}
*/

 // E2グループ削除
- (void)actionE2delateCell:(NSIndexPath*)indexPath
{
	// CoreDataモデル：エンティティ間の削除ルールは双方「無効にする」を指定。（他にするとフリーズ）
	// 削除対象の ManagedObject をチョイス
	E2 *e2objDelete = [RaE2array objectAtIndex:indexPath.row];
	// 該当行削除：　e2list 削除 ==>> しかし、managedObjectContextは削除されない！！！後ほど削除
	[RaE2array removeObjectAtIndex:indexPath.row];  // × removeObject:e2obj];
	MiSection0Rows--; // この削除により1つ減
	// 該当行以下.row更新：　RrE2array 更新 ==>> なんと、managedObjectContextも更新される！！！
	for (NSInteger i = indexPath.row; i < MiSection0Rows ; i++) {
		E2 *e2obj = [RaE2array objectAtIndex:i];
		e2obj.row = [NSNumber numberWithInteger:i];
	}
	// e2obj.childs を全て削除する  ＜＜managedObjectContext を直接削除している＞＞
	for (E3 *e3obj in e2objDelete.childs) {
		[Re1selected.managedObjectContext deleteObject:e3obj];
	}
	// RrE2arrayの削除はmanagedObjectContextに反映されないため、ここで削除する。
	e2objDelete.parent = nil;	//[1.0.1]次の集計から除外するためリンク切る ＜＜＜deleteObjectでは切れない＞＞＞
	[Re1selected.managedObjectContext deleteObject:e2objDelete];
	// E1 sum属性　＜高速化＞ 親sum保持させる
	[Re1selected setValue:[Re1selected valueForKeyPath:@"childs.@sum.sumNoGray"] forKey:@"sumNoGray"];
	[Re1selected setValue:[Re1selected valueForKeyPath:@"childs.@sum.sumNoCheck"] forKey:@"sumNoCheck"];
	[Re1selected setValue:[Re1selected valueForKeyPath:@"childs.@sum.sumWeightStk"] forKey:@"sumWeightStk"];
	[Re1selected setValue:[Re1selected valueForKeyPath:@"childs.@sum.sumWeightNed"] forKey:@"sumWeightNed"];
	
	if (PbSharePlanList==NO) {  // SpMode=YESならば[SAVE]ボタンを非表示にしたので通らないハズだが、念のため。
		// SAVE　＜＜万一システム障害で落ちてもデータが残るようにコマメに保存する方針＞＞
		NSError *error = nil;
		if (![Re1selected.managedObjectContext save:&error]) {
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			//exit(-1);  // Fail
		}
	}
	
	NSLog(@"indexPath=%@", indexPath);
	// テーブルビューから選択した行を削除する　　　　　　//[self.tableView reloadData]だとアニメ効果が無いため下記採用
	if ([RaE2array count]<=0) {
		[self.tableView reloadData];	//FIX//残り1個を削除すると落ちるのを回避するため。アニメ効果ない
	} else {
		[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
							  withRowAnimation:UITableViewRowAnimationFade];		//アニメ効果のため
	}
#ifdef AzPAD
	// 右ナビ E3 を更新する
	[self fromE2toE3:(-9)]; // (-9)E3初期化（リロード＆再描画、セクション0表示）
#endif
}

// All Zero  全在庫数量を、ゼロにする
- (void)actionAllZero
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"All ZERO",nil)
													message:nil
												   delegate:self 
										  cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
										  otherButtonTitles:@"OK", nil];
	alert.tag = ALERT_TAG_ALLZERO;
	[alert show];
	[alert release];
}
- (void)actionAllZero_OKGO
{	// 全在庫数量を、ゼロにする
	if ([RaE2array count] <= 0) return;
	//----------------------------------------------------------------------------CoreData Loading
	for (E2 *e2obj in RaE2array) {
		//---------------------------------------------------------------------------- E3 Section
		// SELECT & ORDER BY　　テーブルの行番号を記録した属性"row"で昇順ソートする
		NSMutableArray *e3array = [[NSMutableArray alloc] initWithArray:[e2obj.childs allObjects]];
		// ソートなしのまま、全e3の .stock を ZERO にする
		for (E3 *e3obj in e3array) {
			NSInteger lStock = 0; // ZERO clear
			NSInteger lWeight = [e3obj.weight integerValue];
			NSInteger lRequired = [e3obj.need integerValue];
			[e3obj setValue:[NSNumber numberWithInteger:lStock] forKey:@"stock"];
			[e3obj setValue:[NSNumber numberWithInteger:(lWeight*lStock)] forKey:@"weightStk"];
			[e3obj setValue:[NSNumber numberWithInteger:(lRequired-lStock)] forKey:@"lack"]; // 不足数
			[e3obj setValue:[NSNumber numberWithInteger:((lRequired-lStock)*lWeight)] forKey:@"weightLack"]; // 不足重量
			if (0 < lRequired) {
				[e3obj setValue:[NSNumber numberWithInteger:1] forKey:@"noGray"];
				[e3obj setValue:[NSNumber numberWithInteger:1] forKey:@"noCheck"];
			} else {
				[e3obj setValue:[NSNumber numberWithInteger:0] forKey:@"noGray"];
				[e3obj setValue:[NSNumber numberWithInteger:0] forKey:@"noCheck"];
			}
		}
		[e3array release];
		
		// E2 sum属性　＜高速化＞ 親sum保持させる
		[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.noGray"] forKey:@"sumNoGray"];
		[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.noCheck"] forKey:@"sumNoCheck"];
		[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.weightStk"] forKey:@"sumWeightStk"];
		[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.weightNed"] forKey:@"sumWeightNed"];
	}
	
	// E1 sum属性　＜高速化＞ 親sum保持させる
	[Re1selected setValue:[Re1selected valueForKeyPath:@"childs.@sum.sumNoGray"] forKey:@"sumNoGray"];
	[Re1selected setValue:[Re1selected valueForKeyPath:@"childs.@sum.sumNoCheck"] forKey:@"sumNoCheck"];
	[Re1selected setValue:[Re1selected valueForKeyPath:@"childs.@sum.sumWeightStk"] forKey:@"sumWeightStk"];
	[Re1selected setValue:[Re1selected valueForKeyPath:@"childs.@sum.sumWeightNed"] forKey:@"sumWeightNed"];
	
	if (PbSharePlanList==NO) {  // SpMode=YESならば[SAVE]ボタンを非表示にしたので通らないハズだが、念のため。
		// SAVE : e3edit,e2list は ManagedObject だから更新すれば ManagedObjectContext に反映されている
		NSError *err = nil;
		if (![Re1selected.managedObjectContext save:&err]) {
			NSLog(@"Unresolved error %@, %@", err, [err userInfo]);
			abort();
		}
	}
	
	[self viewWillAppear:YES];
	// 先頭を表示する
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
	[self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
#ifdef AzPAD
	// 右ナビ E3 を更新する
	[self fromE2toE3:(-9)]; // (-9)E3初期化（リロード＆再描画、セクション0表示）
#endif
}

- (void)actionEmailSend
{
	MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
	picker.mailComposeDelegate = self;
	
#ifdef AzDEBUG
	// To: 宛先
	NSArray *toRecipients = [NSArray arrayWithObject:@"m@azukid.com"];
	[picker setToRecipients:toRecipients];
#endif
	
	// Subject: 件名
	NSString* zSubj = [NSString stringWithFormat:@"%@ : %@ ", NSLocalizedString(@"Product Title",nil), Re1selected.name];
	[picker setSubject:zSubj];  

	// CSV SAVE
	NSString *zErr = [FileCsv zSave:Re1selected toLocalFileName:GD_CSVFILENAME4]; // この間、待たされるのが問題になるかも！！
	if (zErr) {
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO; // NetworkアクセスサインOFF
		UIAlertView *alert = [[UIAlertView alloc] 
							  initWithTitle:NSLocalizedString(@"CSV Save Fail",nil)
							  message:zErr
							  delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
		[alert show];
		[alert release];
		return;
	}
	NSString *home_dir = NSHomeDirectory();
	NSString *doc_dir = [home_dir stringByAppendingPathComponent:@"tmp"];
	NSString *csvPath = [doc_dir stringByAppendingPathComponent:GD_CSVFILENAME4];
	// Body: 添付ファイル
	//NSString* fileName = @"attachement.packlist";
	NSString* fileName = [NSString stringWithFormat:@"%@.packlist", Re1selected.name];
	NSData* fileData = [NSData dataWithContentsOfFile:csvPath];
	[picker addAttachmentData:fileData mimeType:@"application/packlist" fileName:fileName];
	
	// Body: 本文
	NSString* zBody = [NSString stringWithFormat:@"%@%@%@%@%@", 
					   NSLocalizedString(@"Email send Body1",nil),
					   NSLocalizedString(@"Email send Body2",nil),
					   NSLocalizedString(@"Email send Body3",nil),
					   NSLocalizedString(@"Email send Body4",nil),
					   NSLocalizedString(@"Email send Body5",nil) ];
	[picker setMessageBody:zBody isHTML:YES];
	
	// Email オープン
	[appDelegate.mainVC presentModalViewController:picker animated:YES];
	[picker release];
}

- (void)actionSharedPackListUp
{
#ifdef AzPAD
	if ([Mpopover isPopoverVisible]) return; //[1.0.6-Bug01]同時タッチで落ちる⇒既に開いておれば拒否
#endif

	SpAppendVC *spAppendVC = [[SpAppendVC alloc] init];
	spAppendVC.Re1selected = Re1selected;

#ifdef AzPAD
	spAppendVC.title = NSLocalizedString(@"SharePlan Append",nil);
	if ([menuPopover isPopoverVisible]) { //タテ
		//[vc setHidesBottomBarWhenPushed:YES]; // 現在のToolBar状態をPushした上で、次画面では非表示にする
		[self.navigationController pushViewController:spAppendVC animated:YES];
	} else {	//ヨコ
		[Mpopover release], Mpopover = nil;
		//Mpopover = [[PadPopoverInNaviCon alloc] initWithContentViewController:vc];
		UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:spAppendVC];
		Mpopover = [[UIPopoverController alloc] initWithContentViewController:nc];
		[nc release];
		Mpopover.delegate = self;	// popoverControllerDidDismissPopover:を呼び出してもらうため
		[MindexPathEdit release], MindexPathEdit = nil;
		[Mpopover presentPopoverFromRect:CGRectMake(320/2, 768-60, 1,1)	 //ヨコしか通らない。タテならばPopover内になるから
								  inView:self.navigationController.view
				permittedArrowDirections:UIPopoverArrowDirectionDown  animated:YES];
		spAppendVC.selfPopover = Mpopover;
		//spAppendVC.delegate = nil; //Uploadだから再描画不要
	}
#else
	[spAppendVC setHidesBottomBarWhenPushed:YES]; // 現在のToolBar状態をPushした上で、次画面では非表示にする
	[self.navigationController pushViewController:spAppendVC animated:YES];
#endif
	[spAppendVC release];
}

- (void)actionBackupDropbox
{
	// 未認証の場合、認証処理後、AppDelegate:handleOpenURL:から呼び出される
	if ([[DBSession sharedSession] isLinked]) 
	{	// Dropbox 認証済み
#ifdef AzPAD
		DropboxVC *vc = [[DropboxVC alloc] initWithNibName:@"DropboxVC-iPad" bundle:nil];
#else
		DropboxVC *vc = [[DropboxVC alloc] initWithNibName:@"DropboxVC" bundle:nil];
#endif
		vc.Re1selected = Re1selected;	// [SAVE]
		[self presentModalViewController:vc animated:YES];
	} else {
		// Dropbox 未認証
		appDelegate.dropboxSaveE1selected = Re1selected;	// [SAVE]
		[[DBSession sharedSession] link];
	}
}

- (void)actionBackupGoogle
{
	if (MiSection0Rows <=0) return;
#ifdef AzPAD
	if ([Mpopover isPopoverVisible]) return; //[1.0.6-Bug01]同時タッチで落ちる⇒既に開いておれば拒否
#endif
	
	GooDocsView *goodocs = [[GooDocsView alloc] initWithStyle:UITableViewStylePlain];
	goodocs.Rmoc = nil;  // Upでは使用しない
	goodocs.Re1selected = Re1selected; // E1
	goodocs.PbUpload = YES;

#ifdef AzPAD
	goodocs.title = NSLocalizedString(@"Backup Google",nil);
	if ([menuPopover isPopoverVisible]) { //タテ
		[self.navigationController pushViewController:goodocs animated:YES];
	} else {	//ヨコ
		[Mpopover release], Mpopover = nil;
		//Mpopover = [[PadPopoverInNaviCon alloc] initWithContentViewController:goodocs];
		UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:goodocs];
		Mpopover = [[UIPopoverController alloc] initWithContentViewController:nc];
		[nc release];
		Mpopover.delegate = self;	// popoverControllerDidDismissPopover:を呼び出してもらうため
		[MindexPathEdit release], MindexPathEdit = nil;
		[Mpopover presentPopoverFromRect:CGRectMake(320/2, 768-60, 1,1)	 //ヨコしか通らない。タテならばPopover内になるから
								  inView:self.navigationController.view
				permittedArrowDirections:UIPopoverArrowDirectionDown  animated:YES];
		goodocs.selfPopover = Mpopover;
		goodocs.delegate = nil; //Uploadだから再描画不要
	}
#else
	goodocs.title = self.title;
	[self.navigationController pushViewController:goodocs animated:YES];
#endif
	[goodocs release];
}

- (void)actionBackupYourPC
{
#ifdef AzPAD
	if ([menuPopover isPopoverVisible]) {	//選択後、Popoverならば閉じる
		[menuPopover dismissPopoverAnimated:YES];
	}
#endif
	// HTTP Server Start
	if (RalertHttpServer == nil) {
		RalertHttpServer = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"HttpSv BACKUP", nil) 
													  message:NSLocalizedString(@"HttpSv Wait", nil) 
													 delegate:self 
											cancelButtonTitle:nil  //@"CANCEL" 
											otherButtonTitles:NSLocalizedString(@"HttpSv stop", nil) , nil];
	}
	RalertHttpServer.tag = ALERT_TAG_HTTPServerStop;
	[RalertHttpServer show];
	//[MalertHttpServer release];
	// CSV SAVE
	NSString *zErr = [FileCsv zSave:Re1selected toLocalFileName:GD_CSVFILENAME4]; // この間、待たされるのが問題になるかも！！
	if (zErr) {
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO; // NetworkアクセスサインOFF
		UIAlertView *alert = [[UIAlertView alloc] 
							  initWithTitle:NSLocalizedString(@"CSV Save Fail",nil)
							  message:zErr
							  delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
		[alert show];
		[alert release];
		return;
	}
	// if (httpServer) return; <<< didSelectRowAtIndexPath:直後に配置してダブルクリック回避している。
	NSString *root = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
	RhttpServer = [HTTPServer new];
	[RhttpServer setType:@"_http._tcp."];
	[RhttpServer setConnectionClass:[MyHTTPConnection class]];
	[RhttpServer setDocumentRoot:[NSURL fileURLWithPath:root]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(httpInfoUpdate:) name:@"LocalhostAdressesResolved" object:nil];
	[localhostAddresses performSelectorInBackground:@selector(list) withObject:nil];
	[RhttpServer setPort:8080];
	[RhttpServer setBackup:YES]; // BACKUP Mode
	[RhttpServer setPlanName:Re1selected.name]; // ファイル名を "プラン名.AzPack.csv" にするため
	NSError *error;
	if(![RhttpServer start:&error])
	{
		NSLog(@"Error starting HTTP Server: %@", error);
		[RhttpServer release];
		RhttpServer = nil;
	}
}

- (void)actionCopiedPasteBoard
{
#ifdef AzPAD
	if ([menuPopover isPopoverVisible]) {	//選択後、Popoverならば閉じる
		[menuPopover dismissPopoverAnimated:YES];
	}
#endif
	// PasteBoard SAVE
	UIAlertView *alert = [[UIAlertView alloc] init];
	alert.title = NSLocalizedString(@"Please Wait",nil);
	[alert show];
	//---------------------------------------CSV SAVE Start.
	NSString *zErr = [FileCsv zSave:Re1selected toLocalFileName:nil]; // nil:PasteBoard Copy mode.
	//---------------------------------------CSV SAVE End.
	[alert dismissWithClickedButtonIndex:0 animated:NO]; // 閉じる
	[alert release];
	if (zErr) {
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO; // NetworkアクセスサインOFF
		alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"PBoard Error",nil)
										   message:zErr
										  delegate:nil 
								 cancelButtonTitle:nil 
								 otherButtonTitles:@"OK", nil];
		[alert show];
		//alert.title = NSLocalizedString(@"PBoard Error",nil);
		//alert.message = zErr;
		//[alert addButtonWithTitle:@"OK"];
		[alert release];
		return;
	}
	alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"PBoard Copy",nil)
									   message:NSLocalizedString(@"PBoard Copy OK",nil)
									  delegate:nil
							 cancelButtonTitle:nil
							 otherButtonTitles:@"OK", nil];
	[alert show];
	//alert.title = NSLocalizedString(@"PBoard Copy",nil);
	//alert.message = NSLocalizedString(@"PBoard Copy OK",nil);
	//[alert addButtonWithTitle:@"OK"];
	[alert release];
}



#pragma mark - delegate <MFMailComposeViewControllerDelegate>

- (void)mailComposeController:(MFMailComposeViewController*)controller 
		  didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{
    switch (result){
        case MFMailComposeResultCancelled:
            //キャンセルした場合
            break;
        case MFMailComposeResultSaved:
            //保存した場合
            break;
        case MFMailComposeResultSent:
            //送信した場合
			alertBox( NSLocalizedString(@"Contact Sent",nil), nil, @"OK" );
            break;
        case MFMailComposeResultFailed:
            //送信失敗
			alertBox( NSLocalizedString(@"Contact Failed",nil), NSLocalizedString(@"Contact Failed msg",nil), @"OK" );
            break;
        default:
            break;
    }
	// [self dismissModalViewControllerAnimated:YES];
	[appDelegate.mainVC dismissModalViewControllerAnimated:YES];
}


#pragma mark - delegate UIActionSheet
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (actionSheet.tag) {
		case ACTIONSEET_TAG_DELETEGROUP: // E2グループ削除
			if (buttonIndex == actionSheet.destructiveButtonIndex) 
			{ //========== E2 削除実行 ==========
				[self actionE2delateCell:MindexPathActionDelete];
			}
			break;
			
/*		case ACTIONSEET_TAG_MENU:
			switch (buttonIndex) {
				case 0: // All Zero  全在庫数量を、ゼロにする
					[self	actionAllZero];
					break;
					
				case 1: // Email send
					[self actionEmailSend];
					break;
					
				case 2: // Upload Share Plan
					[self actionSharedPackListUp];
					break;
					
				case 3: // Backup to Google
					[self actionBackupGoogle];
					break;
					
				case 4: // Backup to YourPC
					[self actionBackupYourPC];
					break;
					
				case 5: // ペーストボードへコピー
					[self actionCopiedPasteBoard];
					break;
					
				case 6: // Cancel
					break;
					
				case 7: // TEST ADD 10x10
				{
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"TEST ADD 10x10 00" 
																	message:@"Please Select" 
																   delegate:self 
														  cancelButtonTitle:@"CANCEL" 
														  otherButtonTitles:@"OK", nil];
					alert.tag = ALERT_TAG_TESTDATA;
					[alert show];
					[alert release];
				}
					break;
			}
			break;*/
			
		default:
			break;
	}
}


#pragma mark - delegate UIAlertView

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (alertView.tag) {
		case ALERT_TAG_TESTDATA:
			if (buttonIndex != 1) return; // CANCEL
			[self addTestData];
			break;
			
		case ALERT_TAG_HTTPServerStop:
			[RhttpServer stop];
			[RhttpServer release];
			RhttpServer = nil;
			[[NSNotificationCenter defaultCenter] removeObserver:self name:@"LocalhostAdressesResolved" object:nil];
			break;
			
		case ALERT_TAG_ALLZERO:
			if (buttonIndex != 1) return; // CANCEL
			[self actionAllZero_OKGO];
			break;
	}
}


#pragma mark  - Local methods

// E2の配下E3を表示する
- (void)fromE2toE3:(NSInteger)iSection  // <0:Sort type, >=0:Section
{													// (-9)E3初期化（リロード＆再描画、セクション0表示）
	E3viewController *e3view;
	
#ifdef AzPAD
	if (PbSharePlanList==NO) {
		// 既存Ｅ３更新
		if ([delegateE3viewController respondsToSelector:@selector(viewWillAppear:)]) {
			assert(delegateE3viewController);
			if (iSection==(-9)) {
				delegateE3viewController.PiFirstSection = 0;
				delegateE3viewController.PiSortType = (-9); // E3初期化（リロード＆再描画、セクション0表示）
			}
			else if (iSection<0) {	// Sort List
				delegateE3viewController.PiFirstSection = 0;
				delegateE3viewController.PiSortType = (-1) * iSection;
			}
			else {
				delegateE3viewController.PiFirstSection = iSection;  //E3で頭出しするセクション
				delegateE3viewController.PiSortType = (-1); // E3既存データあればリロードしない
			}
			delegateE3viewController.PbSharePlanList = PbSharePlanList;
			//
			[delegateE3viewController viewWillAppear:YES];
		}
		return;
	}
#endif
	
	//AzPad でも PbSharePlanList=YES のとき、通る。
	// E3 へドリルダウン
	e3view = [[E3viewController alloc] init];
	// 以下は、E3viewControllerの viewDidLoad 後！、viewWillAppear の前に処理されることに注意！
#ifdef AzPAD
	e3view.title = Re1selected.name;  //  self.title;  // NSLocalizedString(@"Items", nil);
#else
	e3view.title = self.title;  // PbSharePlanList=YES のとき "Sample" になるように
#endif
	e3view.Re1selected = Re1selected; // E1
	//e3view.PiFirstSection = indexPath.row;  // Group.ROW ==>> E3で頭出しするセクション
	//e3view.PiSortType = (-1);
	if (iSection<0) {
		e3view.PiFirstSection = 0;
		e3view.PiSortType = (-1) * iSection;
	} else {
		e3view.PiFirstSection = iSection;  //E3で頭出しするセクション
		e3view.PiSortType = (-1);
	}
	e3view.PbSharePlanList = PbSharePlanList;
	[self.navigationController pushViewController:e3view animated:YES];
	[e3view release];
}


- (void)e2adde2add
{
	// ContextにE2ノードを追加する　E2edit内でCANCELならば削除している
	E2 *e2newObj = [NSEntityDescription insertNewObjectForEntityForName:@"E2"
												 inManagedObjectContext:Re1selected.managedObjectContext];
	//[1.0.1]「新しい・・方式」として名称未定のまま先に進めるようにした
	e2newObj.name = nil; //(未定)  NSLocalizedString(@"New Index",nil);
	e2newObj.row = [NSNumber numberWithInteger:MiSection0Rows]; // 末尾に追加：行番号(row) ＝ 現在の行数 ＝ 現在の最大行番号＋1
	e2newObj.parent = Re1selected;	//親子リンク
	// SAVE
	NSError *err = nil;
	if (![Re1selected.managedObjectContext save:&err]) {
		NSLog(@"Unresolved error %@, %@", err, [err userInfo]);
		return;
	}
	// E3へ RaE2array を渡しているので、ここで e2newObj を追加しておく必要がある
	[RaE2array addObject:e2newObj];
	MiSection0Rows = [RaE2array count];
	
#ifdef AzPAD
	//MindexPathEdit = [NSIndexPath indexPathForRow:0 inSection:MiSection0Rows];	//新しい目次の行
	[self.tableView reloadData];
	NSIndexPath* ip = [NSIndexPath indexPathForRow:[e2newObj.row integerValue]  inSection:0]; //Row,0
	//NG	[self.tableView scrollToRowAtIndexPath:ip
	//NG						  atScrollPosition:UITableViewScrollPositionTop animated:NO];
	// E3.Refresh
	delegateE3viewController.PiSortType = (-9);	// (-9)E3初期化（リロード＆再描画、セクション0表示）
	[delegateE3viewController viewWillAppear:YES];
	// E3へ
	[self fromE2toE3:ip.row]; // Ｅ3へドリルダウンする
#else	
	// E3:Itemへ
	//NSIndexPath* ip = [NSIndexPath indexPathForRow:[e2newObj.row integerValue]  inSection:0];
	[self fromE2toE3:[e2newObj.row integerValue]]; // 次回の画面復帰のための状態記録をしてからＥ２へドリルダウンする
#endif
}

- (void)e2editView:(NSIndexPath *)indexPath
{
	if (indexPath.section != 0) return;  // ここを通るのはセクション0だけ。
	if (MiSection0Rows <= indexPath.row) return;  // Addボタン行などの場合パスする
#ifdef AzPAD
	if ([Mpopover isPopoverVisible]) return; //[1.0.6-Bug01]同時タッチで落ちる⇒既に開いておれば拒否
#endif
	
	E2 *e2obj = [RaE2array objectAtIndex:indexPath.row];
	
	Me2editView = [[E2edit alloc] init]; // popViewで戻れば解放されているため、毎回alloc必要。
	Me2editView.title = NSLocalizedString(@"Edit Group",nil);
	Me2editView.Re1selected = Re1selected;
	Me2editView.Re2target = e2obj;
	Me2editView.PiAddRow = (-1); // Edit mode
	Me2editView.PbSharePlanList = PbSharePlanList;
	
#ifdef AzPAD
	if ([menuPopover isPopoverVisible]) {
		//タテ： E2viewが[MENU]でPopover内包されているとき、E2editはiPhone同様にNavi遷移するだけ
		[self.navigationController pushViewController:Me2editView animated:YES];
	} else {
		//ヨコ： E2viewが左ペインにあるとき、E2editを内包するPopoverを閉じる
		[Mpopover release], Mpopover = nil;
		UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:Me2editView];
		Mpopover = [[UIPopoverController alloc] initWithContentViewController:nc];
		[nc release];
		Mpopover.delegate = self;	// popoverControllerDidDismissPopover:を呼び出してもらうため
		//MindexPathEdit = indexPath;
		[MindexPathEdit release], MindexPathEdit = [indexPath copy];
		CGRect rc = [self.tableView rectForRowAtIndexPath:indexPath];
		rc.origin.x = rc.size.width - 25;	rc.size.width = 1;
		rc.origin.y += 10;	rc.size.height -= 20;
		[Mpopover presentPopoverFromRect:rc
								  inView:self.view  permittedArrowDirections:UIPopoverArrowDirectionLeft  animated:YES];
		Me2editView.selfPopover = Mpopover;  //[Mpopover release]; //(retain)  内から閉じるときに必要になる
		Me2editView.delegate = self;		// refresh callback
	}
#else
	[Me2editView setHidesBottomBarWhenPushed:YES]; // 現在のToolBar状態をPushした上で、次画面では非表示にする
	[self.navigationController pushViewController:Me2editView animated:YES];
#endif
	[Me2editView release]; // self.navigationControllerがOwnerになる
}


#ifdef AzDEBUG
- (void)addTestData
{
	// TEST DATA ADD 10x10
    NSInteger ie2, ie3;
	NSInteger ie3Row;
	NSInteger ie2Row = MiSection0Rows;  // 開始row ＝ 現在ノード数
	NSInteger iStock;
	NSInteger iNeed;
	
	// E2ノード追加
	E2 *e2obj;
	E3 *e3obj;
	for (ie2=0 ; ie2 < 10 ; ie2++, ie2Row++)
	{
		// コンテキストに新規の E2エンティティのオブジェクトを挿入します。
		e2obj = [NSEntityDescription insertNewObjectForEntityForName:@"E2"
											  inManagedObjectContext:Re1selected.managedObjectContext];
		
		[e2obj setValue:[NSString stringWithFormat:@"Group %d",ie2Row] forKey:@"name"];
		[e2obj setValue:[NSNumber numberWithInteger:ie2Row] forKey:@"row"];
		MiSection0Rows = ie2Row;
		
		// e1selected(E1) の childs に newObj を追加する
		[Re1selected addChildsObject:e2obj];
		
		// E3ノード追加
		for (ie3=0, ie3Row=0 ; ie3 < 10 ; ie3++, ie3Row++)
		{
			// コンテキストに新規の E3エンティティのオブジェクトを挿入します。
			e3obj = [NSEntityDescription insertNewObjectForEntityForName:@"E3"
												  inManagedObjectContext:Re1selected.managedObjectContext];
			
			[e3obj setValue:[NSString stringWithFormat:@"Item %d-%d",ie2Row,ie3Row] forKey:@"name"];
			[e3obj setValue:[NSString stringWithFormat:@"Item %d-%d Note",ie2Row,ie3Row] forKey:@"note"];
			
			iStock = ie3;
			iNeed = 9 - ie3;
			
			[e3obj setValue:[NSNumber numberWithInteger:iStock] forKey:@"weight"];
			[e3obj setValue:[NSNumber numberWithInteger:iStock] forKey:@"stock"];
			[e3obj setValue:[NSNumber numberWithInteger:iNeed] forKey:@"need"];
			[e3obj setValue:[NSNumber numberWithInteger:iStock*iStock] forKey:@"weightStk"];  // E3のみ　E1,E2のは不要になった。
			[e3obj setValue:[NSNumber numberWithInteger:iStock*iNeed] forKey:@"weightNed"];  // E3のみ　E1,E2のは不要になった。
			[e3obj setValue:[NSNumber numberWithInteger:iNeed-iStock] forKey:@"lack"];
			[e3obj setValue:[NSNumber numberWithInteger:(iNeed-iStock)*iStock] forKey:@"weightLack"];
			
			NSInteger iNoGray = 0;
			if (0 < iNeed) iNoGray = 1;
			[e3obj setValue:[NSNumber numberWithInteger:iNoGray] forKey:@"noGray"]; // NoGray:有効(0<必要数)アイテム
			
			NSInteger iNoCheck = 0;
			if (0 < iNeed && iStock < iNeed) iNoCheck = 1;
			[e3obj setValue:[NSNumber numberWithInteger:iNoCheck] forKey:@"noCheck"]; // NoCheck:不足アイテム
			
			[e3obj setValue:[NSNumber numberWithInteger:ie3Row] forKey:@"row"];  // row = indexPath.row
			
			// e1selected(E2) の childs に e3node を追加する
			[e2obj addChildsObject:e3obj];
		}
		
		// E2 sum属性　＜高速化＞ 親sum保持させる
		[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.noGray"] forKey:@"sumNoGray"];
		[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.noCheck"] forKey:@"sumNoCheck"];
		[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.weightStk"] forKey:@"sumWeightStk"];
		[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.weightNed"] forKey:@"sumWeightNed"];
	}
	
	// E1 sum属性　＜高速化＞ 親sum保持させる
	[Re1selected setValue:[Re1selected valueForKeyPath:@"childs.@sum.sumNoGray"] forKey:@"sumNoGray"];
	[Re1selected setValue:[Re1selected valueForKeyPath:@"childs.@sum.sumNoCheck"] forKey:@"sumNoCheck"];
	[Re1selected setValue:[Re1selected valueForKeyPath:@"childs.@sum.sumWeightStk"] forKey:@"sumWeightStk"];
	[Re1selected setValue:[Re1selected valueForKeyPath:@"childs.@sum.sumWeightNed"] forKey:@"sumWeightNed"];
	
	if (PbSharePlanList==NO) {  // SpMode=YESならば[SAVE]ボタンを非表示にしたので通らないハズだが、念のため。
		NSError *err = nil;
		if (![Re1selected.managedObjectContext save:&err]) {
			NSLog(@"Unresolved error %@, %@", err, [err userInfo]);
			abort();
		}
	}
	
    //[self.tableView reloadData];   // テーブルビューを更新
	// ROOR階層に戻る
	[self.navigationController popToRootViewControllerAnimated:YES];
}
#endif


#pragma mark - View lifecicle

// UITableViewインスタンス生成時のイニシャライザ　viewDidLoadより先に1度だけ通る
- (id)initWithStyle:(UITableViewStyle)style 
{
	self = [super initWithStyle:UITableViewStyleGrouped];  // セクションありテーブル
	if (self) {
		// 初期化成功
		appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		PbSharePlanList = NO;
	}
	return self;
}

// IBを使わずにviewオブジェクトをプログラム上でcreateするときに使う（viewDidLoadは、nibファイルでロードされたオブジェクトを初期化するために使う）
- (void)loadView
{	//【Tips】ここでaddSubviewするオブジェクトは全てautoreleaseにすること。メモリ不足時には自動的に解放後、改めてここを通るので、初回同様に生成するだけ。
	[super loadView];
	
	// その他、初期化
	
#ifdef AzPAD
	if (PbSharePlanList) {
		self.contentSizeForViewInPopover = GD_POPOVER_SIZE;
		self.navigationController.toolbarHidden = YES;	// ツールバー不要
	} else {
		self.contentSizeForViewInPopover = GD_POPOVER_SIZE; //アクションメニュー配下(Share,Googleなど）においてサイズ統一
		self.navigationItem.hidesBackButton = YES;	// E3側に統一したので不要になった。
		self.navigationController.toolbarHidden = NO;	// ツールバー表示する
	}
#endif

	// Set up NEXT Left [Back] buttons.
	self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc]
											  initWithTitle:NSLocalizedString(@"Group", nil)
											  style:UIBarButtonItemStylePlain 
											  target:nil  action:nil] autorelease];

	if (PbSharePlanList==NO) {
		// Set up Right [Edit] buttons.
		self.navigationItem.rightBarButtonItem = self.editButtonItem;
		self.tableView.allowsSelectionDuringEditing = YES;

/*		// Tool Bar Button
		UIBarButtonItem *buFlex = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																				 target:nil action:nil] autorelease];
		UIBarButtonItem *buAction = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
																				   target:self action:@selector(azAction)] autorelease];
		NSArray *buArray = [NSArray arrayWithObjects: buFlex, buAction, buFlex, nil];
		[self setToolbarItems:buArray animated:YES];*/
	}
}

- (void)viewDidLoad 
{
	[super viewDidLoad];
	// listen to our app delegates notification that we might want to refresh our detail view
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshAllViews:) name:NFM_REFRESH_ALL_VIEWS
											   object:[[UIApplication sharedApplication] delegate]];
}


// 他のViewやキーボードが隠れて、現れる都度、呼び出される
- (void)viewWillAppear:(BOOL)animated 
{
	[super viewWillAppear:animated];
	
	// 画面表示に関係する Option Setting を取得する
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	MbAzOptTotlWeightRound = [defaults boolForKey:GD_OptTotlWeightRound]; // YES=四捨五入 NO=切り捨て
	MbAzOptShowTotalWeight = [defaults boolForKey:GD_OptShowTotalWeight];
	MbAzOptShowTotalWeightReq = [defaults boolForKey:GD_OptShowTotalWeightReq];
	
	//self.title = ;　呼び出す側でセット済み。　変化させるならばココで。
	
	// 最新データ取得：Add直後などに再取得が必要なのでここで処理。　＜＜viewDidLoadだとAdd後呼び出されない＞＞
	//----------------------------------------------------------------------------CoreData Loading
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"row" ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:&sortDescriptor count:1];
	
	// E2 = self.e1selected.childs
	
	NSMutableArray *sortArray = [[NSMutableArray alloc] initWithArray:[Re1selected.childs allObjects]];
	[sortArray sortUsingDescriptors:sortDescriptors];
	if (RaE2array != sortArray) {
		//[Me2array release]; ---------▲もし、Me2arrayにsortArrayの要素があれば、先に解放されてしまう危険あり！
		//Me2array = [sortArray retain];
		[sortArray retain];	// 先に確保
		[RaE2array release];	// それから解放
		RaE2array = sortArray;
	}
	[sortArray release];
	
	[sortDescriptor release];
	[sortDescriptors release];
	
	// ＜高速化＞ ここで行数を求めておけば、次回フィッチするまで不変。 ＜＜削除のとき-1している＞＞
	MiSection0Rows = [RaE2array count];
	
	// テーブルビューを更新します。
    [self.tableView reloadData];	// これにより修正結果が表示される
	
#ifdef AzPAD
	// ここ以前の箇所でE2が非表示のときにpop処理すると落ちる。どうやらE2を表示してから処理する必要があるようだ
	UINavigationController* navRight = [appDelegate.mainVC.viewControllers objectAtIndex:1]; //[1]
	if (navRight.topViewController == [navRight.viewControllers objectAtIndex:0]) {
		UINavigationController* navLeft = [appDelegate.mainVC.viewControllers objectAtIndex:0]; //[0]
		[navLeft popToRootViewControllerAnimated:NO];  // PadRootVC
	}
#else
	if (0 < McontentOffsetDidSelect.y) {
		// app.Me3dateUse=nil のときや、メモリ不足発生時に元の位置に戻すための処理。
		// McontentOffsetDidSelect は、didSelectRowAtIndexPath にて記録している。
		self.tableView.contentOffset = McontentOffsetDidSelect;
	}
	else {
		[self.tableView flashScrollIndicators]; // Apple基準：スクロールバーを点滅させる
	}
#endif
}

// ビューが最後まで描画された後やアニメーションが終了した後にこの処理が呼ばれる
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

#ifdef AzPAD
	//loadViewの設定優先　[self.navigationController setToolbarHidden:NO animated:animated]; // ツールバー表示する
#else
	if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) { // ヨコ
		[self.navigationController setToolbarHidden:YES animated:animated]; // ツールバー消す
	} else {
		[self.navigationController setToolbarHidden:NO animated:animated]; // ツールバー表示する
	}
#endif

#ifdef FREE_AD
	// E3で回転してから戻った場合に対応するため ＜＜E3以下全てに回転対応するのが面倒だから
	//[apd AdViewWillRotate:self.interfaceOrientation];
	// 各viewDidAppear:にて「許可/禁止」を設定する
#ifdef AzPAD
	[appDelegate AdRefresh:NO];	//広告禁止  iPadでは、E2とE3を同時表示するため
#else
	if (PbSharePlanList) {
		[appDelegate AdRefresh:NO];	//広告禁止 Fix[1.1.0]
	} else {
		[appDelegate AdRefresh:YES];	//広告許可
	}
#endif
#endif
}

// この画面が非表示になる直前に呼ばれる
- (void)viewWillDisappear:(BOOL)animated 
{
#ifdef AzPAD
	if ([Mpopover isPopoverVisible]) { //[1.0.6-Bug01]戻る同時タッチで落ちる⇒強制的に閉じるようにした。
		[Mpopover dismissPopoverAnimated:animated];
	}
#endif
	[super viewWillDisappear:animated];
}


// MARK: View回転

// 回転サポート
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
#ifdef AzPAD
	return YES;  // 現在の向きは、self.interfaceOrientation で取得できる
#else
	if (appDelegate.AppShouldAutorotate==NO) {
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
	}
	return YES;  // 現在の向きは、self.interfaceOrientation で取得できる
#endif
}

// shouldAutorotateToInterfaceOrientation で YES を返すと、回転開始時に呼び出される
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation 
								duration:(NSTimeInterval)duration
{
#ifdef AzPAD
	//　E1が消えてE2が表示されてからは、ここから呼び出す必要あり。
	[appDelegate.padRootVC willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
#endif

#ifdef FREE_AD
	// 広告非表示でも回転時に位置調整しておく必要あり ＜＜現れるときの開始位置のため＞＞
	[appDelegate AdViewWillRotate:toInterfaceOrientation];
#endif
}

#ifdef AzPAD
// 回転した後に呼び出される
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{	// Popoverの位置を調整する　＜＜UIPopoverController の矢印が画面回転時にターゲットから外れてはならない＞＞
	if ([Mpopover isPopoverVisible]) {
		// E2は、タテになると非表示⇒Popoverになるので、常に閉じる
		// 回転後のアンカー位置が再現不可なので閉じる
		[Mpopover dismissPopoverAnimated:YES];
		[Mpopover release], Mpopover = nil;
	}
	
	
}
#endif

#pragma mark View Unload

- (void)unloadRelease {	// dealloc, viewDidUnload から呼び出される
	//【Tips】loadViewでautorelease＆addSubviewしたオブジェクトは全てself.viewと同時に解放されるので、ここでは解放前の停止処理だけする。
	NSLog(@"--- unloadRelease --- E2viewController");
	
	//【Tips】デリゲートなどで参照される可能性のあるデータなどは破棄してはいけない。
	// ただし、他オブジェクトからの参照無く、viewWillAppearにて生成されるものは破棄可能
	
	if (RhttpServer) {
		[RhttpServer stop];
		[RhttpServer release], RhttpServer = nil;
	}
	[RalertHttpServer release], RalertHttpServer = nil;
	[MdicAddresses release], MdicAddresses = nil;
	[RaE2array release], RaE2array = nil;
}

- (void)viewDidUnload 
{	// メモリ不足時、裏側にある場合に呼び出されるので、viewDidLoadで生成したObjを解放する。
	//NSLog(@"--- viewDidUnload ---"); 
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[super viewDidUnload];  // TableCell破棄される
	[self unloadRelease];		// その後、AdMob破棄する
	// この後に loadView ⇒ viewDidLoad ⇒ viewWillAppear がコールされる
}

- (void)dealloc     // 生成とは逆順に解放するのが好ましい
{
#ifdef AzPAD
	//[menuPopover]は、setPopover:にて親から渡されたものなので解放しない。
	self.delegateE3viewController = nil;
	Mpopover.delegate = nil;	//[1.0.6-Bug01]戻る同時タッチで落ちる⇒delegate呼び出し強制断
	[Mpopover release], Mpopover = nil;
	[MindexPathEdit release], MindexPathEdit = nil;
#endif
	[self unloadRelease];
	[MindexPathActionDelete release], MindexPathActionDelete = nil;
	//--------------------------------@property (retain)
	[Re1selected release];
    [super dealloc];
}


#pragma mark - iCloud
- (void)refreshAllViews:(NSNotification*)note 
{	// iCloud-CoreData に変更があれば呼び出される
    //if (note) {
		[self.tableView reloadData];
		//[self viewWillAppear:YES];
    //}
}


#pragma mark - delegate UITableView

// TableView セクション数を応答
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;  // (0)Group (1)Sort list　　(2)Action menu
}

// TableView セクションの行数を応答
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	NSInteger rows = 0;
	switch (section) {
		case 0: // Group
			if (PbSharePlanList) {
				rows = MiSection0Rows; // Addなし
			} else {
				rows = MiSection0Rows + 1; // (+1)Add
			}
			break;
		case 1: // Sort list
			if (!PbSharePlanList && 0 < MiSection0Rows) rows = GD_E2SORTLIST_COUNT;  // (＋1)即ソート廃止
			else rows = 0;
			break;
		case 2: // Action menu
			if (!PbSharePlanList && 0 < MiSection0Rows) {
				if (appDelegate.AppEnabled_Dropbox) {
					rows = 7;
				} else {
					rows = 6;
				}
			}
			else rows = 0;
			break;
	}
    return rows;
}

// TableView セクションタイトルを応答
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
	double dWeightStk;
	double dWeightReq;

	switch (section) {
		case 0:
			if (MbAzOptShowTotalWeight) {
				// ＜高速化＞ E3(Item)更新時、その親E2のsum属性、さらにその親E1のsum属性を更新することで整合および参照時の高速化を実現した。
				long lWeightStk = [[Re1selected valueForKey:@"sumWeightStk"] longValue];
				if (MbAzOptTotlWeightRound) {
					// 四捨五入　＜＜ %.1f により小数第2位が丸められる＞＞ 
					dWeightStk = (double)lWeightStk / 1000.0f;
				} else {
					// 切り捨て                       ↓これで下2桁が0になる
					dWeightStk = (double)(lWeightStk / 100) / 10.0f;
				}
			}
			if (MbAzOptShowTotalWeightReq) {
				// ＜高速化＞ E3(Item)更新時、その親E2のsum属性、さらにその親E1のsum属性を更新することで整合および参照時の高速化を実現した。
				long lWeightReq = [[Re1selected valueForKey:@"sumWeightNed"] longValue];
				if (MbAzOptTotlWeightRound) {
					// 四捨五入　＜＜ %.1f により小数第2位が丸められる＞＞ 
					dWeightReq = (double)lWeightReq / 1000.0f;
				} else {
					// 切り捨て                       ↓これで下2桁が0になる
					dWeightReq = (double)(lWeightReq / 100) / 10.0f;
				}
			}
			if (MbAzOptShowTotalWeight && MbAzOptShowTotalWeightReq) {
				return [NSString stringWithFormat:@"%@  %.1f／%.1fKg", 
												NSLocalizedString(@"Group total",nil), dWeightStk, dWeightReq];
			} else if (MbAzOptShowTotalWeight) {
				return [NSString stringWithFormat:@"%@  %.1fKg", 
												NSLocalizedString(@"Group total",nil), dWeightStk];
			} else if (MbAzOptShowTotalWeightReq) {
				return [NSString stringWithFormat:@"%@  ／%.1fKg", 
												NSLocalizedString(@"Group total",nil), dWeightReq];
			} else {
				return [NSString stringWithFormat:@"%@", NSLocalizedString(@"Group",nil)];
			}
			break;
		case 1:
			if (!PbSharePlanList && 0<MiSection0Rows) {
				return NSLocalizedString(@"Sort list", @"並び替え");
			}
			break;
		case 2:
			if (!PbSharePlanList && 0<MiSection0Rows) {
				return NSLocalizedString(@"Action menu",nil);
			}
			break;
	}
	return nil;
}

// TableView セクションフッタを応答
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	switch (section) {
		case 2:
#ifdef FREE_AD
#ifdef AzPAD
			return @"\n\n\n\n\n\n\n\n\n\n\n\n\n\n";	// 大型AdMobスペースのための下部余白
#else
			if (PbSharePlanList) {
				return NSLocalizedString(@"SharePLAN PreView",nil);
			}
			return @"\n\n\n\n\n";	// 広告スペースのための下部余白
#endif
#endif
			break;
	}
	return nil;
}

// セルの高さを指示する
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{
#ifdef AzPAD
	return 50;
#else
	return 44; // デフォルト：44ピクセル
#endif
}

// TableView 指定されたセルを生成＆表示
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	static NSString *zCellDefault = @"CellDefault";
	static NSString *zCellSubtitle = @"CellSubtitle";
	//static NSString *zCellWithSwitch = @"CellWithSwitch";
    UITableViewCell *cell = nil;

	//AzLOG(@"E2 cell Section=%d Row=%d Begin", indexPath.section, indexPath.row);

	switch (indexPath.section) {
		case 0: // section: Group
			if (indexPath.row < MiSection0Rows) {
				// 通常のノードセル
				cell = [tableView dequeueReusableCellWithIdentifier:zCellSubtitle];
				if (cell == nil) {
					cell = [[[UITableViewCell alloc] 
							 initWithStyle:UITableViewCellStyleSubtitle
							 reuseIdentifier:zCellSubtitle] autorelease];
				}
				// e2node
				E2 *e2obj = [RaE2array objectAtIndex:indexPath.row];
				
#ifdef AzDEBUG
				if ([e2obj.name length] <= 0) 
					cell.textLabel.text = NSLocalizedString(@"(New Index)", nil);
				else
					cell.textLabel.text = [NSString stringWithFormat:@"%ld) %@", 
										   (long)[e2obj.row integerValue], e2obj.name];
#else
				if ([e2obj.name length] <= 0) 
					cell.textLabel.text = NSLocalizedString(@"(New Index)", nil);
				else
					cell.textLabel.text = e2obj.name;
#endif
				
#ifdef AzPAD
				cell.textLabel.font = [UIFont systemFontOfSize:20];
				cell.detailTextLabel.font = [UIFont systemFontOfSize:14];
#else
				cell.textLabel.font = [UIFont systemFontOfSize:18];
				cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
#endif
				cell.textLabel.textAlignment = UITextAlignmentLeft;
				cell.textLabel.textColor = [UIColor blackColor];

				cell.detailTextLabel.textAlignment = UITextAlignmentLeft;
				cell.detailTextLabel.textColor = [UIColor brownColor];
				
				NSInteger lNoGray = [e2obj.sumNoGray integerValue];
				NSInteger lNoCheck = [e2obj.sumNoCheck integerValue];

				double dWeightStk;
				double dWeightReq;
				if (MbAzOptShowTotalWeight) {
					// ＜高速化＞ E3(Item)更新時、その親E2のsum属性、さらにその親E1のsum属性を更新することで整合および参照時の高速化を実現した。
					NSInteger lWeightStk = [e2obj.sumWeightStk integerValue];
					if (MbAzOptTotlWeightRound) {
						// 四捨五入　＜＜ %.1f により小数第2位が丸められる＞＞ 
						dWeightStk = (double)lWeightStk / 1000.0f;
					} else {
						// 切り捨て                       ↓これで下2桁が0になる
						dWeightStk = (double)(lWeightStk / 100) / 10.0f;
					}
				}
				if (MbAzOptShowTotalWeightReq) {
					// ＜高速化＞ E3(Item)更新時、その親E2のsum属性、さらにその親E1のsum属性を更新することで整合および参照時の高速化を実現した。
					NSInteger lWeightReq = [e2obj.sumWeightNed integerValue];
					if (MbAzOptTotlWeightRound) {
						// 四捨五入　＜＜ %.1f により小数第2位が丸められる＞＞ 
						dWeightReq = (double)lWeightReq / 1000.0f;
					} else {
						// 切り捨て                       ↓これで下2桁が0になる
						dWeightReq = (double)(lWeightReq / 100) / 10.0f;
					}
				}

				NSString* zNote = e2obj.note;
				if ([e2obj.name length]<=0 && [e2obj.note length]<=0) {
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

				if (0 < lNoCheck) {
					UIImageView *imageView1 = [[UIImageView alloc] init];
					UIImageView *imageView2 = [[UIImageView alloc] init];
					imageView1.image = [UIImage imageNamed:@"Icon32-Circle.png"];
					imageView2.image = GimageFromString(32,-11,30,[NSString stringWithFormat:@"%ld", (long)lNoCheck]);
					
					if (UIGraphicsBeginImageContextWithOptions != NULL) { // iOS4.0以上
						UIGraphicsBeginImageContextWithOptions(imageView1.image.size, NO, 0.0); //[0.4.18]Retina対応
					} else { // Old
						UIGraphicsBeginImageContext(imageView1.image.size);
					}

					CGRect rect = CGRectMake(0, 0, imageView1.image.size.width, imageView1.image.size.height);
					[imageView1.image drawInRect:rect];  
					[imageView2.image drawInRect:rect blendMode:kCGBlendModeMultiply alpha:0.9];  
					UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();  
					UIGraphicsEndImageContext();  
					[cell.imageView setImage:resultingImage];
					AzRETAIN_CHECK(@"E2 lNoCheck:imageView1", imageView1, 1)
					[imageView1 release];
					AzRETAIN_CHECK(@"E2 lNoCheck:imageView2", imageView2, 1)
					[imageView2 release];
					AzRETAIN_CHECK(@"E2 lNoCheck:resultingImage", resultingImage, 2)
				}
				else if (0 < lNoGray) {
					cell.imageView.image = [UIImage imageNamed:@"Icon32-CircleCheck.png"];
				}
				else { // 全てGray
					cell.imageView.image = [UIImage imageNamed:@"Icon32-CircleGray.png"];
				}
				
				if (PbSharePlanList) {	//サンプル
					cell.showsReorderControl = NO;		// Move拒否
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;	// > ディスクロージャマーク
				} else {
					cell.showsReorderControl = YES;		// Move許可
					cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton; // ディスクロージャボタン
				}
			} 
			else if (indexPath.row == MiSection0Rows) {
				// 追加ボタンセル　(+)Add Group
				cell = [tableView dequeueReusableCellWithIdentifier:zCellDefault];
				if (cell == nil) {
					cell = [[[UITableViewCell alloc] 
							 initWithStyle:UITableViewCellStyleDefault      // Default型
							 reuseIdentifier:zCellDefault] autorelease];
				}
				if (indexPath.row == MiSection0Rows) {
					cell.imageView.image = [UIImage imageNamed:@"Icon24-GreenPlus.png"];
					//cell.textLabel.text = NSLocalizedString(@"Add Group",nil);
					cell.textLabel.text = NSLocalizedString(@"New Index",nil);
				} else {
					cell.imageView.image = [UIImage imageNamed:@"Icon24-GreenPlus.png"];
					cell.textLabel.text = NSLocalizedString(@"Copy Group",nil);
				}
#ifdef AzPAD
				cell.textLabel.font = [UIFont systemFontOfSize:18];
#else
				cell.textLabel.font = [UIFont systemFontOfSize:14];
#endif
				cell.textLabel.textAlignment = UITextAlignmentCenter; // 中央寄せ
				cell.textLabel.textColor = [UIColor darkGrayColor];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;	// > ディスクロージャマーク
				cell.showsReorderControl = NO;
			}
			break;

		case 1:	// section: Sort list
			cell = [tableView dequeueReusableCellWithIdentifier:zCellSubtitle];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle		// サブタイトル型(3.0)
											   reuseIdentifier:zCellSubtitle] autorelease];
			}
#ifdef AzPAD
			cell.textLabel.font = [UIFont systemFontOfSize:18];
			cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
#else
			cell.textLabel.font = [UIFont systemFontOfSize:16];
			cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
#endif
			cell.textLabel.textAlignment = UITextAlignmentLeft;
			cell.textLabel.textColor = [UIColor blackColor];

			cell.detailTextLabel.textAlignment = UITextAlignmentLeft;
			cell.detailTextLabel.textColor = [UIColor grayColor];

			cell.imageView.image = nil;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;	// > ディスクロージャマーク
			cell.showsReorderControl = NO;		// Move禁止
			
			switch (indexPath.row) {
				case 0:
					cell.textLabel.text = NSLocalizedString(@"SortLackQty",nil);
					cell.detailTextLabel.text = NSLocalizedString(@"SortLackQtyMsg",nil);
					break;
				case 1:
					cell.textLabel.text = NSLocalizedString(@"SortLackWeight",nil);
					cell.detailTextLabel.text = NSLocalizedString(@"SortLackWeightMsg",nil);
					break;
				case 2:
					cell.textLabel.text = NSLocalizedString(@"SortWeight",nil);
					cell.detailTextLabel.text = NSLocalizedString(@"SortWeightMsg",nil);
					break;
				default:
					cell.textLabel.text = @"Err";
					break;
			}
			break;
		
		case 2:	// section: Action menu
			cell = [tableView dequeueReusableCellWithIdentifier:zCellSubtitle];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle		// サブタイトル型(3.0)
											   reuseIdentifier:zCellSubtitle] autorelease];
			}
#ifdef AzPAD
			cell.textLabel.font = [UIFont systemFontOfSize:18];
			cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
#else
			cell.textLabel.font = [UIFont systemFontOfSize:16];
			cell.detailTextLabel.font = [UIFont systemFontOfSize:10];
#endif
			cell.textLabel.textAlignment = UITextAlignmentLeft;
			cell.textLabel.textColor = [UIColor darkGrayColor];
			
			cell.detailTextLabel.textAlignment = UITextAlignmentLeft;
			cell.detailTextLabel.textColor = [UIColor grayColor];

			cell.imageView.image = nil;
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.showsReorderControl = NO;		// Move禁止
			
			NSInteger iRow = indexPath.row;
			if (appDelegate.AppEnabled_Dropbox==NO && 3<=iRow) iRow++; // Dropbox無効
			switch (iRow) {
				case 0:
					cell.imageView.image = [UIImage imageNamed:@"Icon32-CircleCheckClear"];
					cell.textLabel.text = NSLocalizedString(@"All ZERO",nil);
					cell.textLabel.textColor = [UIColor redColor];
					cell.detailTextLabel.text = NSLocalizedString(@"All ZERO msg",nil);
					break;
				case 1: //[1.1]E-mail send
					cell.imageView.image = [UIImage imageNamed:@"Icon32-MailNew"];
					cell.textLabel.text = NSLocalizedString(@"Email send",nil);
					cell.detailTextLabel.text = NSLocalizedString(@"Email send msg",nil);
					break;
				case 2:
					cell.imageView.image = [UIImage imageNamed:@"Icon32-Shared"];
					cell.textLabel.text = NSLocalizedString(@"SharePlan Append",nil);
					cell.detailTextLabel.text = NSLocalizedString(@"SharePlan Append msg",nil);
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;	// > ディスクロージャマーク
					break;
				case 3:
					cell.imageView.image = [UIImage imageNamed:@"Dropbox-130x44"];
					cell.textLabel.text = NSLocalizedString(@"Backup Dropbox",nil);
					cell.detailTextLabel.text = NSLocalizedString(@"Backup Dropbox msg",nil);
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;	// > ディスクロージャマーク
					break;
				case 4:
					cell.imageView.image = [UIImage imageNamed:@"Icon32-Google"];
					cell.textLabel.text = NSLocalizedString(@"Backup Google",nil);
					cell.detailTextLabel.text = NSLocalizedString(@"Backup Google msg",nil);
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;	// > ディスクロージャマーク
					break;
				case 5:
					cell.imageView.image = [UIImage imageNamed:@"Icon32-NearPc"];
					cell.textLabel.text = NSLocalizedString(@"Backup YourPC",nil);
					cell.detailTextLabel.text = NSLocalizedString(@"Backup YourPC msg",nil);
					break;
				case 6:
					cell.imageView.image = [UIImage imageNamed:@"Icon32-PasteCopy"];
					cell.textLabel.text = NSLocalizedString(@"Copied to PasteBoard",nil);
					cell.detailTextLabel.text = NSLocalizedString(@"Copied to PasteBoard msg",nil);
					break;
			}
			break;
	}
	return cell;
}

// UISwitch Action
- (void)switchAction: (UISwitch *)sender
{
	if (sender.tag != 999) return;

	BOOL bQuickSort = [sender isOn];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:bQuickSort forKey:GD_OptItemsQuickSort];
}

// TableView Editボタンスタイル
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
		if (indexPath.row < MiSection0Rows) 
			return UITableViewCellEditingStyleDelete;
//		else
//			return UITableViewCellEditingStyleInsert;
	}
    return UITableViewCellEditingStyleNone;
}

/*
- (BOOL)canBecomeFirstResponder {
	return YES;
}
- (void)copy:(id)sender
{
	AzLOG(@"--COPY--");
}
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
	if (@selector(copy:) == action) return YES;
	return [super canPerformAction:action withSender:sender];
}
//- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	if ([self becomeFirstResponder])  {
		UIMenuController *menu = [UIMenuController sharedMenuController];
		CGPoint touchPoint = [touch locationInView:self.tableView];
		CGRect minRect;
		minRect.origin = touchPoint;
		[menu setTargetRect:minRect inView:self.tableView];
		[menu setMenuVisible:YES animated:YES];
	}
}
*/

// TableView 行選択時の動作
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (RhttpServer) return;
	
	// didSelect時のScrollView位置を記録する（viewWillAppearにて再現するため）
	McontentOffsetDidSelect = [tableView contentOffset];

	switch (indexPath.section) {
		case 0: // GROUP
			if (MiSection0Rows <= indexPath.row) {	// Add Group
				[self e2adde2add];
				return; //Popover時に閉じないように
			} 
			else if (self.editing) {
				[self e2editView:indexPath];
				return; //Popover時に閉じないように
			} 
			else {
				// E2 : NSManagedObject
				//E2 *e2obj = [RaE2array objectAtIndex:indexPath.row];
				[self fromE2toE3:indexPath.row]; // 次回の画面復帰のための状態記録をしてからＥ3へドリルダウンする
			}
			break; // Popover Close

		case 1: // Sort list
			if (0 < MiSection0Rows && indexPath.row < GD_E2SORTLIST_COUNT) 
			{
#ifdef AzPAD
				// 既存Ｅ３更新
				if ([delegateE3viewController respondsToSelector:@selector(viewWillAppear:)]) {
					assert(delegateE3viewController);
					delegateE3viewController.PiFirstSection = 0;  // Group.ROW ==>> E3で頭出しするセクション
					delegateE3viewController.PiSortType = indexPath.row;
					delegateE3viewController.PbSharePlanList = PbSharePlanList;
					[delegateE3viewController viewWillAppear:YES];
				}
				break; // Popover Close
#else
				// E3 へドリルダウン
				E3viewController *e3view = [[E3viewController alloc] initWithStyle:UITableViewStylePlain];
				// 以下は、E3viewControllerの viewDidLoad 後！、viewWillAppear の前に処理されることに注意！
				e3view.title = Re1selected.name;  //self.title;  // NSLocalizedString(@"Items", nil);
				e3view.Re1selected = Re1selected; // E1
				e3view.PiFirstSection = 0;  // Group.ROW ==>> E3で頭出しするセクション
				e3view.PiSortType = indexPath.row;
				e3view.PbSharePlanList = PbSharePlanList;
				[self.navigationController pushViewController:e3view animated:YES];
				[e3view release];
#endif
			}
			break;
			
		case 2: { // Action Menu
			NSInteger iRow = indexPath.row;
			if (appDelegate.AppEnabled_Dropbox==NO && 3<=iRow) iRow++; // Dropbox無効
			switch (iRow) {
				case 0: // All Zero  全在庫数量を、ゼロにする
					[self	actionAllZero];
					break;
					
				case 1: //[1.1]E-mail send
					[self actionEmailSend];
					break;
					
				case 2: // Upload Share Plan
					[self actionSharedPackListUp];
					return; //Popover時に閉じないように
					
				case 3: // Backup to Dropbox
					[self actionBackupDropbox];
					return; //Popover時に閉じないように
					
				case 4: // Backup to Google
					[self actionBackupGoogle];
					return; //Popover時に閉じないように
					
				case 5: // Backup to YourPC
					[self actionBackupYourPC];
					break;
					
				case 6: // ペーストボードへコピー
					[self actionCopiedPasteBoard];
					break;
			}
		}	break;
	}
#ifdef AzPAD
	if ([menuPopover isPopoverVisible]) {	//選択後、Popoverならば閉じる
		[menuPopover dismissPopoverAnimated:YES];
	}
#endif
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


// ディスクロージャボタンが押されたときの処理
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	[self e2editView:indexPath];
}


#pragma mark  Edit Move

// TableView Editモードの表示
- (void)setEditing:(BOOL)editing animated:(BOOL)animated 
{
	[super setEditing:editing animated:animated];
    // この後、self.editing = YES になっている。
	// [self.tableView reloadData]だとアニメ効果が消される。　(OS 3.0 Function)を使って解決した。
	NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 1)]; // [0]セクションから1個
	[self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade]; // (OS 3.0 Function)
#ifdef AzPAD
	// 右ナビ E3 を更新する
	[self fromE2toE3:(-9)]; // (-9)E3初期化（リロード＆再描画、セクション0表示）
#endif
}

// TableView Editモード処理
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
															forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		// 削除コマンド警告　==>> (void)actionSheet にて処理
		//Bug//MindexPathActionDelete = indexPath;
		[MindexPathActionDelete release], MindexPathActionDelete = [indexPath copy];
		// 削除コマンド警告
		UIActionSheet *action = [[UIActionSheet alloc] 
								 initWithTitle:NSLocalizedString(@"CAUTION", nil)
								 delegate:self 
								 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
								 destructiveButtonTitle:NSLocalizedString(@"DELETE Group", nil)
								 otherButtonTitles:nil];
		action.tag = ACTIONSEET_TAG_DELETEGROUP;
		if (self.interfaceOrientation == UIInterfaceOrientationPortrait 
			OR self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
			// タテ：ToolBar表示
			[action showFromToolbar:self.navigationController.toolbar]; // ToolBarがある場合
		} else {
			// ヨコ：ToolBar非表示（TabBarも無い）　＜＜ToolBar無しでshowFromToolbarするとFreeze＞＞
			[action showInView:self.view]; //windowから出すと回転対応しない
		}
		[action release];
    }
}

/*
- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	// スワイプにより1行だけが編集モードに入るときに呼ばれる。
	// このオーバーライドにより、setEditting が呼び出されないようにしている。 Add行を出さないため
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	// スワイプにより1行だけが編集モードに入り、それが解除されるときに呼ばれる。
	// このオーバーライドにより、setEditting が呼び出されないようにしている。 Add行を出さないため
}
*/

// Editモード時の行Edit可否
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	//if (indexPath.section == 0 && indexPath.row < MiSection0Rows) return YES; // 行編集許可
	//return NO; // 行編集禁止
	return YES; // 行編集許可
}

// Editモード時の行移動の可否　　＜＜最終行のAdd専用行を移動禁止にしている＞＞
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0 && indexPath.row < MiSection0Rows) return YES;
	return NO;  // 移動禁止
}

// Editモード時の行移動「先」を返す　　＜＜最終行のAdd専用行への移動ならば1つ前の行を返している＞＞
- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)oldPath 
														toProposedIndexPath:(NSIndexPath *)newPath {
    NSIndexPath *target = newPath;
	NSInteger rows = MiSection0Rows - 1;  // 移動可能な行数（Add行を除く）
	// セクション０限定仕様
	if (newPath.section != 0 || rows < newPath.row  ) {
		// Add行が異動先になった場合、その1つ前の通常行を返すことにより、Add行への移動禁止となる。
		// Add行ならば、E2ノードの最終行(row-1)を応答する
		target = [NSIndexPath indexPathForRow:rows inSection:0];
	}
    return target;
}

// Editモード時の行移動処理　　＜＜CoreDataにつきArrayのように削除＆挿入ではダメ。ソート属性(row)を書き換えることにより並べ替えている＞＞
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)oldPath 
												  toIndexPath:(NSIndexPath *)newPath {
	// CoreDataは順序を保持しないため 属性"ascend"を昇順ソート表示している
	// この 属性"ascend"の値を行異動後に更新するための処理

	// e2list 更新 ==>> なんと、managedObjectContextも更新される。 ただし、削除や挿入は反映されない！！！
	// E2 : NSManagedObject
	E2 *e2obj = [RaE2array objectAtIndex:oldPath.row];

	[RaE2array removeObjectAtIndex:oldPath.row];
	[RaE2array insertObject:e2obj atIndex:newPath.row];
	
	NSInteger start = oldPath.row;
	NSInteger end = newPath.row;
	if (end < start) {
		start = newPath.row;
		end = oldPath.row;
	}
	for (NSInteger i = start; i <= end; i++) {
		e2obj = [RaE2array objectAtIndex:i];
		e2obj.row = [NSNumber numberWithInteger:i];
	}

	if (PbSharePlanList==NO) {  // SpMode=YESならば[SAVE]ボタンを非表示にしたので通らないハズだが、念のため。
		// SAVE　＜＜万一システム障害で落ちてもデータが残るようにコマメに保存する方針＞＞
		NSError *error = nil;
		if (![Re1selected.managedObjectContext save:&error]) {
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			exit(-1);  // Fail
		}
	}
}


#ifdef AzPAD
#pragma mark - delegate UIPopoverController
- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{	// Popoverの外部をタップして閉じる前に通知
	// 内部(SAVE)から、dismissPopoverAnimated:で閉じた場合は呼び出されない。
	//[1.0.6]Cancel: 今更ながら、insert後、saveしていない限り、rollbackだけで十分であることが解った。

	UINavigationController* nc = (UINavigationController*)[popoverController contentViewController];
	if ( [[nc visibleViewController] isMemberOfClass:[E2edit class]] ) {	// E2edit のときだけ、
		if (appDelegate.AppUpdateSave) { // E2editにて、変更あるので閉じさせない
			alertBox(NSLocalizedString(@"Cancel or Save",nil), 
					 NSLocalizedString(@"Cancel or Save msg",nil), NSLocalizedString(@"Roger",nil));
			return NO; 
		}
	}
	return YES; // 閉じることを許可
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{	// [Cancel][Save][枠外タッチ]何れでも閉じるときここを通るので解放する。さもなくば回転後に現れることになる
	if (popoverController == menuPopover) {
		if (self.navigationController.topViewController != self) {
			//タテ： E2viewが[MENU]でPopover内包されているとき、配下に遷移しておれば戻す
			[self.navigationController popViewControllerAnimated:NO];	// < 前のViewへ戻る
			[Re1selected.managedObjectContext rollback]; // 前回のSAVE以降を取り消す
		}
	}	
}

#endif

@end
