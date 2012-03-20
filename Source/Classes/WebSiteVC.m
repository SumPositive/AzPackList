//
//  WebSiteVC.m
//  AzPacking
//
//  Created by 松山 和正 on 10/02/06.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Global.h"
#import "AppDelegate.h"
#import "WebSiteVC.h"


@interface WebSiteVC (PrivateMethods)
- (void)close:(id)sender;
- (void)updateToolBar;
- (void)toolReload;
- (void)toolBack;
- (void)toolForward;
@end

@implementation WebSiteVC
{
	NSString		*Rurl;
	NSString		*RzDomain;
	id					mBookmarkDelegate;

	NSURL			*urlOutside;		//ポインタ代入につきcopyしている
	
	UIWebView *MwebView;
	UIBarButtonItem *mBuCopyUrl;
	UIBarButtonItem *MbuBack;
	UIBarButtonItem *MbuReload;
	UIBarButtonItem *MbuForward;
	UIActivityIndicatorView *MactivityIndicator;
	UILabel				*MlbMessage;

	AppDelegate		*appDelegate_;
	BOOL MbOptShouldAutorotate;
	UIAlertView			*mAlertMsg;
}
@synthesize Rurl, RzDomain;


#pragma mark - Action

- (void)messageHide
{	// performSelectorから呼び出されて、URLメッセージを消す
	// アニメ準備
	CGContextRef context = UIGraphicsGetCurrentContext();
	[UIView beginAnimations:nil context:context];
	[UIView setAnimationDuration:1.5];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];
	
	// アニメ終了状態
	//MlbMessage.hidden = YES;	アニメ効果なし
	MlbMessage.alpha = 0;
	
	// アニメ実行
	[UIView commitAnimations];
}

- (void)messageShow:(NSString*)zMsg holdSec:(float)fSec
{
	MlbMessage.text = zMsg; //[[request URL] absoluteString];
	MlbMessage.hidden = NO; // 表示
	MlbMessage.alpha = 1;
	MlbMessage.backgroundColor = [UIColor blueColor];

	// ここで、afterDelay:の間に再入したとき、直前のタイマを破棄したいが、やりかた不明のため保留中
	
	if (0 < fSec) {
		// fSec(秒)後に非表示にする
		[self performSelector:@selector(messageHide) withObject:nil afterDelay:fSec]; 
	}
}

- (void)toolReload {
	[MwebView reload];
}

- (void)toolBack {
	if (MwebView.canGoBack) [MwebView goBack];
}

- (void)toolForward {
	if (MwebView.canGoForward) [MwebView goForward];
}

- (void)close:(id)sender 
{
	if (appDelegate_.app_is_iPad) {
		[self dismissModalViewControllerAnimated:YES];
	} else {
		[self.navigationController popViewControllerAnimated:YES];	// < 前のViewへ戻る
	}
}

- (void)closeBookmarkUrl:(id)sender 
{	// 現在のURLを送信する
	NSString* url = [MwebView stringByEvaluatingJavaScriptFromString:@"document.URL"];
	if (10<[url length]) {
		/*** Web画面イメージを記録する  ＜＜将来案
		UIGraphicsBeginImageContext(self.view.bounds.size);
		[MwebView.layer  renderInContext:UIGraphicsGetCurrentContext()];  
		UIImage *img = UIGraphicsGetImageFromCurrentImageContext();  
		UIGraphicsEndImageContext();  
		 */

		if ([mBookmarkDelegate respondsToSelector:@selector(webSiteBookmarkUrl:)]) {
			[mBookmarkDelegate webSiteBookmarkUrl:url];
		}
		[self close:sender];
	}
}

- (void)updateToolBar {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = MwebView.loading;
	MbuBack.enabled = MwebView.canGoBack;
	MbuForward.enabled = MwebView.canGoForward;
}

