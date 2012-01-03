//
//  URLDownload.m
//
//  Created by 松山 和正 on 10/01/03.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Global.h"
#import "URLDownload.h"


@implementation URLDownload
@synthesize filePath;

- (void)dealloc {
	[request release];
	[directoryPath release];
	[filePath release];
	[file release];
	[delegate release];
	[con release];
	[super dealloc];
}

- (void)cancel {
	[con cancel];
}

- (id)initWithRequest:(NSURLRequest *)req 
			directory:(NSString *)dir 
			 delegate:(id<URLDownloadDeleagte, NSObject>)dg 
{
	if (self = [super init]) {
		request = [req retain];
		directoryPath = [dir retain];
		delegate = [dg retain];
		
		con = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	}
	return self;
}

// NSURLConnection delegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	filePath = [[response suggestedFilename] retain];
	if ([delegate respondsToSelector:@selector(download: didReceiveResponse:)])
		[delegate download:self didReceiveResponse:response];
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	AzLOG(@"%@", [error localizedDescription]);
	if ([delegate respondsToSelector:@selector(download: didFailWithError:)])
		[delegate download:self didFailWithError:error];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	@try {
		if (file == nil) {
			NSFileManager *fm = [NSFileManager defaultManager];
/* 保存フォルダ名
 .../Document 固定につき不要 
			BOOL isDir;
			if (![fm fileExistsAtPath:directoryPath isDirectory:&isDir]) {
				// フォルダが無いので作る
				NSError *error;
				if (![fm createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:&error]) {
					// フォルダが作れない
					AzLOG([error localizedDescription]);
					AzLOG([error localizedFailureReason]);
					AzLOG([error localizedRecoverySuggestion]);
					[NSException raise:@"Exception" format:[error localizedDescription]];
				}
			} else if (!isDir) {
				// 作ろうとしたフォルダ名と同じファイル名が存在している
				[NSException raise:@"Exception" format:@"Failed to create directory at %@, because there is a file already.", directoryPath];
			}
*/
/* 保存ファイル名
 "AzPack.csv" 固定
			NSString *tmpFilePath = [[directoryPath stringByAppendingPathComponent:filePath] 
									 stringByStandardizingPath];
			int suffix = 0;
			while ([fm fileExistsAtPath:tmpFilePath]) {
				suffix++;
				tmpFilePath = [[directoryPath stringByAppendingPathComponent:
								[NSString stringWithFormat:@"%@%d", filePath, suffix]] 
							   stringByStandardizingPath];
			}
*/
			NSString *tmpFilePath = [[directoryPath stringByAppendingPathComponent:@"AzPack.csv"] 
									 stringByStandardizingPath];
			if ([fm fileExistsAtPath:tmpFilePath]) {
				// 既存の"AzPack.csv"あれば削除する
				NSError *error;
				[fm removeItemAtPath:tmpFilePath error:&error];
			}
			[fm createFileAtPath:tmpFilePath contents:[NSData data] attributes:nil];
			[filePath release];
			filePath = [tmpFilePath retain];
			
			file = [[NSFileHandle fileHandleForWritingAtPath:filePath] retain];
		}
		[file writeData:data];
		if ([delegate respondsToSelector:@selector(download: didReceiveDataOfLength:)]) {
			if ([delegate download:self didReceiveDataOfLength:[data length]] == NO) {
				// CANCEL (masa)
				[connection cancel];
				[delegate download:self didCancelBecauseOf:nil];
			}
		}
	}
	@catch (NSException * e) {
		AzLOG(@"%@", [e reason]);
		[connection cancel];
		[delegate download:self didCancelBecauseOf:e];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[delegate downloadDidFinish:self];
}
/*
 
 - (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
 - (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
 - (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse;
 - (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse;
 */

@end