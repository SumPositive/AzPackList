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
//#import "GooDocsTVC.h"
#import "SettingTVC.h"
#import "ExportServerVC.h"
#import "HTTPServer.h"
#import "MyHTTPConnection.h"
#import "localhostAddresses.h"
#import "FileCsv.h"
#import "WebSiteVC.h"
#import "SpAppendVC.h"
#import "DropboxVC.h"
#import "PatternImageView.h"
//#import "GoogleAuth.h"
#import "GDocUploadVC.h"


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
{
@private
	UIPopoverController*	menuPopover_;  //[MENU]にて自身を包むPopover  閉じる為に必要
	// setPopover:にてセットされる
	
	NSMutableArray		*e2array_;   // Rrは local alloc につき release 必須を示す
	HTTPServer			*httpServer_;
	UIAlertView			*alertHttpServer_;
	NSDictionary		*dicAddresses_;
	E2edit				*e2editView_;				// self.navigationControllerがOwnerになる
	
	UIPopoverController*			popOver_;
	NSIndexPath*						indexPathEdit_;	//[1.1]ポインタ代入注意！copyするように改善した。
	
	AppDelegate		*appDelegate_;
	NSIndexPath	  *indexPathActionDelete_;	//[1.1]ポインタ代入注意！copyするように改善した。

	BOOL optWeightRound_;
	BOOL optShowTotalWeight_;
	BOOL optShowTotalWeightReq_;
	NSInteger section0Rows_; // E2レコード数　＜高速化＞
	CGPoint		contentOffsetDidSelect_; // didSelect時のScrollView位置を記録
}
@synthesize e1selected = e1selected_;
@synthesize sharePlanList = sharePlanList_;
@synthesize delegateE3viewController = delegateE3viewController_;


#pragma mark - Delegate

- (void)setPopover:(UIPopoverController*)pc
{
	menuPopover_ = pc;
	menuPopover_.delegate = self;	//枠外タッチでpopoverControllerDidDismissPopover：を呼び出すため。
}

- (void)refreshE2view
{
	if (indexPathEdit_)
	{
		// E2 再描画
		NSArray* ar = [NSArray arrayWithObject:indexPathEdit_];
		[self.tableView reloadRowsAtIndexPaths:ar withRowAnimation:NO];
		// E3 再描画
		[self fromE2toE3:indexPathEdit_.row];
	}
}


#pragma mark - Action

- (void)azSettingView
{
	SettingTVC *vi = [[SettingTVC alloc] init];
	[vi setHidesBottomBarWhenPushed:YES]; // 現在のToolBar状態をPushした上で、次画面では非表示にする
	[self.navigationController pushViewController:vi animated:YES];
	//[vi release];
}


 // E2グループ削除