- (NSString *)stringAddTagUrl:(NSString*)strUrl
{	// Shop Url に アフェリエイト TAG/ID が無ければ付加する
	NSString *zTag = nil;
	
	NSRange rg = [strUrl rangeOfString:@".amazon.co.jp/"];
	if (0 < rg.length) {
		if (appDelegate_.app_is_iPad) {	// PCサイト
			zTag = @"&tag=art063-22";
		} else {	// モバイルサイト　　　　　"ie=UTF8" が無いと日本語キーワードが化ける
			zTag = @"&at=art063-22";
		}
	} 
	else {
		rg = [strUrl rangeOfString:@".amazon.com/"];
		if (0 < rg.length) {
			zTag = @"&tag=azuk-20";
		} 
		else {
			rg = [strUrl rangeOfString:@".amazon.cn/"];
			if (0 < rg.length) {
				zTag = @"&tag=azukid-23";
			} 
			else {
				rg = [strUrl rangeOfString:@".rakuten.co.jp/"];
				if (0 < rg.length) {
					zTag = @"&afid=0e4c9297.0f29bc13.0e4c9298.6adf8529";
				}
			}
		}
	}
	
	if (zTag) {
		rg = [strUrl rangeOfString:zTag];
		if (rg.length==0) {
			// Tagなし 末尾へ追加する
			return [strUrl stringByAppendingString:zTag];
		} else {
			// Tagあり
			return strUrl;
		}
	}
	return strUrl;
}


#pragma mark - View lifecicle

- (id)initWithBookmarkDelegate:(id)delegate
{
	self = [super init];
	if (self) {
		// 初期化処理：インスタンス生成時に1回だけ通る
		mBookmarkDelegate = delegate;
		// loadView:では遅い。shouldAutorotateToInterfaceOrientation:が先に呼ばれるため
		appDelegate_ = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		// 背景テクスチャ・タイルペイント
		//self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Tx-Back"]];
	}
	return self;
}

/*
- (void)loadView {
    [super loadView];
}*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = nil;
	
	MwebView = [[UIWebView alloc] init];
	MwebView.scalesPageToFit = YES;
	MwebView.delegate = self;
	MwebView.frame = self.view.bounds;	// = frameWeb;
	MwebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	//MwebView.autoresizingMask = UIViewAutoresizingNone;
	//MwebView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	MwebView.clipsToBounds = YES;
	MwebView.contentMode = UIViewContentModeCenter;
	[self.view addSubview:MwebView];
	
	/*	UIBarButtonItem *buFixed = [[UIBarButtonItem alloc] 
								initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
								target:nil action:nil];*/

	// 左側ボタン
	MbuBack = [[UIBarButtonItem alloc] 
			   initWithImage:[UIImage imageNamed:@"Icon16-WebBack"]
			   style:UIBarButtonItemStylePlain
			   target:self action:@selector(toolBack)];
	MbuForward = [[UIBarButtonItem alloc] 
				  initWithImage:[UIImage imageNamed:@"Icon16-WebForward"]
				  style:UIBarButtonItemStylePlain
				  target:self action:@selector(toolForward)];
	MbuReload = [[UIBarButtonItem alloc] 
				 initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
				 target:self action:@selector(toolReload)];
	
	MactivityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 32.0f, 32.0f)];
	[MactivityIndicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
	[MactivityIndicator startAnimating]; // 通信不能のとき、インジケータだけ動かすため
	UIBarButtonItem *buActInd = [[UIBarButtonItem alloc] initWithCustomView:MactivityIndicator];

	if (mBookmarkDelegate) {
		mBuCopyUrl = [[UIBarButtonItem alloc] 
					  initWithTitle:NSLocalizedString(@"Bookmark", nil)
					  style:UIBarButtonItemStyleBordered
					  target:self action:@selector(closeBookmarkUrl:)];
	} else {
		mBuCopyUrl = nil;
	}
	// 左は正順に並べる
	self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:  
											   MbuBack, MbuReload, MbuForward, buActInd, mBuCopyUrl, nil];
	
	// 右側ボタン
	/*UIBarButtonItem *buClose = [[UIBarButtonItem alloc] 
								initWithTitle:NSLocalizedString(@"Back", nil)
								style:UIBarButtonItemStyleBordered
								target:self action:@selector(close:)];*/
	UIBarButtonItem *buClose = [[UIBarButtonItem alloc] 
								initWithBarButtonSystemItem:UIBarButtonSystemItemStop
								target:self action:@selector(close:)];
	// 右は逆順に並べる
	self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects: buClose, nil];
	
	// URL表示用のラベル生成
	MlbMessage = [[UILabel alloc] init];
	MlbMessage.textColor = [UIColor whiteColor];
	MlbMessage.backgroundColor = [UIColor blueColor];
	MlbMessage.font = [UIFont systemFontOfSize:12];
	MlbMessage.hidden = YES;
	[self.view addSubview:MlbMessage]; //, [MlbMessage release];
	// .frame セットは、viewWillAppear:にてdidRotateFromInterfaceOrientation:を呼び出している
}

- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
	// 画面表示に関係する Option Setting を取得する
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	MbOptShouldAutorotate = [defaults boolForKey:UD_OptShouldAutorotate];
	
	MwebView.frame = self.view.bounds;

	[self messageShow:self.Rurl holdSec:5.0f];
}

- (void)viewDidAppear:(BOOL)animated 
{
    [super viewDidAppear:animated];
	
	NSString *strUrl = [self stringAddTagUrl:self.Rurl];
	NSLog(@"WebSiteVC: stringAddTagUrl: {%@}", strUrl);
	if (10 < [strUrl length]) {
		NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:strUrl]];
		[MwebView loadRequest:request];
		[self updateToolBar];
		[self didRotateFromInterfaceOrientation:self.interfaceOrientation]; // 回転に合わせて.frame調整している
	} else {
		[self close:nil];
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

// ユーザインタフェースの回転を始める前にこの処理が呼ばれる。 ＜＜OS 3.0以降の推奨メソッド＞＞
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
	MlbMessage.hidden = YES;
}

// ユーザインタフェースが回転した後に呼ばれる
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	// URL表示用のラベル生成
	CGRect rc = self.view.frame;  // この時点では、ToolBar領域が除外されている
	rc.size.height = 14;
	rc.origin.y = 0;  //self.view.frame.size.height - rc.size.height;
	MlbMessage.frame = rc;
	MlbMessage.hidden = NO;
}


// ビューが非表示にされる前や解放される前に呼ばれる
- (void)viewWillDisappear:(BOOL)animated 
{
	if (MwebView) {	// viewDidUnload:では遅い?かPopoverでは通らないようだ。 iPadでは、ここで処理しなければ落ちる。
		[MwebView stopLoading];
		MwebView.delegate = nil; // これしないと落ちます
		MwebView = nil;
	}
	
	// 画面表示から消す
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO; // NetworkアクセスサインOFF
	// 上部のバーを復帰（表示）させる
	self.navigationController.navigationBarHidden = NO;	// 見えている間に処理する必要あり＜＜viewDidDisappear:だと効かない
	// 下部のバーを消す処理は不要　（POPで戻るときに消される）
	// ただし、呼び出し側で .hidesBottomBarWhenPushed = YES としていると逆に残ってしまうようだ。
	
	[super viewWillDisappear:animated];
}

/*
// ビューが非表示になった後に呼ばれる
- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}
*/

- (void)viewDidUnload 
{	// メモリ不足時、裏側にある場合に呼び出されるので、viewDidLoadで生成したObjを解放する。
	if (MwebView) {
		[MwebView stopLoading];
		MwebView.delegate = nil; // これしないと落ちます
		MwebView = nil;
	}
	[super viewDidUnload];
}


- (void)dealloc 
{
	if (MwebView) {
		[MwebView stopLoading];
		MwebView.delegate = nil; // これしないと落ちます
		MwebView = nil;
	}
	
	urlOutside = nil;
	Rurl = nil;
	RzDomain = nil;
}



