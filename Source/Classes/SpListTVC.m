//
//  SpListTVC.m
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
#import "SpListTVC.h"
#import "SpDetailTVC.h"

#import  <YAJLiOS/YAJL.h>
//#import <DropboxSDK/JSON.h>  SBJSONでは、読み取りエラー発生した。（多分、CSV部）


#define CELL_TAG_NAME		91
#define CELL_TAG_NOTE		92
#define CELL_TAG_INFO		93

#define ACTION_TAG_A_PLAN	901

#define ALERT_TAG_PREVIEW	802
#define ALERT_TAG_BREAK		811


#ifdef DEBUGxxx
#define PAGE_LIMIT			3
#else
#define PAGE_LIMIT			20
#endif

@interface SpListTVC (PrivateMethods)
- (NSString *)vSharePlanSearch:(NSInteger)iOffset;
@end

@implementation SpListTVC
{
@private
	NSMutableArray		*RaSharePlans;
	NSURLConnection		*RurlConnection;
	NSMutableData		*RdaResponse;
	AppDelegate		*appDelegate_;
	BOOL					MbSearchOver;
	BOOL					MbSearching;
	NSInteger			MiConnectTag;	// (0)Non (1)Search (2)Append (3)Download (4)Delete
}
//@synthesize RaTags = aTags_P_;
@synthesize RzLanguage = zLanguage_P_;  //=nil:ALL
@synthesize RzSort = zSort_P_;


#pragma mark - Action

- (NSString *)vSharePlanSearch:(NSInteger)iOffset
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES; // NetworkアクセスサインON
	
	// POST URL
	NSString *postCmd = @"func=Search";
	//NSString *postCmd = [NSString stringWithString:@"func=Search"];
	
	// userPass
	postCmd = postCmdAddUserPass( postCmd );
	
	// LANGUAGE
	//2.0//postCmd = postCmdAddLanguage( postCmd );
	if (2<=[zLanguage_P_ length] && [zLanguage_P_ length]<=10)
	{	// 先頭10文字に制限 ＜＜＜GAE V2より10文字まで可能
		postCmd = [postCmd stringByAppendingFormat:@"&language=%@", zLanguage_P_];
	}
	
	// SORT
	postCmd = [postCmd stringByAppendingFormat:@"&sort=%@", zSort_P_];
	
	/*	// TAG
	 for (NSString *zz in aTags_P_) {
	 postCmd = [postCmd stringByAppendingFormat:@"&tag=%@", zz];
	 }*/
	
	
	// PAGE制御
	postCmd = [postCmd stringByAppendingFormat:@"&shLimit=%d", PAGE_LIMIT];
	postCmd = [postCmd stringByAppendingFormat:@"&shOffset=%ld", (long)iOffset];
	
	NSLog(@"vSharePlanSearch: postCmd={%@}", postCmd);
	
	if (RurlConnection) {
		[RurlConnection cancel];
		//[RurlConnection release], 
		RurlConnection = nil;
	}
	// 非同期通信
	RurlConnection = [[NSURLConnection alloc] initWithRequest:requestSpPOST(postCmd)
													 delegate:self];
	MiConnectTag = 1; // Search
	return nil; //OK
}



#pragma mark - View lifestyle

- (id)initWithStyle:(UITableViewStyle)style 
{
	self = [super initWithStyle:UITableViewStylePlain];
	if (self) {
		// 初期化成功
		//RautoPool = [[NSAutoreleasePool alloc] init];	// [0.6]autorelease独自解放のため
		MbSearching = YES;
		RaSharePlans = [NSMutableArray new]; // unloadReleaseしないこと
		appDelegate_ = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	}
	return self;
}