- (void)actionE2delateCell:(NSIndexPath*)indexPath
{
	// CoreDataモデル：エンティティ間の削除ルールは双方「無効にする」を指定。（他にするとフリーズ）
	// 削除対象の ManagedObject をチョイス
	E2 *e2objDelete = [e2array_ objectAtIndex:indexPath.row];
	// 該当行削除：　e2list 削除 ==>> しかし、managedObjectContextは削除されない！！！後ほど削除
	[e2array_ removeObjectAtIndex:indexPath.row];  // × removeObject:e2obj];
	section0Rows_--; // この削除により1つ減
	// 該当行以下.row更新：　RrE2array 更新 ==>> なんと、managedObjectContextも更新される！！！
	for (NSInteger i = indexPath.row; i < section0Rows_ ; i++) {
		E2 *e2obj = [e2array_ objectAtIndex:i];
		e2obj.row = [NSNumber numberWithInteger:i];
	}
	// e2obj.childs を全て削除する  ＜＜managedObjectContext を直接削除している＞＞
	for (E3 *e3obj in e2objDelete.childs) {
		[e1selected_.managedObjectContext deleteObject:e3obj];
	}
	// RrE2arrayの削除はmanagedObjectContextに反映されないため、ここで削除する。
	e2objDelete.parent = nil;	//[1.0.1]次の集計から除外するためリンク切る ＜＜＜deleteObjectでは切れない＞＞＞
	[e1selected_.managedObjectContext deleteObject:e2objDelete];
	// E1 sum属性　＜高速化＞ 親sum保持させる
	[e1selected_ setValue:[e1selected_ valueForKeyPath:@"childs.@sum.sumNoGray"] forKey:@"sumNoGray"];
	[e1selected_ setValue:[e1selected_ valueForKeyPath:@"childs.@sum.sumNoCheck"] forKey:@"sumNoCheck"];
	[e1selected_ setValue:[e1selected_ valueForKeyPath:@"childs.@sum.sumWeightStk"] forKey:@"sumWeightStk"];
	[e1selected_ setValue:[e1selected_ valueForKeyPath:@"childs.@sum.sumWeightNed"] forKey:@"sumWeightNed"];
	
	if (sharePlanList_==NO) {  // SpMode=YESならば[SAVE]ボタンを非表示にしたので通らないハズだが、念のため。
		// SAVE　＜＜万一システム障害で落ちてもデータが残るようにコマメに保存する方針＞＞
		NSError *error = nil;
		if (![e1selected_.managedObjectContext save:&error]) {
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			//exit(-1);  // Fail
		}
	}
	
	NSLog(@"indexPath=%@", indexPath);
	// テーブルビューから選択した行を削除する　　　　　　//[self.tableView reloadData]だとアニメ効果が無いため下記採用
	if ([e2array_ count]<=0) {
		[self.tableView reloadData];	//FIX//残り1個を削除すると落ちるのを回避するため。アニメ効果ない
	} else {
		[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
							  withRowAnimation:UITableViewRowAnimationFade];		//アニメ効果のため
	}

	if (appDelegate_.app_is_iPad) {
		// 右ナビ E3 を更新する
		[self fromE2toE3:(-9)]; // (-9)E3初期化（リロード＆再描画、セクション0表示）
	}
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
	//[alert release];
}
- (void)actionAllZero_OKGO
{	// 全在庫数量を、ゼロにする
	if ([e2array_ count] <= 0) return;
	//----------------------------------------------------------------------------CoreData Loading
	for (E2 *e2obj in e2array_) {
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
		//[e3array release];
		
		// E2 sum属性　＜高速化＞ 親sum保持させる
		[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.noGray"] forKey:@"sumNoGray"];
		[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.noCheck"] forKey:@"sumNoCheck"];
		[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.weightStk"] forKey:@"sumWeightStk"];
		[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.weightNed"] forKey:@"sumWeightNed"];
	}
	
	// E1 sum属性　＜高速化＞ 親sum保持させる
	[e1selected_ setValue:[e1selected_ valueForKeyPath:@"childs.@sum.sumNoGray"] forKey:@"sumNoGray"];
	[e1selected_ setValue:[e1selected_ valueForKeyPath:@"childs.@sum.sumNoCheck"] forKey:@"sumNoCheck"];
	[e1selected_ setValue:[e1selected_ valueForKeyPath:@"childs.@sum.sumWeightStk"] forKey:@"sumWeightStk"];
	[e1selected_ setValue:[e1selected_ valueForKeyPath:@"childs.@sum.sumWeightNed"] forKey:@"sumWeightNed"];
	
	if (sharePlanList_==NO) {  // SpMode=YESならば[SAVE]ボタンを非表示にしたので通らないハズだが、念のため。
		// SAVE : e3edit,e2list は ManagedObject だから更新すれば ManagedObjectContext に反映されている
		NSError *err = nil;
		if (![e1selected_.managedObjectContext save:&err]) {
			NSLog(@"Unresolved error %@, %@", err, [err userInfo]);
			abort();
		}
	}
	
	[self viewWillAppear:YES];
	// 先頭を表示する
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
	[self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];

	if (appDelegate_.app_is_iPad) {
		// 右ナビ E3 を更新する
		[self fromE2toE3:(-9)]; // (-9)E3初期化（リロード＆再描画、セクション0表示）
	}
}

- (void)actionEmailSend
{
	MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
	picker.mailComposeDelegate = self;
	
#ifdef DEBUG
	// To: 宛先
	NSArray *toRecipients = [NSArray arrayWithObject:@"m@azukid.com"];
	[picker setToRecipients:toRecipients];
#endif
	
	NSString *zPackName;
	if (e1selected_.name) {
		zPackName = e1selected_.name;
	} else { // 名称未定
		zPackName = NSLocalizedString(@"(New Pack)",nil);
	}
	
	// Subject: 件名
	NSString* zSubj = [NSString stringWithFormat:@"%@ : %@", NSLocalizedString(@"Product Title",nil), zPackName];
	[picker setSubject:zSubj];  

	// 添付ファイル生成
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(queue, ^{
		// CSV SAVE
		FileCsv *fcsv = [[FileCsv alloc] init];
		NSString *zErr = [fcsv zSaveTmpFile:e1selected_ crypt:YES];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[UIApplication sharedApplication].networkActivityIndicatorVisible = NO; // NetworkアクセスサインOFF
			if (zErr) {
				UIAlertView *alert = [[UIAlertView alloc] 
									  initWithTitle:NSLocalizedString(@"CSV Save Fail",nil)
									  message:zErr
									  delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
				[alert show];
				return;
			}
			NSString *csvPath = fcsv.tmpPathFile;

			// Body: 本文
			NSString* zBody = [NSString stringWithFormat:@"%@%@%@%@%@", 
							   NSLocalizedString(@"Email send Body1",nil),
							   NSLocalizedString(@"Email send Body2",nil),
							   NSLocalizedString(@"Email send Body3",nil),
							   NSLocalizedString(@"Email send Body4",nil),
							   NSLocalizedString(@"Email send Body5",nil) ];
			if (fcsv.didEncryption) {
				zBody = [zBody stringByAppendingString:NSLocalizedString(@"Email send Body6 didEncryption",nil)];
			} else {
				//不要//zBody = [zBody stringByAppendingString:NSLocalizedString(@"Email send Body6 NoEncryption",nil)];
			}
			[picker setMessageBody:zBody isHTML:YES];
			
			// Body: 添付ファイル
			NSString* fileName = [NSString stringWithFormat:@"%@.%@", zPackName, GD_EXTENSION];
			NSData* fileData = [NSData dataWithContentsOfFile:csvPath];
			[picker addAttachmentData:fileData mimeType:@"application/packlist" fileName:fileName];
			
			// Email オープン
			if (appDelegate_.app_is_iPad) {
				picker.modalPresentationStyle = UIModalPresentationFormSheet;
				[appDelegate_.mainSVC presentModalViewController:picker animated:YES];
			} else {
				[appDelegate_.mainNC presentModalViewController:picker animated:YES];
			}
		});
	});
}

- (void)actionSharedPackListUp:(NSIndexPath*)indexPath
{
	if (appDelegate_.app_is_iPad) {
		if ([popOver_ isPopoverVisible]) return; //[1.0.6-Bug01]同時タッチで落ちる⇒既に開いておれば拒否
	}

	SpAppendVC *spAppendVC = [[SpAppendVC alloc] init];
	spAppendVC.Re1selected = e1selected_;

	if (appDelegate_.app_is_iPad) {
		spAppendVC.title = NSLocalizedString(@"SharePlan Append",nil);
		if ([menuPopover_ isPopoverVisible]) { //タテ
			//[vc setHidesBottomBarWhenPushed:YES]; // 現在のToolBar状態をPushした上で、次画面では非表示にする
			[self.navigationController pushViewController:spAppendVC animated:YES];
		} else {	//ヨコ
			//[Mpopover release], 
			popOver_ = nil;
			//Mpopover = [[PadPopoverInNaviCon alloc] initWithContentViewController:vc];
			UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:spAppendVC];
			popOver_ = [[UIPopoverController alloc] initWithContentViewController:nc];
			//[nc release];
			popOver_.delegate = self;	// popoverControllerDidDismissPopover:を呼び出してもらうため
			//[MindexPathEdit release], 
			indexPathEdit_ = nil;
			
			CGRect rcArrow = [self.tableView rectForRowAtIndexPath:indexPath];
			rcArrow.origin.x = rcArrow.size.width - 85;		rcArrow.size.width = 1;
			rcArrow.origin.y += 10;	rcArrow.size.height -= 20;
			[popOver_ presentPopoverFromRect:rcArrow  inView:self.view
					permittedArrowDirections:UIPopoverArrowDirectionLeft  animated:YES];
			
			//[Mpopover presentPopoverFromRect:CGRectMake(320/2, 768-60, 1,1)	 //ヨコしか通らない。タテならばPopover内になるから
			//						  inView:self.navigationController.view
			//		permittedArrowDirections:UIPopoverArrowDirectionDown  animated:YES];
			spAppendVC.selfPopover = popOver_;
			//spAppendVC.delegate = nil; //Uploadだから再描画不要
		}
	} else {
		[spAppendVC setHidesBottomBarWhenPushed:YES]; // 現在のToolBar状態をPushした上で、次画面では非表示にする
		[self.navigationController pushViewController:spAppendVC animated:YES];
	}
	//[spAppendVC release];
}

- (void)actionBackupDropbox:(NSIndexPath*)indexPath
{	// BACKUP [SAVE]
	if (appDelegate_.app_is_iPad) {
		if ([popOver_ isPopoverVisible]) return; //[1.0.6-Bug01]同時タッチで落ちる⇒既に開いておれば拒否
	}
	
	// 未認証の場合、認証処理後、AppDelegate:handleOpenURL:から呼び出される
	if ([[DBSession sharedSession] isLinked]) 
	{	// Dropbox 認証済み
		DropboxVC *vc = [[DropboxVC alloc] initWithE1:e1selected_];
		assert(vc);
		if (appDelegate_.app_is_iPad) {
			/*popOver_ = nil;
			popOver_ = [[UIPopoverController alloc] initWithContentViewController:vc];
			popOver_.delegate = nil;	// 不要
			CGRect rcArrow = [self.tableView rectForRowAtIndexPath:indexPath];
			rcArrow.origin.x = rcArrow.size.width - 85;		rcArrow.size.width = 1;
			rcArrow.origin.y += 10;	rcArrow.size.height -= 20;
			[popOver_ presentPopoverFromRect:rcArrow  inView:self.view
					permittedArrowDirections:UIPopoverArrowDirectionLeft  animated:YES]; */
			// Dropboxだけは、認証して戻ったときAppDelegate内で再現させるため座標情報が不要なFormSheetにしている。
			vc.modalPresentationStyle = UIModalPresentationFormSheet;
			[self presentModalViewController:vc animated:YES];
		} 
		else {
			if (appDelegate_.app_opt_Ad) {
				[appDelegate_ AdRefresh:NO];	//広告禁止
			}
			[vc setHidesBottomBarWhenPushed:YES]; // 現在のToolBar状態をPushした上で、次画面では非表示にする
			[self.navigationController pushViewController:vc animated:YES];
		}
	}
	else {
		// Dropbox 未認証
		appDelegate_.dropboxSaveE1selected = e1selected_;	// [SAVE]
		[[DBSession sharedSession] link];
	}
}

- (void)actionBackupGoogle:(NSIndexPath*)indexPath
{
	if (section0Rows_ <=0) return;
	if (appDelegate_.app_is_iPad) {
		if ([popOver_ isPopoverVisible]) return; //[1.0.6-Bug01]同時タッチで落ちる⇒既に開いておれば拒否
	}
	
	GDocUploadVC *gup = [[GDocUploadVC alloc] init];
	gup.Re1selected = e1selected_;

	if (appDelegate_.app_is_iPad) {
	/*	goodocs.title = NSLocalizedString(@"Backup Google",nil);
		if ([menuPopover_ isPopoverVisible]) { //タテ
			[self.navigationController pushViewController:goodocs animated:YES];
		} else {	//ヨコ
			UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:goodocs];
			popOver_ = [[UIPopoverController alloc] initWithContentViewController:nc];
			popOver_.delegate = self;	// popoverControllerDidDismissPopover:を呼び出してもらうため
			indexPathEdit_ = nil;
			CGRect rcArrow = [self.tableView rectForRowAtIndexPath:indexPath];
			rcArrow.origin.x = rcArrow.size.width - 85;		rcArrow.size.width = 1;
			rcArrow.origin.y += 10;	rcArrow.size.height -= 20;
			[popOver_ presentPopoverFromRect:rcArrow  inView:self.view
					permittedArrowDirections:UIPopoverArrowDirectionLeft  animated:YES];
			goodocs.selfPopover = popOver_;
			goodocs.delegate = nil; //Uploadだから再描画不要
		}*/
		gup.modalPresentationStyle = UIModalPresentationFormSheet;
		[self presentModalViewController:gup animated:YES];
	} else {
		[self.navigationController pushViewController:gup animated:YES];
	}
}

- (void)actionBackupYourPC
{
	if (appDelegate_.app_is_iPad) {
		if ([menuPopover_ isPopoverVisible]) {	//選択後、Popoverならば閉じる
			[menuPopover_ dismissPopoverAnimated:YES];
		}
	}
	// HTTP Server Start
	if (alertHttpServer_ == nil) {
		alertHttpServer_ = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"HttpSv BACKUP", nil) 
													  message:NSLocalizedString(@"HttpSv Wait", nil) 
													 delegate:self 
											cancelButtonTitle:nil  //@"CANCEL" 
											otherButtonTitles:NSLocalizedString(@"HttpSv stop", nil) , nil];
	}
	alertHttpServer_.tag = ALERT_TAG_HTTPServerStop;
	[alertHttpServer_ show];

	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(queue, ^{
		// CSV SAVE
		FileCsv *fcsv = [[FileCsv alloc] init];
		fcsv.isShardMode = YES; // 写真を除外する
		NSString *zErr = [fcsv zSaveTmpFile:e1selected_ crypt:YES];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			if (zErr) {
				[UIApplication sharedApplication].networkActivityIndicatorVisible = NO; // NetworkアクセスサインOFF
				UIAlertView *alert = [[UIAlertView alloc] 
									  initWithTitle:NSLocalizedString(@"CSV Save Fail",nil)
									  message:zErr
									  delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
				[alert show];
				return;
			}
			// if (httpServer) return; <<< didSelectRowAtIndexPath:直後に配置してダブルクリック回避している。
			//NSString *root = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
			NSString *root = NSTemporaryDirectory();
			
			httpServer_ = [HTTPServer new];
			[httpServer_ setType:@"_http._tcp."];
			[httpServer_ setConnectionClass:[MyHTTPConnection class]];
			[httpServer_ setDocumentRoot:[NSURL fileURLWithPath:root]];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(httpInfoUpdate:) name:@"LocalhostAdressesResolved" object:nil];
			[localhostAddresses performSelectorInBackground:@selector(list) withObject:nil];
			[httpServer_ setPort:8080];
			[httpServer_ setBackup:YES]; // BACKUP Mode
			[httpServer_ setPlanName:e1selected_.name]; // ファイル名を "プラン名.AzPack.csv" にするため
			NSError *error;
			if(![httpServer_ start:&error])
			{
				NSLog(@"Error starting HTTP Server: %@", error);
				//[RhttpServer release];
				httpServer_ = nil;
			}
		});
	});
}

