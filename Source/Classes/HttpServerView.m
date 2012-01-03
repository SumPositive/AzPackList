//
//  HttpServerView.m
//  AzPacking-0.6
//
//  Created by 松山 和正 on 10/06/27.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Global.h"
#import "Entity.h"
#import "FileCsv.h"
#import "HTTPServer.h"
#import "MyHTTPConnection.h"
#import "localhostAddresses.h"
#import "HttpServerView.h"

#define ALERT_TAG_HTTPServerStop	109


@implementation HttpServerView
@synthesize Re0root;


- (void)dealloc {
	if (MalertHttpServer) [MalertHttpServer release];

	if (httpServer) {
		[httpServer stop];
		[httpServer release];
	}
	
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
    }
    return self;
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (alertView.tag) {
		case ALERT_TAG_HTTPServerStop:
			if (httpServer) [httpServer stop];
			[[NSNotificationCenter defaultCenter] removeObserver:self name:@"LocalhostAdressesResolved" object:nil];
			//
			[self hide];
			break;
	}
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect 
{
	UIImageView *imgView;
	if (rect.size.width < rect.size.height) {
		// タテ画面
		imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"azuki-320.jpg"]];
	} else {
		// ヨコ画面
		imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"azuki-480.jpg"]];
	}
	//imgView.contentMode = UIViewContentModeScaleAspectFit; // 画像のaspect比を維持し、ちょうどはいるようにする
	imgView.contentMode = UIViewContentModeScaleAspectFill; // 画像のaspect比を維持し、最大に伸ばす
	imgView.frame = self.bounds;
	[self addSubview:imgView];
	[imgView release];
	
	if (MalertHttpServer) return;

	MalertHttpServer = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"HttpSv Title", nil) 
												  message:NSLocalizedString(@"HttpSv Wait", nil) 
												 delegate:self 
										cancelButtonTitle:nil  //@"CANCEL" 
										otherButtonTitles:NSLocalizedString(@"HttpSv stop", nil) , nil];
	MalertHttpServer.tag = ALERT_TAG_HTTPServerStop;
	[MalertHttpServer show];
	//[MalertHttpServer release];
}

- (void)animationDidEnd  // showアニメーションが完了したときに呼ばれる
{
	if (MalertHttpServer == nil) {
		MalertHttpServer = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"HttpSv Title", nil) 
													  message:NSLocalizedString(@"HttpSv Wait", nil) 
													 delegate:self 
											cancelButtonTitle:nil  //@"CANCEL" 
											otherButtonTitles:NSLocalizedString(@"HttpSv stop", nil) , nil];
		MalertHttpServer.tag = ALERT_TAG_HTTPServerStop;
		[MalertHttpServer show];
	}

	//HTTP Server Start
	// if (httpServer) return; <<< didSelectRowAtIndexPath:直後に配置してダブルクリック回避している。

	// CSV SAVE ＜＜先にCSVファイル書き出しする
	NSString *zErr = [FileCsv zSave:Re0root toLocalFileName:GD_CSVFILENAME];
	if (zErr) {
		UIAlertView *alert = [[UIAlertView alloc] 
							  initWithTitle:NSLocalizedString(@"Upload Fail",nil)
							  message:zErr
							  delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
		[alert show];
		[alert release];
		return;
	}
	//
	NSString *root = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
	httpServer = [HTTPServer new];
	[httpServer setType:@"_http._tcp."];
	[httpServer setConnectionClass:[MyHTTPConnection class]];
	[httpServer setDocumentRoot:[NSURL fileURLWithPath:root]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(httpInfoUpdate:) name:@"LocalhostAdressesResolved" object:nil];
	[localhostAddresses performSelectorInBackground:@selector(list) withObject:nil];
	[httpServer setPort:8080];
	//[httpServer setBackup:NO]; // RESTORE Mode
	//[httpServer setManagedObjectContext:Re0root.managedObjectContext];
	//[httpServer setAddRow:MiSection0Rows];
	[httpServer setPe0root:Re0root];
	NSError *error;
	if(![httpServer start:&error])
	{
		NSLog(@"Error starting HTTP Server: %@", error);
		[httpServer release];
		httpServer = nil;
	}
	// Upload成功後、CSV LOAD する  ＜＜連続リストアできるように httpResponseForMethod 内で処理＞＞
}


// HTTP Server Address Display
- (void)httpInfoUpdate:(NSNotification *) notification
{
	NSLog(@"httpInfoUpdate:");
	
	if(notification)
	{
		[addresses release];
		addresses = [[notification object] copy];
		NSLog(@"addresses: %@", addresses);
	}
	
	if(addresses == nil)
	{
		return;
	}
	
	NSString *info;
	UInt16 port = [httpServer port];
	
	NSString *localIP = nil;
	localIP = [addresses objectForKey:@"en0"];
	if (!localIP)
	{
		localIP = [addresses objectForKey:@"en1"];
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
	if (MalertHttpServer) {
		MalertHttpServer.message = info;
		[MalertHttpServer show];
	}
}

- (void)show
{
	// Scroll in the overlay
	CGContextRef context = UIGraphicsGetCurrentContext();
	[UIView beginAnimations:nil context:context];
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:[self superview] cache:YES];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:1.0];

	// このアニメーションが完了したときの処理を指定
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationDidEnd)];
	
	//self.backgroundColor = [UIColor grayColor];
	self.backgroundColor = [UIColor colorWithRed:151.0/255.0 green:80.0/255.0 blue:77.0/255.0 alpha:1.0]; // Azukid Color
	
	[[self superview] exchangeSubviewAtIndex:0 withSubviewAtIndex:1];
	[UIView	commitAnimations];
}

- (void)hide
{
	// Scroll in the overlay
	CGContextRef context = UIGraphicsGetCurrentContext();
	[UIView beginAnimations:nil context:context];
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:[self superview] cache:YES];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:1.0];

	[[self superview] exchangeSubviewAtIndex:0 withSubviewAtIndex:1];
	[UIView	commitAnimations];

	[self removeFromSuperview]; //ビューの削除
}


@end
