//
//  Mongo.h
//  MongoHub
//
//  Created by Syd on 10-4-25.
//  Copyright 2010 MusicPeace.ORG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#undef check
#import <mongo/client/dbclient.h>

#define ERROR_MESSAGE_MONGODB @"error"
#define CONNECTION_NOTIFICATION_MONGODB @"connection"

@class MongoDB;

@protocol MongoDBDelegate
@optional
- (void)mongoDBConnectionSucceded:(MongoDB *)mongoDB;
- (void)mongoDBConnectionFailed:(MongoDB *)mongoDB withErrorMessage:(NSString *)errorMessage;
- (void)mongoDB:(MongoDB *)mongoDB databaseListFetched:(NSArray *)list withErrorMessage:(NSString *)errorMessage;
- (void)mongoDB:(MongoDB *)mongoDB serverStatusFetched:(NSArray *)serverStatus withErrorMessage:(NSString *)errorMessage;
- (void)mongoDB:(MongoDB *)mongoDB serverStatusDeltaFetched:(NSDictionary *)serverStatusDelta withErrorMessage:(NSString *)errorMessage;
- (void)mongoDB:(MongoDB *)mongoDB collectionListFetched:(NSArray *)collectionList withDatabaseName:(NSString *)databaseName errorMessage:(NSString *)errorMessage;
- (void)mongoDB:(MongoDB *)mongoDB databaseStatsFetched:(NSArray *)databaseStats withDatabaseName:(NSString *)databaseName errorMessage:(NSString *)errorMessage;
- (void)mongoDB:(MongoDB *)mongoDB collectionStatsFetched:(NSArray *)databaseStats withDatabaseName:(NSString *)databaseName collectionName:(NSString *)collectionName errorMessage:(NSString *)errorMessage;

- (void)mongoDB:(MongoDB *)mongoDB databaseDropedWithName:(NSString *)databaseName errorMessage:(NSString *)errorMessage;
- (void)mongoDB:(MongoDB *)mongoDB collectionCreatedWithName:(NSString *)collectionName databaseName:(NSString *)databaseName errorMessage:(NSString *)errorMessage;
- (void)mongoDB:(MongoDB *)mongoDB collectionDropedWithName:(NSString *)collectionName databaseName:(NSString *)databaseName errorMessage:(NSString *)errorMessage;
@end

@interface MongoDB : NSObject {
    id<MongoDBDelegate, NSObject>   _delegate;
    NSOperationQueue                *_operationQueue;
    
    mongo::DBClientConnection *conn;
    mongo::DBClientReplicaSet::DBClientReplicaSet *repl_conn;
    
    BOOL                            _connected;
    NSMutableDictionary             *_databaseList;
    NSMutableArray                  *_serverStatus;
    NSDate                          *_dateForDelta;
    mongo::BSONObj                  _serverStatusForDelta;
}
+ (NSArray *) bsonDictWrapper:(mongo::BSONObj)retval;
+ (NSArray *) bsonArrayWrapper:(mongo::BSONObj)retval;

- (NSOperation *)connectWithHostName:(NSString *)host databaseName:(NSString *)databaseName userName:(NSString *)userName password:(NSString *)password;
- (NSOperation *)connectWithReplicaName:(NSString *)name hosts:(NSArray *)hosts databaseName:(NSString *)databaseName userName:(NSString *)userName password:(NSString *)password;
- (NSOperation *)fetchDatabaseList;
- (NSOperation *)fetchServerStatus;
- (NSOperation *)fetchServerStatusDelta;
- (NSOperation *)fetchCollectionListWithDatabaseName:(NSString *)databaseName userName:(NSString *)user password:(NSString *)password;
- (NSOperation *)fetchDatabaseStatsWithDatabaseName:(NSString *)databaseName userName:(NSString *)user password:(NSString *)password;
- (NSOperation *)fetchCollectionStatsWithCollectionName:(NSString *)collectionName databaseName:(NSString *)databaseName userName:(NSString *)user password:(NSString *)password;

- (NSOperation *)dropDatabaseWithName:(NSString *)databaseName userName:(NSString *)user password:(NSString *)password;