- (void)actionCopiedPasteBoard
{
	if (appDelegate_.app_is_iPad) {
		if ([menuPopover_ isPopoverVisible]) {	//選択後、Popoverならば閉じる
			[menuPopover_ dismissPopoverAnimated:YES];
		}
	}
	// PasteBoard SAVE
	UIAlertView *alert = [[UIAlertView alloc] init];
	alert.title = NSLocalizedString(@"Please Wait",nil);
	[alert show];
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(queue, ^{		// 非同期マルチスレッド処理
		FileCsv *fcsv = [[FileCsv alloc] init];
		fcsv.isShardMode = YES; // 写真を除外する
		NSString *zErr = [fcsv zSavePasteboard:e1selected_ crypt:YES];
		
		dispatch_async(dispatch_get_main_queue(), ^{	// 終了後の処理
			[alert dismissWithClickedButtonIndex:0 animated:NO]; // 閉じる
			[UIApplication sharedApplication].networkActivityIndicatorVisible = NO; // NetworkアクセスサインOFF
			if (zErr==nil) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"PBoard Copy",nil)
																message:NSLocalizedString(@"PBoard Copy OK",nil)
															   delegate:nil
													  cancelButtonTitle:nil
													  otherButtonTitles:@"OK", nil];
				[alert show];
			}
			else {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"PBoard Error",nil)
												   message:zErr
												  delegate:nil 
										 cancelButtonTitle:nil 
										 otherButtonTitles:@"OK", nil];
				[alert show];
			}
		});
	});
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

	if (appDelegate_.app_is_iPad) {
		[appDelegate_.mainSVC dismissModalViewControllerAnimated:YES];
	} else {
		[appDelegate_.mainNC dismissModalViewControllerAnimated:YES];
	}
}


#pragma mark - delegate UIActionSheet
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (actionSheet.tag) {
		case ACTIONSEET_TAG_DELETEGROUP: // E2グループ削除
			if (buttonIndex == actionSheet.destructiveButtonIndex) 
			{ //========== E2 削除実行 ==========
				[self actionE2delateCell:indexPathActionDelete_];
			}
			break;
						
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
			[httpServer_ stop];
			//[RhttpServer release];
			httpServer_ = nil;
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
	
	if (appDelegate_.app_is_iPad) {
		if (sharePlanList_==NO) {
			// 既存Ｅ３更新
			if ([delegateE3viewController_ respondsToSelector:@selector(viewWillAppear:)]) {
				assert(delegateE3viewController_);
				if (iSection==(-9)) {
					delegateE3viewController_.firstSection = 0;
					delegateE3viewController_.sortType = (-9); // E3初期化（リロード＆再描画、セクション0表示）
				}
				else if (iSection<0) {	// Sort List
					delegateE3viewController_.firstSection = 0;
					delegateE3viewController_.sortType = (-1) * iSection;
				}
				else {
					delegateE3viewController_.firstSection = iSection;  //E3で頭出しするセクション
					delegateE3viewController_.sortType = (-1); // E3既存データあればリロードしない
				}
				delegateE3viewController_.sharePlanList = sharePlanList_;
				//
				[delegateE3viewController_ viewWillAppear:YES];
			}
			return;
		}
	}
	
	//AzPad でも PbSharePlanList=YES のとき、通る。
	// E3 へドリルダウン
	e3view = [[E3viewController alloc] init];
	// 以下は、E3viewControllerの viewDidLoad 後！、viewWillAppear の前に処理されることに注意！

	if (appDelegate_.app_is_iPad) {
		e3view.title = e1selected_.name;  //  self.title;  // NSLocalizedString(@"Items", nil);
	} else {
		e3view.title = self.title;  // PbSharePlanList=YES のとき "Sample" になるように
	}
	e3view.e1selected = e1selected_; // E1
	//e3view.PiFirstSection = indexPath.row;  // Group.ROW ==>> E3で頭出しするセクション
	//e3view.PiSortType = (-1);
	if (iSection<0) {
		e3view.firstSection = 0;
		e3view.sortType = (-1) * iSection;
	} else {
		e3view.firstSection = iSection;  //E3で頭出しするセクション
		e3view.sortType = (-1);
	}
	e3view.sharePlanList = sharePlanList_;
	[self.navigationController pushViewController:e3view animated:YES];
	//[e3view release];
}


