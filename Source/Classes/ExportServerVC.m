    //
//  ExportServerVC.m
//  AzPacking-0.4
//
//  Created by 松山 和正 on 10/04/01.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

//  setContentToHTMLString  は非公開APIなので使用禁止です。
//  setContentToHTMLString  は非公開APIなので使用禁止です。
//  setContentToHTMLString  は非公開APIなので使用禁止です。

#import "Global.h"
#import "ExportServerVC.h"

#include <ifaddrs.h>
#include <arpa/inet.h> 

#define DOCUMENTS_FOLDER [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]
#define PICS_FOLDER [NSHomeDirectory() stringByAppendingPathComponent:@"../../Media/DCIM/100APPLE/"]

/*
@interface UITextView (extended)
//- (void)setContentToHTMLString:(NSString *) contentText; 非公開APIなので使用禁止
@end
*/
@interface NSDate (extended)
-(NSDate *) dateWithCalendarFormat:(NSString *)format timeZone: (NSTimeZone *) timeZone;
@end
/*
@interface ExportServerVC (PrivateMethods)
- (NSString *)getIPAddress;
@end
*/
@implementation ExportServerVC

static ExportServerVC *sharedInstance = nil;

+(ExportServerVC *) sharedInstance {
    if(!sharedInstance) {
		sharedInstance = [[self alloc] init];
    }
    return sharedInstance;
}


/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

- (ExportServerVC *) init
{
	if (!(self = [super init])) return self;
	self.title = @"Export Server";
	serverStatus = STATUS_OFFLINE;
	return self;
}

// Return the hostname.local address for the iPhone
- (NSString *) localAddress
{
	char baseHostName[255];
	gethostname(baseHostName, 255);
	
	// The simulator has the .local suffix already so check if one is there and add one if it is not
	NSString *hn = [NSString stringWithCString:baseHostName encoding:NSASCIIStringEncoding];
	return [NSString stringWithFormat:@"http://%@%@:%d", hn, [hn hasSuffix:@".local"] ? @"" : @".local", chosenPort];
}

/*
 - (NSString *) getIPAddress 
{ 
	NSString *address = @"error"; 
	struct ifaddrs *interfaces = NULL; 
	struct ifaddrs *temp_addr = NULL; 
	int success = 0; 
	success = getifaddrs(&interfaces); 
	if (success == 0) { 
		temp_addr = interfaces; 
		while(temp_addr != NULL) { 
			if(temp_addr->ifa_addr->sa_family == AF_INET) { 
				if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) { 
					address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)]; 
				} 
			} 
			temp_addr = temp_addr->ifa_next; 
		} 
	} 
	freeifaddrs(interfaces); 
	return address; 
} 
*/

// Return the iPhone's IP address
- (NSString *) localIPAddress
{
/*	char baseHostName[255];
	gethostname(baseHostName, 255);
	
	char hn[255];
	sprintf(hn, "%s.local", baseHostName);
	struct hostent *host = gethostbyname(hn);  // gethostbynameが非常に遅い！
    if (host == NULL)
	{
        herror("resolv");
		return NULL;
	}
    else {
        struct in_addr **list = (struct in_addr **)host->h_addr_list;
        return [NSString stringWithFormat:@"http://%@:%d", 
				[NSString stringWithCString:inet_ntoa(*list[0])  encoding:NSASCIIStringEncoding],
				chosenPort];
    }
	return NULL;　*/

	NSString *address = @"error"; 
	struct ifaddrs *interfaces = NULL; 
	struct ifaddrs *temp_addr = NULL; 
	int success = 0; 
	success = getifaddrs(&interfaces); 
	if (success == 0) { 
		temp_addr = interfaces; 
		while(temp_addr != NULL) { 
			if(temp_addr->ifa_addr->sa_family == AF_INET) { 
				if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) { 
					address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)]; 
				} 
			} 
			temp_addr = temp_addr->ifa_next; 
		} 
	} 
	freeifaddrs(interfaces); 
	return [NSString stringWithFormat:@"http://%@:%d", address, chosenPort];
}

