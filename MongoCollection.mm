//
//  MongoCollection.m
//  MongoHub
//
//  Created by Jérôme Lebel on 28/08/11.
//  Copyright (c) 2011 fotonauts.com. All rights reserved.
//

#import <RegexKit/RegexKit.h>
#import "MongoCollection.h"
#import "MongoDB.h"
#import "MongoDB_internal.h"
#import "MongoQuery.h"

@interface MongoCollection()

@end

@implementation MongoCollection

@synthesize databaseName = _databaseName, collectionName = _collectionName, mongoDB = _mongoDB, userName = _userName, password = _password, delegate = _delegate;

- (id)initWithMongoDB:(MongoDB *)mongoDB databaseName:(NSString *)databaseName collectionName:(NSString *)collectionName userName:(NSString *)userName password:(NSString *)password
{
    if (self = [self init]) {
        _mongoDB = [mongoDB retain];
        _databaseName = [databaseName retain];
        _collectionName = [collectionName retain];
        _userName = [userName retain];
        _password = [password retain];
        _absoluteCollection = [[NSString alloc] initWithFormat:@"%@.%@", _databaseName, _collectionName];
    }
    return self;
}

- (void)dealloc
{
    [_mongoDB release];
    [_databaseName release];
    [_collectionName release];
    [_absoluteCollection release];
    [_userName release];
    [_password release];
    [super dealloc];
}

- (BOOL)authenticateSynchronouslyWithMongoQuery:(MongoQuery *)mongoQuery
{
    return [_mongoDB authenticateSynchronouslyWithDatabaseName:self.databaseName userName:self.userName password:self.password mongoQuery:mongoQuery];
}

- (void)findCallback:(MongoQuery *)mongoQuery
{
    NSArray *result;
    NSString *errorMessage;
    
    [mongoQuery ends];
    result = [mongoQuery.parameters objectForKey:@"result"];
    errorMessage = [mongoQuery.parameters objectForKey:@"errormessage"];
    if ([_delegate respondsToSelector:@selector(mongoCollection:queryResultFetched:withMongoQuery:errorMessage:)]) {
        [_delegate mongoCollection:self queryResultFetched:result withMongoQuery:mongoQuery errorMessage:errorMessage];
    }
}

