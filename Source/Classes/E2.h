//
//  E2.h
//  iPack E2 Group Level
//
//  Created by 松山 和正 on 09/12/03.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

//#import <Foundation/Foundation.h>

@class E1;

@interface E2 : NSManagedObject {
}
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *note;
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

