//
//  WebSiteVC.m
//  AzPacking
//
//  Created by 松山 和正 on 10/02/06.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Global.h"
#import "WebSiteVC.h"


@interface WebSiteVC (PrivateMethods)
- (void)close:(id)sender;
- (void)updateToolBar;
- (void)toolReload;
- (void)toolBack;
- (void)toolForward;
@end

@implementation WebSiteVC
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

- (void)close:(id)sender 
{
#ifdef AzPAD
	//[self.navigationController dismissModalViewControllerAnimated:YES];
	[self dismissModalViewControllerAnimated:YES];
#else
	[self.navigationController popViewControllerAnimated:YES];	// < 前のViewへ戻る
#endif
}

- (void)updateToolBar {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = MwebView.loading;
	MbuBack.enabled = MwebView.canGoBack;
	MbuForward.enabled = MwebView.canGoForward;
}



#pragma mark - View lifecicle

- (void)loadView {
    [super loadView];
    
	//NSLog(@"frameWeb=(%f,%f)-(%f,%f)", frameWeb.origin.x,frameWeb.origin.y, frameWeb.size.width,frameWeb.size.height);
	//MwebView = [[UIWebView alloc] initWithFrame:frameWeb];
	MwebView = [[UIWebView alloc] init];
	MwebView.scalesPageToFit = YES;
	MwebView.delegate = self;
	MwebView.frame = self.view.bounds;
	//MwebView.frame = frameWeb;
	MwebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	//MwebView.autoresizingMask = UIViewAutoresizingNone;
	//MwebView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	MwebView.clipsToBounds = YES;
	[self.view addSubview:MwebView];  //dealloc//[MwebView release]
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

	// 上部のバーを無くして、全て下部ツールバーだけにした。
	self.navigationController.navigationBarHidden = YES;
	
	UIBarButtonItem *buFlex = [[[UIBarButtonItem alloc] 
								initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
								target:nil action:nil] autorelease];
	
	UIBarButtonItem *buClose = [[[UIBarButtonItem alloc] 
							   initWithBarButtonSystemItem:UIBarButtonSystemItemStop
							   target:self action:@selector(close:)] autorelease];

	MbuBack = [[[UIBarButtonItem alloc] 
				initWithImage:[UIImage imageNamed:@"Icon16-WebBack"]
				style:UIBarButtonItemStylePlain
				target:self action:@selector(toolBack)] autorelease];
	MbuForward = [[[UIBarButtonItem alloc] 
				   initWithImage:[UIImage imageNamed:@"Icon16-WebForward"]
				   style:UIBarButtonItemStylePlain
				   target:self action:@selector(toolForward)] autorelease];
	MbuReload = [[[UIBarButtonItem alloc] 
				  initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
				  target:self action:@selector(toolReload)] autorelease];
	
	MactivityIndicator = [[[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 32.0f, 32.0f)] autorelease];
	[MactivityIndicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
	[MactivityIndicator startAnimating]; // 通信不能のとき、インジケータだけ動かすため
	UIBarButtonItem *buActInd = [[[UIBarButtonItem alloc] initWithCustomView:MactivityIndicator] autorelease];

	NSArray *aArray = [NSArray arrayWithObjects:  MbuReload, buFlex, MbuBack, buActInd, MbuForward, buFlex, buClose, nil];
	self.navigationController.toolbarHidden = NO;
	self.navigationController.toolbar.barStyle = UIBarStyleBlackOpaque;
	[self setToolbarItems:aArray animated:YES];
	
	// URL表示用のラベル生成
	MlbMessage = [[UILabel alloc] init];
	MlbMessage.textColor = [UIColor whiteColor];
	MlbMessage.backgroundColor = [UIColor blueColor];
	MlbMessage.font = [UIFont systemFontOfSize:12];
	MlbMessage.hidden = YES;
	[self.view addSubview:MlbMessage], [MlbMessage release];
	// .frame セットは、viewWillAppear:にてdidRotateFromInterfaceOrientation:を呼び出している
}

- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
	// 画面表示に関係する Option Setting を取得する
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	MbOptShouldAutorotate = [defaults boolForKey:GD_OptShouldAutorotate];
	
	MwebView.frame = self.view.bounds;
	MwebView.contentMode = UIViewContentModeCenter;

	[self messageShow:self.Rurl holdSec:5.0f];

	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.Rurl]];
	[MwebView loadRequest:request];
	[self updateToolBar];

	[self didRotateFromInterfaceOrientation:self.interfaceOrientation]; // 回転に合わせて.frame調整している
}

