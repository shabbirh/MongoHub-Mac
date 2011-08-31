//
//  MongoCollection.h
//  MongoHub
//
//  Created by Jérôme Lebel on 28/08/11.
//  Copyright (c) 2011 fotonauts.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MongoCollection;
@class MongoQuery;

@protocol MongoCollectionDelegate<NSObject>

@optional
- (void)mongoCollection:(MongoCollection *)collection queryResultFetched:(NSArray *)result withMongoQuery:(MongoQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
- (void)mongoCollection:(MongoCollection *)collection queryCountWithValue:(long long)value withMongoQuery:(MongoQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
- (void)mongoCollection:(MongoCollection *)collection updateDonwWithMongoQuery:(MongoQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
@end

@class MongoDB;

@interface MongoCollection : NSObject
{
    MongoDB             *_mongoDB;
    NSString            *_databaseName;
    NSString            *_collectionName;
    NSString            *_userName;
    NSString            *_password;
    NSString            *_absoluteCollection;
    
    id<MongoCollectionDelegate> _delegate;
}

- (id)initWithMongoDB:(MongoDB *)mongoDB databaseName:(NSString *)databaseName collectionName:(NSString *)collectionName userName:(NSString *)userName password:(NSString *)password;

- (MongoQuery *)findWithQuery:(NSString *)query fields:(NSString *)fields skip:(int)skip limit:(int)limit sort:(NSString *)sort;
- (MongoQuery *)countWithQuery:(NSString *)query;
- (MongoQuery *)updateWithQuery:(NSString *)query fields:(NSString *)fields upset:(BOOL)upset;
- (MongoQuery *)saveJsonString:(NSString *)jsonString withRecordId:(NSString *)recordId;

@property(nonatomic, retain, readonly) MongoDB *mongoDB;
@property(nonatomic, retain, readonly) NSString *databaseName;
@property(nonatomic, retain, readonly) NSString *collectionName;
@property(nonatomic, retain, readonly) NSString *userName;
@property(nonatomic, retain, readonly) NSString *password;
@property(nonatomic, retain, readwrite) id<MongoCollectionDelegate> delegate;

@end
