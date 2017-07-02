//
//  AZWebView.m
//  
//
//  Created by 松山 和正 on 10/02/06.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
#undef  NSLocalizedString		//⇒ AZLocalizedString  AZClass専用にすること

#import "AZWebView.h"


@interface AZWebView (PrivateMethods)
- (void)close:(id)sender;
- (void)updateToolBar;
- (void)toolReload;
- (void)toolBack;
- (void)toolForward;
@end

@implementation AZWebView
@synthesize ppUrl = __Url;
@synthesize ppDomain = __Domain;
@synthesize ppBookmarkDelegate = __BookmarkDelegate;


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
	mLbMessage.alpha = 0;
	
	// アニメ実行
	[UIView commitAnimations];
}

- (void)messageShow:(NSString*)zMsg holdSec:(float)fSec
{
	mLbMessage.text = zMsg; //[[request URL] absoluteString];
	mLbMessage.hidden = NO; // 表示
	mLbMessage.alpha = 1;
	mLbMessage.backgroundColor = [UIColor blueColor];

	// ここで、afterDelay:の間に再入したとき、直前のタイマを破棄したいが、やりかた不明のため保留中
	
	if (0 < fSec) {
		// fSec(秒)後に非表示にする
		[self performSelector:@selector(messageHide) withObject:nil afterDelay:fSec]; 
	}
}

- (void)toolReload {
	[mWebView reload];
}

- (void)toolBack {
	if (mWebView.canGoBack) [mWebView goBack];
}

- (void)toolForward {
	if (mWebView.canGoForward) [mWebView goForward];
}

- (void)close:(id)sender 
{
	if (mIsPad) {
		[self dismissViewControllerAnimated:YES completion:nil];
	} else {
		[self.navigationController popViewControllerAnimated:YES];	// < 前のViewへ戻る
	}
}

- (void)closeBookmarkUrl:(id)sender 
{	// 現在のURLを送信する
	NSString* url = [mWebView stringByEvaluatingJavaScriptFromString:@"document.URL"];
	if (10<[url length]) {
		/*** Web画面イメージを記録する  ＜＜将来案
		UIGraphicsBeginImageContext(self.view.bounds.size);
		[MwebView.layer  renderInContext:UIGraphicsGetCurrentContext()];  
		UIImage *img = UIGraphicsGetImageFromCurrentImageContext();  
		UIGraphicsEndImageContext();  
		 */

		if ([__BookmarkDelegate respondsToSelector:@selector(azWebViewBookmark:)]) {
			[__BookmarkDelegate azWebViewBookmark:url];
		}
		[self close:sender];
	}
}

- (void)updateToolBar {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = mWebView.loading;
	mBuBack.enabled = mWebView.canGoBack;
	mBuForward.enabled = mWebView.canGoForward;
}

/*
- (NSString *)stringAddTagUrl:(NSString*)strUrl
{	// Shop Url に アフェリエイト TAG/ID が無ければ付加する
	NSString *zTag = nil;
	
	NSRange rg = [strUrl rangeOfString:@".amazon.co.jp/"];
	if (0 < rg.length) {
		if (mIsPad) {	// PCサイト
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
*/

#pragma mark - View lifecicle

