//
//  AZClass.m
//
//  Created by Sum Positive on 2011/10/01.
//  Copyright 2011 Sum Positive. All rights reserved.
//
#undef  NSLocalizedString		//⇒ AZClassLocalizedString  AZClass専用にすること

#import "AZClass.h"


void azAlertBox( NSString *zTitle, NSString *zMsg, NSString *zButton )
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:zTitle
													message:zMsg
												   delegate:nil
										  cancelButtonTitle:nil
										  otherButtonTitles:zButton, nil];
	[alert show];
}

// nil --> [NSNull null]   コンテナ保存オブジェクトにnilが含まれる可能性があるときに使用
id azNSNull( id obj )
{
	if (obj) return obj;
	return [NSNull null];
}

// [NSNull null] --> nil
id azNil( id obj )
{
	if (obj) {
		if (obj==[NSNull null]) {
			return nil;
		}
		return obj;
	}
	return nil;
}



#pragma mark - UUID
// UDID（デバイスID）非推奨に伴い、MACアドレス利用に変更するため
#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
NSString *azMacAddress( void )
{	// cf. http://iphonedevelopertips.com/device/determine-mac-address.html
	int                 mgmtInfoBase[6];
	char                *msgBuffer = NULL;
	size_t              length;
	unsigned char       macAddress[6];
	struct if_msghdr    *interfaceMsgStruct;
	struct sockaddr_dl  *socketStruct;
	NSString            *errorFlag = NULL;
	
	// Setup the management Information Base (mib)
	mgmtInfoBase[0] = CTL_NET;        // Request network subsystem
	mgmtInfoBase[1] = AF_ROUTE;       // Routing table info
	mgmtInfoBase[2] = 0;              
	mgmtInfoBase[3] = AF_LINK;        // Request link layer information
	mgmtInfoBase[4] = NET_RT_IFLIST;  // Request all configured interfaces
	
	// With all configured interfaces requested, get handle index
	if ((mgmtInfoBase[5] = if_nametoindex("en0")) == 0) 
		errorFlag = @"if_nametoindex failure";
	else
	{
		// Get the size of the data available (store in len)
		if (sysctl(mgmtInfoBase, 6, NULL, &length, NULL, 0) < 0) 
			errorFlag = @"sysctl mgmtInfoBase failure";
		else
		{
			// Alloc memory based on above call
			if ((msgBuffer = malloc(length)) == NULL)
				errorFlag = @"buffer allocation failure";
			else
			{
				// Get system information, store in buffer
				if (sysctl(mgmtInfoBase, 6, msgBuffer, &length, NULL, 0) < 0)
					errorFlag = @"sysctl msgBuffer failure";
			}
		}
	}
	
	// Befor going any further...
	if (errorFlag != NULL)
	{
		NSLog(@"Error: %@", errorFlag);
		return errorFlag;
	}
	
	// Map msgbuffer to interface message structure
	interfaceMsgStruct = (struct if_msghdr *) msgBuffer;
	
	// Map to link-level socket structure
	socketStruct = (struct sockaddr_dl *) (interfaceMsgStruct + 1);
	
	// Copy link layer address data in socket structure to an array
	memcpy(&macAddress, socketStruct->sdl_data + socketStruct->sdl_nlen, 6);
	
	// Read from char array into a string object, into traditional Mac address format
	//NSString *macAddressString = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X", 
	NSString *macAddressString = [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X",
								  macAddress[0], macAddress[1], macAddress[2], 
								  macAddress[3], macAddress[4], macAddress[5]];
	NSLog(@"azMacAddress={%@}", macAddressString);
	
	// Release the buffer memory
	free(msgBuffer);
	
	return macAddressString;
}

#import <CommonCrypto/CommonDigest.h>  // MD5
// GiftCode生成　　＜＜これと同じものを Version 1.2 にも実装して「招待パス」表示している
NSString *azGiftCode( NSString *secretKey)
{	// userPass : デバイスID（UDID） & MD5   （UDIDをそのまま利用するのはセキュリティ上好ましくないため）
	//NSString *code = [UIDevice currentDevice].uniqueIdentifier;		// デバイスID文字列 ＜＜iOS5.1以降廃止のため
	// MACアドレスに secretKey(固有文字)を絡めて種コード生成
	NSString *code = [NSString stringWithFormat:@"Syukugawa%@%@", azMacAddress(), secretKey];
	NSLog(@"MAC address: code=%@", code);
	// code を MD5ハッシュ化
	const char *cstr = [code UTF8String];	// C文字列化
	unsigned char ucMd5[CC_MD5_DIGEST_LENGTH];	// MD5結果領域 [16]bytes
	CC_MD5(cstr, (CC_LONG)strlen(cstr), ucMd5);			// MD5生成
	// 16進文字列化 ＜＜ucMd5[0]〜[15]のうち10文字分だけ使用する＞＞
	code = [NSString stringWithFormat: @"%02X%02X%02X%02X%02X",  
			ucMd5[1], ucMd5[5], ucMd5[7], ucMd5[11], ucMd5[13]];	
	AzLOG(@"azGiftCode: code=%@", code);
	return code;
}


#pragma mark - azString
NSString *azStringNoEmoji( NSString *emoji )
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
	NSLog(@"azStringNoEmoji: zKey=%@", zKey);
	return [NSString stringWithString: zKey];
}

NSString *azStringPercentEscape( NSString *zPara )
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
	NSLog(@"azStringPercentEscape: {%@}\n⇒{%@}", zPara, zEsc);
	return zEsc;
}


//END