#pragma mark - <UIWebViewDelegate>

- (void)webViewDidStartLoad:(UIWebView *)webView 
{	// ウェブビューがコンテンツの読み込みを始めた後
	[self updateToolBar];
	[MactivityIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView 
{	// ウェブビューがコンテンツの読み込みを完了した後
	[self updateToolBar];
	[MactivityIndicator stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error 
{	// ウェブビューがコンテンツの読み込みに失敗した場合
	[self updateToolBar];
	[MactivityIndicator stopAnimating];
	//[MactivityIndicator stopAnimating]; 動かし続ける
	//[self messageShow:NSLocalizedString(@"Connection Error", nil) holdSec:0.6f];
	//MlbMessage.backgroundColor = [UIColor redColor]; //ERROR message
}

// URL制限する：無制限ならばレーティング"17+"になってしまう！
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request 
 navigationType:(UIWebViewNavigationType)navigationType
{
	if (navigationType == UIWebViewNavigationTypeLinkClicked) // リンクをクリックしたとき、だけチェックする 
	{
		[self messageShow:[[request URL] absoluteString] holdSec:5.0f];
		NSLog(@"Web: URL[%@]", [[request URL] absoluteString]);
		
		NSString *zHost = [[request URL] host];
		// 主ドメイン
		if (RzDomain && [zHost hasSuffix:RzDomain]) { //末尾比較  　item.rakuten.co.jp == rakuten.co.jp  を通すため。
			return YES; // 許可
		}
		// 主ドメインからのリンク先で許可するドメイン
		// Amazon
		if ([zHost hasSuffix:@".amazon.co.jp"]) return YES; // 許可ドメイン
		if ([zHost hasSuffix:@".amazon.com"]) return YES; // 許可ドメイン
		if ([zHost hasSuffix:@".amazon.cn"]) return YES; // 許可ドメイン
		if ([zHost hasSuffix:@".javari.jp"]) return YES; // 許可ドメイン
		if ([zHost hasSuffix:@".doubleclick.net"]) return YES; // 許可ドメイン Google
		// 楽天
		if ([zHost hasSuffix:@".rakuten.ne.jp"]) return YES; // 許可ドメイン
		if ([zHost hasSuffix:@".rakuten.co.jp"]) return YES; // 許可ドメイン
		// Azukid support
		if ([zHost hasSuffix:@".tumblr.com"]) return YES; // 許可ドメイン
		if ([zHost hasSuffix:@".seesaa.net"]) return YES; // 許可ドメイン
		if ([zHost hasSuffix:@".apple.com"]) return YES; // 許可ドメイン

		NSLog(@"zHost[%@] != RzDomain[%@]", zHost, RzDomain);

		urlOutside = [[request URL] copy]; // copyしないと消えてしまうので要注意
		NSLog(@"urlOutside=%@", urlOutside);

		// 範囲外へのアクセス禁止
		//ARC//UIAlertView *alert =  ローカル変数では、デリゲート呼び出しされる前に解放されて落ちるようだ。
		mAlertMsg = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"WebSite CAUTION", nil)
														message:[urlOutside absoluteString]
													   delegate:self
											  cancelButtonTitle:NSLocalizedString(@"WebSite Cancel", nil)
											  otherButtonTitles:NSLocalizedString(@"WebSite GoOut", nil), nil];
		[mAlertMsg show];
		MlbMessage.backgroundColor = [UIColor redColor]; //許可していないドメイン
		return NO;
	}
	return YES;
}

//urlOutsideをcopy属性で保存している
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
// アラートビューでボタンがクリックされた時に呼び出されるデリゲート
{
    NSLog(@"button=%d",buttonIndex);
    if (buttonIndex!=alertView.cancelButtonIndex) { // 「はい」のとき
        NSLog(@"urlOutside=%@",urlOutside);
        // リンクへ飛ぶ
        [[UIApplication sharedApplication] openURL:urlOutside]; // httpがあるので自動的にブラウザが立ち上がる
    }
}


@end