/*
- (void)viewDidAppear:(BOOL)animated 
{
    [super viewDidAppear:animated];
	
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.Rurl]];
	[MwebView loadRequest:request];
	[self updateToolBar];
}
*/

// 回転サポート
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	//return MbOptShouldAutorotate OR (interfaceOrientation == UIInterfaceOrientationPortrait);
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
	rc.origin.y = self.view.frame.size.height - rc.size.height;
	MlbMessage.frame = rc;
	MlbMessage.hidden = NO;
}


// ビューが非表示にされる前や解放される前に呼ばれる
- (void)viewWillDisappear:(BOOL)animated 
{
	// 画面表示から消す
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO; // NetworkアクセスサインOFF
	// 上部のバーを復帰（表示）させる
	self.navigationController.navigationBarHidden = NO;	// 見えている間に処理する必要あり＜＜viewDidDisappear:だと効かない
	// 下部のバーを消す処理は不要　（POPで戻るときに消される）
	// ただし、呼び出し側で .hidesBottomBarWhenPushed = YES としていると逆に残ってしまうようだ。
	[super viewWillDisappear:animated];
}

/* // ビューが非表示になった後に呼ばれる
- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}*/

- (void)viewDidUnload 
{
	// メモリ不足時、裏側にある場合に呼び出されるので、viewDidLoadで生成したObjを解放する。
}

- (void)dealloc 
{
	if (MwebView) {
		[MwebView stopLoading];
		MwebView.delegate = nil; // これしないと落ちます
		[MwebView release], MwebView = nil;
	}
	
	[urlOutside release], urlOutside = nil;
	// @property (retain)
	[Rurl release], Rurl = nil;
	[RzDomain release], RzDomain = nil;
    [super dealloc];
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
	//[MactivityIndicator stopAnimating]; 動かし続ける
	[self messageShow:NSLocalizedString(@"Connection Error", nil) holdSec:0.0f];
	MlbMessage.backgroundColor = [UIColor redColor]; //ERROR message
}

// URL制限する：無制限ならばレーティング"17+"になってしまう！
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request 
 navigationType:(UIWebViewNavigationType)navigationType
{
	if (navigationType == UIWebViewNavigationTypeLinkClicked) // リンクをクリックしたとき、だけチェックする 
	{
		[self messageShow:[[request URL] absoluteString] holdSec:5.0f];
		
		NSString *zHost = [[request URL] host];
		// 主ドメイン
		if ([zHost hasSuffix:RzDomain]) { //末尾比較  　item.rakuten.co.jp == rakuten.co.jp  を通すため。
			return YES; // 許可
		}
		// 主ドメインからのリンク先で許可するドメイン
		if ([zHost hasSuffix:@".rakuten.ne.jp"]) return YES; // 許可ドメイン
		if ([zHost hasSuffix:@".javari.jp"]) return YES; // 許可ドメイン

		NSLog(@"zHost[%@] != RzDomain[%@]", zHost, RzDomain);

		urlOutside = [[request URL] copy]; // copyしないと消えてしまうので要注意
		NSLog(@"urlOutside=%@", urlOutside);

		// 範囲外へのアクセス禁止
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"WebSite CAUTION", nil)
														message:[urlOutside absoluteString]
													   delegate:self
											  cancelButtonTitle:NSLocalizedString(@"WebSite Cancel", nil)
											  otherButtonTitles:NSLocalizedString(@"WebSite GoOut", nil), nil];
		[alert show];
		[alert release];
		MlbMessage.backgroundColor = [UIColor redColor]; //許可していないドメイン
		return NO;
	}
	return YES;
}


@end
