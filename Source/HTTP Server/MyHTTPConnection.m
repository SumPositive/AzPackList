//
//  This class was created by Nonnus,
//  who graciously decided to share it with the CocoaHTTPServer community.
//

#import <UIKit/UIKit.h>  // NSLocalizedString()のため
#import "Global.h"
#import "MyHTTPConnection.h"
#import "HTTPServer.h"
#import "HTTPResponse.h"
#import "AsyncSocket.h"
#import "FileCsv.h"

@implementation MyHTTPConnection

- (void)dealloc  //[1.0.0]Leak対策
{
	[multipartData release], multipartData = nil; //[1.0.0]Leak対策
	[super dealloc];
}


/**
 * Returns whether or not the requested resource is browseable.
**/
- (BOOL)isBrowseable:(NSString *)path
{
	// Override me to provide custom configuration...
	// You can configure it for the entire server, or based on the current request
	
	return YES;
}


/**
 * This method creates a html browseable page.
 * Customize to fit your needs
**/
- (NSString *)createBrowseableIndex:(NSString *)path
{
    //NSArray *array = [[NSFileManager defaultManager] directoryContentsAtPath:path];
    NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:path];
    
    NSMutableString *outdata = [NSMutableString new];
	[outdata appendString:@"<html><head>"];
	// <meta http-equiv="Content-Type" content="text/html; charset=Shift_JIS">
	[outdata appendString:@"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">"];
	[outdata appendFormat:@"<title>PackList Service %@</title>", server.name];
	[outdata appendString:@"<style>html {background-color:#eeeeee} body { background-color:#FFFFFF; font-family:Tahoma,Arial,Helvetica,sans-serif; font-size:18x; margin-left:15%; margin-right:15%; border:3px groove #006600; padding:15px; } </style>"];
	[outdata appendString:@"</head><body>"];

	if (server.bBackup) 
	{	// BACKUP Mode
		[outdata appendString:NSLocalizedString(@"HTML Backup1",nil)];
		[outdata appendString:NSLocalizedString(@"HTML Backup2",nil)];
		[outdata appendString:@"<p>"];
		//	[outdata appendFormat:@"<a href=\"..\">..</a><br />\n"];
		//for (NSString *fname in array)
		NSString *fname;
		while ((fname = [dirEnum nextObject]))
		{
			//NSDictionary *fileDict = [[NSFileManager defaultManager] fileAttributesAtPath:[path stringByAppendingPathComponent:fname] traverseLink:NO];
			//if ([[fileDict objectForKey:NSFileType] isEqualToString: @"NSFileTypeDirectory"]) {
			//	// Directory表示しない
			//	// fname = [fname stringByAppendingString:@"/"];
			//} 
			//else 
			if ([fname isEqualToString:GD_CSVFILENAME4]) {
				NSError *error = nil;
				NSDictionary *fileDict = [[NSFileManager defaultManager] attributesOfItemAtPath:[path stringByAppendingPathComponent:fname] error:&error];
				[outdata appendFormat:NSLocalizedString(@"HTML Backup3",nil), 
						fname, server.planName, fname, [[fileDict objectForKey:NSFileSize] floatValue] / 1024];
			}
		}
		[outdata appendString:@"</p><br/>"];
		[outdata appendString:NSLocalizedString(@"HTML Backup4",nil)];
		[outdata appendString:NSLocalizedString(@"HTML Backup5",nil)];
	}
	else
	{	// RESTORE Mode
		[outdata appendString:NSLocalizedString(@"HTML Restore1",nil)];
		[outdata appendString:NSLocalizedString(@"HTML Restore2",nil)];
		if ([self supportsPOST:path withSize:0])
		{
			[outdata appendString:@"<form action=\"\" method=\"post\" enctype=\"multipart/form-data\" name=\"form1\" id=\"form1\" target=\"_self\">"];
			[outdata appendString:@"<label>"];
			[outdata appendString:@"<input type=\"file\" name=\"file\" id=\"file\" />"];
			[outdata appendString:@"</label>"];
			[outdata appendString:@"<label>"];
			//[outdata appendString:@"<input type=\"submit\" name=\"button\" id=\"button\" value=\"Submit\" />"];
			[outdata appendFormat:@"<input type=\"submit\" name=\"button\" id=\"button\" value=\"%@\" />", 
																		NSLocalizedString(@"Submit",nil)];
			[outdata appendString:@"</label>"];
			[outdata appendString:@"</form>"];
		}
	}
	
#if TARGET_OS_IPHONE
#else
	[outdata appendString:@"<br><bq>＊ERROR＊ No define TARGET_OS_IPHONE</bq>"];
#endif

	[outdata appendString:@"</body></html>"];
    
	//NSLog(@"outData: %@", outdata);
    return [outdata autorelease];
}