- (void)e2adde2add
{
	// ContextにE2ノードを追加する　E2edit内でCANCELならば削除している
	E2 *e2newObj = [NSEntityDescription insertNewObjectForEntityForName:@"E2"
												 inManagedObjectContext:e1selected_.managedObjectContext];
	//[1.0.1]「新しい・・方式」として名称未定のまま先に進めるようにした
	e2newObj.name = nil; //(未定)  NSLocalizedString(@"New Index",nil);
	e2newObj.row = [NSNumber numberWithInteger:section0Rows_]; // 末尾に追加：行番号(row) ＝ 現在の行数 ＝ 現在の最大行番号＋1
	e2newObj.parent = e1selected_;	//親子リンク
	// SAVE
	NSError *err = nil;
	if (![e1selected_.managedObjectContext save:&err]) {
		NSLog(@"Unresolved error %@, %@", err, [err userInfo]);
		return;
	}
	// E3へ RaE2array を渡しているので、ここで e2newObj を追加しておく必要がある
	[e2array_ addObject:e2newObj];
	section0Rows_ = [e2array_ count];
	
	if (appDelegate_.app_is_iPad) {
		//MindexPathEdit = [NSIndexPath indexPathForRow:0 inSection:MiSection0Rows];	//新しい目次の行
		[self.tableView reloadData];
		NSIndexPath* ip = [NSIndexPath indexPathForRow:[e2newObj.row integerValue]  inSection:0]; //Row,0
		//NG	[self.tableView scrollToRowAtIndexPath:ip
		//NG						  atScrollPosition:UITableViewScrollPositionTop animated:NO];
		// E3.Refresh
		delegateE3viewController_.sortType = (-9);	// (-9)E3初期化（リロード＆再描画、セクション0表示）
		[delegateE3viewController_ viewWillAppear:YES];
		// E3へ
		[self fromE2toE3:ip.row]; // Ｅ3へドリルダウンする
	} else {
		// E3:Itemへ
		//NSIndexPath* ip = [NSIndexPath indexPathForRow:[e2newObj.row integerValue]  inSection:0];
		[self fromE2toE3:[e2newObj.row integerValue]]; // 次回の画面復帰のための状態記録をしてからＥ２へドリルダウンする
	}
}

- (void)e2editView:(NSIndexPath *)indexPath
{
	if (indexPath.section != 0) return;  // ここを通るのはセクション0だけ。
	if (section0Rows_ <= indexPath.row) return;  // Addボタン行などの場合パスする

	if (appDelegate_.app_is_iPad) {
		if ([popOver_ isPopoverVisible]) return; //[1.0.6-Bug01]同時タッチで落ちる⇒既に開いておれば拒否
	}
	
	E2 *e2obj = [e2array_ objectAtIndex:indexPath.row];
	
	e2editView_ = [[E2edit alloc] init]; // popViewで戻れば解放されているため、毎回alloc必要。
	e2editView_.title = NSLocalizedString(@"Edit Group",nil);
	e2editView_.e1selected = e1selected_;
	e2editView_.e2target = e2obj;
	e2editView_.addRow = (-1); // Edit mode
	e2editView_.sharePlanList = sharePlanList_;
	
	if (appDelegate_.app_is_iPad) {
		if ([menuPopover_ isPopoverVisible]) {
			//タテ： E2viewが[MENU]でPopover内包されているとき、E2editはiPhone同様にNavi遷移するだけ
			[self.navigationController pushViewController:e2editView_ animated:YES];
		} else {
			//ヨコ： E2viewが左ペインにあるとき、E2editを内包するPopoverを閉じる
			//[Mpopover release], 
			popOver_ = nil;
			UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:e2editView_];
			popOver_ = [[UIPopoverController alloc] initWithContentViewController:nc];
			//[nc release];
			popOver_.delegate = self;	// popoverControllerDidDismissPopover:を呼び出してもらうため
			//MindexPathEdit = indexPath;
			//[MindexPathEdit release], 
			indexPathEdit_ = [indexPath copy];
			CGRect rc = [self.tableView rectForRowAtIndexPath:indexPath];
			rc.origin.x = rc.size.width - 25;	rc.size.width = 1;
			rc.origin.y += 10;	rc.size.height -= 20;
			[popOver_ presentPopoverFromRect:rc
									  inView:self.view  permittedArrowDirections:UIPopoverArrowDirectionLeft  animated:YES];
			e2editView_.selfPopover = popOver_;  //[Mpopover release]; //(retain)  内から閉じるときに必要になる
			e2editView_.delegate = self;		// refresh callback
		}
	} else {
		[e2editView_ setHidesBottomBarWhenPushed:YES]; // 現在のToolBar状態をPushした上で、次画面では非表示にする
		[self.navigationController pushViewController:e2editView_ animated:YES];
	}
	//[Me2editView release]; // self.navigationControllerがOwnerになる
}