// IBを使わずにviewオブジェクトをプログラム上でcreateするときに使う（viewDidLoadは、nibファイルでロードされたオブジェクトを初期化するために使う）
- (void)loadView
{
	[super loadView];

	self.title = NSLocalizedString(@"SharePlan",nil);
	
	self.tableView.allowsSelectionDuringEditing = YES;

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
	
	[self.tableView reloadData]; // 次Viewから戻ったときに再描画する　＜＜特に削除後が重要＞＞
}

// 表示後
- (void)viewDidAppear:(BOOL)animated 
{
    [super viewDidAppear:animated];
	
	MbSearching = NO;
	
	if ([RaSharePlans count]<=0) {	
		// 最初の25個取得
		@autoreleasepool {
			[self vSharePlanSearch:0];
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

// ユーザインタフェースの回転の最後の半分が始まる前にこの処理が呼ばれる　＜＜このタイミングで配置転換すると見栄え良い＞＞
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[self.tableView reloadData]; // cell回転(再描画)させるために必要
}


- (void)unloadRelease	// dealloc, viewDidUnload から呼び出される
{
	NSLog(@"--- unloadRelease --- SpListTVC");
	
	[RurlConnection cancel]; // 停止させてから解放する
	//[RurlConnection release],	
	RurlConnection = nil;
	
	//[RdaResponse release],		
	RdaResponse = nil;
}

- (void)viewDidUnload 
{	// メモリ不足時、裏側にある場合に呼び出されるので、viewDidLoadで生成したObjを解放する。
	//NSLog(@"--- viewDidUnload ---"); 
	// メモリ不足時、裏側にある場合に呼び出される。addSubviewされたOBJは、self.viewと同時に解放される
	[self unloadRelease];
	[super viewDidUnload];
	// この後に loadView ⇒ viewDidLoad ⇒ viewWillAppear がコールされる
}

- (void)dealloc 
{
	[self unloadRelease];
	RaSharePlans = nil;
}


#pragma mark - <UITableViewDelegate>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [RaSharePlans count] + 1;
}

// TableView セクション名を応答
//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 

// セルの高さを指示する
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if ([RaSharePlans count] <= indexPath.row) return 44;

	if (appDelegate_.app_is_iPad || UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) { //タテ
		return 70; // タテ
	} else {
		return 55; //ヨコ
	}
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    static NSString *zCellPlan = @"CellPlan";
    static NSString *zCellTerm = @"CellTerm";
    UILabel *lb;

	if ([RaSharePlans count] <= indexPath.row) {
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:zCellTerm];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
										   reuseIdentifier:zCellTerm];
			cell.textLabel.font = [UIFont systemFontOfSize:16];
		}
		if ([RaSharePlans count] <= 0) {
			if (MbSearching) {
				cell.textLabel.text = NSLocalizedString(@"Communicating",nil);
			} else {
				cell.textLabel.text = NSLocalizedString(@"No PLAN",nil);
			}
			cell.textLabel.textAlignment = UITextAlignmentCenter;
		} else if (MbSearchOver) {
			cell.textLabel.text = NSLocalizedString(@"Over",nil);
			cell.textLabel.textAlignment = UITextAlignmentCenter;
		} else {
			cell.textLabel.text = NSLocalizedString(@"More",nil);
			cell.textLabel.textAlignment = UITextAlignmentRight;
		} 
		return cell;
	}
	
	NSAssert(indexPath.row < [RaSharePlans count], nil);
	// Plans
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:zCellPlan];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
									   reuseIdentifier:zCellPlan];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; // >
		//
		lb = [[UILabel alloc] init];
		lb.font = [UIFont systemFontOfSize:16];
		lb.textAlignment = UITextAlignmentLeft;
		lb.textColor = [UIColor blackColor];
		//lb.backgroundColor = [UIColor lightGrayColor]; // DEBUG
		lb.tag = CELL_TAG_NAME;
		[cell.contentView addSubview:lb]; //[lb release];
		//
		lb = [[UILabel alloc] init];
		lb.font = [UIFont systemFontOfSize:12];
		lb.textAlignment = UITextAlignmentLeft;
		lb.numberOfLines = 2;
		lb.textColor = [UIColor blackColor];
		//lb.backgroundColor = [UIColor lightGrayColor]; // DEBUG
		lb.tag = CELL_TAG_NOTE;
		[cell.contentView addSubview:lb]; //[lb release];
		//
		lb = [[UILabel alloc] init];
		lb.font = [UIFont systemFontOfSize:12];
		lb.textAlignment = UITextAlignmentRight;
		lb.textColor = [UIColor blackColor];
		lb.backgroundColor = [UIColor lightGrayColor];
		lb.tag = CELL_TAG_INFO;
		[cell.contentView addSubview:lb]; //[lb release];
	}
	//
	NSDictionary *dic = [RaSharePlans objectAtIndex:indexPath.row];
	//NSString *zOwn = @"";  ＜＜セキュリティ！この段階では表示しない＞＞
	//if ([[dic objectForKey:@"own"] boolValue]) zOwn = NSLocalizedString(@"Owner",nil);
	
	// @"stamp"(W3C-DTF:UTC) --> NSDate 
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	// カレンダーの設定 ＜＜システム設定が「和暦」になると、2012-->平成2012年-->西暦4000年になるのを避けるため、西暦（グレゴリア）に固定
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	[df setCalendar:calendar];
	//[df setTimeStyle:NSDateFormatterFullStyle];
	[df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
	NSDate *utc = [df dateFromString:[dic objectForKey:@"stamp"]];
	NSLog(@"stamp=%@ --> utc=%@", [dic objectForKey:@"stamp"], utc);
	// utc --> string
	[df setLocale:[NSLocale currentLocale]];  // 現在のロケールをセット
	[df setDateFormat:@"YYYY-MM-dd hh:mm:ss"];
	NSString *zStamp = [df stringFromDate:utc];
	
	// Nickname
	NSString *zNickname = @"";
	if ([dic objectForKey:@"userName"] != [NSNull null]) {
		zNickname = [dic objectForKey:@"userName"];
	}
	//
	if (appDelegate_.app_is_iPad || UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) { //タテ
		// タテ
		lb = (UILabel *)[cell.contentView viewWithTag:CELL_TAG_NAME];
		lb.frame = CGRectMake(10,4, cell.frame.size.width-20,18);
		//AzLOG(@"dic---name=%@", [dic objectForKey:@"name"]);
		if ([dic objectForKey:@"name"] == [NSNull null]) {
			lb.text = NSLocalizedString(@"Undecided",nil);
		} else {
			lb.text = [dic objectForKey:@"name"];
		}
		
		lb = (UILabel *)[cell.contentView viewWithTag:CELL_TAG_NOTE];
		lb.frame = CGRectMake(10,23, cell.frame.size.width-40,70-14-1-23);
		if ([dic objectForKey:@"note"] == [NSNull null]) {
			lb.text = @"";
		} else {
			lb.text = [dic objectForKey:@"note"];
		}
		
		lb = (UILabel *)[cell.contentView viewWithTag:CELL_TAG_INFO];
		lb.frame = CGRectMake(0,70-14, self.view.frame.size.width,14);
#ifdef DEBUG
		lb.text = [NSString stringWithFormat:@"%@  %@ (%@) ", zNickname, zStamp, [dic objectForKey:@"downCount"]];
#else
		// DL数は非公開にする
		lb.text = [NSString stringWithFormat:@"%@   %@ %@  ", zNickname, NSLocalizedString(@"Release",nil), zStamp];
#endif
	}
	else {
		// ヨコ
		lb = (UILabel *)[cell.contentView viewWithTag:CELL_TAG_NAME];
		lb.frame = CGRectMake(10,2, cell.frame.size.width-20,18);
		if ([dic objectForKey:@"name"] == [NSNull null]) {
			lb.text = NSLocalizedString(@"Undecided",nil);
		} else {
			lb.text = [dic objectForKey:@"name"];
		}
		
		lb = (UILabel *)[cell.contentView viewWithTag:CELL_TAG_NOTE];
		lb.frame = CGRectMake(10,21, cell.frame.size.width-40,55-14-1-21);
		if ([dic objectForKey:@"note"] == [NSNull null]) {
			lb.text = @"";
		} else {
			lb.text = [dic objectForKey:@"note"];
		}
		
		lb = (UILabel *)[cell.contentView viewWithTag:CELL_TAG_INFO];
		//lb.frame = CGRectMake(0,55-14, cell.frame.size.width,14);
		lb.frame = CGRectMake(0,55-14, self.view.frame.size.width,14);
	/*	lb.text = [NSString stringWithFormat:@"%@    %@ %@   %@ %@  ", zOwn,
				   NSLocalizedString(@"Release",nil), [dic objectForKey:@"stamp"], 
				   NSLocalizedString(@"Popular",nil), [dic objectForKey:@"downCount"]];　*/
		lb.text = [NSString stringWithFormat:@"%@   %@ %@  ", zNickname, NSLocalizedString(@"Release",nil), zStamp];
	}
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];	// 選択状態を解除する

	if (indexPath.row < [RaSharePlans count]) {
		NSDictionary *dic = [RaSharePlans objectAtIndex:indexPath.row];
		NSLog(@"##### own=%@", [[dic objectForKey:@"own"] boolValue]?@"YES":@"NO");
		// SpDetailTVC
		SpDetailTVC *vc = [[SpDetailTVC alloc] init];
		vc.RzSharePlanKey = [dic objectForKey:@"e1key"];
		vc.PbOwner = [[dic objectForKey:@"own"] boolValue];
		[self.navigationController pushViewController:vc animated:YES];
		//[vc release];
	}
	else if (!MbSearchOver) {
		// Next Search
		@autoreleasepool {
			NSString *err = [self vSharePlanSearch:[RaSharePlans count]];
			if (err) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Search Err",nil)
																message:err
															   delegate:nil 
													  cancelButtonTitle:nil 
													  otherButtonTitles:NSLocalizedString(@"Roger",nil), nil];
				[alert show];
				//[alert release];
			}
		}
	}
}	