/*
 // Return the full host address
- (NSString *) hostAddy
{
	return [NSString stringWithFormat:@"http://%@:%d/", [self localIPAddress], chosenPort];
}*/

/*
- (NSString *) createindex
{
	// Return a custom Index.html populated with camera roll images
	NSArray *array = [[[NSFileManager defaultManager] directoryContentsAtPath:PICS_FOLDER]
					  pathsMatchingExtensions:[NSArray arrayWithObject:@"JPG"]];
	
	char baseHostName[255];
	gethostname(baseHostName, 255);
	NSString *hostname = [NSString stringWithCString:baseHostName  encoding:NSASCIIStringEncoding];
	
	NSMutableString *outdata = [[NSMutableString alloc] init];
	[outdata appendString:@"<style>html {background-color:#eeeeee} body { background-color:#FFFFFF; font-family:Tahoma,Arial,Helvetica,sans-serif; font-size:18x; margin-left:15%; margin-right:15%; border:3px groove #006600; padding:15px; } </style>"];
	[outdata appendFormat:@"<h1>Pictures from %@</h1>", hostname];
	[outdata appendString:@"<bq>The following images are hosted live from the iPhone's DCIM folder.</bq"];

	[outdata appendString:@"<p>"];
	for (NSString *fname in array)
	{
		NSDictionary *picDict = [[NSFileManager defaultManager] fileAttributesAtPath:[PICS_FOLDER stringByAppendingPathComponent:fname] traverseLink:NO];
		NSString *modDate = [[[picDict objectForKey:NSFileModificationDate] dateWithCalendarFormat:@"%Y-%m-%d at %H:%M:%S" timeZone:nil] description];
		[outdata appendFormat:@"* <a href=\"%@\">%@</a> [%8d bytes, %@]<br />\n", fname, fname, [picDict objectForKey:NSFileSize], modDate];
	}
	[outdata appendString:@"</p>"];
	[array release];
	
	return [outdata autorelease];
}
*/

// Expand this mime lookup method if you want to host other file types
- (NSString *) mimeForExt: (NSString *) ext
{
	NSString *uc = [ext uppercaseString];
//	if ([uc isEqualToString:@"JPG"]) return @"image/jpeg";
//	if ([uc isEqualToString:@"HTM"]) return @"text/html";
//	if ([uc isEqualToString:@"HTML"]) return @"text/html";
	if ([uc isEqualToString:@"CSV"]) return @"text/csv";
	return NULL;
}

