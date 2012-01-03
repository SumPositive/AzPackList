//
//  ExportServerVC.h
//  AzPacking-0.4
//
//  Created by 松山 和正 on 10/04/01.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <fcntl.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>

#define BUFSIZE 8096

#define STATUS_OFFLINE	0
#define STATUS_ATTEMPT	1
#define STATUS_ONLINE	2

#define	MAXTRIES		5

@interface ExportServerVC : NSObject {
	int				serverStatus;
	BOOL			isServing;
	int				listenfd;
	int				ntries;
	int				chosenPort;
}
+ (ExportServerVC *) sharedInstance;
- (void) stopService;
- (BOOL) isServing;
@end
