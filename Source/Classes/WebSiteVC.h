//
//  WebSiteVC.h
//  AzPacking
//
//  Created by 松山 和正 on 10/02/06.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface NSObject (WebSiteDelegate)	// @protocolでない非形式プロトコル（カテゴリ）方式によるデリゲート
- (void)webSiteBookmarkUrl:(NSString *)url;
@end

@interface WebSiteVC : UIViewController <UIWebViewDelegate>
@property (nonatomic, retain) NSString		*Rurl;
@property (nonatomic, retain) NSString		*RzDomain;

- (id)initWithBookmarkDelegate:(id)delegate;
@end

