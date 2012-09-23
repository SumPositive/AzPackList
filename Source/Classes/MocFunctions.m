//
//  MocFunctions.m
//	AzBodyNote
//
//  Created by Sum Positive on 2011/10/01.
//  Copyright 2011 Sum Positive @Azukid.com. All rights reserved.
//
#import "MocFunctions.h"


@implementation MocFunctions

//static NSManagedObjectContext *scMoc = nil;

#pragma mark - ＋ クラスメソッド

static MocFunctions	*staticMocFunctions= nil;
+ (MocFunctions *)sharedMocFunctions 
{
	@synchronized(self)
	{	//シングルトン：selfに対する処理が、この間は別のスレッドから行えないようになる。
		if (staticMocFunctions==nil) {
			staticMocFunctions = [[MocFunctions alloc] init];
		}
		return staticMocFunctions;
	}
	return nil;
}


#pragma mark - ー インスタンスメソッド
- (void)initialize
{
	GA_TRACK_METHOD
	//[EntityRelation setMoc:[self managedObjectContext]];
	mContext = [self managedObjectContext];
	if (mContext==nil) {
		GA_TRACK_ERROR(@"mContext==nil");
	}
}
/*
- (void)setMoc:(NSManagedObjectContext *)moc
{
	assert(moc);
	mContext = moc;
}*/

- (NSManagedObjectContext*)getMoc
{
	return mContext;
}

- (id)insertAutoEntity:(NSString *)zEntityName	// autorelease
{
	assert(mContext);
	// Newが含まれているが、自動解放インスタンスが生成される。
	// 即commitされる。つまり、rollbackやcommitの対象外である。 ＜＜そんなことは無い！ roolback可能 save必要
	return [NSEntityDescription insertNewObjectForEntityForName:zEntityName inManagedObjectContext:mContext];
	// ここで生成されたEntityは、rollBack では削除されない。　Cancel時には、deleteEntityが必要。 ＜＜そんなことは無い！ roolback可能 save必要
}	

- (void)deleteEntity:(NSManagedObject *)entity
{
	if (entity) {
		[mContext deleteObject:entity];	// 即commitされる。つまり、rollbackやcommitの対象外である。 ＜＜そんなことは無い！ roolback可能 save必要
	}
}

- (BOOL)hasChanges		// YES=commit以後に変更あり
{
	return [mContext hasChanges];
}

- (BOOL)commit
{
	assert(mContext);
	// SAVE
	NSError *err = nil;
	if (![mContext  save:&err]) {
		//NSLog(@"*** MOC commit error ***\n%@\n%@\n***\n", err, [err userInfo]);
		GA_TRACK_EVENT_ERROR([err description],0);
		//exit(-1);  // Fail
		azAlertBox(NSLocalizedString(@"MOC CommitErr",nil),
				   NSLocalizedString(@"MOC CommitErrMsg",nil),
				   NSLocalizedString(@"Roger",nil));
		return NO;
	}
	return YES;
}


- (void)rollBack
{
	assert(mContext);
	// ROLLBACK
	[mContext rollback]; // 前回のSAVE以降を取り消す
}

- (void)stopRelease
{	// MOC（メモリ上）をクリアし、mContextを解放する。
	GA_TRACK_METHOD
	assert(mContext);
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[mContext reset];
	mContext = nil; //解放
}



#pragma mark - Search

- (NSArray *)select:(NSString *)zEntity
			  limit:(NSUInteger)iLimit
			 offset:(NSUInteger)iOffset
			  where:(NSPredicate *)predicate
			   sort:(NSArray *)arSort 
{
	assert(mContext);
	NSFetchRequest *req = nil;
	@try {
		req = [[NSFetchRequest alloc] init];
		
		// select
		NSEntityDescription *entity = [NSEntityDescription entityForName:zEntity 
												  inManagedObjectContext:mContext];
		[req setEntity:entity];
		
		// limit	抽出件数制限
		if (0 < iLimit) {
			[req setFetchLimit:iLimit];
		}
		
		// offset
		if (iOffset != 0) {
			[req setFetchOffset:iOffset];
		}
		
		// where
		if (predicate) {
			//NSLog(@"MocFunction: select: where: %@", predicate);
			[req setPredicate:predicate];
		}
		
		// order by
		if (arSort) {
			[req setSortDescriptors:arSort];
		}

		NSError *error = nil;
		NSArray *arFetch = [mContext executeFetchRequest:req error:&error];
		//[req release], req = nil;
		if (error) {
			NSLog(@"select: Error %@, %@", error, [error userInfo]);
			GA_TRACK_EVENT_ERROR([error localizedDescription],0);
			return nil;
		}
		return arFetch; // autorelease
	}
	@catch (NSException *errEx) {
		NSLog(@"select @catch:NSException: %@ : %@", [errEx name], [errEx reason]);
		GA_TRACK_ERROR([errEx description]);
	}
	@finally {
		//[req release], req = nil;
	}
	return nil;
}

