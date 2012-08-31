//
//  SpDetailTVC.m
//  AzPacking
//
//  Created by 松山 和正 on 10/01/27.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Global.h"
#import "AppDelegate.h"
#import "Elements.h"
#import "FileCsv.h"
#import "SpPOST.h"
#import "SpDetailTVC.h"
#import "E2viewController.h"
#import "PatternImageView.h"

#import  <YAJLiOS/YAJL.h>
//#import <DropboxSDK/JSON.h>  SBJSONでは、読み取りエラー発生した。（多分、CSV部）


#define ACTION_TAG_A_PLAN	901

#define ALERT_TAG_PREVIEW	802		// 各桁計10の倍数にしている。
#define ALERT_TAG_BREAK		811
#define ALERT_TAG_DELETE	820

#define CELL_TAG_NOTE		703


@interface SpDetailTVC (PrivateMethods)
- (NSString *)vSharePlanDelete:(NSString *)zKey;
- (NSString *)vSharePlanDownload:(NSString *)zKey;
- (NSString *)vSharePlanCountUp:(NSString *)zKey;
@end

@implementation SpDetailTVC

@synthesize RzSharePlanKey;
@synthesize PbOwner;


#pragma mark - Send Mail

- (void)sendmail:(NSString*)packListName  key:(NSString*)key
{
	MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
	picker.mailComposeDelegate = self;
	// To: 宛先
	NSArray *toRecipients = [NSArray arrayWithObject:@"packlist@azukid.com"];
	[picker setToRecipients:toRecipients];
	
	// Subject: 件名
	NSString* zSubj = NSLocalizedString(@"Product Title",nil);
	zSubj = [zSubj stringByAppendingString:@"   "];
	zSubj = [zSubj stringByAppendingString:NSLocalizedString(@"Share　Reporting",nil)];
	[picker setSubject:zSubj];  
	
	// Body: 本文
	NSArray *languages = [NSLocale preferredLanguages];
	NSString* zBody = NSLocalizedString(@"Product Title",nil);
	zBody = [zBody stringByAppendingFormat:@"\nLocale: %@ (%@)\n",
			 [[NSLocale currentLocale] objectForKey:NSLocaleIdentifier],
			 [languages objectAtIndex:0]];
	
	zBody = [zBody stringByAppendingFormat:@"PackList ID [%@]\n\n", key];
	
	zBody = [zBody stringByAppendingFormat:NSLocalizedString(@"Share　Reporting msg",nil), packListName];
	[picker setMessageBody:zBody isHTML:NO];
	
	picker.modalPresentationStyle = UIModalPresentationFormSheet;
	[self presentModalViewController:picker animated:YES];
}

#pragma mark  <MFMailComposeViewControllerDelegate>

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
			azAlertBox( NSLocalizedString(@"Contact Sent",nil), NSLocalizedString(@"Contact Sent msg",nil), @"OK" );
            break;
        case MFMailComposeResultFailed:
            //[self setAlert:@"メール送信失敗！":@"メールの送信に失敗しました。ネットワークの設定などを確認して下さい"];
			azAlertBox( NSLocalizedString(@"Contact Failed",nil), NSLocalizedString(@"Contact Failed msg",nil), @"OK" );
            break;
        default:
            break;
    }
	// Close
	[self dismissModalViewControllerAnimated:YES];
}


#pragma mark - View Lifecicle

- (void)unloadRelease	// dealloc, viewDidUnload から呼び出される
{
	NSLog(@"--- unloadRelease --- SpDetailTVC");
	
	[RurlConnection cancel]; // 停止させてから解放する
	//[RurlConnection release],	
	RurlConnection = nil;

	//[RdaResponse release],		
	RdaResponse = nil;
}

- (void)dealloc 
{
	if (Re1add) {
		[Re1add.managedObjectContext rollback];		// [FileCsv zLoad:]にて save していないので、rollback で配下全て取り消しできる。
		Re1add = nil;
	}
	[self unloadRelease];
	//--------------------------------@property (retain)
	//[RzSharePlanKey release];
    //[super dealloc];
}

- (void)viewDidUnload 
{	// メモリ不足時、裏側にある場合に呼び出されるので、viewDidLoadで生成したObjを解放する。
	//NSLog(@"--- viewDidUnload ---"); 
	// メモリ不足時、裏側にある場合に呼び出される。addSubviewされたOBJは、self.viewと同時に解放される
	[self unloadRelease];
	[super viewDidUnload];
	// この後に loadView ⇒ viewDidLoad ⇒ viewWillAppear がコールされる
}


