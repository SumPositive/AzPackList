//
//  MocFunctions.h
//	AzBodyNote
//
//  Created by Sum Positive on 2011/10/01.
//  Copyright 2011 Sum Positive @Azukid.com. All rights reserved.
//
//  マルチＭＯＣ対応のため、インスタンスメソッドにした。

#import <Foundation/Foundation.h>

//#import "AppDelegate.h" この.hがAppDelegate.hに#importされるため不適切
#import "Global.h"
#import "Elements.h"


#define CoreData_iCloud_SYNC		NO			// YES or NO


@interface MocFunctions : NSObject 
{
@private
	NSManagedObjectContext				*mContext;
	NSManagedObjectModel				*mCoreModel;
	NSPersistentStoreCoordinator		*mCorePsc;
}

// ＋ クラスメソッド
+ (MocFunctions *)sharedMocFunctions;

// − インスタンスメソッド
- (void)initialize;
//- (void)setMoc:(NSManagedObjectContext *)moc;
- (NSManagedObjectContext*)getMoc;
- (id)insertAutoEntity:(NSString *)zEntityName;
- (void)deleteEntity:(NSManagedObject *)entity;
- (BOOL)hasChanges;
- (BOOL)commit;
- (void)rollBack;
- (void)stopRelease;

- (NSArray *)select:(NSString *)zEntity
			  limit:(NSUInteger)iLimit
			 offset:(NSUInteger)iOffset
			  where:(NSPredicate *)predicate
			   sort:(NSArray *)arSort;

- (void)deleteAllCoreData;

- (NSDictionary*)dictionaryObject:(NSManagedObject*)mobj;
- (NSManagedObject*)insertNewObjectForDictionary:(NSDictionary*)dict;

// PackList Original
- (NSInteger)E1_maxRow;

- (void)iCloudAllClear;


@end