// POST 成功
- (NSString *)postResponseOK
{
    NSMutableString *outdata = [NSMutableString new];

	[outdata appendString:@"<html><head>"];
	// <meta http-equiv="Content-Type" content="text/html; charset=Shift_JIS">
	[outdata appendString:@"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">"];
	[outdata appendFormat:@"<title>PackList Service %@</title>", server.name];
	[outdata appendString:@"<style>html {background-color:#eeeeee} body { background-color:#FFFFFF; font-family:Tahoma,Arial,Helvetica,sans-serif; font-size:18x; margin-left:15%; margin-right:15%; border:3px groove #006600; padding:15px; } </style>"];
	[outdata appendString:@"</head><body>"];
	
	[outdata appendString:NSLocalizedString(@"HTML Restore1",nil)];
	[outdata appendString:NSLocalizedString(@"HTML RestoreOK1",nil)];
	[outdata appendString:NSLocalizedString(@"HTML RestoreOK2",nil)];
	[outdata appendString:@"</body></html>"];
    
	//NSLog(@"outData: %@", outdata);
    return [outdata autorelease];
}

// POST 失敗
- (NSString *)postResponseNG:(NSString *)zError
{
    NSMutableString *outdata = [NSMutableString new];
	
	[outdata appendString:@"<html><head>"];
	// <meta http-equiv="Content-Type" content="text/html; charset=Shift_JIS">
	[outdata appendString:@"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">"];
	[outdata appendFormat:@"<title>PackList Service %@</title>", server.name];
	[outdata appendString:@"<style>html {background-color:#eeeeee} body { background-color:#FFFFFF; font-family:Tahoma,Arial,Helvetica,sans-serif; font-size:18x; margin-left:15%; margin-right:15%; border:3px groove #006600; padding:15px; } </style>"];
	[outdata appendString:@"</head><body>"];
	
	[outdata appendString:NSLocalizedString(@"HTML Restore1",nil)];
	[outdata appendString:NSLocalizedString(@"HTML RestoreNG1",nil)];
	[outdata appendFormat:@"<bq>%@</bq>", zError];
	[outdata appendString:NSLocalizedString(@"HTML RestoreNG2",nil)];
	[outdata appendString:@"</body></html>"];
    
	//NSLog(@"outData: %@", outdata);
    return [outdata autorelease];
}



- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)relativePath
{
	if ([@"POST" isEqualToString:method])
	{
		return YES;
	}
	
	return [super supportsMethod:method atPath:relativePath];
}


/**
 * Returns whether or not the server will accept POSTs.
 * That is, whether the server will accept uploaded data for the given URI.
**/
- (BOOL)supportsPOST:(NSString *)path withSize:(UInt64)contentLength
{
//	NSLog(@"POST:%@", path);
	
	dataStartIndex = 0;		//チャンクリセット

	if (multipartData) {		//[1.0.0]Leak対策：ブラウザリロードする度に呼び出されることが解った。
		[multipartData release], multipartData = nil;
	}
	multipartData = [[NSMutableArray alloc] init];	//チャンクバッファ
	
	postHeaderOK = FALSE;
	
	return YES;
}


/**
 * This method is called to get a response for a request.
 * You may return any object that adopts the HTTPResponse protocol.
 * The HTTPServer comes with two such classes: HTTPFileResponse and HTTPDataResponse.
 * HTTPFileResponse is a wrapper for an NSFileHandle object, and is the preferred way to send a file response.
 * HTTPDataResopnse is a wrapper for an NSData object, and may be used to send a custom response.
**/
- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
	NSLog(@"httpResponseForURI: method:%@ path:%@", method, path);
	
	//NSData *requestData = [(NSData *)CFHTTPMessageCopySerializedMessage(request) autorelease];
	
	//NSString *requestStr = [[[NSString alloc] initWithData:requestData encoding:NSASCIIStringEncoding] autorelease];
	//NSLog(@"\n=== Request ====================\n%@\n================================", requestStr);
	
	if (requestContentLength > 0)  // Process POST data
	{
		//NSLog(@"processing post data: %i", requestContentLength);
		
		if ([multipartData count] < 2) return nil;
		
		NSString* postInfo = [[NSString alloc] initWithBytes:[[multipartData objectAtIndex:1] bytes]
													  length:[[multipartData objectAtIndex:1] length]
													encoding:NSUTF8StringEncoding];
		
		NSArray* postInfoComponents = [postInfo componentsSeparatedByString:@"; filename="];
		postInfoComponents = [[postInfoComponents lastObject] componentsSeparatedByString:@"\""];
		postInfoComponents = [[postInfoComponents objectAtIndex:1] componentsSeparatedByString:@"\\"];
		NSString* filename = [postInfoComponents lastObject];
		
		// This makes sure we did not submitted upload form without selecting file.
		if (![filename isEqualToString:@""] && [[filename lowercaseString] hasSuffix:@".csv"]) 
		{
			UInt16 separatorBytes = 0x0A0D;
			NSMutableData* separatorData = [NSMutableData dataWithBytes:&separatorBytes length:2];
			[separatorData appendData:[multipartData objectAtIndex:0]];
			int l = [separatorData length];
			int count = 2;	//number of times the separator shows up at the end of file data
			
			NSFileHandle* dataToTrim = [multipartData lastObject];
			NSLog(@"data: %@", dataToTrim);
			
			for (unsigned long long i = [dataToTrim offsetInFile] - l; i > 0; i--)
			{
				[dataToTrim seekToFileOffset:i];
				if ([[dataToTrim readDataOfLength:l] isEqualToData:separatorData])
				{
					[dataToTrim truncateFileAtOffset:i];
					i -= l;
					if (--count == 0) break;
				}
			}
			
			NSLog(@"NewFileUploaded");
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NewFileUploaded" object:nil];
		} 
		else {
			// ファイル名が "*.CSV" でない
			[postInfo release];
			[multipartData release], multipartData = nil;
			requestContentLength = 0;
			NSData *browseData = [[self postResponseNG:@"No! *.CSV file"] dataUsingEncoding:NSUTF8StringEncoding];
			return [[[HTTPDataResponse alloc] initWithData:browseData] autorelease];
		}
		
		//for (int n = 1; n < [multipartData count] - 1; n++)
		//	NSLog(@"%@", [[NSString alloc] initWithBytes:[[multipartData objectAtIndex:n] bytes] length:[[multipartData objectAtIndex:n] length] encoding:NSUTF8StringEncoding]);
		
		[postInfo release];
		[multipartData release], multipartData = nil;
		requestContentLength = 0;
		
		// ダウンロード成功
		// CSV読み込み
		FileCsv *fcsv = [[[FileCsv alloc] init] autorelease];
		BOOL bCsv = [fcsv zLoadTmpFile];
		if (bCsv==NO) {
			// CSV読み込み失敗
			NSString *errmsg = nil;
			int iNo = 1;
			for (NSString *msg in fcsv.errorMsgs) {
				errmsg = [errmsg stringByAppendingFormat:@"(%d) %@\n", iNo++, msg];
			}
			NSLog(@"FileCsv zLoad ERR: %@", errmsg);
			NSData *browseData = [[self postResponseNG:@"zLoad ERROR"] dataUsingEncoding:NSUTF8StringEncoding];
			return [[[HTTPDataResponse alloc] initWithData:browseData] autorelease];
		} else {
			// 続けてリストアするときのためインクリメントしておく
			[server setAddRow:server.PiAddRow + 1]; 
			// 成功メッセージを返す
			NSData *browseData = [[self postResponseOK] dataUsingEncoding:NSUTF8StringEncoding];
			return [[[HTTPDataResponse alloc] initWithData:browseData] autorelease];
		}
	}
	
	NSString *filePath = [self filePathForURI:path];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
	{
		return [[[HTTPFileResponse alloc] initWithFilePath:filePath] autorelease];
	}
	else
	{
		NSString *folder = [path isEqualToString:@"/"] ? [[server documentRoot] path] : [NSString stringWithFormat: @"%@%@", [[server documentRoot] path], path];
		if ([self isBrowseable:folder])
		{
			//NSLog(@"folder: %@", folder);
			NSData *browseData = [[self createBrowseableIndex:folder] dataUsingEncoding:NSUTF8StringEncoding];
			return [[[HTTPDataResponse alloc] initWithData:browseData] autorelease];
		}
	}
	
	return nil;
}


