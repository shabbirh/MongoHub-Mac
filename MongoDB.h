//
//  Mongo.h
//  MongoHub
//
//  Created by Syd on 10-4-25.
//  Copyright 2010 MusicPeace.ORG. All rights reserved.
//

#import <Foundation/Foundation.h>
#undef check
#import <mongo/client/dbclient.h>

@class MongoDB;
@class MongoCollection;
@class MongoQuery;

@protocol MongoDBDelegate<NSObject>
@optional
- (void)mongoDBConnectionSucceded:(MongoDB *)mongoDB withMongoQuery:(MongoQuery *)mongoQuery;
- (void)mongoDBConnectionFailed:(MongoDB *)mongoDB withMongoQuery:(MongoQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
- (void)mongoDB:(MongoDB *)mongoDB databaseListFetched:(NSArray *)list withMongoQuery:(MongoQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
- (void)mongoDB:(MongoDB *)mongoDB serverStatusFetched:(NSArray *)serverStatus withMongoQuery:(MongoQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
- (void)mongoDB:(MongoDB *)mongoDB serverStatusDeltaFetched:(NSDictionary *)serverStatusDelta withMongoQuery:(MongoQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
- (void)mongoDB:(MongoDB *)mongoDB collectionListFetched:(NSArray *)collectionList withMongoQuery:(MongoQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
- (void)mongoDB:(MongoDB *)mongoDB databaseStatsFetched:(NSArray *)databaseStats withMongoQuery:(MongoQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
- (void)mongoDB:(MongoDB *)mongoDB collectionStatsFetched:(NSArray *)databaseStats withMongoQuery:(MongoQuery *)mongoQuery errorMessage:(NSString *)errorMessage;

- (void)mongoDB:(MongoDB *)mongoDB databaseDropedWithMongoQuery:(MongoQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
- (void)mongoDB:(MongoDB *)mongoDB collectionCreatedWithMongoQuery:(MongoQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
- (void)mongoDB:(MongoDB *)mongoDB collectionDropedWithMongoQuery:(MongoQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
@end

@interface MongoDB : NSObject
{
    id<MongoDBDelegate>             _delegate;
    NSOperationQueue                *_operationQueue;
    MongoQuery                      *_currentMongoQuery;
    
    void                            *_connexion;
    void                            *_replicaConnexion;
    
    BOOL                            _connected;
    NSMutableDictionary             *_databaseList;
    NSMutableArray                  *_serverStatus;
    NSDate                          *_dateForDelta;
    void                            *_serverStatusForDelta;
}
- (MongoQuery *)connectWithHostName:(NSString *)host databaseName:(NSString *)databaseName userName:(NSString *)userName password:(NSString *)password;
- (MongoQuery *)connectWithReplicaName:(NSString *)name hosts:(NSArray *)hosts databaseName:(NSString *)databaseName userName:(NSString *)userName password:(NSString *)password;
- (MongoQuery *)fetchDatabaseList;
- (MongoQuery *)fetchServerStatus;
- (MongoQuery *)fetchServerStatusDelta;
- (MongoQuery *)fetchCollectionListWithDatabaseName:(NSString *)databaseName userName:(NSString *)user password:(NSString *)password;
- (MongoQuery *)fetchDatabaseStatsWithDatabaseName:(NSString *)databaseName userName:(NSString *)user password:(NSString *)password;
- (MongoQuery *)fetchCollectionStatsWithCollectionName:(NSString *)collectionName databaseName:(NSString *)databaseName userName:(NSString *)user password:(NSString *)password;

- (MongoQuery *)dropDatabaseWithName:(NSString *)databaseName userName:(NSString *)user password:(NSString *)password;

- (MongoQuery *)createCollectionWithName:(NSString *)collectionName databaseName:(NSString *)databaseName userName:(NSString *)user password:(NSString *)password;
- (MongoQuery *)dropCollectionWithName:(NSString *)collectionName databaseName:(NSString *)databaseName userName:(NSString *)user password:(NSString *)password;

- (MongoCollection *)mongoCollectionWithDatabaseName:(NSString *)databaseName collectionName:(NSString *)collectionName userName:(NSString *)userName password:(NSString *)password;

- (void) saveInDB:(NSString *)dbname 
       collection:(NSString *)collectionname 
             user:(NSString *)user 
         password:(NSString *)password 
       jsonString:(NSString *)jsonString 
              _id:(NSString *)_id;
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

@property(nonatomic, readwrite, assign) id<MongoDBDelegate> delegate;
@property(nonatomic, readonly, assign, getter=isConnected) BOOL connected;
@property(nonatomic, readonly, retain) NSArray *databaseList;
@property(nonatomic, readonly, retain) NSArray *serverStatus;
@property(nonatomic, readonly, assign) MongoQuery *currentMongoQuery;

@end