- (MongoQuery *)findWithQuery:(NSString *)query fields:(NSString *)fields skip:(int)skip limit:(int)limit sort:(NSString *)sort
{
    MongoQuery *mongoQuery = nil;
    
    mongoQuery = [_mongoDB addQueryInQueue:^(MongoQuery *currentMongoQuery) {
        NSMutableArray *response;
        NSString *errorMessage = nil;
        NSString *oid = nil;
        NSString *oidType = nil;
        NSString *jsonString = nil;
        NSString *jsonStringb = nil;
        NSMutableArray *repArr = nil;
        NSMutableArray *oriArr = nil;
        NSMutableDictionary *item = nil;
        NSString *collection;
        
        collection = [[NSString alloc] initWithFormat:@"%@.%@", _databaseName, _collectionName];
        response = [[NSMutableArray alloc] initWithCapacity:limit];
        try {
            if ([self authenticateSynchronouslyWithMongoQuery:mongoQuery]) {
                mongo::BSONObj queryBSON = mongo::fromjson([query UTF8String]);
                mongo::BSONObj sortBSON = mongo::fromjson([sort UTF8String]);
                mongo::BSONObj fieldsToReturn;
                
                if ([fields length] > 0) {
                    NSArray *keys = [fields componentsSeparatedByString:@","];
                    
                    mongo::BSONObjBuilder builder;
                    for (NSString *str in keys) {
                        builder.append([str UTF8String], 1);
                    }
                    fieldsToReturn = builder.obj();
                }
                
                std::auto_ptr<mongo::DBClientCursor> cursor;
                if (_mongoDB.replicaConnexion) {
                    cursor = _mongoDB.replicaConnexion->query(std::string([collection UTF8String]), mongo::Query(queryBSON).sort(sortBSON), limit, skip, &fieldsToReturn);
                } else {
                    cursor = _mongoDB.connexion->query(std::string([collection UTF8String]), mongo::Query(queryBSON).sort(sortBSON), limit, skip, &fieldsToReturn);
                }
                while (cursor->more()) {
                    mongo::BSONObj b = cursor->next();
                    mongo::BSONElement e;
                    b.getObjectID (e);
                    
                    if (e.type() == mongo::jstOID) {
                        oidType = @"ObjectId";
                        [oid release];
                        oid = [[NSString alloc] initWithUTF8String:e.__oid().str().c_str()];
                    } else {
                        oidType = @"String";
                        [oid release];
                        oid = [[NSString alloc] initWithUTF8String:e.str().c_str()];
                    }
                    [jsonString release];
                    jsonString = [[NSString alloc] initWithUTF8String:b.jsonString(mongo::TenGen).c_str()];
                    [jsonStringb release];
                    jsonStringb = [[NSString alloc] initWithUTF8String:b.jsonString(mongo::TenGen, 1).c_str()];
                    if (jsonString == nil) {
                        jsonString = [@"" retain];
                    }
                    if (jsonStringb == nil) {
                        jsonStringb = [@"" retain];
                    }
                    [repArr release];
                    repArr = [[NSMutableArray alloc] initWithCapacity:4];
                    id regx2 = [RKRegex regexWithRegexString:@"(Date\\(\\s\\d+\\s\\))" options:RKCompileCaseless];
                    RKEnumerator *matchEnumerator2 = [jsonString matchEnumeratorWithRegex:regx2];
                    while([matchEnumerator2 nextRanges] != NULL) {
                        NSString *enumeratedStr=NULL;
                        [matchEnumerator2 getCapturesWithReferences:@"$1", &enumeratedStr, nil];
                        [repArr addObject:enumeratedStr];
                    }
                    [oriArr release];
                    oriArr = [[NSMutableArray alloc] initWithCapacity:4];
                    id regx = [RKRegex regexWithRegexString:@"(Date\\(\\s+\"[^^]*?\"\\s+\\))" options:RKCompileCaseless];
                    RKEnumerator *matchEnumerator = [jsonStringb matchEnumeratorWithRegex:regx];
                    while([matchEnumerator nextRanges] != NULL) {
                        NSString *enumeratedStr=NULL;
                        [matchEnumerator getCapturesWithReferences:@"$1", &enumeratedStr, nil];
                        [oriArr addObject:enumeratedStr];
                    }
                    for (unsigned int i=0; i<[repArr count]; i++) {
                        NSString *old;
                        
                        old = jsonStringb;
                        jsonStringb = [[jsonStringb stringByReplacingOccurrencesOfString:[oriArr objectAtIndex:i] withString:[repArr objectAtIndex:i]] retain];
                        [old release];
                    }
                    [item release];
                    item = [[NSMutableDictionary alloc] initWithCapacity:6];
                    [item setObject:@"_id" forKey:@"name"];
                    [item setObject:oidType forKey:@"type"];
                    [item setObject:oid forKey:@"value"];
                    [item setObject:jsonString forKey:@"raw"];
                    [item setObject:jsonStringb forKey:@"beautified"];
                    [item setObject:[[_mongoDB class] bsonDictWrapper:b] forKey:@"child"];
                    [response addObject:item];
                }
                [currentMongoQuery.mutableParameters setObject:response forKey:@"result"];
            }
        } catch (mongo::DBException &e) {
            errorMessage = [[NSString alloc] initWithUTF8String:e.what()];
            [currentMongoQuery.mutableParameters setObject:errorMessage forKey:@"errormessage"];
            [errorMessage release];
        }
        [self performSelectorOnMainThread:@selector(findCallback:) withObject:currentMongoQuery waitUntilDone:NO];
        [response release];
        [oid release];
        [jsonString release];
        [jsonStringb release];
        [repArr release];
        [oriArr release];
        [item release];
        [collection release];
    }];
    [mongoQuery.mutableParameters setObject:query forKey:@"query"];
    [mongoQuery.mutableParameters setObject:fields forKey:@"fields"];
    [mongoQuery.mutableParameters setObject:[NSNumber numberWithInt:skip] forKey:@"skip"];
    [mongoQuery.mutableParameters setObject:[NSNumber numberWithInt:limit] forKey:@"limit"];
    [mongoQuery.mutableParameters setObject:sort forKey:@"sort"];
    [mongoQuery.mutableParameters setObject:self forKey:@"collection"];
    return mongoQuery;
}

- (void)countCallback:(MongoQuery *)mongoQuery
{
    long long int count;
    NSString *errorMessage;
    
    [mongoQuery ends];
    count = [[mongoQuery.parameters objectForKey:@"count"] longLongValue];
    errorMessage = [mongoQuery.parameters objectForKey:@"errormessage"];
    if ([_delegate respondsToSelector:@selector(mongoCollection:queryCountWithValue:withMongoQuery:errorMessage:)]) {
        [_delegate mongoCollection:self queryCountWithValue:count withMongoQuery:mongoQuery errorMessage:errorMessage];
    }
}

