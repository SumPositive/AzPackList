//
//  AzPackCsv.h
//  AzPacking
//
//  Created by 松山 和正 on 10/01/28.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class E1;

@interface AzPackCsv : NSObject 
{
	NSManagedObjectContext *PmanagedObjectContext;
	// WRITE only
	E1 *Pe1selected;		// SAVEするE1　　　　　(nil)ならばREAD
	// READ only
	NSInteger Pe1rows;  // 行数⇒新規追加.row になる　　(-1)ならばWRITE
	
@private
	
}

@property (nonatomic, retain) NSManagedObjectContext *PmanagedObjectContext;
@property (nonatomic, retain) E1 *Pe1selected;
@property NSInteger Pe1rows;

- (NSString *)csvWrite;		// managedObjectContext を AzPack.csv へ書き込む（常に上書き）
- (NSString *)csvRead;		// AzPack.csv を managedObjectContext へ読み込む

@end
