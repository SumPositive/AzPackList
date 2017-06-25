//
//  AZWebView.h
//  
//
//  Created by 松山 和正 on 10/02/06.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AZClass.h"

@interface AZWebView : UIViewController <UIWebViewDelegate>
{
@private
	NSURL			*urlOutside;		//ポインタ代入につきcopyしている
	UIWebView				*mWebView;
	UILabel					*mLbMessage;
	UIBarButtonItem		*mBuCopyUrl;
	UIBarButtonItem		*mBuBack;
	UIBarButtonItem		*mBuReload;
	UIBarButtonItem		*mBuForward;
	UIAlertView				*mAlertMsg;
	UIActivityIndicatorView *mActivityIndicator;
	
	BOOL					mIsPad;
}

@property (nonatomic, retain) NSString		*ppUrl;				//初期表示URL
@property (nonatomic, retain) NSSet			*ppDomain;		//許可ドメインのセット （Host名の末尾を比較している）
@property (nonatomic, assign) id					ppBookmarkDelegate;	//<AZWebViewBookmarkDelegate>

@end

@protocol AZWebViewBookmarkDelegate <NSObject>
#pragma mark - <AZWebViewBookmarkDelegate>
- (void)azWebViewBookmark:(NSString *)url;
@end

