//
//  DatabasesArrayCollection.h
//  MongoHub
//
//  Created by Syd on 10-4-25.
//  Copyright 2010 MusicPeace.ORG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MHConnection;
@class MHDatabase;

@interface DatabasesArrayController : NSArrayController {

}

- (id)newObjectWithConn:(MHConnection *)conn name:(NSString *)name user:(NSString *)user password:(NSString *)password;
- (void)clean:(MHConnection *)conn databases:(NSArray *)databases;
- (BOOL)checkDuplicate:(MHConnection *) conn name:(NSString *)name;
- (NSArray *)itemsUsingFetchPredicate:(NSPredicate *)fetchPredicate;
- (MHDatabase *)dbInfo:(MHConnection *) conn name:(NSString *)name;
@end
