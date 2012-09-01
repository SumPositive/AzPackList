//
//  EntityRelation.h
//  AzPacking 0.4
//
//  Created by 松山 和正 on 10/03/15.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

//NSManagedObjectContext *managedObjectContext();

@interface EntityRelation : NSObject 

// クラスメソッド（グローバル関数）
+ (void)setMoc:(NSManagedObjectContext*)moc;
+ (NSManagedObjectContext*)getMoc;
+ (void)commit;
+ (void)rollBack;
+ (void)reset;
+ (NSInteger)E1_maxRow;

@end