/**
 * This method is called to handle data read from a POST.
 * The given data is part of the POST body.
**/
- (void)processDataChunk:(NSData *)postDataChunk
{
	// Override me to do something useful with a POST.
	// If the post is small, such as a simple form, you may want to simply append the data to the request.
	// If the post is big, such as a file upload, you may want to store the file to disk.
	// 
	// Remember: In order to support LARGE POST uploads, the data is read in chunks.
	// This prevents a 50 MB upload from being stored in RAM.
	// The size of the chunks are limited by the POST_CHUNKSIZE definition.
	// Therefore, this method may be called multiple times for the same POST request.
	
	//NSLog(@"processPostDataChunk");
	
	if (!postHeaderOK)
	{
		UInt16 separatorBytes = 0x0A0D;
		NSData* separatorData = [NSData dataWithBytes:&separatorBytes length:2];
		
		int l = [separatorData length];

		for (int i = 0; i < [postDataChunk length] - l; i++)
		{
			NSRange searchRange = {i, l};

			if ([[postDataChunk subdataWithRange:searchRange] isEqualToData:separatorData])
			{
				NSRange newDataRange = {dataStartIndex, i - dataStartIndex};
				dataStartIndex = i + l;
				i += l - 1;
				NSData *newData = [postDataChunk subdataWithRange:newDataRange];

				if ([newData length])
				{
					[multipartData addObject:newData];
				}
				else
				{
					postHeaderOK = TRUE;
					
					if ([multipartData count] < 2) {
						AzLOG(@"ERR: [multipartData count] < 2");
						return;
					}
					//NSString* postInfo = [[NSString alloc] initWithBytes:[[multipartData objectAtIndex:1] bytes] length:[[multipartData objectAtIndex:1] length] encoding:NSUTF8StringEncoding];
					//NSArray* postInfoComponents = [postInfo componentsSeparatedByString:@"; filename="];
					//postInfoComponents = [[postInfoComponents lastObject] componentsSeparatedByString:@"\""];
					//postInfoComponents = [[postInfoComponents objectAtIndex:1] componentsSeparatedByString:@"\\"];
					//NSString* filename = [[[server documentRoot] path] stringByAppendingPathComponent:[postInfoComponents lastObject]];
					// ファイル名は常に GD_CSVFILENAME4 にする。
					NSString* filename = [[[server documentRoot] path] stringByAppendingPathComponent:GD_CSVFILENAME4];
					NSRange fileDataRange = {dataStartIndex, [postDataChunk length] - dataStartIndex};
					
					[[NSFileManager defaultManager] createFileAtPath:filename contents:[postDataChunk subdataWithRange:fileDataRange] attributes:nil];
					//NSFileHandle *file = [[NSFileHandle fileHandleForUpdatingAtPath:filename] retain];
					NSFileHandle *file = [NSFileHandle fileHandleForUpdatingAtPath:filename]; //retain];

					if (file)
					{
						[file seekToEndOfFile];
						[multipartData addObject:file];
					}
					
					//[postInfo release];
					
					break;
				}
			}
		}
	}
	else
	{
		[(NSFileHandle*)[multipartData lastObject] writeData:postDataChunk];
	}
}

@end