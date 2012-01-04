//
//  WebSiteVC.h
//  AzPacking
//
//  Created by 松山 和正 on 10/02/06.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface WebSiteVC : UIViewController <UIWebViewDelegate>
{

@private
	NSString		*Rurl;
	NSString		*RzDomain;
	//----------------------------------------------viewDidLoadでnil, dealloc時にrelese
	NSURL			*urlOutside;		//ポインタ代入につきcopyしている
	//----------------------------------------------Owner移管につきdealloc時のrelese不要
	UIWebView *MwebView;
	UIBarButtonItem *MbuBack;
	UIBarButtonItem *MbuReload;
	UIBarButtonItem *MbuForward;
	UIActivityIndicatorView *MactivityIndicator;
	UILabel				*MlbMessage;
	//----------------------------------------------assign
	AppDelegate		*appDelegate_;
	BOOL MbOptShouldAutorotate;
}

@property (nonatomic, retain) NSString		*Rurl;
@property (nonatomic, retain) NSString		*RzDomain;

//- (id)initWithFrame:(CGRect)frame;

@end
