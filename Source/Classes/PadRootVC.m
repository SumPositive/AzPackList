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


@interface PadRootVC (PrivateMethods)
@end


@implementation PadRootVC
@synthesize popoverButtonItem;


- (void)unloadRelease	// dealloc, viewDidUnload から呼び出される
{
	NSLog(@"--- unloadRelease --- PadRootVC");
   //[popoverButtonItem release], 
	popoverButtonItem = nil;
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
	self.popoverButtonItem = nil;
	// この後に loadView ⇒ viewDidLoad ⇒ viewWillAppear がコールされる
}


#pragma mark - View lifecycle

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization

		// 背景テクスチャ・タイルペイント
		//self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Tx-Back"]];
		// 背景色
		self.view.backgroundColor = [UIColor colorWithRed:152/255.0f 
													green:81/255.0f 
													 blue:75/255.0f 
													alpha:1.0f];
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
	UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(124,124, 72,72)];
	[iv setImage:[UIImage imageNamed:@"Icon72"]];
	[self.view addSubview:iv]; 
	//[iv release], 
	iv = nil;
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

/* SplitViewは、透明なので通らない！
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}
*/



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
    self.popoverButtonItem = barButtonItem;
	UINavigationController *navi = [svc.viewControllers objectAtIndex:1];
	UIViewController <DetailViewController> *detailVC = (UIViewController <DetailViewController> *)navi.visibleViewController;
	if ([detailVC respondsToSelector:@selector(showPopoverButtonItem:)]) {
		[detailVC showPopoverButtonItem:popoverButtonItem];
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
		[detailVC hidePopoverButtonItem:popoverButtonItem];
	}
    //self.popoverController = nil;
	self.popoverButtonItem = nil;
}

@end
