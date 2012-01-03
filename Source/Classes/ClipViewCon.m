//
//  ClipVieCon.m
//  AzPack
//
//  Created by 松山 和正 on 09/12/03.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
// InterfaceBuilderを使わずに作ったViewController

#import "Global.h"
#import "ClipVieCon.h"


@implementation ClipVieCon   // ViewController

@synthesize tvClip;

- (void)dealloc {
	[tvClip release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (id)init {
	if ( !(self = [super init]) ) return self;
	
	self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
	
	self.tvClip = [[UITextView alloc] initWithFrame:CGRectMake(20,40,280,200)];
	[tvClip setDelegate:self];
	[self.view addSubview:tvClip];
	
	// [Back]ボタンを左側に追加する
	UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc]
									   initWithImage:[UIImage imageNamed:@"simpleLeft2-icon16.png"]
									   style:UIBarButtonItemStylePlain  target:nil  action:nil];
	self.navigationItem.backBarButtonItem = backButtonItem;
	[backButtonItem release];		

	return self;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	tvClip.text = @"CSV";

	[tfClip becomeFirstResponder];
}

@end