// Serve files to GET requests
- (void) handleWebRequest:(NSNumber *)fdNum
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	int fd = [fdNum intValue];
	static char buffer[BUFSIZE+1];
	
	int len = read(fd, buffer, BUFSIZE); 	
	buffer[len] = '\0';
	
	NSString *request = [NSString stringWithCString:buffer  encoding:NSASCIIStringEncoding];
	NSArray *reqs = [request componentsSeparatedByString:@"\n"];
	NSString *getreq = [[reqs objectAtIndex:0] substringFromIndex:4];
	NSRange range = [getreq rangeOfString:@"HTTP/"];
	if (range.location == NSNotFound)
	{
		printf("Error: GET request was improperly formed\n");
		close(fd);
		return;
	}
	
	NSString *filereq = [[getreq substringToIndex:range.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	if ([filereq isEqualToString:@"/"]) 
	{
		NSString *outcontent = [NSString stringWithFormat:@"HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n"];
		write(fd, [outcontent UTF8String], [outcontent length]);
		
//		NSString *outdata = [self createindex];
//		write(fd, [outdata UTF8String], [outdata length]);
		NSMutableString *outdata = [[NSMutableString alloc] init];
		[outdata appendString:@"<p>"];
		[outdata appendFormat:@"* <a href=\"%@\">%@</a> <br />\n", GD_CSVFILENAME, GD_CSVFILENAME];
		[outdata appendString:@"</p>"];
		write(fd, [outdata UTF8String], [outdata length]);
		[outdata release];
		
		close(fd);
		return;
	}
	
	
	NSString *mime = [self mimeForExt:[filereq pathExtension]];
	if (!mime)
	{
		printf("Error: recovering mime type.\n");
		NSString *outcontent = [NSString stringWithFormat:@"HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n"];
		write (fd, [outcontent UTF8String], [outcontent length]);
		outcontent = NSLocalizedString(@"Sorry. This file type is not supported",nil);
		write (fd, [outcontent UTF8String], [outcontent length]);
		close(fd);
		return;
	}
	
//	filereq = [filereq stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//	NSString *fullpath = [PICS_FOLDER stringByAppendingString:filereq];
	NSString *fullpath = [PICS_FOLDER stringByAppendingString:GD_CSVFILENAME];
	AzLOG(@"fullpath=%@", fullpath);
	NSData *data = [NSData dataWithContentsOfFile:fullpath];
	
	if (!data || (![[NSFileManager defaultManager] fileExistsAtPath:fullpath]))
	{
		printf("Error: file not found.\n");
		NSString *outcontent = [NSString stringWithFormat:@"HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n"];
		write (fd, [outcontent UTF8String], [outcontent length]);
		outcontent = NSLocalizedString(@"Sorry. File not found",nil);//@"<p>Sorry. File not found.</p>\n";
		write (fd, [outcontent UTF8String], [outcontent length]);
		close(fd);
		return;
	}
	
	printf("%d bytes read from file\n", [data length]);
	NSString *outcontent = [NSString stringWithFormat:@"HTTP/1.0 200 OK\r\nContent-Type: %@\r\n\r\n", mime];
	write (fd, [outcontent UTF8String], [outcontent length]);
	write(fd, [data bytes], [data length]);
	close(fd);
	
	[pool release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != 0) return; 
	// CANCEL
	[self stopService];
}

// Begin serving data -- this is a private method called by startService
- (void) startServer
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	int socketfd;
	socklen_t length;
	static struct sockaddr_in cli_addr; 
	static struct sockaddr_in serv_addr;
	
	// Set up socket
	if((listenfd = socket(AF_INET, SOCK_STREAM,0)) <0)	
	{
		isServing = NO;
		return;
	}
	
    // Serve to a random port
	serv_addr.sin_family = AF_INET;
	serv_addr.sin_addr.s_addr = htonl(INADDR_ANY);
	serv_addr.sin_port = 0;
	
	// Bind
	if(bind(listenfd, (struct sockaddr *)&serv_addr,sizeof(serv_addr)) <0)	
	{
		isServing = NO;
		return;
	}
	
	// Find out what port number was chosen.
	int namelen = sizeof(serv_addr);
	if (getsockname(listenfd, (struct sockaddr *)&serv_addr, (void *) &namelen) < 0) {
		close(listenfd);
		isServing = NO;
		return;
	}
	chosenPort = ntohs(serv_addr.sin_port);
	
	// Listen
	if(listen(listenfd, 64) < 0)	
	{
		isServing = NO;
		return;
	} 
	
	// Service has now succesfully started
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
											   initWithTitle:NSLocalizedString(@"Stop Service",nil) 
											   style:UIBarButtonItemStylePlain 
											   target:self 
											   action:@selector(stopService)] autorelease];


/*	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Web Service" 
													 message:@"" 
													delegate:self 
										   cancelButtonTitle:@"STOP" 
										   otherButtonTitles:nil] autorelease];
	[alert show];*/
	
	
	
	// Respond to requests until the service shuts down
	while (1 > 0) {
		length = sizeof(cli_addr);
		if((socketfd = accept(listenfd, (struct sockaddr *)&cli_addr, &length)) < 0)
		{
			isServing = NO;
			return;
		}
		[self handleWebRequest:[NSNumber numberWithInt:socketfd]];
	}
	
	[pool release];
}

//  setContentToHTMLString  は非公開APIなので使用禁止です。
//  setContentToHTMLString  は非公開APIなので使用禁止です。
//  setContentToHTMLString  は非公開APIなので使用禁止です。

/*- (void) serviceWasEstablished	// 既にあるサービス
{
	[(UITextView *)self.view setContentToHTMLString:
				[NSString stringWithFormat:NSLocalizedString(@"HTML Success",nil),
				 [self localAddress] ? [self localAddress ]: @"", 
				 [self localIPAddress] ? [self localIPAddress] : @"" ]];
}*/