- (id)init
{
	self = [super init];
	if (self) {
		// 初期化処理：インスタンス生成時に1回だけ通る
		GA_TRACK_PAGE(@"AZWebView");
		//NG//mIsPad = [[[UIDevice currentDevice] model] hasPrefix:@"iPad"];
		//NG//iPad上でiPhoneモードのとき、iPhoneにならない。
		mIsPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
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
	
	mWebView = [[UIWebView alloc] init];
	mWebView.scalesPageToFit = YES;
	mWebView.delegate = self;
	mWebView.frame = self.view.bounds;	// = frameWeb;
	mWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	//MwebView.autoresizingMask = UIViewAutoresizingNone;
	//MwebView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	mWebView.clipsToBounds = YES;
	mWebView.contentMode = UIViewContentModeCenter;
	[self.view addSubview:mWebView];
	
	
	// 左側ボタン
	mBuBack = [[UIBarButtonItem alloc] 
			   initWithImage:[UIImage imageNamed:@"AZWeb-Back-16"]
			   style:UIBarButtonItemStylePlain
			   target:self action:@selector(toolBack)];
	mBuForward = [[UIBarButtonItem alloc] 
				  initWithImage:[UIImage imageNamed:@"AZWeb-Forward-16"]
				  style:UIBarButtonItemStylePlain
				  target:self action:@selector(toolForward)];
	mBuReload = [[UIBarButtonItem alloc] 
				 initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
				 target:self action:@selector(toolReload)];
	
	mActivityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 32.0f, 32.0f)];
	[mActivityIndicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
	[mActivityIndicator startAnimating]; // 通信不能のとき、インジケータだけ動かすため
	UIBarButtonItem *buActInd = [[UIBarButtonItem alloc] initWithCustomView:mActivityIndicator];
	
	if ([__BookmarkDelegate respondsToSelector:@selector(azWebViewBookmark:)]) {
		mBuCopyUrl = [[UIBarButtonItem alloc] 
					  initWithTitle:AZLocalizedString(@"AZWebView Bookmark", nil)
					  style:UIBarButtonItemStylePlain
					  target:self action:@selector(closeBookmarkUrl:)];
	} else {
		mBuCopyUrl = nil;
	}
	// 左は正順に並べる
	self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:  
											  mBuBack, mBuReload, mBuForward, buActInd, mBuCopyUrl, nil];
	
	//WebViewだけ [Back]ボタンを右側にしている。 ＜＜Webページ戻ると間違って閉じないように。
	UIBarButtonItem *buClose = [[UIBarButtonItem alloc] 
								initWithBarButtonSystemItem:UIBarButtonSystemItemStop
								target:self action:@selector(close:)];
	// 右は逆順に並べる
	self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects: buClose, nil];

	
	// URL表示用のラベル生成
	mLbMessage = [[UILabel alloc] init];
	mLbMessage.textColor = [UIColor whiteColor];
	mLbMessage.backgroundColor = [UIColor blueColor];
	mLbMessage.font = [UIFont systemFontOfSize:12];
	mLbMessage.hidden = YES;
	[self.view addSubview:mLbMessage]; //, [MlbMessage release];
	// .frame セットは、viewWillAppear:にてdidRotateFromInterfaceOrientation:を呼び出している
}

- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];

	mWebView.frame = self.view.bounds;

	[self messageShow:self.ppUrl holdSec:5.0f];
}

- (void)viewDidAppear:(BOOL)animated 
{
    [super viewDidAppear:animated];
	
	//NSString *strUrl = [self stringAddTagUrl:self.ppUrl];
	NSLog(@"WebSiteVC: self.ppUrl: {%@}", self.ppUrl);
	if (10 < [self.ppUrl length]) {
		NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.ppUrl]];
		[mWebView loadRequest:request];
		[self updateToolBar];
		UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
		[self didRotateFromInterfaceOrientation:orientation]; // 回転に合わせて.frame調整している
	} else {
		[self close:nil];
	}
}

// 回転サポート
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{	// iPhoneでは常に許可する
    return YES;
}

// ユーザインタフェースの回転を始める前にこの処理が呼ばれる。 ＜＜OS 3.0以降の推奨メソッド＞＞
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
	mLbMessage.hidden = YES;
}

// ユーザインタフェースが回転した後に呼ばれる
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	// URL表示用のラベル生成
	CGRect rc = self.view.frame;  // この時点では、ToolBar領域が除外されている
	rc.size.height = 14;
	rc.origin.y = 0;  //self.view.frame.size.height - rc.size.height;
	mLbMessage.frame = rc;
	mLbMessage.hidden = NO;
}

//iOS8
- (void)viewWillTransitionToSize:(CGSize)size
	   withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	if (size.width <= size.height) {
		// 画面回転後、縦向きになった
		
	} else {
		// 画面回転後、横向きになった
		
	}
}