// 全データ削除する
- (void)deleteAllCoreData
{
	NSUInteger count = 0;
	
	for (NSEntityDescription *entity in [[[mContext persistentStoreCoordinator] managedObjectModel] entities]) 
	{
		NSFetchRequest *request = [[NSFetchRequest alloc] init];
		[request setEntity:[NSEntityDescription entityForName:[entity name] inManagedObjectContext:mContext]];
		
		NSArray *temp = [mContext executeFetchRequest:request error:NULL];
		
		if (temp) {
			count += [temp count];
		}
		
		//[request release];
		
		for (NSManagedObject *object in temp) {
			[mContext deleteObject:object];
		}
	}
	NSLog(@"deleteAllCoreData: count=%d", count);
	[self commit];
}


#pragma mark - JSON
#define TYPE_NSDate		@"#date#"

// JSON変換できるようにするため、NSManagedObject を NSDictionary に変換する。 ＜＜関連（リレーション）非対応
- (NSDictionary*)dictionaryObject:(NSManagedObject*)mobj
{
    //self.traversed = YES;　　<<<--配下に自身があるとき無限ループしないためのフラグ　＜＜ありえないので未対応
	NSArray* attributes = [[[mobj entity] attributesByName] allKeys];
    //関連（リレーション）非対応
	//NSArray* relationships = [[[mobj entity] relationshipsByName] allKeys];
    //NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity: [attributes count] + [relationships count] + 1];
	NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity: [attributes count] + 1];

    //[dict setObject:[[mobj class] description] forKey:@"class"]; ＜＜ "NSManagedObject" になる
    [dict setObject:[[mobj entity] name] forKey:@"#class"];
	
	// 属性
    for (NSString* attr in attributes) {
        NSObject* value = [mobj valueForKey:attr];
		
        if ([value isKindOfClass:[NSDate class]]) {		// JSON未定義型に対応するため
			NSDate *dt = (NSDate*)value;
			// NSDate ---> NSString
			// utcFromDate: デフォルトタイムゾーンのNSDate型 を UTC協定世界時 文字列 "2010-12-31T00:00:00" にする
			// Key に Prefix: TYPE_NSDate を付ける
			[dict setObject:utcFromDate(dt) forKey:[TYPE_NSDate stringByAppendingString:attr]];
		}
		else if (value != nil) {
            [dict setObject:value forKey:attr];
        }
    }
    return dict;
	
    /***　関連（リレーション）非対応
    for (NSString* relationship in relationships) {	// 配下を再帰的にdict化する
        NSObject* value = [mobj valueForKey:relationship];
		
        if ([value isKindOfClass:[NSSet class]]) {
            // 対多
            // The core data set holds a collection of managed objects
            NSSet* relatedObjects = (NSSet*) value;
			
            // Our set holds a collection of dictionaries
            NSMutableSet* dictSet = [NSMutableSet setWithCapacity:[relatedObjects count]];
			
            for (NSManagedObject* relatedObject in relatedObjects) {
				[dictSet addObject:[self dictionaryObject:relatedObject]];
            }

            [dict setObject:dictSet forKey:relationship];
        }
        else if ([value isKindOfClass:[NSManagedObject class]]) {
            // 対1
            NSManagedObject* relatedObject = (NSManagedObject*) value;
            [dict setObject:[self dictionaryObject:relatedObject] forKey:relationship];
        }
    }
	***/
}


