

このAPI名（download）をそのまま使うと申請拒否されるようになりました。
2010-11-07 Appleからの拒絶メール「モチメモ 0.7」参照
「モチメモ 0.7」からは、URLDownloadを使用しなくなったので除外した。


//
//  URLDownload.h
//
//  Created by 松山 和正 on 10/01/03.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class URLDownload;

@protocol URLDownloadDeleagte
- (void)downloadDidFinish:(URLDownload *)download;
- (void)download:(URLDownload *)download didCancelBecauseOf:(NSException *)exception;
- (void)download:(URLDownload *)download didFailWithError:(NSError *)error;
@optional
- (BOOL)download:(URLDownload *)download didReceiveDataOfLength:(NSUInteger)length; // Cancel実装
- (void)download:(URLDownload *)download didReceiveResponse:(NSURLResponse *)response;

@end

@interface URLDownload : NSObject {
	id <URLDownloadDeleagte, NSObject> delegate;
	NSString *directoryPath;
	NSString *filePath;
	NSURLRequest *request;
	NSFileHandle *file;
	NSURLConnection *con;
}
@property(readonly) NSString *filePath;

- (id)initWithRequest:(NSURLRequest *)req directory:(NSString *)dir delegate:(id<URLDownloadDeleagte, NSObject>)dg;
- (void)dealloc;
- (void)cancel;

// NSURLConnection delegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
//- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
//- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
//- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse;
//- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse;

@end