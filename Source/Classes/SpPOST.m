//
//  SpPOST.m
//  AzPacking
//
//  Created by 松山 和正 on 10/03/01.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Global.h"
#import "SpPOST.h"
#import <CommonCrypto/CommonDigest.h>  // MD5


void alertMsgBox( NSString *title, NSString *msg, NSString *buttonTitle )
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
													message:msg
												   delegate:nil 
										  cancelButtonTitle:nil 
										  otherButtonTitles:buttonTitle, nil];
	[alert show];
	//[alert release];
}


NSMutableURLRequest *requestSpPOST( NSString *PzBody )
{
#ifdef DEBUGxxx
	//Local Server　　＜＜GoogleAppEngineLuncherを起動する
	NSString *url = @"http://localhost:8081/SharePlan";
#else
	//Google Server
	NSString *url = @"http://" GAE_Version ".latest." GAE_Name ".appspot.com/SharePlan";
	//NSString *url = [NSString stringWithString:@"http://" GAE_Version ".latest." GAE_Name ".appspot.com/SharePlan"];
#endif
	
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
													   cachePolicy:NSURLRequestUseProtocolCachePolicy 
												   timeoutInterval:60.0];
	
	// POST Param1=aaa&Param2=bbb
	[req setHTTPMethod:@"POST"];	//メソッドをPOSTに指定

	/*[2.0]	//POST全体をエスケープ処理するのは良くない！ 
					// 日本語やコマンド文字が含まれる可能性のある『パラメータ毎に％エスケープ処理する』こと。
					// その為の関数 ⇒ GstringPercentEscape();
					// &tag= が無くなったので日本語などの％エスケープ処理は必要無くなった。
	//AzLOG(@"dataSpPOST:PzBody=%@", PzBody);
	// 日本語を含むURLをUTF8でエンコーディングする
	// エスケープさせない「コマンド使用」など文字を記述
	static const CFStringRef charactersToLeaveUnescaped = CFSTR("?&=$");	//POST「コマンド使用」文字を記述
	// 通常ではエスケープされないが、してほしい文字を記述
	static const CFStringRef legalURLCharactersToBeEscaped = NULL;	//ここでのPOSTメッセージには不要
	// __bridge_transfer : CオブジェクトをARC管理オブジェクトにする
	NSString *encodedCmd = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(
																								 kCFAllocatorDefault,	
																								 (__bridge CFStringRef)PzBody,
																								 charactersToLeaveUnescaped,
																								 legalURLCharactersToBeEscaped,
																								 kCFStringEncodingUTF8);
	NSLog(@"Escape: encodedCmd {%@}", encodedCmd);
	 [req setHTTPBody:[encodedCmd dataUsingEncoding:NSUTF8StringEncoding]];  //エンコ済みコマンドセット
	 encodedCmd = nil;
	 */
	[req setHTTPBody:[PzBody dataUsingEncoding:NSUTF8StringEncoding]];  //エンコ済みコマンドセット
	//同期通信を開始
	return req;
}

NSString *postCmdAddUserPass( NSString *PzPostCmd )
{
/*没
	NSString *uuid = [[NSUserDefaults standardUserDefaults] valueForKey:UD_DeviceID];
	if (uuid) {
		//1度生成されておれば、それを使用する。
		return [PzPostCmd stringByAppendingFormat:@"&userPass=%@", uuid];
	}*/
	
	// userPass : デバイスID（UDID）+ zipcode & MD5   （UDIDをそのまま利用するのはセキュリティ上好ましくないため）
#ifdef DEBUGxxx
	NSString *userPass = DEBUG_userPass;
#else
	//DEPRECATED//NSString *userPass = [UIDevice currentDevice].uniqueIdentifier;		// デバイスID文字列
	//DEPRECATEDにつき、無効になったとき、MACアドレスを使うようにした [2.0]
	NSString *userPass = azMacAddress();  // in AZClass.m
#endif
	// Zipcode(郵便番号程度の暗唱ワード)を付加して userPass を生成
	NSString *nickname = [[NSUserDefaults standardUserDefaults] valueForKey:GD_DefNickname];
	// 公開経験が無ければ、nickname==nil -->> UD_DeviceID 記録しない！
	if (nickname==nil) {
		nickname = @"";
	}
	userPass = [userPass stringByAppendingFormat:@"syUku%@gAwa", nickname];  //【変更禁止】過去にアップした人が削除できなくなるため。
	NSLog(@"userPass=%@", userPass);
	
	// userPass を MD5ハッシュ化
	const char *cstr = [userPass UTF8String];	// C文字列化
	unsigned char ucMd5[CC_MD5_DIGEST_LENGTH];	// MD5結果領域 [16]bytes
	CC_MD5(cstr, strlen(cstr), ucMd5);			// MD5生成
	
	// 16進文字列化
	NSString *zMd5Hex = [NSString stringWithFormat: @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",    
						 ucMd5[0], ucMd5[1], ucMd5[2], ucMd5[3],
						 ucMd5[4], ucMd5[5], ucMd5[6], ucMd5[7],
						 ucMd5[8], ucMd5[9], ucMd5[10], ucMd5[11],
						 ucMd5[12], ucMd5[13], ucMd5[14], ucMd5[15]];	
	AzLOG(@"userPass:zMd5Hex=%@", zMd5Hex);

/*	if (nickname) {	// 公開経験が無ければ、nickname==nil -->> UD_DeviceID 記録しない！
		//2.0//1度だけ生成して、再インストールするまで、それを使用する。
		[[NSUserDefaults standardUserDefaults] setObject:zMd5Hex forKey:UD_DeviceID];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}*/
	
	return [PzPostCmd stringByAppendingFormat:@"&userPass=%@", zMd5Hex]; // autorelease
}

/*[2.0]選択可能にした。
NSString *postCmdAddLanguage( NSString *PzPostCmd )
{
	// language : 2字言語コード(ISO 639-1)  ＜＜将来的には選択可能にする＞＞
	//NSString *language = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode]; 
								// これでは、iOS設定「リージョン」が取得できるが、「言語」とは異なる場合があるので没

	NSString *language = NSLocalizedString(@"LanguageCode",nil); // 表示言語に一致させるため  "ja", "en"
	AzLOG(@"language=%@", language); //「書式」の言語が取得できる。（「言語」ではない！）
	return [PzPostCmd stringByAppendingFormat:@"&language=%@", [language substringToIndex:2]]; //先頭2文字
}
*/