#ifdef DEBUG
- (void)addTestData
{
	// TEST DATA ADD 10x10
    NSInteger ie2, ie3;
	NSInteger ie3Row;
	NSInteger ie2Row = section0Rows_;  // 開始row ＝ 現在ノード数
	NSInteger iStock;
	NSInteger iNeed;
	
	// E2ノード追加
	E2 *e2obj;
	E3 *e3obj;
	for (ie2=0 ; ie2 < 10 ; ie2++, ie2Row++)
	{
		// コンテキストに新規の E2エンティティのオブジェクトを挿入します。
		e2obj = [NSEntityDescription insertNewObjectForEntityForName:@"E2"
											  inManagedObjectContext:e1selected_.managedObjectContext];
		
		[e2obj setValue:[NSString stringWithFormat:@"Group %d",ie2Row] forKey:@"name"];
		[e2obj setValue:[NSNumber numberWithInteger:ie2Row] forKey:@"row"];
		section0Rows_ = ie2Row;
		
		// e1selected(E1) の childs に newObj を追加する
		[e1selected_ addChildsObject:e2obj];
		
		// E3ノード追加
		for (ie3=0, ie3Row=0 ; ie3 < 10 ; ie3++, ie3Row++)
		{
			// コンテキストに新規の E3エンティティのオブジェクトを挿入します。
			e3obj = [NSEntityDescription insertNewObjectForEntityForName:@"E3"
												  inManagedObjectContext:e1selected_.managedObjectContext];
			
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
	[e1selected_ setValue:[e1selected_ valueForKeyPath:@"childs.@sum.sumNoGray"] forKey:@"sumNoGray"];
	[e1selected_ setValue:[e1selected_ valueForKeyPath:@"childs.@sum.sumNoCheck"] forKey:@"sumNoCheck"];
	[e1selected_ setValue:[e1selected_ valueForKeyPath:@"childs.@sum.sumWeightStk"] forKey:@"sumWeightStk"];
	[e1selected_ setValue:[e1selected_ valueForKeyPath:@"childs.@sum.sumWeightNed"] forKey:@"sumWeightNed"];
	
	if (sharePlanList_==NO) {  // SpMode=YESならば[SAVE]ボタンを非表示にしたので通らないハズだが、念のため。
		NSError *err = nil;
		if (![e1selected_.managedObjectContext save:&err]) {
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
		appDelegate_ = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		//NG//sharePlanList_ = NO;  ＜＜＜常にNOになってしまう。
		
		// 背景テクスチャ・タイルペイント
		if (appDelegate_.app_is_iPad) {
			//self.view.backgroundColor = //iPad1では無効
			UIView* view = self.tableView.backgroundView;
			if (view) {
				PatternImageView *tv = [[PatternImageView alloc] initWithFrame:view.frame
																  patternImage:[UIImage imageNamed:@"Tx-Back"]]; // タイルパターン生成
				[view addSubview:tv];
			}
			self.contentSizeForViewInPopover = GD_POPOVER_SIZE; //アクションメニュー配下(Share,Googleなど）においてサイズ統一
		} 
		else {
			self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Tx-Back"]];
		}
	}
	return self;
}

// IBを使わずにviewオブジェクトをプログラム上でcreateするときに使う（viewDidLoadは、nibファイルでロードされたオブジェクトを初期化するために使う）
- (void)loadView
{	//【Tips】ここでaddSubviewするオブジェクトは全てautoreleaseにすること。メモリ不足時には自動的に解放後、改めてここを通るので、初回同様に生成するだけ。
	[super loadView];

	// Set up NEXT Left [Back] buttons.
	self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]
											  initWithTitle:NSLocalizedString(@"Group", nil)
											  style:UIBarButtonItemStylePlain 
											  target:nil  action:nil];

	/*** loadViewやviewDidLoad:では、@property が参照できないので、viewWillAppear:へ移設
	if (sharePlanList_==NO) {
		// Set up Right [Edit] buttons.
		self.navigationItem.rightBarButtonItem = self.editButtonItem;
		self.tableView.allowsSelectionDuringEditing = YES;
	}*/
}

- (void)viewDidLoad 
{
	[super viewDidLoad];
	// listen to our app delegates notification that we might want to refresh our detail view
    [[NSNotificationCenter defaultCenter] addObserver:self			// viewDidUnload:にて removeObserver:必須
											 selector:@selector(refreshAllViews:) 
												 name:NFM_REFRESH_ALL_VIEWS
											   object:nil];  //=nil: 全てのオブジェクトからの通知を受ける
}


// 他のViewやキーボードが隠れて、現れる都度、呼び出される
- (void)viewWillAppear:(BOOL)animated 
{
	[super viewWillAppear:animated];
	
	if (appDelegate_.app_is_iPad) {
		if (sharePlanList_) {
			self.navigationItem.hidesBackButton = NO;  // 必要
			[self.navigationController setToolbarHidden:YES animated:animated]; // ツールバー消す
		} else {
			self.navigationItem.hidesBackButton = YES;	// E3側に統一したので不要になった。
			[self.navigationController setToolbarHidden:NO animated:animated]; // ツールバー表示する
		}
	} else {
		[self.navigationController setToolbarHidden:YES animated:animated]; // ツールバー消す
	}
	
	if (sharePlanList_==NO) {	// loadViewやviewDidLoad:では、@property が参照できないので、viewWillAppear:へ移設
		// Set up Right [Edit] buttons.
		self.navigationItem.rightBarButtonItem = self.editButtonItem;
		self.tableView.allowsSelectionDuringEditing = YES;
	}

	// 画面表示に関係する Option Setting を取得する
	//NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSUbiquitousKeyValueStore *kvs = [NSUbiquitousKeyValueStore defaultStore];
	optWeightRound_ = [kvs boolForKey:KV_OptWeightRound]; // YES=四捨五入 NO=切り捨て
	optShowTotalWeight_ = [kvs boolForKey:KV_OptShowTotalWeight];
	optShowTotalWeightReq_ = [kvs boolForKey:KV_OptShowTotalWeightReq];
	
	//self.title = ;　呼び出す側でセット済み。　変化させるならばココで。
	
	// 最新データ取得：Add直後などに再取得が必要なのでここで処理。　＜＜viewDidLoadだとAdd後呼び出されない＞＞
	//----------------------------------------------------------------------------CoreData Loading
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"row" ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:&sortDescriptor count:1];
	
	// E2 = self.e1selected.childs
	
	NSMutableArray *sortArray = [[NSMutableArray alloc] initWithArray:[e1selected_.childs allObjects]];
	[sortArray sortUsingDescriptors:sortDescriptors];
	if (e2array_ != sortArray) {
		//[Me2array release]; ---------▲もし、Me2arrayにsortArrayの要素があれば、先に解放されてしまう危険あり！
		//Me2array = [sortArray retain];
		//[sortArray retain];	// 先に確保
		//[RaE2array release];	// それから解放
		e2array_ = sortArray;
	}
	//[sortArray release];
	
	//[sortDescriptor release];
	//[sortDescriptors release];
	
	// ＜高速化＞ ここで行数を求めておけば、次回フィッチするまで不変。 ＜＜削除のとき-1している＞＞
	section0Rows_ = [e2array_ count];
	
	// テーブルビューを更新します。
    [self.tableView reloadData];	// これにより修正結果が表示される
	
	if (appDelegate_.app_is_iPad) {
		// ここ以前の箇所でE2が非表示のときにpop処理すると落ちる。どうやらE2を表示してから処理する必要があるようだ
		UINavigationController* navRight = [appDelegate_.mainSVC.viewControllers objectAtIndex:1]; //[1]
		if (navRight.topViewController == [navRight.viewControllers objectAtIndex:0]) {
			UINavigationController* navLeft = [appDelegate_.mainSVC.viewControllers objectAtIndex:0]; //[0]
			[navLeft popToRootViewControllerAnimated:NO];  // PadRootVC
		}
	} else {
		if (0 < contentOffsetDidSelect_.y) {
			// app.Me3dateUse=nil のときや、メモリ不足発生時に元の位置に戻すための処理。
			// McontentOffsetDidSelect は、didSelectRowAtIndexPath にて記録している。
			self.tableView.contentOffset = contentOffsetDidSelect_;
		}
		else {
			[self.tableView flashScrollIndicators]; // Apple基準：スクロールバーを点滅させる
		}
	}
}

// ビューが最後まで描画された後やアニメーションが終了した後にこの処理が呼ばれる
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

	if (appDelegate_.app_opt_Ad) {
		// E3で回転してから戻った場合に対応するため ＜＜E3以下全てに回転対応するのが面倒だから
		//[apd AdViewWillRotate:self.interfaceOrientation];
		// 各viewDidAppear:にて「許可/禁止」を設定する
		if (appDelegate_.app_is_iPad) {
			[appDelegate_ AdRefresh:NO];	//広告禁止  iPadでは、E2とE3を同時表示するため
		} else {
			if (sharePlanList_) {
				[appDelegate_ AdRefresh:NO];	//広告禁止 Fix[1.1.0]
			} else {
				[appDelegate_ AdRefresh:YES];	//広告許可
			}
		}
	}
}

// この画面が非表示になる直前に呼ばれる
- (void)viewWillDisappear:(BOOL)animated 
{
	if (appDelegate_.app_is_iPad) {
		if ([popOver_ isPopoverVisible]) { //[1.0.6-Bug01]戻る同時タッチで落ちる⇒強制的に閉じるようにした。
			[popOver_ dismissPopoverAnimated:animated];
		}
		// YES=BagSwing // 全収納済みとなったE1から戻ったとき。
		appDelegate_.app_BagSwing = (0 < [e1selected_.sumNoGray integerValue]				// グレーを除く
															   && [e1selected_.sumNoCheck integerValue] <= 0	// 全チェック済
														 && 0 < [e1selected_.childs count]);								// 目次あり
	}
	
	[super viewWillDisappear:animated];
}


