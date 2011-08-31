//
//  MongoDB_internal.h
//  MongoHub
//
//  Created by Jérôme Lebel on 29/08/11.
//  Copyright (c) 2011 fotonauts.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MongoDB.h"
#import "MongoQuery.h"

@interface MongoDB()

@property(nonatomic, readwrite, assign, getter=isConnected) BOOL connected;
@property(nonatomic, readwrite, assign) mongo::DBClientConnection *connexion;
@property(nonatomic, readwrite, assign) mongo::DBClientReplicaSet::DBClientReplicaSet *replicaConnexion;
@property(nonatomic, readwrite, assign) mongo::BSONObj *serverStatusForDelta;
@property(nonatomic, readwrite, assign) MongoQuery *currentMongoQuery;

- (BOOL)authenticateSynchronouslyWithDatabaseName:(NSString *)databaseName userName:(NSString *)user password:(NSString *)password mongoQuery:(MongoQuery *)mongoQuery;
- (BOOL)authUser:(NSString *)user 
            pass:(NSString *)pass 
        database:(NSString *)db;
- (MongoQuery *)addQueryInQueue:(void (^)(MongoQuery *currentMongoQuery))block;

+ (NSArray *) bsonDictWrapper:(mongo::BSONObj)retval;
+ (NSArray *) bsonArrayWrapper:(mongo::BSONObj)retval;

@end

@interface MongoQuery()

- (void)starts;
- (void)ends;
- (void)removeBlockOperation;

@property (nonatomic, readwrite, retain) NSDictionary *parameters;
@property (nonatomic, readwrite, retain) NSMutableDictionary *mutableParameters;
@property (nonatomic, readwrite, assign) NSBlockOperation *blockOperation;

@end