/*- (void) couldNotEstablishService
{
	[(UITextView *)self.view setContentToHTMLString:@"<h2>Service could not be established</h2><p>This application could not establish the HTTP server at this time. Please try again later.</p><br /><br />"];
}*/

/*- (void) serviceReattempt
{
	[(UITextView *)self.view setContentToHTMLString:@"<h2>Reattempting to Establish Service</h2><p>The last attempt to establish service failed. Retrying in 3 seconds.</p><br /><br />"];
}*/

/*- (void) tryingToEstablishService
{
	[(UITextView *)self.view setContentToHTMLString:@"<h2>Attempting to Establish Service</h2><p>Please wait.</p><br /><br />"];
}*/

/*- (void) stoppingService
{
	[(UITextView *)self.view setContentToHTMLString:@"<h2>You stopped service.</h2><p>The HTTP server is no longer active.</p><br /><br />"];
}*/

/*- (void) youCanStartService
{
	[(UITextView *)self.view setContentToHTMLString:@"<h2>Web Server</h2><p>Press <b>Start Service</b> to begin serving files from your iPhone to web browsers on your local network.</p><br /><br/>"];
}*/


// The clock ticks every three seconds to try and establish service until
// exceeding the maximum number of tries set by MAXTRIES
- (void) tick: (NSTimer *) timer
{
	if (isServing) // success!
	{
		[timer invalidate];

/*		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
												   initWithTitle:NSLocalizedString(@"Stop Service",nil)
												   style:UIBarButtonItemStylePlain 
												   target:self 
												   action:@selector(stopService)] autorelease];
		[self serviceWasEstablished]; */

		//NSString *msg1 = [self localAddress];
		NSString *msg2 = [self localIPAddress];

		NSString *msg = [NSString stringWithFormat:@"PCブラウザから下記URLへ\nアクセスしてください。\n%@\n",msg2];

		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Backup" 
														 message:msg
														delegate:self 
											   cancelButtonTitle:@"STOP" 
											   otherButtonTitles:nil] autorelease];
		[alert show];
		return;
	}
	
	ntries++;
	
	if (ntries >= MAXTRIES)
	{
		[timer invalidate];
//		[self couldNotEstablishService];
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
												   initWithTitle:NSLocalizedString(@"Start Service",nil) 
												   style:UIBarButtonItemStylePlain 
												   target:self 
												   action:@selector(startService)] autorelease];
		return;		
	}
	
//	[self serviceReattempt];
}

- (BOOL) isServing
{
	return isServing;
}

// Shut down service
- (void) stopService
{
	printf("Shutting down service\n");
	isServing = NO;
	close(listenfd);
//	[self stoppingService];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
											   initWithTitle:NSLocalizedString(@"Start Service",nil)
											   style:UIBarButtonItemStylePlain 
											   target:self 
											   action:@selector(startService)] autorelease];
}

// Start service
- (void) startService
{
	if (isServing)
	{
		printf("Error: Already Serving!\n");
		return;
	}
	
	isServing = NO;
	close(listenfd);
//	[self tryingToEstablishService];
	self.navigationItem.rightBarButtonItem = NULL;
	ntries = 0;
	isServing = YES;
	[NSThread detachNewThreadSelector:@selector(startServer) toTarget:self withObject:NULL];
    [NSTimer scheduledTimerWithTimeInterval: 3.0f
									 target: self
								   selector: @selector(tick:)
								   userInfo: nil
									repeats: YES];
}


// Build the simple interaction view
- (void)loadView
{
/*	UITextView *textView = [[[UITextView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]] autorelease];
	[textView setEditable:NO];
	self.view = textView;
	[self youCanStartService]; */
	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
											   initWithTitle:NSLocalizedString(@"Start Service",nil)
											   style:UIBarButtonItemStylePlain 
											   target:self 
											   action:@selector(startService)] autorelease];
	isServing = NO;
//	[self startService];
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

/*
- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}
*/

@end