// JSON変換した NSDictionary から NSManagedObject を生成する。
- (NSManagedObject*)insertNewObjectForDictionary:(NSDictionary*)dict
{
    NSString* class = [dict objectForKey:@"#class"];
	NSManagedObject* newObject;
	@try {
		newObject = [NSEntityDescription insertNewObjectForEntityForName:class inManagedObjectContext:mContext];
	}
	@catch (NSException *exception) {
		NSLog(@"insertNewObjectForDictionary: No class={%@}", class);
		return nil;
	}
	//NSLog(@"#class=%@,  newObject=%@", class, newObject);

    for (NSString* key in dict) 
	{
        NSObject* value = [dict objectForKey:key];
		NSLog(@"key=%@,  value=%@", key, value);
		if (value==nil) {
			continue;
		}
		
		if ([key hasPrefix:@"#"]) {	// JSON未定義型に対応するため
			if ([key isEqualToString:@"#class"]) {
				continue;
			}
			else if ([key hasPrefix:TYPE_NSDate]) {
				// UTC日付文字列 ---> NSDate
				NSString *str = (NSString*)value;
				// dateFromUTC: UTC協定世界時 文字列 "2010-12-31T00:00:00" を デフォルトタイムゾーンのNSDate型にする
				// Prefix: TYPE_NSDate を取り除いてKeyにする
				//ok//NSLog(@"*** dateFromUTC(%@) ==> %@", str, [dateFromUTC(str) description]);  //設定が和暦でも正しい西暦になることを確認した。
				[newObject  setValue:dateFromUTC(str) forKey: [key substringFromIndex:[TYPE_NSDate length]]];
				//ok//NSLog(@"*** newObject.DATE=%@", [newObject valueForKey:[key substringFromIndex:[TYPE_NSDate length]]]);
			}
			else {
				assert(NO);	// 未定義の型
			}
		}
        else if ([value isKindOfClass:[NSDictionary class]]) {
			/***　関連（リレーション）非対応
            // This is a to-one relationship
            NSManagedObject* childObject = [MocFunctions insertNewObjectFromDictionary:(NSDictionary*)value  inContext:mContext];
            [mobj setValue:childObject forKey:key];　***/
        }
        else if ([value isKindOfClass:[NSSet class]]) {
			/***　関連（リレーション）非対応
            // This is a to-many relationship
            NSSet* relatedObjectDictionaries = (NSSet*) value;
            // Get a proxy set that represents the relationship, and add related objects to it.
            // (Note: this is provided by Core Data)
            NSMutableSet* relatedObjects = [mobj mutableSetValueForKey:key];
			
            for (NSDictionary* relatedObjectDict in relatedObjectDictionaries) {
                NSManagedObject* childObject = [MocFunctions insertNewObjectFromDictionary:relatedObjectDict  inContext:mContext];
                [relatedObjects addObject:childObject];
            }***/
        }
        else {  // This is an attribute
			@try {
				[newObject setValue:value forKey:key];
			}
			@catch (NSException *exception) {
				NSLog(@"insertNewObjectForDictionary: No key={%@}", key);
			}
        }
    }
	return newObject;
}


#pragma mark - PackList Original

- (NSInteger)E1_maxRow
{
	assert(mContext);
	NSFetchRequest* request = [[NSFetchRequest alloc] init];
	
	// entity
	NSEntityDescription* entity = [NSEntityDescription entityForName:@"E1" inManagedObjectContext:mContext];
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
	NSArray *array = [mContext executeFetchRequest:request error:&error];
	NSInteger maxRow = 0;
	
	if (error) {
		NSLog(@"ERROR:E1_maxRow: %@", error);
	} else {
		maxRow = [[[array objectAtIndex:0] valueForKey:@"maxRow"] integerValue];
	}
	return maxRow;
}




#pragma mark - iCloud
// iCloud完全クリアする　＜＜＜同期矛盾が生じたときや構造変更時に使用
- (void)iCloudAllClear
{
	// iCloudサーバー上のゴミデータ削除
	NSURL *icloudURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
	NSError *err;
	[[NSFileManager defaultManager] removeItemAtURL:icloudURL error:&err];
	if (err) {
		GA_TRACK_ERROR([err description])
	} else {
		NSLog(@"iCloud: Removed %@", icloudURL);
	}
}