#pragma mark - <UIAlertViewDelegate>
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
	}
}


#pragma mark - NSURLConnection delegate

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
		
		switch (MiConnectTag) {
			case 1: { // Search
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
				/***
				 // JSON --> NSArray   ＜＜＜ Dropbox標準のSBJSONを使用
				 NSError *err = nil;
				 SBJSON	*js = [SBJSON new];
				 NSArray *jsonArray = [js objectWithString:jsonStr error:&err];
				 js = nil;
				 if (err) {
				 NSLog(@"tmpFileLoad: SBJSON: objectWithString: (err=%@) zJson=%@", [err description], jsonStr);
				 alertMsgBox( NSLocalizedString(@"Connection Error",nil), 
				 [err description],
				 NSLocalizedString(@"Roger",nil) );
				 [self.navigationController popViewControllerAnimated:YES];	// 前のViewへ戻る
				 break;
				 }***/
#ifdef DEBUG
				for (NSDictionary *dic in jsonArray) {
					NSLog(@"e1key=%@", [dic objectForKey:@"e1key"]);
					NSLog(@"name=%@", [dic objectForKey:@"name"]);
					NSLog(@"stamp=%@", [dic objectForKey:@"stamp"]);
					NSLog(@"downCount=%@", [dic objectForKey:@"downCount"]);
				}	
#endif
				[RaSharePlans addObjectsFromArray:jsonArray];
				MbSearchOver = ([jsonArray count] < PAGE_LIMIT);
				[self.tableView reloadData];
			}	break;
				
			default:
				break;
		}
		//[jsonStr release];
	}
	else {
		// 該当なし
		[self.tableView reloadData];
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


@end