// ビューが非表示にされる前や解放される前に呼ばれる
- (void)viewWillDisappear:(BOOL)animated 
{
	if (mWebView) {	// viewDidUnload:では遅い?かPopoverでは通らないようだ。 iPadでは、ここで処理しなければ落ちる。
		[mWebView stopLoading];
		mWebView.delegate = nil; // これしないと落ちます
		mWebView = nil;
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
	if (mWebView) {
		[mWebView stopLoading];
		mWebView.delegate = nil; // これしないと落ちます
		mWebView = nil;
	}
	[super viewDidUnload];
}


- (void)dealloc 
{
	if (mWebView) {
		[mWebView stopLoading];
		mWebView.delegate = nil; // これしないと落ちます
		mWebView = nil;
	}
	urlOutside = nil;
}



#pragma mark - <UIWebViewDelegate>

- (void)webViewDidStartLoad:(UIWebView *)webView 
{	// ウェブビューがコンテンツの読み込みを始めた後
	[self updateToolBar];
	[mActivityIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView 
{	// ウェブビューがコンテンツの読み込みを完了した後
	[self updateToolBar];
	[mActivityIndicator stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error 
{	// ウェブビューがコンテンツの読み込みに失敗した場合
	NSLog(@"webView: didFailLoadWithError=%@", [error localizedDescription]);
	GA_TRACK_EVENT_ERROR([error description],0);
	azAlertBox([error localizedDescription], self.ppUrl, @"OK");
	[self updateToolBar];
	[mActivityIndicator stopAnimating];
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
		// 許可するドメイン
		for (NSString *dom in __Domain)
		{
			if ([zHost hasSuffix:dom]) { //末尾比較  　item.rakuten.co.jp == rakuten.co.jp  を通すため。
				return YES; // 許可
			}
		}
		NSLog(@"zHost[%@] not in __Domain[%@]", zHost, __Domain);

		urlOutside = [[request URL] copy]; // copyしないと消えてしまうので要注意
		NSLog(@"urlOutside=%@", urlOutside);

		// アクセス禁止
//		mAlertMsg = [[UIAlertView alloc] initWithTitle:AZLocalizedString(@"AZWebView CAUTION", nil)
//														message:[urlOutside absoluteString]
//													   delegate:self
//											  cancelButtonTitle:AZLocalizedString(@"AZWebView Back", nil)
//											  otherButtonTitles:AZLocalizedString(@"AZWebView GoOut", nil), nil];
//		[mAlertMsg show];

        [self azAleartTitle: AZLocalizedString(@"AZWebView CAUTION", nil)
                    message: [urlOutside absoluteString]
                         b1: AZLocalizedString(@"AZWebView Back", nil)
                    b1style: UIAlertActionStyleCancel
                   b1action: ^(UIAlertAction * _Nullable action) {
                       //
                   }
                         b2: AZLocalizedString(@"AZWebView GoOut", nil)
                    b2style: UIAlertActionStyleDefault
                   b2action: ^(UIAlertAction * _Nullable action) {
                       NSLog(@"urlOutside=%@",urlOutside);
                       // リンクへ飛ぶ
                       [[UIApplication sharedApplication] openURL:urlOutside]; // httpがあるので自動的にブラウザが立ち上がる
                   }
                   animated: YES
                 completion: nil];
        
		mLbMessage.backgroundColor = [UIColor redColor]; //許可していないドメイン
		return NO;
	}
	return YES;
}


//urlOutsideをcopy属性で保存している
//-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
//// アラートビューでボタンがクリックされた時に呼び出されるデリゲート
//{
//    NSLog(@"button=%ld",(long)buttonIndex);
//    if (buttonIndex!=alertView.cancelButtonIndex) { // 「はい」のとき
//        NSLog(@"urlOutside=%@",urlOutside);
//        // リンクへ飛ぶ
//        [[UIApplication sharedApplication] openURL:urlOutside]; // httpがあるので自動的にブラウザが立ち上がる
//    }
//}


@end