- (NSOperation *)createCollectionWithName:(NSString *)collectionName databaseName:(NSString *)databaseName userName:(NSString *)user password:(NSString *)password;
- (NSOperation *)dropCollectionWithName:(NSString *)collectionName databaseName:(NSString *)databaseName userName:(NSString *)user password:(NSString *)password;

- (NSArray *) findInDB:(NSString *)dbname 
                   collection:(NSString *)collectionname 
                         user:(NSString *)user 
                     password:(NSString *)password 
                     critical:(NSString *)critical 
                       fields:(NSString *)fields 
                         skip:(NSNumber *)skip 
                        limit:(NSNumber *)limit 
                         sort:(NSString *)sort;
- (void) saveInDB:(NSString *)dbname 
       collection:(NSString *)collectionname 
             user:(NSString *)user 
         password:(NSString *)password 
       jsonString:(NSString *)jsonString 
              _id:(NSString *)_id;
- (void) updateInDB:(NSString *)dbname 
         collection:(NSString *)collectionname 
               user:(NSString *)user 
           password:(NSString *)password 
           critical:(NSString *)critical 
             fields:(NSString *)fields 
              upset:(NSNumber *)upset;
- (void) removeInDB:(NSString *)dbname 
         collection:(NSString *)collectionname 
               user:(NSString *)user 
           password:(NSString *)password 
           critical:(NSString *)critical;
- (void) insertInDB:(NSString *)dbname 
         collection:(NSString *)collectionname 
               user:(NSString *)user 
           password:(NSString *)password 
           insertData:(NSString *)insertData;
- (void) insertInDB:(NSString *)dbname 
         collection:(NSString *)collectionname 
               user:(NSString *)user 
           password:(NSString *)password 
               data:(NSDictionary *)insertData 
             fields:(NSArray *)fields 
         fieldTypes:(NSDictionary *)fieldTypes;
- (NSArray *) indexInDB:(NSString *)dbname 
                    collection:(NSString *)collectionname 
                          user:(NSString *)user 
                      password:(NSString *)password;
- (void) ensureIndexInDB:(NSString *)dbname 
              collection:(NSString *)collectionname 
                    user:(NSString *)user 
                password:(NSString *)password 
               indexData:(NSString *)indexData;
- (void) reIndexInDB:(NSString *)dbname 
          collection:(NSString *)collectionname 
                user:(NSString *)user 
            password:(NSString *)password;
- (void) dropIndexInDB:(NSString *)dbname 
            collection:(NSString *)collectionname 
                  user:(NSString *)user 
              password:(NSString *)password 
             indexName:(NSString *)indexName;
- (long long int) countInDB:(NSString *)dbname 
       collection:(NSString *)collectionname 
             user:(NSString *)user 
         password:(NSString *)password 
         critical:(NSString *)critical;
- (NSArray *)mapReduceInDB:dbname 
                       collection:collectionname 
                             user:user 
                         password:password 
                            mapJs:mapFunction 
                         reduceJs:reduceFunction 
                         critical:critical 
                           output:output;

- (std::auto_ptr<mongo::DBClientCursor>) findAllCursorInDB:(NSString *)dbname collection:(NSString *)collectionname user:(NSString *)user password:(NSString *)password fields:(mongo::BSONObj) fields;

- (std::auto_ptr<mongo::DBClientCursor>) findCursorInDB:(NSString *)dbname collection:(NSString *)collectionname user:(NSString *)user password:(NSString *)password critical:(NSString *)critical fields:(NSString *)fields skip:(NSNumber *)skip limit:(NSNumber *)limit sort:(NSString *)sort;

- (void) updateBSONInDB:(NSString *)dbname 
             collection:(NSString *)collectionname 
                   user:(NSString *)user 
               password:(NSString *)password 
               critical:(mongo::Query)critical 
                 fields:(mongo::BSONObj)fields 
                  upset:(BOOL)upset;

@property(nonatomic, readwrite, assign) id<MongoDBDelegate, NSObject> delegate;
@property(nonatomic, readonly, assign, getter=isConnected) BOOL connected;
@property(nonatomic, readonly, retain) NSArray *databaseList;
@property(nonatomic, readonly, retain) NSArray *serverStatus;

@end
