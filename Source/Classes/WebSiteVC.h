//
//  WebSiteVC.h
//  AzPacking
//
//  Created by 松山 和正 on 10/02/06.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface WebSiteVC : UIViewController <UIWebViewDelegate>

@property (nonatomic, retain) NSString		*Rurl;
@property (nonatomic, retain) NSString		*RzDomain;

//- (id)initWithFrame:(CGRect)frame;

@end