// MARK: View回転

// 回転サポート
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	//[self.navigationController setToolbarHidden:YES animated:YES]; // ツールバー消す
	if (appDelegate_.app_opt_Autorotate==NO && appDelegate_.app_is_iPad==NO) {	// 回転禁止にしている場合
		return (interfaceOrientation == UIInterfaceOrientationPortrait); // 正面（ホームボタンが画面の下側にある状態）のみ許可
	}
	return YES;  // 現在の向きは、self.interfaceOrientation で取得できる
}

// shouldAutorotateToInterfaceOrientation で YES を返すと、回転開始時に呼び出される
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation 
								duration:(NSTimeInterval)duration
{
	if (appDelegate_.app_is_iPad) {
		//　E1が消えてE2が表示されてからは、ここから呼び出す必要あり。
		[appDelegate_.padRootVC willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	}

	//if (appDelegate_.app_opt_Ad) {
		// 広告非表示でも回転時に位置調整しておく必要あり ＜＜現れるときの開始位置のため＞＞
		[appDelegate_ AdViewWillRotate:toInterfaceOrientation];
	//}
}

// 回転した後に呼び出される
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{	// Popoverの位置を調整する　＜＜UIPopoverController の矢印が画面回転時にターゲットから外れてはならない＞＞
	if ([popOver_ isPopoverVisible]) {
		// E2は、タテになると非表示⇒Popoverになるので、常に閉じる
		// 回転後のアンカー位置が再現不可なので閉じる
		[popOver_ dismissPopoverAnimated:YES];
		//[Mpopover release], 
		popOver_ = nil;
	}
	
	
}

#pragma mark View Unload

- (void)unloadRelease {	// dealloc, viewDidUnload から呼び出される
	//【Tips】loadViewでautorelease＆addSubviewしたオブジェクトは全てself.viewと同時に解放されるので、ここでは解放前の停止処理だけする。
	NSLog(@"--- unloadRelease --- E2viewController");
	
	//【Tips】デリゲートなどで参照される可能性のあるデータなどは破棄してはいけない。
	// ただし、他オブジェクトからの参照無く、viewWillAppearにて生成されるものは破棄可能
	
	if (httpServer_) {
		[httpServer_ stop];
		//[RhttpServer release], 
		httpServer_ = nil;
	}
	//[RalertHttpServer release], 
	alertHttpServer_ = nil;
	//[MdicAddresses release], 
	dicAddresses_ = nil;
	//[RaE2array release], 
	e2array_ = nil;
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
	//[menuPopover]は、setPopover:にて親から渡されたものなので解放しない。
	delegateE3viewController_ = nil;
	[popOver_ setDelegate:nil];	//[1.0.6-Bug01]戻る同時タッチで落ちる⇒delegate呼び出し強制断
	//[Mpopover release], 
	popOver_ = nil;
	//[MindexPathEdit release], 
	indexPathEdit_ = nil;

	[self unloadRelease];
	//[MindexPathActionDelete release], 
	indexPathActionDelete_ = nil;
	//--------------------------------@property (retain)
	//[Re1selected release];
	//[super dealloc];
}


#pragma mark - iCloud
- (void)refreshAllViews:(NSNotification*)note 
{	// iCloud-CoreData に変更があれば呼び出される
	//@synchronized(note)
	//{
		[self viewWillAppear:YES];
	//}
}


#pragma mark - delegate UITableView

// TableView セクション数を応答
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;  // (0)Group (1)Sort list　　(2)Action menu  (3)Old menu
}

// TableView セクションの行数を応答
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	NSInteger rows = 0;
	switch (section) {
		case 0: // Group
			if (sharePlanList_) {
				rows = section0Rows_; // Addなし
			} else {
				rows = section0Rows_ + 1; // (+1)Add
			}
			break;
		case 1: // Sort list
			if (!sharePlanList_ && 0 < section0Rows_) rows = GD_E2SORTLIST_COUNT;  // (＋1)即ソート廃止
			else rows = 0;
			break;
		case 2: // Action menu
			if (!sharePlanList_ && 0 < section0Rows_) {
				rows = 5;
			}
			else rows = 0;
			break;
		case 3: // Old menu
			if (!sharePlanList_ && 0 < section0Rows_) {
				rows = 2;
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
			if (optShowTotalWeight_) {
				// ＜高速化＞ E3(Item)更新時、その親E2のsum属性、さらにその親E1のsum属性を更新することで整合および参照時の高速化を実現した。
				long lWeightStk = [[e1selected_ valueForKey:@"sumWeightStk"] longValue];
				if (optWeightRound_) {
					// 四捨五入　＜＜ %.1f により小数第2位が丸められる＞＞ 
					dWeightStk = (double)lWeightStk / 1000.0f;
				} else {
					// 切り捨て                       ↓これで下2桁が0になる
					dWeightStk = (double)(lWeightStk / 100) / 10.0f;
				}
			}
			if (optShowTotalWeightReq_) {
				// ＜高速化＞ E3(Item)更新時、その親E2のsum属性、さらにその親E1のsum属性を更新することで整合および参照時の高速化を実現した。
				long lWeightReq = [[e1selected_ valueForKey:@"sumWeightNed"] longValue];
				if (optWeightRound_) {
					// 四捨五入　＜＜ %.1f により小数第2位が丸められる＞＞ 
					dWeightReq = (double)lWeightReq / 1000.0f;
				} else {
					// 切り捨て                       ↓これで下2桁が0になる
					dWeightReq = (double)(lWeightReq / 100) / 10.0f;
				}
			}
			if (optShowTotalWeight_ && optShowTotalWeightReq_) {
				return [NSString stringWithFormat:@"%@  %.1f／%.1fKg", 
												NSLocalizedString(@"Group total",nil), dWeightStk, dWeightReq];
			} else if (optShowTotalWeight_) {
				return [NSString stringWithFormat:@"%@  %.1fKg", 
												NSLocalizedString(@"Group total",nil), dWeightStk];
			} else if (optShowTotalWeightReq_) {
				return [NSString stringWithFormat:@"%@  ／%.1fKg", 
												NSLocalizedString(@"Group total",nil), dWeightReq];
			} else {
				return [NSString stringWithFormat:@"%@", NSLocalizedString(@"Group",nil)];
			}
			break;
		case 1:
			if (!sharePlanList_ && 0<section0Rows_) {
				return NSLocalizedString(@"Sort list", @"並び替え");
			}
			break;
		case 2:
			if (!sharePlanList_ && 0<section0Rows_) {
				return NSLocalizedString(@"menu Action",nil);
			}
			break;
		case 3:
			if (!sharePlanList_ && 0<section0Rows_) {
				return NSLocalizedString(@"menu Old",nil);
			}
			break;
	}
	return nil;
}