- (id)initWithStyle:(UITableViewStyle)style 
{
	if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
		// 初期化成功
		//RautoPool = [[NSAutoreleasePool alloc] init];	// [0.6]autorelease独自解放のため
		Re1add = nil;
		RdaResponse = nil;
		MiConnectTag = 0;
		appDelegate_ = (AppDelegate *)[[UIApplication sharedApplication] delegate];

		// 背景テクスチャ・タイルペイント
		if (appDelegate_.app_is_iPad) {
			//self.view.backgroundColor = //iPadでは無効
			UIView* view = self.tableView.backgroundView;
			if (view) {
				PatternImageView *tv = [[PatternImageView alloc] initWithFrame:view.frame
																  patternImage:[UIImage imageNamed:@"Tx-Back"]]; // タイルパターン生成
				[view addSubview:tv];
			}
		} else {
			self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Tx-Back"]];
		}
	}
	return self;
}

// IBを使わずにviewオブジェクトをプログラム上でcreateするときに使う（viewDidLoadは、nibファイルでロードされたオブジェクトを初期化するために使う）
- (void)loadView
{
	[super loadView];
	
	self.title = NSLocalizedString(@"Sample Display",nil);
	
	self.tableView.allowsSelectionDuringEditing = YES;

	// Set up NEXT Left [Back] buttons.
	self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]
											  initWithTitle:NSLocalizedString(@"Back", nil)
											  style:UIBarButtonItemStylePlain 
											  target:nil  action:nil];

}

// 表示前
- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];

	// 画面表示に関係する Option Setting を取得する
	//NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSUbiquitousKeyValueStore *kvs = [NSUbiquitousKeyValueStore defaultStore];
	MbOptTotlWeightRound = [kvs boolForKey:KV_OptWeightRound]; // YES=四捨五入 NO=切り捨て
	MbOptShowTotalWeight = [kvs boolForKey:KV_OptShowTotalWeight];
	MbOptShowTotalWeightReq = [kvs boolForKey:KV_OptShowTotalWeightReq];
	
	if (Re1add) {
		NSLog(@"Re1add=%@", Re1add);
		[self.tableView reloadData]; // cell回転(再描画)させるために必要
	}
}

// 表示後
- (void)viewDidAppear:(BOOL)animated 
{
    [super viewDidAppear:animated];
	GA_TRACK_METHOD
	
	if (Re1add==nil) { // 初回
		@autoreleasepool {
			[self vSharePlanDownload:RzSharePlanKey]; // viewWillAppear:ではRzSharePlanKeyが未定だからここ
		}
	}
}

