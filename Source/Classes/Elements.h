//
//  Elements.h
//  iPack E1 Title Level
//
//  Created by 松山 和正 on 09/12/03.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define AzDataModelVersion	3

//---------------------------------------------------------------------------------------E1
@interface E1 : NSManagedObject {
}
	@property (nonatomic, retain) NSNumber *row;
	@property (nonatomic, retain) NSString *name;
	@property (nonatomic, retain) NSString *note;
	@property (nonatomic, retain) NSNumber *sumNoGray;		// Data Model Version.3
	@property (nonatomic, retain) NSNumber *sumNoCheck;		// Data Model Version.2
	@property (nonatomic, retain) NSNumber *sumWeightStk;
	@property (nonatomic, retain) NSNumber *sumWeightNed;
	@property (nonatomic, retain) NSSet	   *childs;
@end

// coalesce these into one @interface E1 (CoreDataGeneratedAccessors) section
@interface E1 (CoreDataGeneratedAccessors)
	- (void)addChildsObject:(NSManagedObject *)value;
	- (void)removeChildsObject:(NSManagedObject *)value;
	- (void)addChilds:(NSSet *)value;
	- (void)removeChilds:(NSSet *)value;
@end

//---------------------------------------------------------------------------------------E2
@interface E2 : NSManagedObject {
}
	@property (nonatomic, retain) NSNumber *row;
	@property (nonatomic, retain) NSString *name;
	@property (nonatomic, retain) NSString *note;
	@property (nonatomic, retain) NSNumber *sumNoGray;		// Data Model Version.3
	@property (nonatomic, retain) NSNumber *sumNoCheck;		// Data Model Version.2
	@property (nonatomic, retain) NSNumber *sumWeightStk;
	@property (nonatomic, retain) NSNumber *sumWeightNed;
	@property (nonatomic, retain) E1 *parent;
	@property (nonatomic, retain) NSSet *childs;
@end

// coalesce these into one @interface E2 (CoreDataGeneratedAccessors) section
@interface E2 (CoreDataGeneratedAccessors)
	- (void)addChildsObject:(NSManagedObject *)value;
	- (void)removeChildsObject:(NSManagedObject *)value;
	- (void)addChilds:(NSSet *)value;
	- (void)removeChilds:(NSSet *)value;
@end

//---------------------------------------------------------------------------------------E3
@interface E3 : NSManagedObject {
}
	@property (nonatomic, retain) NSNumber *row;
	@property (nonatomic, retain) NSString *name;
	@property (nonatomic, retain) NSString *note;
	@property (nonatomic, retain) NSNumber *stock;		// 在庫数
	@property (nonatomic, retain) NSNumber *need;		// 必要数
	@property (nonatomic, retain) NSNumber *lack;		// 不足数
	@property (nonatomic, retain) NSNumber *noGray;		// Data Model Version.3
	@property (nonatomic, retain) NSNumber *noCheck;	// Data Model Version.2
	@property (nonatomic, retain) NSNumber *weight;
	@property (nonatomic, retain) NSNumber *weightStk;
	@property (nonatomic, retain) NSNumber *weightNed;
	@property (nonatomic, retain) NSNumber *weightLack;
	@property (nonatomic, retain) NSString		*shopKeyword;	//4//[1.1]Shopping
	@property (nonatomic, retain) NSString		*shopNote;			//4//未使用
	@property (nonatomic, retain) NSData			*image;				//4//未使用
	@property (nonatomic, retain) E2 *parent;
@end

// END