// TableView セクションフッタを応答
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	switch (section) {
		case 3:
			if (sharePlanList_) {
				return NSLocalizedString(@"SharePLAN PreView",nil);
			}
			if (appDelegate_.app_opt_Ad) {
				if (appDelegate_.app_is_iPad) {
					return @"\n\n\n\n\n\n\n\n\n\n\n\n\n\n";	// 大型AdMobスペースのための下部余白
				} else {
					return @"\n\n\n";	// 広告スペースのための下部余白
				}
			}
			return @"";
			break;
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
			if (indexPath.row < section0Rows_) {
				// 通常のノードセル
				cell = [tableView dequeueReusableCellWithIdentifier:zCellSubtitle];
				if (cell == nil) {
					cell = [[UITableViewCell alloc] 
							 initWithStyle:UITableViewCellStyleSubtitle
							 reuseIdentifier:zCellSubtitle];
				}
				// e2node
				E2 *e2obj = [e2array_ objectAtIndex:indexPath.row];
				
#ifdef DEBUG
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
				
				NSInteger lNoGray = [e2obj.sumNoGray integerValue];
				NSInteger lNoCheck = [e2obj.sumNoCheck integerValue];

				double dWeightStk;
				double dWeightReq;
				if (optShowTotalWeight_) {
					// ＜高速化＞ E3(Item)更新時、その親E2のsum属性、さらにその親E1のsum属性を更新することで整合および参照時の高速化を実現した。
					NSInteger lWeightStk = [e2obj.sumWeightStk integerValue];
					if (optWeightRound_) {
						// 四捨五入　＜＜ %.1f により小数第2位が丸められる＞＞ 
						dWeightStk = (double)lWeightStk / 1000.0f;
					} else {
						// 切り捨て                       ↓これで下2桁が0になる
						dWeightStk = (double)(lWeightStk / 100) / 10.0f;
					}
				}
				if (optShowTotalWeightReq_) {
					// ＜高速化＞ E3(Item)更新時、その親E2のsum属性、さらにその親E1のsum属性を更新することで整合および参照時の高速化を実現した。
					NSInteger lWeightReq = [e2obj.sumWeightNed integerValue];
					if (optWeightRound_) {
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
				
				if (optShowTotalWeight_ && optShowTotalWeightReq_) {
					cell.detailTextLabel.text = [NSString stringWithFormat:@"%.1f／%.1fKg  %@", 
												 dWeightStk, dWeightReq, zNote];
				} else if (optShowTotalWeight_) {
					cell.detailTextLabel.text = [NSString stringWithFormat:@"%.1fKg  %@", 
												 dWeightStk, zNote];
				} else if (optShowTotalWeightReq_) {
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
					//[imageView1 release];
					//[imageView2 release];
				}
				else if (0 < lNoGray) {
					cell.imageView.image = [UIImage imageNamed:@"Icon32-CircleCheck.png"];
				}
				else { // 全てGray
					cell.imageView.image = [UIImage imageNamed:@"Icon32-CircleGray.png"];
				}
				
				if (sharePlanList_) {	//サンプル
					cell.showsReorderControl = NO;		// Move拒否
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;	// > ディスクロージャマーク
				} else {
					cell.showsReorderControl = YES;		// Move許可
					cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton; // ディスクロージャボタン
				}
			} 
			else if (indexPath.row == section0Rows_) {
				// 追加ボタンセル　(+)Add Group
				cell = [tableView dequeueReusableCellWithIdentifier:zCellDefault];
				if (cell == nil) {
					cell = [[UITableViewCell alloc] 
							 initWithStyle:UITableViewCellStyleDefault      // Default型
							 reuseIdentifier:zCellDefault];
				}
				if (indexPath.row == section0Rows_) {
					cell.imageView.image = [UIImage imageNamed:@"Icon24-GreenPlus.png"];
					//cell.textLabel.text = NSLocalizedString(@"Add Group",nil);
					cell.textLabel.text = NSLocalizedString(@"New Index",nil);
				} else {
					cell.imageView.image = [UIImage imageNamed:@"Icon24-GreenPlus.png"];
					cell.textLabel.text = NSLocalizedString(@"Copy Group",nil);
				}

				if (appDelegate_.app_is_iPad) {
					cell.textLabel.font = [UIFont systemFontOfSize:18];
				} else {
					cell.textLabel.font = [UIFont systemFontOfSize:14];
				}
				cell.textLabel.textAlignment = UITextAlignmentCenter; // 中央寄せ
				cell.textLabel.textColor = [UIColor darkGrayColor];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;	// > ディスクロージャマーク
				cell.showsReorderControl = NO;
			}
			break;

		case 1:	// section: Sort list
			cell = [tableView dequeueReusableCellWithIdentifier:zCellSubtitle];
			if (cell == nil) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle		// サブタイトル型(3.0)
											   reuseIdentifier:zCellSubtitle];
			}

			if (appDelegate_.app_is_iPad) {
				cell.textLabel.font = [UIFont systemFontOfSize:18];
				cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
			} else {
				cell.textLabel.font = [UIFont systemFontOfSize:16];
				cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
			}
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
		
		case 2:	//------------------------------------------------------------------ section: Action menu
			cell = [tableView dequeueReusableCellWithIdentifier:zCellSubtitle];
			if (cell == nil) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle		// サブタイトル型(3.0)
											   reuseIdentifier:zCellSubtitle];
			}

			if (appDelegate_.app_is_iPad) {
				cell.textLabel.font = [UIFont systemFontOfSize:18];
				cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
			} else {
				cell.textLabel.font = [UIFont systemFontOfSize:16];
				cell.detailTextLabel.font = [UIFont systemFontOfSize:10];
			}
			cell.textLabel.textAlignment = UITextAlignmentLeft;
			cell.textLabel.textColor = [UIColor darkGrayColor];
			
			cell.detailTextLabel.textAlignment = UITextAlignmentLeft;
			cell.detailTextLabel.textColor = [UIColor grayColor];

			cell.imageView.image = nil;
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.showsReorderControl = NO;		// Move禁止
			
			switch (indexPath.row) {
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
					if (appDelegate_.app_is_iPad==NO  OR  [menuPopover_ isPopoverVisible]) {  //iPad-Popover内ならばiPhoneと同じ
						cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;	// > ディスクロージャマーク
					}
					break;
				case 3:
					cell.imageView.image = [UIImage imageNamed:@"Dropbox-130x44"];
					cell.textLabel.text = NSLocalizedString(@"Backup Dropbox",nil);
					cell.detailTextLabel.text = NSLocalizedString(@"Backup Dropbox msg",nil);
					if (appDelegate_.app_is_iPad==NO  OR  [menuPopover_ isPopoverVisible]) {  //iPad-Popover内ならばiPhoneと同じ
						cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;	// > ディスクロージャマーク
					}
					break;
				case 4:
					cell.imageView.image = [UIImage imageNamed:@"Icon32-GoogleDoc"];
					cell.textLabel.text = NSLocalizedString(@"Backup Google",nil);
					cell.detailTextLabel.text = NSLocalizedString(@"Backup Google msg",nil);
					if (appDelegate_.app_is_iPad==NO  OR  [menuPopover_ isPopoverVisible]) {  //iPad-Popover内ならばiPhoneと同じ
						cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;	// > ディスクロージャマーク
					}
					break;
			}
			break;
			
		case 3:	//------------------------------------------------------------------ section: Old menu
			cell = [tableView dequeueReusableCellWithIdentifier:zCellSubtitle];
			if (cell == nil) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle		// サブタイトル型(3.0)
											  reuseIdentifier:zCellSubtitle];
			}
			
			if (appDelegate_.app_is_iPad) {
				cell.textLabel.font = [UIFont systemFontOfSize:18];
				cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
			} else {
				cell.textLabel.font = [UIFont systemFontOfSize:16];
				cell.detailTextLabel.font = [UIFont systemFontOfSize:10];
			}
			cell.textLabel.textAlignment = UITextAlignmentLeft;
			cell.textLabel.textColor = [UIColor darkGrayColor];
			
			cell.detailTextLabel.textAlignment = UITextAlignmentLeft;
			cell.detailTextLabel.textColor = [UIColor grayColor];
			
			cell.imageView.image = nil;
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.showsReorderControl = NO;		// Move禁止
			
			switch (indexPath.row) {
				case 0:
					cell.imageView.image = [UIImage imageNamed:@"Icon32-NearPc"];
					cell.textLabel.text = NSLocalizedString(@"Backup YourPC",nil);
					cell.detailTextLabel.text = NSLocalizedString(@"Backup YourPC msg",nil);
					break;
				case 1:
					cell.imageView.image = [UIImage imageNamed:@"Icon32-PasteCopy"];
					cell.textLabel.text = NSLocalizedString(@"Copied to PasteBoard",nil);
					cell.detailTextLabel.text = NSLocalizedString(@"Copied to PasteBoard msg",nil);
					break;
			}
			break;
	}
	return cell;
}

