//
//  GDocDownloadTVC.m
//  AzPackList5
//
//  Created by Sum Positive on 12/02/18.
//  Copyright (c) 2012 Azukid. All rights reserved.
//

#import "Global.h"
#import "AppDelegate.h"
#import "SFHFKeychainUtils.h"
#import "Elements.h"
#import "EntityRelation.h"
#import "FileCsv.h"

#import "GoogleService.h"
#import "GDocDownloadTVC.h"
//#import "GDocRevisionTVC.h"  同名アップしてもリビジョンにはならない


#define TAG_ACTION_DOWNLOAD_START	900

@implementation GDocDownloadTVC
{
	AppDelegate						*mAppDelegate;
	GDataServiceGoogleDocs	*mDocService;
	GDataFeedBase					*mDocFeed;
	GDataEntryDocBase			*mDocSelect;
}


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
		mAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		mDocService = [GoogleService docService];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.title = NSLocalizedString(@"Import Google", nil);

	if (mAppDelegate.app_is_iPad) {
		// CANCELボタンを左側に追加する  Navi標準の戻るボタンでは cancel:処理ができないため
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
												 initWithTitle:NSLocalizedString(@"Back", nil)
												 style:UIBarButtonItemStyleBordered
												 target:self action:@selector(actionBack:)];
	}
}

- (void)actionBack:(id)sender
{
	//[self.navigationController popViewControllerAnimated:YES];	// < 前のViewへ戻る
	[self dismissModalViewControllerAnimated:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	
	if (mDocService) {
		[GoogleService alertIndicatorOn:NSLocalizedString(@"Communicating", nil)];
		
		// ドキュメントリストを抽出する
		mDocFeed = nil;
		NSURL *docsUrl = [GDataServiceGoogleDocs docsFeedURL];
		// PackListファイル一覧を取得する　＜＜フォルダに関係無く全体から抽出する
		GDataQueryDocs *query = [GDataQueryDocs documentQueryWithFeedURL:docsUrl];
		[query setMaxResults:100];				// 一度に取得する件数
		[query setShouldShowFolders:NO];	// フォルダを表示するか
		[query setFullTextQueryString:@".packlist|.azpack|.azp"];	 // この文字列が含まれるものを抽出する//[2.0]GD_EXTENSION にも対応
		[mDocService fetchFeedWithQuery:query
					  completionHandler:^(GDataServiceTicket *ticket, GDataFeedBase *feed, NSError *error) {
						  if (error) {
							  // 失敗
							  [GoogleService docDownloadErrorNo:100 description:error.localizedDescription];
							  return;
						  } else {
							  // 成功
							  mDocFeed = feed;
						  }
						  [self.tableView reloadData];
						  [GoogleService alertIndicatorOff];
					  }];
	}
	else {
		alertBox(NSLocalizedString(@"Google Login NG", nil), nil, @"OK");
		//[GoogleService docDownloadErrorNo:110 description:NSLocalizedString(@"Google Login NG", nil)];
	}
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
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
{	// Return YES for supported orientations
	if (mAppDelegate.app_is_iPad) {
		return YES;	// FormSheet窓対応
	}
	else if (mAppDelegate.app_opt_Autorotate==NO) {	// 回転禁止にしている場合
		return (interfaceOrientation == UIInterfaceOrientationPortrait); // 正面（ホームボタンが画面の下側にある状態）のみ許可
	}
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{   // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{   // Return the number of rows in the section.
    return [[mDocFeed entries] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (section==0) {
		return NSLocalizedString(@"Google Download List",nil);
	}
	return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{	// セル生成
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
		//cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; // > revision
		//cell.textLabel.textAlignment = UITextAlignmentLeft;
		//cell.detailTextLabel.font = [UIFont systemFontOfSize:10];
		cell.detailTextLabel.textAlignment = UITextAlignmentRight;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
{	// セル描画
	GDataEntryDocBase *doc = [mDocFeed entryAtIndex:indexPath.row];
	cell.textLabel.text = [[[doc title] stringValue] stringByDeletingPathExtension]; // 拡張子を除く
	
	NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
	// システム設定で「和暦」にされたとき年表示がおかしくなるため、西暦（グレゴリア）に固定
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	[fmt setCalendar:calendar];
	if ([[[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode] isEqualToString:@"ja"]) 
	{ // 「書式」で変わる。　「言語」でない
		[fmt setDateFormat:@"yyyy年M月d日 EE  HH:mm"];
	} else {
		[fmt setDateFormat:@"EE, MMM d, yyyy  HH:mm"];
	}
	cell.detailTextLabel.text = [NSString stringWithFormat:@"Uploaded: %@", 
								 [fmt stringFromDate:[[doc updatedDate] date]]];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{   // Navigation logic may go here. Create and push another view controller.
	[tableView deselectRowAtIndexPath:indexPath animated:YES];	// 選択状態を解除する

	mDocSelect = [mDocFeed entryAtIndex:indexPath.row];
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:[[mDocSelect title] stringValue]
							delegate:self 
							cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
							destructiveButtonTitle:nil
							otherButtonTitles:NSLocalizedString(@"Download START",nil), 
							nil];
	sheet.tag = TAG_ACTION_DOWNLOAD_START;
	[sheet showInView:self.view];
	
	/*　リビジョンは、GDoc内で修正した場合だけ記録されるため
	GDocRevisionTVC *rev = [[GDocRevisionTVC alloc] init];
	mDocSelect = [mDocFeed entryAtIndex:indexPath.row];
	rev.docSelect = mDocSelect;
	[self.navigationController pushViewController:rev animated:YES];
	*/
}


#pragma mark - <UIActionSheet>

// UIActionSheetDelegate 処理部
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (actionSheet.tag) 
	{
		case TAG_ACTION_DOWNLOAD_START:
			if (buttonIndex == 0 && mDocSelect) {  // START  actionSheetの上から順に(0〜)
				// Download開始
				[GoogleService docDownloadEntry:mDocSelect];
			}
			break;
	}
}

@end