// 回転サポート
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{	
	if (appDelegate_.app_is_iPad) {
		return YES;	// FormSheet窓対応
	}
	else if (appDelegate_.app_opt_Autorotate==NO) {	// 回転禁止にしている場合
		return (interfaceOrientation == UIInterfaceOrientationPortrait); // 正面（ホームボタンが画面の下側にある状態）のみ許可
	}
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation 
										 duration:(NSTimeInterval)duration
{
	[self.tableView reloadData]; // cell回転(再描画)させるために必要
}



- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{	// データ受信時
	if (RdaResponse==nil) {
		RdaResponse = [NSMutableData new];
	}
	[RdaResponse appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{	// 通信終了時
	if (RdaResponse) {
		NSString *jsonStr = [[NSString alloc] initWithData:RdaResponse encoding:NSUTF8StringEncoding];
		AzLOG(@"jsonStr: %@", jsonStr);
		[RdaResponse setData:nil]; // 次回の受信に備えてクリアする
		 
		switch (MiConnectTag) 
		{
			case 3: { // Download --> SpDetailTVC --> SAVE or ROLLBACK
				NSArray *jsonArray;
				@try {
					jsonArray = [jsonStr yajl_JSON]; // YAJLを使ったJSONデータのパース処理 
				}
				@catch (NSException *ex) {
					// jsonStrがJSON文字列ではない
					alertMsgBox( NSLocalizedString(@"Connection Error",nil), 
								nil,
								NSLocalizedString(@"Roger",nil) );
					[self.navigationController popViewControllerAnimated:YES];	// 前のViewへ戻る
					break;
				}
				NSLog(@"jsonArray=%@", jsonArray);
				if (0 < [jsonArray count]) {
					NSDictionary *dic = [jsonArray objectAtIndex:0];
					NSString *planCsv = [dic objectForKey:@"planCsv"];
					
					dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
					dispatch_async(queue, ^{		// 非同期マルチスレッド処理
						FileCsv *fcsv = [[FileCsv alloc] init];
						Re1add = [fcsv e1Load:planCsv   withSave:NO];	// NO = Moc-SAVE しない！ ゆえに、Re1add は rollback だけで取り消し可能。
						
						dispatch_async(dispatch_get_main_queue(), ^{	// 終了後の処理
							if (Re1add) {
								[self.tableView reloadData];
							} 
							else {
								alertMsgBox( NSLocalizedString(@"Download Err",nil), 
											nil,
											NSLocalizedString(@"Roger",nil) );
								// 前Viewへ戻す
							}
							MiConnectTag = 0; // 通信してません
							[UIApplication sharedApplication].networkActivityIndicatorVisible = NO; // NetworkアクセスサインOFF
						});
					});
					return; // 非同期につき、最後の MiConnectTag = 0; を通さないようにするため
				}
			}	break;
				
			case 4: { // Delete
				NSRange rg = [jsonStr rangeOfString:@"Delete:OK"];
				if (rg.length <= 0) {
					//zErr = [NSString stringWithString:str]; // strは次行で解放されるので、pool変数にして返す。
					alertMsgBox( NSLocalizedString(@"Delete Err",nil), 
								jsonStr,
								NSLocalizedString(@"Roger",nil) );
					// 前Viewへ戻す
				}
			}	break;

			case 5: { // CountUp
				NSRange rg = [jsonStr rangeOfString:@"CountUp:OK"];
				if (rg.length <= 0) {
					//alertMsgBox( NSLocalizedString(@"CountUp Err",nil), 
					//			jsonStr,
					//			NSLocalizedString(@"Roger",nil) );
					//CountUpは競合エラー発生の可能性が高い。今の所、エラー発生しても無視する。
					//確実にカウントさせるためには、「シェアードカウンタ」などの対策が必要。
				}
			}	break;

			default:
				break;
		}
	}
	MiConnectTag = 0; // 通信してません
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO; // NetworkアクセスサインOFF
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{	// 通信中断時
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO; // NetworkアクセスサインOFF
	MiConnectTag = 0; // 通信してません
	
	NSString *error_str = [error localizedDescription];
	if (0<[error_str length]) {
		alertMsgBox( NSLocalizedString(@"Connection Error",nil), 
					error_str,
					NSLocalizedString(@"Roger",nil) );
	}
	//[RdaResponse release], 
	RdaResponse = nil;
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if (Re1add) {
		return 3;
	}
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section) {
		case 0:
			if (Re1add) return 2;
			return 1;
		case 1:
			if (PbOwner) return 2;
			return 1;
		case 2:
			return 1;
	}
	return 0;
}

// TableView セクション名を応答
//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 

// セルの高さを指示する
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if (indexPath.section==0 && indexPath.row==1) { // E1.note
		if (appDelegate_.app_is_iPad || UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) { //タテ
			return 100;
		} else { //ヨコ
			return 64;
		}
	}
	else if (indexPath.section==1) {
		return 55;
	}
	return 44; // Def.
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    static NSString *zCellE1name = @"CellE1name";
    static NSString *zCellE1note = @"CellE1note";
    static NSString *zCellFunc = @"CellFunc";
    //UILabel *lb;
	
	switch (indexPath.section) {
		case 0: { //-----------------------------------------------------------Section(0) name
			switch (indexPath.row) {
				case 0: { //----------------------------------------- name
					UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:zCellE1name];
					if (cell == nil) {
						cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
													   reuseIdentifier:zCellE1name];
					}
					if (Re1add) {
						// E1 一時読み込みしたものを表示する
						E1 *e1obj = Re1add;
						//---------------------------以下、E1viewController.m:cellForRowAtIndexPathよりコピー
						if ([e1obj.name length] <= 0) 
							cell.textLabel.text = NSLocalizedString(@"(New Pack)", nil);
						else
							cell.textLabel.text = e1obj.name;
						
						cell.textLabel.font = [UIFont systemFontOfSize:18];
						cell.textLabel.textAlignment = UITextAlignmentLeft;
						cell.textLabel.textColor = [UIColor blackColor];
						
						cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
						cell.detailTextLabel.textAlignment = UITextAlignmentLeft;
						cell.detailTextLabel.textColor = [UIColor grayColor];
						
						// ＜高速化＞ E3(Item)更新時、その親E2のsum属性、さらにその親E1のsum属性を更新することで整合および参照時の高速化を実現した。
						NSInteger lNoGray = [e1obj.sumNoGray integerValue];
						NSInteger lNoCheck = [e1obj.sumNoCheck integerValue];
						// 重量
						double dWeightStk;
						double dWeightReq;
						if (MbOptShowTotalWeight) {
							NSInteger lWeightStk = [e1obj.sumWeightStk integerValue];
							if (MbOptTotlWeightRound) {
								// 四捨五入　＜＜ %.1f により小数第2位が丸められる＞＞ 
								dWeightStk = (double)lWeightStk / 1000.0f;
							} else {
								// 切り捨て                       ↓これで下2桁が0になる
								dWeightStk = (double)(lWeightStk / 100) / 10.0f;
							}
							
							if (MbOptShowTotalWeightReq) {
								NSInteger lWeightReq = [e1obj.sumWeightNed integerValue];
								if (MbOptTotlWeightRound) {
									// 四捨五入　＜＜ %.1f により小数第2位が丸められる＞＞ 
									dWeightReq = (double)lWeightReq / 1000.0f;
								} else {
									// 切り捨て                       ↓これで下2桁が0になる
									dWeightReq = (double)(lWeightReq / 100) / 10.0f;
								}
							}
							
							if (MbOptShowTotalWeight && MbOptShowTotalWeightReq) {
								cell.detailTextLabel.text = [NSString stringWithFormat:@"%.1f／%.1fKg  %@", 
															 dWeightStk, dWeightReq, e1obj.note];
							} else if (MbOptShowTotalWeight) {
								cell.detailTextLabel.text = [NSString stringWithFormat:@"%.1fKg  %@", 
															 dWeightStk, e1obj.note];
							} else if (MbOptShowTotalWeightReq) {
								cell.detailTextLabel.text = [NSString stringWithFormat:@"／%.1fKg  %@", 
															 dWeightReq, e1obj.note];
							} else {
								cell.detailTextLabel.text = e1obj.note;
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
								//[imageView1 release];
								imageView1 = nil;
								//[imageView2 release];
								imageView2 = nil;
							} 
							else if (0 < lNoGray) {
								cell.imageView.image = [UIImage imageNamed:@"Icon32-BagBlue.png"];
							}
							else { // 全てGray
								cell.imageView.image = [UIImage imageNamed:@"Icon32-BagGray.png"];
							}
							cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; // >
							cell.showsReorderControl = NO; // Move
							cell.selectionStyle = UITableViewCellSelectionStyleBlue; // 選択時ハイライトBLUE
						}
					}
					else {
						// E1 読み込み中であることを表示する
						cell.textLabel.text = NSLocalizedString(@"Communicating",nil);
						cell.textLabel.font = [UIFont systemFontOfSize:18];
						cell.textLabel.textAlignment = UITextAlignmentCenter;
						cell.textLabel.textColor = [UIColor blueColor];
						cell.accessoryType = UITableViewCellAccessoryNone;
						cell.selectionStyle = UITableViewCellSelectionStyleNone; // 選択時ハイライトなし
					}
					return cell;
				}	break;

				case 1: { //----------------------------------------- note
					UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:zCellE1note];
					if (cell == nil) {
						cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
													   reuseIdentifier:zCellE1note];
						cell.accessoryType = UITableViewCellAccessoryNone;
						cell.showsReorderControl = NO;		// Move
						cell.selectionStyle = UITableViewCellSelectionStyleNone; // 選択時ハイライトなし
						//
						UILabel *lb = [[UILabel alloc] init];
						lb.font = [UIFont systemFontOfSize:14];
						lb.numberOfLines = 7;
						lb.backgroundColor = [UIColor clearColor]; // grayColor 範囲チェック時
						lb.tag = CELL_TAG_NOTE;
						[cell.contentView addSubview:lb]; //[lb release];
					}
					UILabel *lb = (UILabel *)[cell.contentView viewWithTag:CELL_TAG_NOTE];
					if (appDelegate_.app_is_iPad || UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) { //タテ
						lb.frame = CGRectMake(5, 5, 320-30, 100-10);
					} else { //ヨコ
						lb.frame = CGRectMake(5, 3, 480-30, 64-6);
					}
					//lb.frame = cell.contentView.frame;
					if (Re1add) { // E1 一時読み込みしたものを表示する
						lb.text = Re1add.note;
					}
					return cell;
				}	break;
			}
		} break;
		
		case 1: { //-----------------------------------------------------------Section(1) function
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:zCellFunc];
			if (cell == nil) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
											   reuseIdentifier:zCellFunc];
			}
			switch (indexPath.row) {
				case 0: // Add this PLAN
					cell.textLabel.font = [UIFont systemFontOfSize:16];
					cell.textLabel.textAlignment = UITextAlignmentCenter; // 中央寄せ
					cell.textLabel.textColor = [UIColor blueColor];
					cell.imageView.image = [UIImage imageNamed:@"Icon24-GreenPlus.png"];
					cell.accessoryType = UITableViewCellAccessoryNone;  // なし
					cell.showsReorderControl = NO;
					cell.textLabel.text = NSLocalizedString(@"Add SharePLAN",nil);
					break;
				case 1: // Delete this PLAN
					cell.textLabel.font = [UIFont systemFontOfSize:14];
					cell.textLabel.textAlignment = UITextAlignmentCenter; // 中央寄せ
					cell.textLabel.textColor = [UIColor redColor];
					cell.imageView.image = [UIImage imageNamed:@"Icon24-RedMinus.png"];
					cell.accessoryType = UITableViewCellAccessoryNone;  // なし
					cell.showsReorderControl = NO;
					cell.textLabel.text = NSLocalizedString(@"Delete SharePLAN",nil);
					break;
				default:
					break;
			}
			return cell;
		} break;

		case 2: { //-----------------------------------------------------------Section(2) 不快感を報告
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:zCellFunc];
			if (cell == nil) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
											  reuseIdentifier:zCellFunc];
			}
			cell.textLabel.font = [UIFont systemFontOfSize:16];
			cell.textLabel.textAlignment = UITextAlignmentCenter; // 中央寄せ
			cell.textLabel.textColor = [UIColor blackColor];
			cell.imageView.image = [UIImage imageNamed:@"Icon32-MailNew.png"];
			cell.accessoryType = UITableViewCellAccessoryNone;  // なし
			cell.showsReorderControl = NO;
			cell.textLabel.text = NSLocalizedString(@"Share　Reporting",nil);
			return cell;
		} break;
	}
	return nil;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];	// 選択状態を解除する

	if (indexPath.section==0) {
		if (indexPath.row==0 && Re1add) {
			// E2 へドリルダウン
			E2viewController *e2view = [[E2viewController alloc] init];
			e2view.title = self.title;	// "Sample"
			e2view.e1selected = Re1add;
			e2view.sharePlanList = YES; // SharePlan専用モード
			[self.navigationController pushViewController:e2view animated:YES];
			//[e2view release];
		}
	}
	else if (indexPath.section==1) {
		if (Re1add && indexPath.row==0) {	// Add
			// 採用につき「保存」する
			NSError *err = nil;
			if (![Re1add.managedObjectContext save:&err]) {
				// 保存失敗
				AzLOG(@"Unresolved error %@, %@", err, [err userInfo]);
				alertMsgBox( NSLocalizedString(@"Add Err",nil), nil, @"Roger" );
			} 
			else {
				Re1add = nil; // これが無いと、deallocで削除されてしまう。
				// CountUp
				//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];	// return前に [pool release] 必須！
				[self vSharePlanCountUp:RzSharePlanKey]; 
				//[pool release];
				// OK
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add OK",nil)
																message:nil
															   delegate:self 
													  cancelButtonTitle:nil 
													  otherButtonTitles:@"OK", nil];
				alert.tag = ALERT_TAG_PREVIEW; // 前Viewへ戻る
				[alert show];
				// E1 再フィッチ（データ追加あり）
				[[NSNotificationCenter defaultCenter] postNotificationName:NFM_REFRESH_ALL_VIEWS
																	object:self  userInfo:nil];
			}
		}
		else if (indexPath.row==1) { 
			// Alert確認後、Delete実行
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete SharePLAN",nil)
															message:nil
														   delegate:self 
												  cancelButtonTitle:NSLocalizedString(@"Cancel",nil) 
												  otherButtonTitles:@"OK", nil];
			alert.tag = ALERT_TAG_DELETE;
			[alert show];
			//[alert release];
		}
	}
	else if (indexPath.section==2) {
		// 不快感を報告
		//メール送信可能かどうかのチェック　　＜＜＜MessageUI.framework が必要＞＞＞
		if (![MFMailComposeViewController canSendMail]) {
			//[self setAlert:@"メールが起動出来ません！":@"メールの設定をしてからこの機能は使用下さい。"];
			azAlertBox( NSLocalizedString(@"Contact NoMail",nil), NSLocalizedString(@"Contact NoMail msg",nil), @"OK" );
			return;
		}
		// Send Mail
		[self sendmail:Re1add.name  key:[self RzSharePlanKey]];
	}
}	

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (alertView.tag) {
		case ALERT_TAG_PREVIEW:	// 前画面に戻す
			[self.navigationController popViewControllerAnimated:YES];	// 前のViewへ戻る
			break;
			
		case ALERT_TAG_BREAK: // 通信中断する
			if (RurlConnection) {
				[RurlConnection cancel];
				//[RurlConnection release], 
				RurlConnection = nil;
			}
			[self.navigationController popViewControllerAnimated:YES];	// 前のViewへ戻る
			break;

		case ALERT_TAG_DELETE:
			if (buttonIndex==1) { // OK
				// Delete
				@autoreleasepool {
					NSString *err = [self vSharePlanDelete:RzSharePlanKey];
					if (err) {
						alertMsgBox( NSLocalizedString(@"Delete Err",nil), err, @"Roger" );
					} else {
						alertMsgBox( NSLocalizedString(@"Delete OK",nil), nil, @"OK" );
					}
				}
				//
				if (Re1add) {
					[Re1add.managedObjectContext rollback];		// [FileCsv zLoad:]にて save していないので、rollback で配下全て取り消しできる。
					Re1add = nil; // これが無いと、deallocで rollbackされてしまう。
				}
				//[self.navigationController popViewControllerAnimated:YES];	// 前のViewへ戻る
				// ２つ前のViewへ戻る
				NSArray *vcs = [self.navigationController viewControllers];
				assert(3 <= [vcs count]);
				[self.navigationController popToViewController:[vcs objectAtIndex:[vcs count]-3] animated:YES];
			}
			break;
	}
}