/*
// UISwitch Action
- (void)switchAction: (UISwitch *)sender
{
	if (sender.tag != 999) return;
 
	BOOL bQuickSort = [sender isOn];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:bQuickSort forKey:GD_OptItemsQuickSort];
}*/

// TableView Editボタンスタイル
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
		if (indexPath.row < section0Rows_) 
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
	if (httpServer_) return;
	
	// didSelect時のScrollView位置を記録する（viewWillAppearにて再現するため）
	contentOffsetDidSelect_ = [tableView contentOffset];

	switch (indexPath.section) {
		case 0: // GROUP
			if (section0Rows_ <= indexPath.row) {	// Add Group
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
			if (0 < section0Rows_ && indexPath.row < GD_E2SORTLIST_COUNT) 
			{
				if (appDelegate_.app_is_iPad) {
					// 既存Ｅ３更新
					if ([delegateE3viewController_ respondsToSelector:@selector(viewWillAppear:)]) {
						assert(delegateE3viewController_);
						delegateE3viewController_.firstSection = 0;  // Group.ROW ==>> E3で頭出しするセクション
						delegateE3viewController_.sortType = indexPath.row;
						delegateE3viewController_.sharePlanList = sharePlanList_;
						[delegateE3viewController_ viewWillAppear:YES];
					}
				}
				else {
					// E3 へドリルダウン
					E3viewController *e3view = [[E3viewController alloc] initWithStyle:UITableViewStylePlain];
					// 以下は、E3viewControllerの viewDidLoad 後！、viewWillAppear の前に処理されることに注意！
					e3view.title = e1selected_.name;  //self.title;  // NSLocalizedString(@"Items", nil);
					e3view.e1selected = e1selected_; // E1
					e3view.firstSection = 0;  // Group.ROW ==>> E3で頭出しするセクション
					e3view.sortType = indexPath.row;
					e3view.sharePlanList = sharePlanList_;
					[self.navigationController pushViewController:e3view animated:YES];
					//[e3view release];
				}
			}
			break;
			
		case 2: { // Action Menu
			switch (indexPath.row) {
				case 0: // All Zero  全在庫数量を、ゼロにする
					[self	actionAllZero];
					break;
					
				case 1: //[1.1]E-mail send
					[self actionEmailSend];
					break;
					
				case 2: // Upload Share Plan
					[self actionSharedPackListUp:indexPath];
					return; //Popover時に閉じないように
					
				case 3: // Backup to Dropbox
					[self actionBackupDropbox:indexPath];
					return; //Popover時に閉じないように
					
				case 4: // Backup to Google
					[self actionBackupGoogle:indexPath];
					return; //Popover時に閉じないように
			}
		}	break;

		case 3: { // Old Menu
			switch (indexPath.row) {
				case 0: // Backup to YourPC
					[self actionBackupYourPC];
					break;
					
				case 1: // ペーストボードへコピー
					[self actionCopiedPasteBoard];
					break;
			}
		}	break;
	}

	if (appDelegate_.app_is_iPad) {
		if ([menuPopover_ isPopoverVisible]) {	//選択後、Popoverならば閉じる
			[menuPopover_ dismissPopoverAnimated:YES];
		}
	}
}

// HTTP Server Address Display
- (void)httpInfoUpdate:(NSNotification *) notification
{
	NSLog(@"httpInfoUpdate:");
	
	if(notification)
	{
		//[MdicAddresses release], 
		dicAddresses_ = nil;
		dicAddresses_ = [[notification object] copy];
		NSLog(@"MdicAddresses: %@", dicAddresses_);
	}
	
	if(dicAddresses_ == nil)
	{
		return;
	}
	
	NSString *info;
	UInt16 port = [httpServer_ port];
	
	NSString *localIP = nil;
	localIP = [dicAddresses_ objectForKey:@"en0"];
	if (!localIP)
	{
		localIP = [dicAddresses_ objectForKey:@"en1"];
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
	if (alertHttpServer_) {
		alertHttpServer_.message = info;
		[alertHttpServer_ show];
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

	if (appDelegate_.app_is_iPad) {
		// 右ナビ E3 を更新する
		[self fromE2toE3:(-9)]; // (-9)E3初期化（リロード＆再描画、セクション0表示）
	}
}

// TableView Editモード処理
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
															forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		// 削除コマンド警告　==>> (void)actionSheet にて処理
		//Bug//MindexPathActionDelete = indexPath;
		//[MindexPathActionDelete release], 
		indexPathActionDelete_ = [indexPath copy];
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
		//[action release];
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
	if (indexPath.section == 0 && indexPath.row < section0Rows_) return YES;
	return NO;  // 移動禁止
}

// Editモード時の行移動「先」を返す　　＜＜最終行のAdd専用行への移動ならば1つ前の行を返している＞＞
- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)oldPath 
														toProposedIndexPath:(NSIndexPath *)newPath {
    NSIndexPath *target = newPath;
	NSInteger rows = section0Rows_ - 1;  // 移動可能な行数（Add行を除く）
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
	E2 *e2obj = [e2array_ objectAtIndex:oldPath.row];

	[e2array_ removeObjectAtIndex:oldPath.row];
	[e2array_ insertObject:e2obj atIndex:newPath.row];
	
	NSInteger start = oldPath.row;
	NSInteger end = newPath.row;
	if (end < start) {
		start = newPath.row;
		end = oldPath.row;
	}
	for (NSInteger i = start; i <= end; i++) {
		e2obj = [e2array_ objectAtIndex:i];
		e2obj.row = [NSNumber numberWithInteger:i];
	}

	if (sharePlanList_==NO) {  // SpMode=YESならば[SAVE]ボタンを非表示にしたので通らないハズだが、念のため。
		// SAVE　＜＜万一システム障害で落ちてもデータが残るようにコマメに保存する方針＞＞
		NSError *error = nil;
		if (![e1selected_.managedObjectContext save:&error]) {
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			exit(-1);  // Fail
		}
	}
}


#pragma mark - delegate UIPopoverController
- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{	// Popoverの外部をタップして閉じる前に通知
	// 内部(SAVE)から、dismissPopoverAnimated:で閉じた場合は呼び出されない。
	//[1.0.6]Cancel: 今更ながら、insert後、saveしていない限り、rollbackだけで十分であることが解った。

	UINavigationController* nc = (UINavigationController*)[popoverController contentViewController];
	if ( [[nc visibleViewController] isMemberOfClass:[E2edit class]] ) {	// E2edit のときだけ、
		if (appDelegate_.app_UpdateSave) { // E2editにて、変更あるので閉じさせない
			alertBox(NSLocalizedString(@"Cancel or Save",nil), 
					 NSLocalizedString(@"Cancel or Save msg",nil), NSLocalizedString(@"Roger",nil));
			return NO; 
		}
	}
	return YES; // 閉じることを許可
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{	// [Cancel][Save][枠外タッチ]何れでも閉じるときここを通るので解放する。さもなくば回転後に現れることになる
	if (popoverController == menuPopover_) {
		if (self.navigationController.topViewController != self) {
			//タテ： E2viewが[MENU]でPopover内包されているとき、配下に遷移しておれば戻す
			[self.navigationController popViewControllerAnimated:NO];	// < 前のViewへ戻る
			[e1selected_.managedObjectContext rollback]; // 前回のSAVE以降を取り消す
		}
	}	
}


@end
