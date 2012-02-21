//
//  PadRootVC.m
//  AzPacking
//
//  Created by Sum Positive on 11/05/07.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Global.h"
#import "AppDelegate.h"
#import "PadRootVC.h"
#import "SpSearchVC.h"
#import "E2viewController.h"

#define BAG_FRAME			CGRectMake(100, 120, 72*2, 72*2)  // 取手が中心になるようにしている。
#define BAG_FRAME2		CGRectMake(180, 120, 72*2, 72*2)


@interface PadRootVC (PrivateMethods)
@end


@implementation PadRootVC
{
	AppDelegate		*appDelegate_;
	UIImageView		*imgBag_;
}
@synthesize popoverButtonItem = popoverButtonItem_;

- (void)unloadRelease	// dealloc, viewDidUnload から呼び出される
{
	NSLog(@"--- unloadRelease --- PadRootVC");
   //[popoverButtonItem_ release], 
	popoverButtonItem_ = nil;
}

- (void)dealloc
{
	[self unloadRelease];
    //[super dealloc];
}

- (void)viewDidUnload 
{	// メモリ不足時、裏側にある場合に呼び出されるので、viewDidLoadで生成したObjを解放する。
	// メモリ不足時、裏側にある場合に呼び出される。addSubviewされたOBJは、self.viewと同時に解放される
	[super viewDidUnload];  // TableCell破棄される
	[self unloadRelease];		// その後、AdMob破棄する
	//self.splitViewController = nil;
	popoverButtonItem_ = nil;
	// この後に loadView ⇒ viewDidLoad ⇒ viewWillAppear がコールされる
}


#pragma mark - View lifecycle

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
		appDelegate_ = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		appDelegate_.app_UpdateSave = NO;
		// 背景テクスチャ・タイルペイント
		//self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Tx-Back"]];
		// 背景色
		self.view.backgroundColor = [UIColor colorWithRed:152/255.0f 
													green:81/255.0f 
													 blue:75/255.0f 
													alpha:1.0f];
		
		//iPad// これが、最初の Index Popover のサイズになる。
		//self.contentSizeForViewInPopover = GD_POPOVER_SIZE; //アクションメニュー配下(Share,Googleなど）においてサイズ統一
		self.contentSizeForViewInPopover = CGSizeMake(350, 800); //配下全てFormSheetスタイルにしたことにより自由になったので最大化
   }
    return self;
}

// IBを使わずにviewオブジェクトをプログラム上でcreateするときに使う
//（viewDidLoadは、nibファイルでロードされたオブジェクトを初期化するために使う）
- (void)loadView
{
	//AzLOG(@"------- E1viewController: loadView");    
	[super loadView];
	
	//------------------------------------------アイコン
	imgBag_ = [[UIImageView alloc] initWithFrame:BAG_FRAME];
	imgBag_.contentMode = UIViewContentModeBottomLeft;
	[imgBag_ setImage:[UIImage imageNamed:@"Icon72"]];
	//imgBag_.center = CGPointMake(self.view.bounds.size.width/2+60, 150);
	[self.view addSubview:imgBag_]; 
}

/*
// nibファイルでロードされたオブジェクトを初期化する
- (void)viewDidLoad
{
    [super viewDidLoad];
}
 */

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	[self.navigationController setToolbarHidden:NO animated:NO]; // ツールバー表示
}

// SplitViewは、透明なので通らない！
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	
	if (appDelegate_.app_BagSwing) {		// 振る // 全収納済みとなったE1から戻ったとき。
		appDelegate_.app_BagSwing = NO; // 解除
		
		// Anime 開始位置
		imgBag_.transform = CGAffineTransformIdentity;
		imgBag_.frame = BAG_FRAME;
		
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:1.0];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		
		// 終了後、元の位置に戻す
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(animeAfter)];
		
		// 繰り返し
		[UIView setAnimationRepeatAutoreverses:YES];
		[UIView setAnimationRepeatCount:1.5];
		
		// Anime 終了位置
		imgBag_.frame = BAG_FRAME2;
		imgBag_.transform = CGAffineTransformMakeRotation(-M_PI/2.0);
		
		//CGAffineTransform tfTrans = CGAffineTransformTranslate(CGAffineTransformIdentity, -120, 0);
		//CGAffineTransform tfRotate = CGAffineTransformRotate(CGAffineTransformIdentity, -M_PI/2.0);
		//imgBag_.transform = CGAffineTransformConcat(tfTrans, tfRotate);

		[UIView commitAnimations];
	}
}

- (void)animeAfter
{	// 元の位置に戻す
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:1.0];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	
	// Anime 終了位置
	imgBag_.transform = CGAffineTransformIdentity;  // 変換クリア
	imgBag_.frame = BAG_FRAME;

	[UIView commitAnimations];
}


#pragma mark - Rotation support

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return YES;
}

//[Index]Popoverが開いたときに呼び出される
- (void)splitViewController:(UISplitViewController*)svc 
		  popoverController:(UIPopoverController*)pc 
  willPresentViewController:(UIViewController *)aViewController
{
	//NSLog(@"aViewController=%@", aViewController);
	UINavigationController* nc = (UINavigationController*)aViewController;
	E2viewController* vc = (E2viewController*)nc.visibleViewController;
	if ([vc respondsToSelector:@selector(setPopover:)]) {
		[vc setPopover:pc];	//内側から閉じるため
	}
	return;
}

//タテになって左ペインが隠れる前に呼び出される
- (void)splitViewController:(UISplitViewController*)svc
	 willHideViewController:(UIViewController *)aViewController 
		  withBarButtonItem:(UIBarButtonItem*)barButtonItem 
	   forPopoverController:(UIPopoverController*)pc		//左ペインが内包されるPopover
{
    barButtonItem.title = @"padRoot";
	//self.popoverController = pc;
    popoverButtonItem_ = barButtonItem;
	UINavigationController *navi = [svc.viewControllers objectAtIndex:1];
	UIViewController <DetailViewController> *detailVC = (UIViewController <DetailViewController> *)navi.visibleViewController;
	if ([detailVC respondsToSelector:@selector(showPopoverButtonItem:)]) {
		[detailVC showPopoverButtonItem:popoverButtonItem_];
	}
}

//ヨコになって左ペインが現れる前に呼び出される
- (void)splitViewController:(UISplitViewController*)svc 
	 willShowViewController:(UIViewController *)aViewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem 
{
	UINavigationController *navi = [svc.viewControllers objectAtIndex:1];
	UIViewController <DetailViewController> *detailVC = (UIViewController <DetailViewController> *)navi.visibleViewController;
	if ([detailVC respondsToSelector:@selector(hidePopoverButtonItem:)]) {
		[detailVC hidePopoverButtonItem:popoverButtonItem_];
	}
    //self.popoverController = nil;
	popoverButtonItem_ = nil;
}

@end
