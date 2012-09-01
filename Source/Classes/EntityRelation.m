//
//  EntityRelation.m
//  AzPacking 0.4
//
//  Created by 松山 和正 on 10/03/15.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
//--------------------------暫時、ManagedObjectContext操作関係をここへ集約する
//

#import "Global.h"
#import "AppDelegate.h"
#import "Elements.h"
#import "EntityRelation.h"


@implementation EntityRelation

static NSManagedObjectContext *scMoc_ = nil;

+ (void)setMoc:(NSManagedObjectContext*)moc
{
	scMoc_ = moc;
}

+ (NSManagedObjectContext*)getMoc
{
	assert(scMoc_);
	return scMoc_;
}

+ (void)commit
{
	assert(scMoc_);
	// SAVE
	NSError *err = nil;
	if (![scMoc_  save:&err]) {
		NSLog(@"MOC commit error %@, %@", err, [err userInfo]);
		//exit(-1);  // Fail
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"MOC CommitErr",nil)
														 message:NSLocalizedString(@"MOC CommitErrMsg",nil)
														delegate:nil 
											   cancelButtonTitle:nil 
											   otherButtonTitles:@"OK", nil];
		[alert show];
		return;
	}
}

+ (void)rollBack
{
	assert(scMoc_);
	// ROLLBACK
	[scMoc_ rollback]; // 前回のSAVE以降を取り消す
	[scMoc_ reset];
}

+ (void)reset
{	//NSManagedObject（メモリ上）がすべて開放される。Undo/Redo履歴もクリア
	assert(scMoc_);
	[scMoc_ reset];
}


+ (NSInteger)E1_maxRow
{
	assert(scMoc_);
	NSFetchRequest* request = [[NSFetchRequest alloc] init];

	// entity
	NSEntityDescription* entity = [NSEntityDescription entityForName:@"E1" inManagedObjectContext:scMoc_];
	[request setEntity:entity]; 
	
	// expression
	NSExpression *keyPathExpression = [NSExpression expressionForKeyPath:@"row"];
	NSExpression *expression = [NSExpression expressionForFunction:@"max:"
														 arguments:[NSArray arrayWithObject:keyPathExpression]];
	
	// expresssion description
	NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
	[expressionDescription setName:@"maxRow"];
	[expressionDescription setExpression:expression];
	[expressionDescription setExpressionResultType:NSInteger32AttributeType]; // row 属性データ型に一致させること
	
	// result properties
	[request setResultType:NSDictionaryResultType];
	[request setPropertiesToFetch:[NSArray arrayWithObject:expressionDescription]];
	
	// predicate  絞り込み条件
	//	NSPredicate* predicate = [NSPredicate predicateWithFormat:@"Author == %@", author];
	//	[request setPredicate:predicate];
	
	// execution
	NSError *error = nil;
	NSArray *array = [scMoc_ executeFetchRequest:request error:&error];
	NSInteger maxRow = 0;
	
	if (error) {
		NSLog(@"ERROR:E1_maxRow: %@", error);
	} else {
		maxRow = [[[array objectAtIndex:0] valueForKey:@"maxRow"] integerValue];
	}
	
	//[expressionDescription release];
	//[request release];
	return maxRow;
}


@end
