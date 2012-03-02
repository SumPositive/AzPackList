//
//  Elements.h
//  iPack E1 Title Level
//
//  Created by 松山 和正 on 09/12/03.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define AzDataModelVersion	3

//---------------------------------------------------------------------------------------E4photo	//5//
// E1,2,3が重くならないように分離した。　これは、CSV保存しない。参照時にphotoUrlよりダウンロード生成する。
@interface E4photo : NSManagedObject
	@property (nonatomic, retain) NSData			*photoData;		//5//
@end
#define PHOTO_URL_UUID_PRIFIX			@"PackList:"

//---------------------------------------------------------------------------------------E1
@interface E1 : NSManagedObject
	@property (nonatomic, retain) NSNumber	*row;
	@property (nonatomic, retain) NSString		*name;
	@property (nonatomic, retain) NSString		*note;
	@property (nonatomic, retain) NSNumber	*sumNoGray;		// Data Model Version.3
	@property (nonatomic, retain) NSNumber	*sumNoCheck;	// Data Model Version.2
	@property (nonatomic, retain) NSNumber	*sumWeightStk;
	@property (nonatomic, retain) NSNumber	*sumWeightNed;
	@property (nonatomic, retain) NSSet			*childs;				// E1-->> E2
@end

// coalesce these into one @interface E1 (CoreDataGeneratedAccessors) section
@interface E1 (CoreDataGeneratedAccessors)
	- (void)addChildsObject:(NSManagedObject *)value;
	- (void)removeChildsObject:(NSManagedObject *)value;
	- (void)addChilds:(NSSet *)value;
	- (void)removeChilds:(NSSet *)value;
@end

//---------------------------------------------------------------------------------------E2
@interface E2 : NSManagedObject
	@property (nonatomic, retain) NSNumber	*row;
	@property (nonatomic, retain) NSString		*name;
	@property (nonatomic, retain) NSString		*note;
	@property (nonatomic, retain) NSNumber	*sumNoGray;		// Data Model Version.3
	@property (nonatomic, retain) NSNumber	*sumNoCheck;		// Data Model Version.2
	@property (nonatomic, retain) NSNumber	*sumWeightStk;
	@property (nonatomic, retain) NSNumber	*sumWeightNed;
	@property (nonatomic, retain) E1					*parent;				// E2----> E1
	@property (nonatomic, retain) NSSet			*childs;				// E2-->> E3
@end

// coalesce these into one @interface E2 (CoreDataGeneratedAccessors) section
@interface E2 (CoreDataGeneratedAccessors)
	- (void)addChildsObject:(NSManagedObject *)value;
	- (void)removeChildsObject:(NSManagedObject *)value;
	- (void)addChilds:(NSSet *)value;
	- (void)removeChilds:(NSSet *)value;
@end

//---------------------------------------------------------------------------------------E3
// 変更した場合は、E3viewController:paste:を確認すること。
@interface E3 : NSManagedObject
	@property (nonatomic, retain) NSNumber	*row;
	@property (nonatomic, retain) NSString		*name;
	@property (nonatomic, retain) NSString		*note;
	@property (nonatomic, retain) NSNumber	*stock;		// 在庫数
	@property (nonatomic, retain) NSNumber	*need;		// 必要数
	@property (nonatomic, retain) NSNumber	*lack;		// 不足数
	@property (nonatomic, retain) NSNumber	*noGray;		// Data Model Version.3
	@property (nonatomic, retain) NSNumber	*noCheck;	// Data Model Version.2
	@property (nonatomic, retain) NSNumber	*weight;
	@property (nonatomic, retain) NSNumber	*weightStk;
	@property (nonatomic, retain) NSNumber	*weightNed;
	@property (nonatomic, retain) NSNumber	*weightLack;
	@property (nonatomic, retain) NSString		*shopKeyword;	//4//[1.1]Shopping
	@property (nonatomic, retain) NSString		*shopNote;			//4//未使用
	@property (nonatomic, retain) NSString		*photoUrl;			//5//
	@property (nonatomic, retain) E2					*parent;				// E3---> E2
	@property (nonatomic, retain) E4photo		*e4photo;			//5// E3----> E4photo <Delete Cascade>
@end

// END
