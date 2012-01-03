#import <Foundation/Foundation.h>

@class AsyncSocket;


@interface HTTPServer : NSObject <NSNetServiceDelegate> // FIXME: iOS4
{
	// Underlying asynchronous TCP/IP socket
	AsyncSocket *asyncSocket;
	
	// Standard delegate
	id delegate;
	
	// HTTP server configuration
	NSURL *documentRoot;
	Class connectionClass;
	BOOL	bBackup;		//(MASA) =YES:BACKUP  =NO:RESTORE
	
	// NSNetService and related variables
	NSNetService *netService;
	NSString *domain;
	NSString *type;
	NSString *name;
	UInt16 port;
	NSDictionary *txtRecordDictionary;
	
	NSMutableArray *connections;
	
	// AzPacking FileCsv
	NSString *planName;
	NSManagedObjectContext *PmanagedObjectContext;
	NSInteger PiAddRow;
}

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

- (NSURL *)documentRoot;
- (void)setDocumentRoot:(NSURL *)value;

- (Class)connectionClass;
- (void)setConnectionClass:(Class)value;

- (NSString *)domain;
- (void)setDomain:(NSString *)value;

- (NSString *)type;
- (void)setType:(NSString *)value;

- (NSString *)name;
- (NSString *)publishedName;
- (void)setName:(NSString *)value;

- (BOOL)bBackup;
- (void)setBackup:(BOOL)value;

- (UInt16)port;
- (void)setPort:(UInt16)value;

- (NSDictionary *)TXTRecordDictionary;
- (void)setTXTRecordDictionary:(NSDictionary *)dict;

- (BOOL)start:(NSError **)error;
- (BOOL)stop;

- (uint)numberOfHTTPConnections;

// AzPacking FileCsv
- (NSString *)planName;
- (void)setPlanName:(NSString *)value;

- (NSManagedObjectContext *)PmanagedObjectContext;
- (void)setManagedObjectContext:(NSManagedObjectContext *)value;

- (NSInteger)PiAddRow;
- (void)setAddRow:(NSInteger)value;

@end
