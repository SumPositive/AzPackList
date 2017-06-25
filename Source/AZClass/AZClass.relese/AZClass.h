//
//  AZClass.h
//
//  Created by 松山 masa on 12/04/07.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#define AZClass_COPYRIGHT		@"2009 M.Matsuyama"

#define OR  ||

#ifdef DEBUG	//--------------------------------------------- DEBUG
#define AzLOG(...)							NSLog(__VA_ARGS__)
#else	//----------------------------------------------------- RELEASE
// その他のフラグ：-DNS_BLOCK_ASSERTIONS=1　（NSAssertが除去される）
#define AzLOG(...)
#define NSLog(...) 
#endif

// iOS VERSION		http://goddess-gate.com/dc2/index.php/post/452
#define IOS_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define IOS_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define IOS_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define IOS_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define IOS_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

//iPad		iOS3.2以上
#define iS_iPAD  (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

// AZClass専用 ローカライズ文字列
#define AZLocalizedString(key, msg)    NSLocalizedStringFromTable(key, @"AZLocalizable", msg) 

//----------------------------------------------- Core Graphics 汎用共通関数
//#define CGContextSetRGBaHexStrokeColor(cgc,RGBa)  \
//				CGContextSetRGBStrokeColor(cgc,(RGBa>>48)/256.0,((RGBa>>32)&0xff)/256.0,((RGBa>>16)&0xff)/256.0,(RGBa&0xff)/256.0);
//#define CGContextSetRGBaHexFillColor(cgc,RGBa)  \
//				CGContextSetRGBFillColor(cgc,(RGBa>>48)/256.0,((RGBa>>32)&0xff)/256.0,((RGBa>>16)&0xff)/256.0,(RGBa&0xff)/256.0);


//----------------------------------------------- az グローバル汎用共通関数
void azAlertBox( NSString *zTitle, NSString *zMsg, NSString *zButton );
id azNSNull( id obj );
id azNil( id obj );
// UUID
NSString *azMacAddress( void );
NSString *azGiftCode( NSString *secretKey);
// azString
NSString *azStringNoEmoji( NSString *emoji );
NSString *azStringPercentEscape( NSString *zPara );



#ifdef AZClass_GoogleAnalytics	//----------------------------- Google Analytics
#import "GANTracker.h"

#define __GA_INIT_TRACKER(ACCOUNT, PERIOD, DELEGATE) \
[[GANTracker sharedTracker] startTrackerWithAccountID:ACCOUNT \
dispatchPeriod:PERIOD delegate:DELEGATE];
#define GA_INIT_TRACKER(ACCOUNT, PERIOD, DELEGATE) __GA_INIT_TRACKER(ACCOUNT, PERIOD, DELEGATE);

#define GA_TRACK_PAGE(PAGE) { NSError *error; if (![[GANTracker sharedTracker] \
trackPageview:[NSString stringWithFormat:@"/%@", PAGE] \
withError:&error]) { NSLog(@"GANTracker: error: %@",error.description);  } }

#define GA_TRACK_EVENT(EVENT,ACTION,LABEL,VALUE) { \
NSError *error; if (![[GANTracker sharedTracker] trackEvent:EVENT action:ACTION label:LABEL value:VALUE withError:&error]) \
{ NSLog(@"GANTracker: error: %@",error.description); }  }

#else		//----------------------------------------------- Google Analytics

#define GA_INIT_TRACKER(ACCOUNT, PERIOD, DELEGATE) {NSLog(@"GA_INIT_TRACKER: Not Use");}

#define GA_TRACK_PAGE(PAGE) {NSLog(@"GA_TRACK_PAGE: %@",PAGE);}

#define GA_TRACK_EVENT(EVENT,ACTION,LABEL,VALUE) { \
NSLog(@"GA_TRACK_EVENT: %@, %@, %@, %ld",EVENT,ACTION,LABEL,(long)VALUE);}

#endif		//----------------------------------------------- Google Analytics

#define GA_TRACK_CLASS  {GA_TRACK_PAGE(NSStringFromClass([self class]))}
#define GA_TRACK_METHOD {GA_TRACK_EVENT(NSStringFromClass([self class]),NSStringFromSelector(_cmd),@"",0);}

#define GA_TRACK_LOG(LABEL)  {\
NSString *_zLabel_ = [NSString stringWithFormat:@"<%d>%@",__LINE__,LABEL];\
GA_TRACK_EVENT(NSStringFromClass([self class]),NSStringFromSelector(_cmd),_zLabel_,0);\
NSLog(@"GA_TRACK_LOG: %@:%@ %@",NSStringFromClass([self class]),NSStringFromSelector(_cmd),_zLabel_);\
_zLabel_=nil;}

#define GA_TRACK_ERROR(LABEL)  {\
NSString *_zAction_ = [NSString stringWithFormat:@"%@:%@",NSStringFromClass([self class]),NSStringFromSelector(_cmd)];\
NSString *_zLabel_ = [NSString stringWithFormat:@"<%d>%@",__LINE__,LABEL];\
GA_TRACK_EVENT(@"ERROR",_zAction_,_zLabel_,0);\
NSLog(@"GA_TRACK_ERROR: %@ %@",_zAction_,_zLabel_);\
_zAction_=nil; _zLabel_=nil;}

// 以下、非推奨
#define GA_TRACK_METHOD_LABEL(LABEL,VALUE)		GA_TRACK_LOG(LABEL)
#define GA_TRACK_EVENT_ERROR(LABEL,VALUE)			GA_TRACK_ERROR(LABEL)


//END