- (void)mergeiCloudChanges:(NSNotification*)note forContext:(NSManagedObjectContext*)moc
{
	// マージ処理
    [moc mergeChangesFromContextDidSaveNotification:note];
	
	NSLog(@"mergeiCloudChanges: RefreshAllViews: userInfo=%@", [note userInfo]);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:NFM_REFRESH_ALL_VIEWS
														object:self userInfo:[note userInfo]];
}

// NSNotifications are posted synchronously on the caller's thread
// make sure to vector this back to the thread we want, in this case
// the main thread for our views & controller
- (void)mergeChangesFrom_iCloud:(NSNotification *)notification
{
	NSManagedObjectContext* moc = [self managedObjectContext];
	// this only works if you used NSMainQueueConcurrencyType
	// otherwise use a dispatch_async back to the main thread yourself
	[moc performBlock:^{
		[self mergeiCloudChanges:notification forContext:moc];
	}];
}


#pragma mark - CoreData stack
//[1.2.0.0] AzBodyNote[0.8.0.0]に従って実装した。
- (NSManagedObjectModel *)managedObjectModel
{
    if (mCoreModel != nil) {
        return mCoreModel;
    }
	
	mCoreModel = [NSManagedObjectModel mergedModelFromBundles:nil];
	
	return mCoreModel;
}


- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (mCorePsc != nil) {
        return mCorePsc;
    }
	
	// <Application_Home>/Documents  ＜＜iCloudバックアップ対象
	//NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	// <Application_Home>/Library/Caches　　＜＜iCloudバックアップされない
	//NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	//NSString *dir = [paths objectAtIndex:0];
	//NSLog(@"<Application_Home> %@", dir);
	//NSString *storePath = [dir stringByAppendingPathComponent:@"AzPackList.sqlite"];	//【重要】リリース後変更禁止
	//NSLog(@"storePath=%@", storePath);
	
    NSURL *storeUrl = [[self applicationDocumentsDirectory]
					   URLByAppendingPathComponent:@"AzPackList.sqlite"];	//【重要】リリース後変更禁止
	NSLog(@"storeUrl=%@", storeUrl);
	
    mCorePsc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
	
	//__Enabled_iCloud = NO;
	
	if (CoreData_iCloud_SYNC  && IOS_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0")) {
		// do this asynchronously since if this is the first time this particular device is syncing with preexisting
		// iCloud content it may take a long long time to download
		
/*		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"iCloud sync",nil)
														message:NSLocalizedString(@"iCloud sync msg",nil)
													   delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
		UIActivityIndicatorView *alertAct = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		alertAct.frame = CGRectMake((alert.frame.size.width-50)/2, 20, 50, 50);
		[alert addSubview:alertAct];
		[alertAct startAnimating];
		if (iS_iPAD) {
			[__mainSVC.splitViewController.view addSubview:alert];
		} else {
			[__mainNC.navigationController.view addSubview:alert];
		}
		[__window addSubview:alert];*/
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			NSFileManager *fileManager = [NSFileManager defaultManager];
			// Migrate datamodel
			NSDictionary *options = nil;
			NSURL *cloudURL = [fileManager URLForUbiquityContainerIdentifier:nil]; //.entitlementsから自動取得されるようになった。
			NSLog(@"cloudURL=1=%@", cloudURL);
			NSURL *tlogURL = nil;
			if (cloudURL) {
				//__Enabled_iCloud = YES;
				// アプリ内のコンテンツ名付加：["coredata"]　＜＜＜変わると共有できない。
				//cloudURL = [cloudURL URLByAppendingPathComponent:@"coredata"];
				//NSLog(@"cloudURL=2=%@", cloudURL);
				cloudURL = [cloudURL URLByAppendingPathComponent:@"Documents" isDirectory:YES];
				tlogURL = [cloudURL URLByAppendingPathComponent:@"TLOG" isDirectory:YES];
				NSLog(@"cloudURL=2=%@", cloudURL);
				NSLog(@"tlogURL=2=%@", tlogURL);
				BOOL exists, isDir;
				[fileManager createDirectoryAtURL:cloudURL withIntermediateDirectories:NO attributes:nil error:nil];
				exists = [fileManager fileExistsAtPath:[cloudURL relativePath] isDirectory:&isDir];
				if (exists && isDir) {
					[fileManager createDirectoryAtURL:tlogURL withIntermediateDirectories:NO attributes:nil error:nil];
					exists = [fileManager fileExistsAtPath:[tlogURL relativePath] isDirectory:&isDir];
					//directory exists
					if (exists && isDir) {
					} else{
						tlogURL = nil;
						GA_TRACK_ERROR(@"tlogURL==nil;")
					}
				} else{
					tlogURL = nil;
					GA_TRACK_ERROR(@"tlogURL==nil;")
				}
			} else{
				GA_TRACK_ERROR(@"cloudURL==nil;")
			}
			
			if (cloudURL && tlogURL) {
				options = [NSDictionary dictionaryWithObjectsAndKeys:
						   [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
						   [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
						   @"com.azukid.AzPackList.sqlog", NSPersistentStoreUbiquitousContentNameKey,		//【重要】リリース後変更禁止
						   tlogURL, NSPersistentStoreUbiquitousContentURLKey,													//【重要】リリース後変更禁止
						   nil];
			} else {
				// iCloud is not available
				options = [NSDictionary dictionaryWithObjectsAndKeys:
						   [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,	// 自動移行
						   [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,			// 自動マッピング推論して処理
						   nil];																									// NO ならば、「マッピングモデル」を使って移行処理される。
			}
			NSLog(@"options=%@", options);
			
			// prep the store path and bundle stuff here since NSBundle isn't totally thread safe
			NSPersistentStoreCoordinator* psc = mCorePsc;
			NSError *error = nil;
			[psc lock];
			if (![psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error])
			{
				NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
				GA_TRACK_ERROR([error description]);
				abort();
			}
			[psc unlock];
			
			// tell the UI on the main thread we finally added the store and then
			// post a custom notification to make your views do whatever they need to such as tell their
			// NSFetchedResultsController to -performFetch again now there is a real store
			dispatch_async(dispatch_get_main_queue(), ^{
				NSLog(@"asynchronously added persistent store!");
				[[NSNotificationCenter defaultCenter] postNotificationName:NFM_REFRESH_ALL_VIEWS
																	object:self userInfo:nil];
				//[alertAct stopAnimating];
				//[alert dismissWithClickedButtonIndex:alert.cancelButtonIndex animated:YES];
			});
		});
	}
	else {	// iCloudなし
		//NSURL *storeUrl = [NSURL fileURLWithPath:storePath];
		NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
								 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
								 nil];
		
		NSError *error = nil;
		if (![mCorePsc addPersistentStoreWithType:NSSQLiteStoreType 	 configuration:nil
											  URL:storeUrl  options:options  error:&error])
		{
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			GA_TRACK_EVENT_ERROR([error description],0);
			abort();
		}
	}
	
    return mCorePsc;
}

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContext
{
    if (mContext != nil) {
        return mContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
	NSManagedObjectContext* moc = nil;
	
    if (coordinator != nil) {
		if (CoreData_iCloud_SYNC  && IOS_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0")) {
			moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
			//moc = [[NSManagedObjectContext alloc] init];
			
			[moc performBlockAndWait:^{
				// even the post initialization needs to be done within the Block
				[moc setPersistentStoreCoordinator: coordinator];
				
				// iCloudに変化があれば通知を受ける　＜＜初期ミス！ applicationDidEnterBackground:にて破棄してしまっていた。
				[[NSNotificationCenter defaultCenter] addObserver:self
														 selector:@selector(mergeChangesFrom_iCloud:)
															 name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
														   object:coordinator];
				
				// 競合解決方法   Context <<>> SQLite <<>> iCloud
				// NSErrorMergePolicy - マージコンフリクトを起こすとSQLite保存に失敗する（デフォルト）
				// NSMergeByPropertyStoreTrumpMergePolicy - SQLite(Store)を優先にマージする
				// NSMergeByPropertyObjectTrumpMergePolicy - Context(Object)を優先にマージする
				// NSOverwriteMergePolicy - ContextでSQLiteを上書きする		<<<<<<<<<<
				//　NSRollbackMergePolicy　-　Contextの変更を破棄する
				//[moc setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
			}];
        }
		else {	// iCloudなし
            moc = [[NSManagedObjectContext alloc] init];
            [moc setPersistentStoreCoordinator:coordinator];
        }
    }
    return moc;
}

#pragma mark - Application's documents directory
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


@end
