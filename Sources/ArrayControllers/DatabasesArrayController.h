//
//  DatabasesArrayCollection.h
//  MongoHub
//
//  Created by Syd on 10-4-25.
//  Copyright 2010 MusicPeace.ORG. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MHConnectionStore;
@class MHDatabaseStore;

@interface DatabasesArrayController : NSArrayController {

}

- (id)newObjectWithConn:(MHConnectionStore *)conn name:(NSString *)name user:(NSString *)user password:(NSString *)password;
- (void)clean:(MHConnectionStore *)conn databases:(NSArray *)databases;
- (BOOL)checkDuplicate:(MHConnectionStore *) conn name:(NSString *)name;
- (NSArray *)itemsUsingFetchPredicate:(NSPredicate *)fetchPredicate;
- (MHDatabaseStore *)dbInfo:(MHConnectionStore *) conn name:(NSString *)name;
@end
