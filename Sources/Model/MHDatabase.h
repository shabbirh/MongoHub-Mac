//
//  MHDatabase.h
//  MongoHub
//
//  Created by Syd on 10-4-24.
//  Copyright 2010 MusicPeace.ORG. All rights reserved.
//

#import <CoreData/CoreData.h>
@class MHConnection;

@interface MHDatabase : NSManagedObject {
    NSString *name;
    NSString *user;
    NSString *password;
    MHConnection *connection;
}
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *user;
@property (nonatomic, retain) NSString *password;
@property (nonatomic, retain) MHConnection *connection;

@end
