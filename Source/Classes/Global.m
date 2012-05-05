//
//  Global.m	クラスメソッド（グローバル関数）
//  AzPacking 0.4
//
//  Created by 松山 和正 on 09/12/03.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "Global.h"

@implementation UINavigationController(KeyboardDismiss)
- (BOOL)disablesAutomaticKeyboardDismissal {
	return NO;
}
@end

UIColor *GcolorBlue(float percent) 
{
	float red = percent * 255.0f;
	float green = (red + 20.0f) / 255.0f;
	float blue = (red + 45.0f) / 255.0f;
	if (green > 1.0) green = 1.0f;
	if (blue > 1.0f) blue = 1.0f;
	
	return [UIColor colorWithRed:percent green:green blue:blue alpha:1.0f];
}


// 文字列から画像を生成する			中心座標(Pfx,Pfy)=(16.0,16.0)  PfSize=12.0
UIImage *GimageFromString(float Pfx, float Pfy, float PfSize, NSString* str)
{
    UIFont* font = [UIFont systemFontOfSize:PfSize]; //12.0; [0.4.17]Retina対応
    CGSize size = [str sizeWithFont:font];
    int width = 64; //32; [0.4.17]Retina対応
    int height = 64; //32;
    int pitch = width * 4;
	
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // 第一引数を NULL にすると、適切なサイズの内部イメージを自動で作ってくれる
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, pitch, 
												 colorSpace, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
	CGAffineTransform transform = CGAffineTransformMake(1.0,0.0,0.0, -1.0,0.0,0.0); // 上下転置行列
	CGContextConcatCTM(context, transform);
	
	// 描画開始
    UIGraphicsPushContext(context);
    
	CGContextSetRGBFillColor(context, 255, 0, 0, 1.0f);
	[str drawAtPoint:CGPointMake(Pfx - (size.width / 2.0f), Pfy - 38.5) withFont:font];
	
	// 描画終了
	UIGraphicsPopContext();
	
    // イメージを取り出す
    CGImageRef image = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
	
    // UIImage を生成
    UIImage* uiImage = [UIImage imageWithCGImage:image];
    CGImageRelease(image);
    return uiImage;
}


NSString *GstringFromNumber( NSNumber *num ) 
{
	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
	[formatter setNumberStyle:NSNumberFormatterDecimalStyle];
	NSString *str = [formatter stringFromNumber:num];
	//[formatter release];
	return str; // autorelease
}

NSString *GstringNoEmoji( NSString *emoji )
{
	// 絵文字を除去する
	NSMutableString *zKey = [NSMutableString new];
	for (NSUInteger i = 0; i < [emoji length]; i++)
	{
		// UNICODE(UTF-16)文字を順に取り出します。
		unichar code = [emoji characterAtIndex:i];
		// UNICODE(UTF-16)絵文字範囲 http://ja.wikipedia.org/wiki/SoftBank%E7%B5%B5%E6%96%87%E5%AD%97
		if ((0x20E0<=code && code<=0x2FFF) OR (0xD830<=code && code<=0xDFFF))
		{
			//NSLog(@"\\u%04x <<<", code);
			i++;
		} 
		else {
			//NSLog(@"\\u%04x", code);
			[zKey appendFormat:@"%C", code];
		}
	}
	NSLog(@"actionWebTitle: zKey=%@", zKey);
	return zKey;
}

NSString *GstringPercentEscape( NSString *zPara )
{	// パーセントエスケープ処理してUTF8でエンコーディングする
	// stringByAddingPercentEscapesUsingEncoding:はダメ　＜＜"(0×20)"#%><[\]^`{|}" しかエスケープしないため。
	// エスケープさせない「コマンド使用」など文字を記述
	static const CFStringRef charactersToLeaveUnescaped = NULL;  //なし ＜＜全てエスケープさせるため
	// 通常ではエスケープされないが、してほしい文字を記述
	static const CFStringRef legalURLCharactersToBeEscaped = CFSTR("!*'();:@&=+$,./?%#[]");  //全てエスケープさせるため
	// __bridge_transfer : CオブジェクトをARC管理オブジェクトにする
	NSString *zEsc = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(
																							   kCFAllocatorDefault,	
																							   (__bridge CFStringRef)zPara,
																							   charactersToLeaveUnescaped,
																							   legalURLCharactersToBeEscaped,
																							   kCFStringEncodingUTF8);
	NSLog(@"GstringPercentEscape: {%@}\n⇒{%@}", zPara, zEsc);
	return zEsc;
}


#pragma mark - UTC協定世界時

//******************************************************************************
//***** Device側はデフォルトタイムゾーン時刻を使用。　通信(JSON)やGAE側はUTCを使用。
//******************************************************************************
// UTC協定世界時 文字列 "2010-12-31T00:00:00" を デフォルトタイムゾーンのNSDate型にする
NSDate *dateFromUTC( NSString *zUTC )
{
	// 任意の日付をNSDate型に変換
	NSDateFormatter *dfmt = [[NSDateFormatter alloc] init];
	[dfmt setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]]; // 協定世界時(+0000)
	[dfmt setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
	NSDate *dTZ = [dfmt dateFromString:zUTC];	
	//[dfmt release];
	return dTZ;
}

// デフォルトタイムゾーンのNSDate型 を UTC協定世界時 文字列 "2010-12-31T00:00:00" にする
NSString *utcFromDate( NSDate *dTZ )
{
	NSDateFormatter *dfmt = [[NSDateFormatter alloc] init];
	[dfmt setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]]; // 協定世界時(+0000)
	[dfmt setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
	NSString *zUTC = [dfmt stringFromDate:dTZ];
	//[dfmt release];
	return zUTC; // autorelease
}


NSString *uuidString()
{
	CFUUIDRef uuidObj = CFUUIDCreate(nil);	//create a new UUID
	NSString *uuid = (__bridge_transfer NSString *)CFUUIDCreateString(nil, uuidObj);
	CFRelease(uuidObj);
	return uuid;
}


//******************************************************************************
#ifdef DEBUG
#pragma mark - DEBUG Functions
void debugLogRect( CGRect rc,  NSString *title)
{
	NSLog(@"**RECT*** %@=(%.1f, %.1f)-(%.1f, %.1f)", title, rc.origin.x, rc.origin.y, rc.size.width, rc.size.height);
}
#endif

//END


