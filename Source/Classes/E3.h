//
//  E3.h
//  iPack E3 Item Level
//
//  Created by 松山 和正 on 09/12/06.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

//#import <Foundation/Foundation.h>

@class E2;

@interface E3 : NSManagedObject {
}
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *note;
@property (nonatomic, retain) NSString *spec;
@property (nonatomic, retain) NSNumber *amount;
@property (nonatomic, retain) NSNumber *number;
@property (nonatomic, retain) NSNumber *price;
@property (nonatomic, retain) NSNumber *weight;
@property (nonatomic, retain) E2 *parent;
@end
