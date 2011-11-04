//
//  MHDatabaseStore.h
//  MongoHub
//
//  Created by Syd on 10-4-24.
//  Copyright 2010 MusicPeace.ORG. All rights reserved.
//

#import <CoreData/CoreData.h>

@class MHConnectionStore;

@interface MHDatabaseStore : NSManagedObject {
    NSString *name;
    NSString *user;
    NSString *password;
    MHConnectionStore *connection;
}

- (NSArray *)queryHistoryWithCollection:(NSString *)collectionName;
- (void)addNewQuery:(NSDictionary *)queyr withCollectionName:(NSString *)collectionName;

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *user;
@property (nonatomic, retain) NSString *password;
@property (nonatomic, retain) MHConnectionStore *connection;

@end