- (MongoQuery *)countWithQuery:(NSString *)query
{
    MongoQuery *mongoQuery = nil;
    
    mongoQuery = [_mongoDB addQueryInQueue:^(MongoQuery *currentMongoQuery) {
        NSString *errorMessage;
        NSString *collection = nil;
        
        try {
            if ([self authenticateSynchronouslyWithMongoQuery:mongoQuery]) {
                long long int value;
                NSNumber *count;
                
                collection = [[NSString alloc] initWithFormat:@"%@.%@", _databaseName, _collectionName];
                mongo::BSONObj criticalBSON = mongo::fromjson([query UTF8String]);
                
                if (_mongoDB.replicaConnexion) {
                    value = _mongoDB.replicaConnexion->count(std::string([collection UTF8String]), criticalBSON);
                }else {
                    value = _mongoDB.connexion->count(std::string([collection UTF8String]), criticalBSON);
                }
                count = [[NSNumber alloc] initWithLongLong:value];
                [currentMongoQuery.mutableParameters setObject:count forKey:@"count"];
                [count release];
            }
        } catch (mongo::DBException &e) {
            errorMessage = [[NSString alloc] initWithUTF8String:e.what()];
            [currentMongoQuery.mutableParameters setObject:errorMessage forKey:@"errormessage"];
            [errorMessage release];
        }
        [self performSelectorOnMainThread:@selector(countCallback:) withObject:currentMongoQuery waitUntilDone:NO];
        [collection release];
    }];
    [mongoQuery.mutableParameters setObject:query forKey:@"query"];
    [mongoQuery.mutableParameters setObject:self forKey:@"collection"];
    return mongoQuery;
}

- (void)updateCallback:(MongoQuery *)mongoQuery
{
    NSString *errorMessage;
    
    [mongoQuery ends];
    errorMessage = [mongoQuery.parameters objectForKey:@"errormessage"];
    if ([_delegate respondsToSelector:@selector(mongoCollection:updateDonwWithMongoQuery:errorMessage:)]) {
        [_delegate mongoCollection:self updateDonwWithMongoQuery:mongoQuery errorMessage:errorMessage];
    }
}

- (MongoQuery *)updateWithQuery:(NSString *)query fields:(NSString *)fields upset:(BOOL)upset
{
    MongoQuery *mongoQuery = nil;
    
    mongoQuery = [_mongoDB addQueryInQueue:^(MongoQuery *currentMongoQuery) {
        NSString *errorMessage;
        
        try {
            if ([self authenticateSynchronouslyWithMongoQuery:mongoQuery]) {
                mongo::BSONObj criticalBSON = mongo::fromjson([query UTF8String]);
                mongo::BSONObj fieldsBSON = mongo::fromjson([[NSString stringWithFormat:@"{$set:%@}", fields] UTF8String]);
                if (_mongoDB.replicaConnexion) {
                    _mongoDB.replicaConnexion->update(std::string([_absoluteCollection UTF8String]), criticalBSON, fieldsBSON, (upset == YES)?true:false);
                }else {
                    _mongoDB.connexion->update(std::string([_absoluteCollection UTF8String]), criticalBSON, fieldsBSON, (upset == YES)?true:false);
                }
            }
        } catch (mongo::DBException &e) {
            errorMessage = [[NSString alloc] initWithUTF8String:e.what()];
            [currentMongoQuery.mutableParameters setObject:errorMessage forKey:@"errormessage"];
            [errorMessage release];
        }
        [self performSelectorOnMainThread:@selector(updateCallback:) withObject:currentMongoQuery waitUntilDone:NO];
    }];
    [mongoQuery.mutableParameters setObject:query forKey:@"query"];
    [mongoQuery.mutableParameters setObject:fields forKey:@"fields"];
    [mongoQuery.mutableParameters setObject:[NSNumber numberWithBool:upset] forKey:@"upset"];
    [mongoQuery.mutableParameters setObject:self forKey:@"collection"];
    return mongoQuery;
}

- (MongoQuery *)saveJsonString:(NSString *)jsonString withRecordId:(NSString *)recordId
{
    MongoQuery *mongoQuery = nil;
    
    mongoQuery = [_mongoDB addQueryInQueue:^(MongoQuery *currentMongoQuery) {
        NSString *errorMessage;
        try {
            if ([self authenticateSynchronouslyWithMongoQuery:mongoQuery]) {
                mongo::BSONObj fields = mongo::fromjson([jsonString UTF8String]);
                mongo::BSONObj critical = mongo::fromjson([[NSString stringWithFormat:@"{\"_id\":%@}", recordId] UTF8String]);
                
                if (_mongoDB.replicaConnexion) {
                    _mongoDB.replicaConnexion->update(std::string([_absoluteCollection UTF8String]), critical, fields, false);
                }else {
                    _mongoDB.connexion->update(std::string([_absoluteCollection UTF8String]), critical, fields, false);
                }
            }
        } catch (mongo::DBException &e) {
            errorMessage = [[NSString alloc] initWithUTF8String:e.what()];
            [currentMongoQuery.mutableParameters setObject:errorMessage forKey:@"errormessage"];
            [errorMessage release];
        }
        [self performSelectorOnMainThread:@selector(updateCallback:) withObject:currentMongoQuery waitUntilDone:NO];
    }];
    [mongoQuery.mutableParameters setObject:jsonString forKey:@"jsonstring"];
    [mongoQuery.mutableParameters setObject:recordId forKey:@"recordid"];
    [mongoQuery.mutableParameters setObject:self forKey:@"collection"];
    return mongoQuery;
}

@end