- (NSString *)vSharePlanDelete:(NSString *)zKey
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES; // NetworkアクセスサインON

	// POST URL
	//NSString *postCmd = @"func=Delete";
	NSString *postCmd = @"func=Delete";

	// userPass
	postCmd = postCmdAddUserPass( postCmd );
	
	// key
	postCmd = [postCmd stringByAppendingFormat:@"&e1key=%@", zKey];
	
	
	if (RurlConnection) {
		[RurlConnection cancel];
		//[RurlConnection release], 
		RurlConnection = nil;
	}
	// 非同期通信
	RurlConnection = [[NSURLConnection alloc] initWithRequest:requestSpPOST(postCmd)
													 delegate:self];
	MiConnectTag = 4; // Delete
	return nil; //OK
}

- (NSString *)vSharePlanDownload:(NSString *)zKey
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES; // NetworkアクセスサインON

	// POST URL
	//NSString *postCmd = [NSString stringWithString:@"func=Download"];
	NSString *postCmd = @"func=Download";

	postCmd = [postCmd stringByAppendingFormat:@"&e1key=%@", zKey];
	
	if (RurlConnection) {
		[RurlConnection cancel];
		//[RurlConnection release],
		RurlConnection = nil;
	}
	// 非同期通信
	RurlConnection = [[NSURLConnection alloc] initWithRequest:requestSpPOST(postCmd)
													 delegate:self];
	MiConnectTag = 3; // Download
	return nil; //OK
}

- (NSString *)vSharePlanCountUp:(NSString *)zKey
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES; // NetworkアクセスサインON
	
	// POST URL
	//NSString *postCmd = [NSString stringWithString:@"func=CountUp"];
	NSString *postCmd = @"func=CountUp";
	
	// key
	postCmd = [postCmd stringByAppendingFormat:@"&e1key=%@", zKey];
	
	
	if (RurlConnection) {
		[RurlConnection cancel];
		//[RurlConnection release],
		RurlConnection = nil;
	}
	// 非同期通信
	RurlConnection = [[NSURLConnection alloc] initWithRequest:requestSpPOST(postCmd)
													 delegate:self];
	MiConnectTag = 5; // CountUp
	return nil; //OK
}

@end

