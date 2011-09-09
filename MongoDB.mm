//
//  Mongo.mm
//  MongoHub
//
//  Created by Syd on 10-4-25.
//  Copyright 2010 MusicPeace.ORG. All rights reserved.
//

#import "MongoDB.h"
#import "NSString+Extras.h"
#import <RegexKit/RegexKit.h>
#import <mongo/client/dbclient.h>
#import <mongo/util/sock.h>
#import "MongoDB_internal.h"
#import "MongoCollection.h"
#import "MongoQuery.h"

extern "C" {
    void MongoDB_enableIPv6(BOOL flag)
    {
        mongo::enableIPv6((flag == YES)?true:false);
    }
}

@implementation MongoDB

@synthesize connected = _connected, delegate = _delegate, serverStatus = _serverStatus, currentMongoQuery = _currentMongoQuery;

- (id)init
{
    if ((self = [super init]) != nil) {
        _operationQueue = [[NSOperationQueue alloc] init];
        [_operationQueue setMaxConcurrentOperationCount:1];
        _serverStatus = [[NSMutableArray alloc] init];
        _databaseList = [[NSMutableDictionary alloc] init];
        self.serverStatusForDelta = new mongo::BSONObj();
    }
    return self;
}

- (void)dealloc
{
    if (self.connexion) {
        delete self.connexion;
    }
    if (self.replicaConnexion) {
        delete self.replicaConnexion;
    }
    if (self.serverStatusForDelta) {
        delete self.serverStatusForDelta;
    }
    [_operationQueue release];
    [_serverStatus release];
    [_databaseList release];
    [super dealloc];
}

- (mongo::DBClientConnection *)connexion
{
    return (mongo::DBClientConnection *)_connexion;
}

- (void)setConnexion:(mongo::DBClientConnection *)connexion
{
    _connexion = connexion;
}

- (mongo::DBClientReplicaSet::DBClientReplicaSet *)replicaConnexion
{
    return (mongo::DBClientReplicaSet::DBClientReplicaSet *)_replicaConnexion;
}

- (void)setReplicaConnexion:(mongo::DBClientReplicaSet::DBClientReplicaSet *)replicaConnexion
{
    _replicaConnexion = replicaConnexion;
}

- (mongo::BSONObj *)serverStatusForDelta
{
    return (mongo::BSONObj *)_serverStatusForDelta;
}

- (void)setServerStatusForDelta:(mongo::BSONObj *)serverStatusForDelta
{
    _serverStatusForDelta = serverStatusForDelta;
}

- (BOOL)authenticateSynchronouslyWithDatabaseName:(NSString *)databaseName userName:(NSString *)user password:(NSString *)password mongoQuery:(MongoQuery *)mongoQuery
{
    BOOL result = YES;
    NSString *errorMessage = nil;
    
    if ([user length] > 0 && [password length] > 0) {
        try {
            std::string errmsg;
            std::string dbname;
            
            if ([databaseName length] == 0) {
                dbname = [databaseName UTF8String];
            }else {
                dbname = "admin";
            }
            if (self.replicaConnexion) {
                result = self.replicaConnexion->auth(dbname, std::string([user UTF8String]), std::string([password UTF8String]), errmsg) == true;
            } else {
                result = self.connexion->auth(dbname, std::string([user UTF8String]), std::string([password UTF8String]), errmsg) == true;
            }
            
            if (!result) {
                errorMessage = [[NSString alloc] initWithUTF8String:errmsg.c_str()];
            }
        } catch (mongo::DBException &e) {
            errorMessage = [[NSString alloc] initWithUTF8String:e.what()];
            result = NO;
        }
        if (errorMessage) {
            [mongoQuery.mutableParameters setObject:errorMessage forKey:@"errormessage"];
            [errorMessage release];
        }
    }
    return result;
}

- (MongoQuery *)addQueryInQueue:(void (^)(MongoQuery *currentMongoQuery))block
{
    MongoQuery *mongoQuery;
    NSBlockOperation *blockOperation;
    
    mongoQuery = [[MongoQuery alloc] init];
    blockOperation = [[NSBlockOperation alloc] init];
    [blockOperation addExecutionBlock:^{
        self.currentMongoQuery = mongoQuery;
        [mongoQuery starts];
        block(mongoQuery);
        self.currentMongoQuery = nil;
    }];
    mongoQuery.blockOperation = blockOperation;
    [_operationQueue addOperation:blockOperation];
    [blockOperation release];
    return [mongoQuery autorelease];
}

- (void)connectCallback:(MongoQuery *)query
{
    NSString *errorMessage;
    
    errorMessage = [query.mutableParameters objectForKey:@"errormessage"];
    if (errorMessage && [_delegate respondsToSelector:@selector(mongoDBConnectionFailed:withMongoQuery:errorMessage:)]) {
        [_delegate mongoDBConnectionFailed:self withMongoQuery:query errorMessage:errorMessage];
    } else if (errorMessage == nil && [_delegate respondsToSelector:@selector(mongoDBConnectionSucceded:withMongoQuery:)]) {
        [_delegate mongoDBConnectionSucceded:self withMongoQuery:query];
    }
    self.connected = (errorMessage == nil);
}

- (MongoQuery *)connectWithHostName:(NSString *)host databaseName:(NSString *)databaseName userName:(NSString *)userName password:(NSString *)password
{
    MongoQuery *query;
    NSAssert(self.connexion == NULL, @"already connected");
    NSAssert(self.replicaConnexion == NULL, @"already connected");
    
    self.connexion = new mongo::DBClientConnection;
    query = [self addQueryInQueue:^(MongoQuery *mongoQuery) {
        std::string error;
        
        if (self.connexion->connect([host UTF8String], error) == false) {
            NSString *errorMessage = nil;
            
            errorMessage = [[NSString alloc] initWithUTF8String:error.c_str()];
            [mongoQuery.mutableParameters setObject:errorMessage forKey:@"errormessage"];
            [errorMessage release];
        } else {
            [self authenticateSynchronouslyWithDatabaseName:databaseName userName:userName password:password mongoQuery:mongoQuery];
        }
        [self performSelectorOnMainThread:@selector(connectCallback:) withObject:mongoQuery waitUntilDone:NO];
    }];
    [query.mutableParameters setObject:databaseName forKey:@"databasename"];
    if (userName) {
        [query.mutableParameters setObject:userName forKey:@"username"];
    }
    if (password) {
        [query.mutableParameters setObject:password forKey:@"password"];
    }
    return query;
}

- (MongoQuery *)connectWithReplicaName:(NSString *)name hosts:(NSArray *)hosts databaseName:(NSString *)databaseName userName:(NSString *)userName password:(NSString *)password
{
    MongoQuery *query;
    NSAssert(self.connexion == NULL, @"already connected");
    NSAssert(self.replicaConnexion == NULL, @"already connected");
    
    std::vector<mongo::HostAndPort> servers;
    for (NSString *h in hosts) {
        mongo::HostAndPort server([h UTF8String]);
        servers.push_back(server);
    }
    self.replicaConnexion = new mongo::DBClientReplicaSet::DBClientReplicaSet([name UTF8String], servers);
    query = [self addQueryInQueue:^(MongoQuery *mongoQuery){
        if (self.replicaConnexion->connect() == false) {
            [mongoQuery.mutableParameters setObject:@"Connection Failed" forKey:@"errormessage"];
        } else {
            [self authenticateSynchronouslyWithDatabaseName:databaseName userName:userName password:password mongoQuery:mongoQuery];
        }
        [self performSelectorOnMainThread:@selector(connectCallback:) withObject:mongoQuery waitUntilDone:NO];
    }];
    [query.mutableParameters setObject:name forKey:@"replicaName"];
    [query.mutableParameters setObject:hosts forKey:@"hosts"];
    [query.mutableParameters setObject:databaseName forKey:@"databasename"];
    if (userName) {
        [query.mutableParameters setObject:userName forKey:@"username"];
    }
    if (password) {
        [query.mutableParameters setObject:password forKey:@"password"];
    }
    return query;
}

- (BOOL)authUser:(NSString *)user 
            pass:(NSString *)pass 
        database:(NSString *)db
{
    try {
        std::string errmsg;
        std::string dbname;
        if ([db isPresent]) {
            dbname = [db UTF8String];
        }else {
            dbname = "admin";
        }
        BOOL ok;
        if (self.replicaConnexion) {
            ok = self.replicaConnexion->auth(dbname, std::string([user UTF8String]), std::string([pass UTF8String]), errmsg);
        }else {
            ok = self.connexion->auth(dbname, std::string([user UTF8String]), std::string([pass UTF8String]), errmsg);
        }
        
        if (!ok) {
            NSRunAlertPanel(@"Error", [NSString stringWithUTF8String:errmsg.c_str()], @"OK", nil, nil);
        }
        return ok;
    }catch (mongo::DBException &e) {
        NSRunAlertPanel(@"Error", [NSString stringWithUTF8String:e.what()], @"OK", nil, nil);
    }
    return false;
}

- (void)fetchDatabaseListCallback:(MongoQuery *)query
{
    NSArray *list;
    
    list = [query.parameters objectForKey:@"databaselist"];
    [self willChangeValueForKey:@"databaseList"];
    if (list) {
        for (NSString *databaseName in list) {
            if (![_databaseList objectForKey:databaseName]) {
                [_databaseList setObject:[NSMutableDictionary dictionary] forKey:databaseName];
            }
        }
        for (NSString *databaseName in [_databaseList allKeys]) {
            if (![list containsObject:databaseName]) {
                [_databaseList removeObjectForKey:databaseName];
            }
        }
    } else {
        [_databaseList removeAllObjects];
    }
    [self didChangeValueForKey:@"databaseList"];
    if ([_delegate respondsToSelector:@selector(mongoDB:databaseListFetched:withMongoQuery:errorMessage:)]) {
        [_delegate mongoDB:self databaseListFetched:list withMongoQuery:query errorMessage:[query.parameters objectForKey:@"errormessage"]];
    }
}

- (MongoQuery *)fetchDatabaseList
{
    return [self addQueryInQueue:^(MongoQuery *mongoQuery) {
        try {
            std::list<std::string> dbs;
            if (self.replicaConnexion) {
                dbs = self.replicaConnexion->getDatabaseNames();
            } else {
                dbs = self.connexion->getDatabaseNames();
            }
            NSMutableArray *dblist = [[NSMutableArray alloc] initWithCapacity:dbs.size()];
            for (std::list<std::string>::iterator it=dbs.begin();it!=dbs.end();++it) {
                NSString *db = [[NSString alloc] initWithUTF8String:(*it).c_str()];
                [dblist addObject:db];
                [db release];
            }
            [mongoQuery.mutableParameters setObject:dblist forKey:@"databaselist"];
            [dblist release];
        } catch (mongo::DBException &e) {
            NSString *errorMessage;
            
            errorMessage = [[NSString alloc] initWithUTF8String:e.what()];
            [mongoQuery.mutableParameters setObject:errorMessage forKey:@"errormessage"];
            [errorMessage release];
        }
        [self performSelectorOnMainThread:@selector(fetchDatabaseListCallback:) withObject:mongoQuery waitUntilDone:NO];
    }];
}

- (void)fetchServerStatusCallback:(MongoQuery *)query
{
    NSArray *serverStatus;
    
    serverStatus = [query.parameters objectForKey:@"serverstatus"];
    [self willChangeValueForKey:@"serverStatus"];
    [_serverStatus removeAllObjects];
    [_serverStatus addObjectsFromArray:serverStatus];
    [self didChangeValueForKey:@"serverStatus"];
    if ([_delegate respondsToSelector:@selector(mongoDB:serverStatusFetched:withMongoQuery:errorMessage:)]) {
        [_delegate mongoDB:self serverStatusFetched:serverStatus withMongoQuery:query errorMessage:[query.parameters objectForKey:@"errormessage"]];
    }
}

- (MongoQuery *)fetchServerStatus
{
    return [self addQueryInQueue:^(MongoQuery *mongoQuery){
        try {
            mongo::BSONObj retval;
            if (self.replicaConnexion) {
                self.replicaConnexion->runCommand("admin", BSON("serverStatus"<<1), retval);
            }else {
                self.connexion->runCommand("admin", BSON("serverStatus"<<1), retval);
            }
            [mongoQuery.mutableParameters setObject:[[self class] bsonDictWrapper:retval] forKey:@"serverstatus"];
        } catch (mongo::DBException &e) {
            NSString *errorMessage;
            
            errorMessage = [[NSString alloc] initWithUTF8String:e.what()];
            [mongoQuery.mutableParameters setObject:errorMessage forKey:@"errormessage"];
            [errorMessage release];
        }
        [self performSelectorOnMainThread:@selector(fetchServerStatusCallback:) withObject:mongoQuery waitUntilDone:NO];
    }];
}

- (void)fetchCollectionListCallback:(MongoQuery *)mongoQuery
{
    NSArray *collectionList;
    NSString *databaseName;
    
    databaseName = [mongoQuery.parameters objectForKey:@"databasename"];
    collectionList = [mongoQuery.parameters objectForKey:@"collectionlist"];
    [self willChangeValueForKey:@"databaseList"];
    if (![_databaseList objectForKey:databaseName]) {
        [_databaseList setObject:[NSMutableDictionary dictionary] forKey:databaseName];
    }
    [[_databaseList objectForKey:databaseName] setObject:collectionList forKey:@"collectionList"];
    [self didChangeValueForKey:@"databaseList"];
    if ([_delegate respondsToSelector:@selector(mongoDB:collectionListFetched:withMongoQuery:errorMessage:)]) {
        [_delegate mongoDB:self collectionListFetched:collectionList withMongoQuery:mongoQuery errorMessage:[mongoQuery.parameters objectForKey:@"errormessage"]];
    }
}

- (MongoQuery *)fetchCollectionListWithDatabaseName:(NSString *)databaseName userName:(NSString *)userName password:(NSString *)password
{
    MongoQuery *query;
    
    query = [self addQueryInQueue:^(MongoQuery *mongoQuery){
        try {
            if ([self authenticateSynchronouslyWithDatabaseName:databaseName userName:userName password:password mongoQuery:mongoQuery]) {
                std::list<std::string> collections;
                if (self.replicaConnexion) {
                    collections = self.replicaConnexion->getCollectionNames([databaseName UTF8String]);
                }else {
                    collections = self.connexion->getCollectionNames([databaseName UTF8String]);
                }
                
                NSMutableArray *collectionList = [NSMutableArray arrayWithCapacity:collections.size() ];
                unsigned int istartp = [databaseName length] + 1;
                for (std::list<std::string>::iterator it=collections.begin();it!=collections.end();++it) {
                    NSString *collection = [[NSString alloc] initWithUTF8String:(*it).c_str()];
                    [collectionList addObject:[collection substringWithRange:NSMakeRange( istartp, [collection length]-istartp )] ];
                    [collection release];
                }
                [mongoQuery.mutableParameters setObject:collectionList forKey:@"collectionlist"];
            }
        } catch (mongo::DBException &e) {
            NSString *errorMessage;
            
            errorMessage = [[NSString alloc] initWithUTF8String:e.what()];
            [mongoQuery.mutableParameters setObject:errorMessage forKey:@"errormessage"];
            [errorMessage release];
        }
        [self performSelectorOnMainThread:@selector(fetchCollectionListCallback:) withObject:mongoQuery waitUntilDone:NO];
    }];
    [query.mutableParameters setObject:databaseName forKey:@"databasename"];
    if (userName) {
        [query.mutableParameters setObject:userName forKey:@"username"];
    }
    if (password) {
        [query.mutableParameters setObject:password forKey:@"password"];
    }
    return query;
}

- (void)fetchDatabaseStatsCallback:(MongoQuery *)mongoQuery
{
    NSArray *databaseStats;
    NSString *databaseName;
    
    databaseName = [mongoQuery.parameters objectForKey:@"databasename"];
    databaseStats = [mongoQuery.parameters objectForKey:@"databasestats"];
    [self willChangeValueForKey:@"databaseList"];
    if (![_databaseList objectForKey:databaseName]) {
        [_databaseList setObject:[NSMutableDictionary dictionary] forKey:databaseName];
    }
    [[_databaseList objectForKey:databaseName] setObject:databaseStats forKey:@"databaseStats"];
    [self didChangeValueForKey:@"databaseList"];
    if ([_delegate respondsToSelector:@selector(mongoDB:databaseStatsFetched:withMongoQuery:errorMessage:)]) {
        [_delegate mongoDB:self databaseStatsFetched:databaseStats withMongoQuery:mongoQuery errorMessage:[mongoQuery.parameters objectForKey:@"errormessage"]];
    }
}

- (MongoQuery *)fetchDatabaseStatsWithDatabaseName:(NSString *)databaseName userName:(NSString *)userName password:(NSString *)password
{
    MongoQuery *query;
    
    query = [self addQueryInQueue:^(MongoQuery *mongoQuery){
        try {
            if ([self authenticateSynchronouslyWithDatabaseName:databaseName userName:userName password:password mongoQuery:mongoQuery]) {
                mongo::BSONObj retval;
                if (self.replicaConnexion) {
                    self.replicaConnexion->runCommand([databaseName UTF8String], BSON("dbstats"<<1), retval);
                }else {
                    self.connexion->runCommand([databaseName UTF8String], BSON("dbstats"<<1), retval);
                }
                [mongoQuery.mutableParameters setObject:[[self class] bsonDictWrapper:retval] forKey:@"databasestats"];
            }
        } catch (mongo::DBException &e) {
            NSString *errorMessage;
            
            errorMessage = [[NSString alloc] initWithUTF8String:e.what()];
            [mongoQuery.mutableParameters setObject:errorMessage forKey:@"errormessage"];
            [errorMessage release];
        }
        [self performSelectorOnMainThread:@selector(fetchDatabaseStatsCallback:) withObject:mongoQuery waitUntilDone:NO];
    }];
    [query.mutableParameters setObject:databaseName forKey:@"databasename"];
    if (userName) {
        [query.mutableParameters setObject:userName forKey:@"username"];
    }
    if (password) {
        [query.mutableParameters setObject:password forKey:@"password"];
    }
    return query;
}

- (void) dropDB:(NSString *)dbname 
                        user:(NSString *)user 
                    password:(NSString *)password 
{
    try {
        if ([user length]>0 && [password length]>0) {
            BOOL ok = [self authUser:user pass:password database:dbname];
            if (!ok) {
                return;
            }
        }
        if (self.replicaConnexion) {
            self.replicaConnexion->dropDatabase([dbname UTF8String]);
        }else {
            self.connexion->dropDatabase([dbname UTF8String]);
        }
        NSLog(@"Drop DB: %@", dbname);
    }catch (mongo::DBException &e) {
        NSRunAlertPanel(@"Error", [NSString stringWithUTF8String:e.what()], @"OK", nil, nil);
    }
}

- (void)fetchCollectionStatsCallback:(MongoQuery *)mongoQuery
{
    NSArray *collectionStats;
    
    collectionStats = [mongoQuery.parameters objectForKey:@"collectionstats"];
    if ([_delegate respondsToSelector:@selector(mongoDB:collectionStatsFetched:withMongoQuery:errorMessage:)]) {
        [_delegate mongoDB:self collectionStatsFetched:collectionStats withMongoQuery:mongoQuery errorMessage:[mongoQuery.parameters objectForKey:@"errormessage"]];
    }
}

- (MongoQuery *)fetchCollectionStatsWithCollectionName:(NSString *)collectionName databaseName:(NSString *)databaseName userName:(NSString *)userName password:(NSString *)password
{
    MongoQuery *query;
    
    query = [self addQueryInQueue:^(MongoQuery *mongoQuery){
        try {
            if ([self authenticateSynchronouslyWithDatabaseName:databaseName userName:userName password:password mongoQuery:mongoQuery]) {
                mongo::BSONObj retval;
                
                if (self.replicaConnexion) {
                    self.replicaConnexion->runCommand([databaseName UTF8String], BSON("collstats"<<[collectionName UTF8String]), retval);
                }else {
                    self.connexion->runCommand([databaseName UTF8String], BSON("collstats"<<[collectionName UTF8String]), retval);
                }
                [mongoQuery.mutableParameters setObject:[[self class] bsonDictWrapper:retval] forKey:@"collectionstats"];
            }
        } catch (mongo::DBException &e) {
            NSString *errorMessage;
            
            errorMessage = [[NSString alloc] initWithUTF8String:e.what()];
            [mongoQuery.mutableParameters setObject:errorMessage forKey:@"errormessage"];
            [errorMessage release];
        }
        [self performSelectorOnMainThread:@selector(fetchCollectionStatsCallback:) withObject:mongoQuery waitUntilDone:NO];
    }];
    [query.mutableParameters setObject:collectionName forKey:@"collectionname"];
    [query.mutableParameters setObject:databaseName forKey:@"databasename"];
    if (userName) {
        [query.mutableParameters setObject:userName forKey:@"username"];
    }
    if (password) {
        [query.mutableParameters setObject:password forKey:@"password"];
    }
    return query;
}


- (void)dropDatabaseCallback:(MongoQuery *)mongoQuery
{
    NSString *errorMessage;
    
    errorMessage = [mongoQuery.parameters objectForKey:@"errormessage"];
    if ([_delegate respondsToSelector:@selector(mongoDB:databaseDropedWithMongoQuery:errorMessage:)]) {
        [_delegate mongoDB:self databaseDropedWithMongoQuery:mongoQuery errorMessage:errorMessage];
    }
}

- (MongoQuery *)dropDatabaseWithName:(NSString *)databaseName userName:(NSString *)userName password:(NSString *)password
{
    MongoQuery *query;
    
    query = [self addQueryInQueue:^(MongoQuery *mongoQuery){
        try {
            if ([self authenticateSynchronouslyWithDatabaseName:databaseName userName:userName password:password mongoQuery:mongoQuery]) {
                if (self.replicaConnexion) {
                    self.replicaConnexion->dropDatabase([databaseName UTF8String]);
                }else {
                    self.connexion->dropDatabase([databaseName UTF8String]);
                }
            }
        } catch (mongo::DBException &e) {
            NSString *errorMessage;
            
            errorMessage = [[NSString alloc] initWithUTF8String:e.what()];
            [mongoQuery.mutableParameters setObject:errorMessage forKey:@"errormessage"];
            [errorMessage release];
        }
        [self performSelectorOnMainThread:@selector(dropDatabaseCallback:) withObject:mongoQuery waitUntilDone:NO];
    }];
    [query.mutableParameters setObject:databaseName forKey:@"databasename"];
    if (userName) {
        [query.mutableParameters setObject:userName forKey:@"username"];
    }
    if (password) {
        [query.mutableParameters setObject:password forKey:@"password"];
    }
    return query;
}

- (void)createCollectionCallback:(MongoQuery *)mongoQuery
{
    NSString *errorMessage;
    
    errorMessage = [mongoQuery.parameters objectForKey:@"errormessage"];
    if ([_delegate respondsToSelector:@selector(mongoDB:collectionCreatedWithMongoQuery:errorMessage:)]) {
        [_delegate mongoDB:self collectionCreatedWithMongoQuery:mongoQuery errorMessage:errorMessage];
    }
}

- (MongoQuery *)createCollectionWithName:(NSString *)collectionName databaseName:(NSString *)databaseName userName:(NSString *)userName password:(NSString *)password
{
    MongoQuery *query;
    
    query = [self addQueryInQueue:^(MongoQuery *mongoQuery){
        NSString *collection;
        
        collection = [[NSString alloc] initWithFormat:@"%@.%@", databaseName, collectionName];
        try {
            if ([self authenticateSynchronouslyWithDatabaseName:databaseName userName:userName password:password mongoQuery:mongoQuery]) {
                if (self.replicaConnexion) {
                    self.replicaConnexion->createCollection([collection UTF8String]);
                } else {
                    self.connexion->createCollection([collection UTF8String]);
                }
            }
        } catch (mongo::DBException &e) {
            NSString *errorMessage;
            
            errorMessage = [[NSString alloc] initWithUTF8String:e.what()];
            [mongoQuery.mutableParameters setObject:errorMessage forKey:@"errormessage"];
            [errorMessage release];
        }
        [self performSelectorOnMainThread:@selector(createCollectionCallback:) withObject:mongoQuery waitUntilDone:NO];
        [collection release];
    }];
    [query.mutableParameters setObject:databaseName forKey:@"databasename"];
    [query.mutableParameters setObject:collectionName forKey:@"collectionname"];
    if (userName) {
        [query.mutableParameters setObject:userName forKey:@"username"];
    }
    if (password) {
        [query.mutableParameters setObject:password forKey:@"password"];
    }
    return query;
}

- (void)dropCollectionCallback:(MongoQuery *)mongoQuery
{
    NSString *errorMessage;
    
    errorMessage = [mongoQuery.parameters objectForKey:@"errormessage"];
    if ([_delegate respondsToSelector:@selector(mongoDB:collectionDropedWithMongoQuery:errorMessage:)]) {
        [_delegate mongoDB:self collectionDropedWithMongoQuery:mongoQuery errorMessage:errorMessage];
    }
}

- (MongoQuery *)dropCollectionWithName:(NSString *)collectionName databaseName:(NSString *)databaseName userName:(NSString *)userName password:(NSString *)password
{
    MongoQuery *query;
    query = [self addQueryInQueue:^(MongoQuery *mongoQuery){
        try {
            if ([self authenticateSynchronouslyWithDatabaseName:databaseName userName:userName password:password mongoQuery:mongoQuery]) {
                NSString *col = [NSString stringWithFormat:@"%@.%@", databaseName, collectionName];
                if (self.replicaConnexion) {
                    self.replicaConnexion->dropCollection([col UTF8String]);
                } else {
                    self.connexion->dropCollection([col UTF8String]);
                }
            }
        } catch (mongo::DBException &e) {
            NSString *errorMessage;
            
            errorMessage = [[NSString alloc] initWithUTF8String:e.what()];
            [mongoQuery.mutableParameters setObject:errorMessage forKey:@"errormessage"];
            [errorMessage release];
        }
        [self performSelectorOnMainThread:@selector(dropCollectionCallback:) withObject:mongoQuery waitUntilDone:NO];
    }];
    [query.mutableParameters setObject:databaseName forKey:@"databasename"];
    [query.mutableParameters setObject:collectionName forKey:@"collectionname"];
    if (userName) {
        [query.mutableParameters setObject:userName forKey:@"username"];
    }
    if (password) {
        [query.mutableParameters setObject:password forKey:@"password"];
    }
    return query;
}

- (MongoCollection *)mongoCollectionWithDatabaseName:(NSString *)databaseName collectionName:(NSString *)collectionName userName:(NSString *)userName password:(NSString *)password
{
    return [[[MongoCollection alloc] initWithMongoDB:self databaseName:databaseName collectionName:collectionName userName:userName password:password] autorelease];
}

- (void) saveInDB:(NSString *)dbname 
       collection:(NSString *)collectionname 
             user:(NSString *)user 
         password:(NSString *)password 
       jsonString:(NSString *)jsonString 
              _id:(NSString *)_id
{
    try {
        if ([user length]>0 && [password length]>0) {
            BOOL ok = [self authUser:user pass:password database:dbname];
            if (!ok) {
                return;
            }
        }
        NSString *col = [NSString stringWithFormat:@"%@.%@", dbname, collectionname];NSLog(@"%@", jsonString);NSLog(@"%@", _id);
        mongo::BSONObj fields = mongo::fromjson([jsonString UTF8String]);
        mongo::BSONObj critical = mongo::fromjson([[NSString stringWithFormat:@"{\"_id\":%@}", _id] UTF8String]);
        
        if (self.replicaConnexion) {
            self.replicaConnexion->update(std::string([col UTF8String]), critical, fields, false);
        }else {
            self.connexion->update(std::string([col UTF8String]), critical, fields, false);
        }
        NSLog(@"save in db: %@.%@", dbname, collectionname);
    }catch (mongo::DBException &e) {
        NSRunAlertPanel(@"Error", [NSString stringWithUTF8String:e.what()], @"OK", nil, nil);
    }
}

- (void) removeInDB:(NSString *)dbname 
         collection:(NSString *)collectionname 
               user:(NSString *)user 
           password:(NSString *)password 
           critical:(NSString *)critical
{
    try {
        if ([user length]>0 && [password length]>0) {
            BOOL ok = [self authUser:user pass:password database:dbname];
            if (!ok) {
                return;
            }
        }
        NSString *col = [NSString stringWithFormat:@"%@.%@", dbname, collectionname];
        mongo::BSONObj criticalBSON;
        if ([critical isPresent]) {
            try{
                criticalBSON = mongo::fromjson([critical UTF8String]);
            }catch (mongo::MsgAssertionException &e) {
                NSRunAlertPanel(@"Error", [NSString stringWithUTF8String:e.what()], @"OK", nil, nil);
                return;
            }
            if (self.replicaConnexion) {
                self.replicaConnexion->remove(std::string([col UTF8String]), criticalBSON);
            }else {
                self.connexion->remove(std::string([col UTF8String]), criticalBSON);
            }

        }
        NSLog(@"Remove in db: %@.%@", dbname, collectionname);
    }catch (mongo::DBException &e) {
        NSRunAlertPanel(@"Error", [NSString stringWithUTF8String:e.what()], @"OK", nil, nil);
    }
}

- (void) insertInDB:(NSString *)dbname 
         collection:(NSString *)collectionname 
               user:(NSString *)user 
           password:(NSString *)password 
           insertData:(NSString *)insertData
{
    try {
        if ([user length]>0 && [password length]>0) {
            BOOL ok = [self authUser:user pass:password database:dbname];
            if (!ok) {
                return;
            }
        }
        NSString *col = [NSString stringWithFormat:@"%@.%@", dbname, collectionname];
        mongo::BSONObj insertDataBSON;
        if ([insertData isPresent]) {
            try{
                insertDataBSON = mongo::fromjson([insertData UTF8String]);
            }catch (mongo::MsgAssertionException &e) {
                NSRunAlertPanel(@"Error", [NSString stringWithUTF8String:e.what()], @"OK", nil, nil);
                return;
            }
            if (self.replicaConnexion) {
                self.replicaConnexion->insert(std::string([col UTF8String]), insertDataBSON);
            }else {
                self.connexion->insert(std::string([col UTF8String]), insertDataBSON);
            }

        }
        NSLog(@"Insert into db: %@.%@", dbname, collectionname);
    }catch (mongo::DBException &e) {
        NSRunAlertPanel(@"Error", [NSString stringWithUTF8String:e.what()], @"OK", nil, nil);
    }
}

- (void) insertInDB:(NSString *)dbname 
         collection:(NSString *)collectionname 
               user:(NSString *)user 
           password:(NSString *)password 
               data:(NSDictionary *)insertData 
             fields:(NSArray *)fields 
         fieldTypes:(NSDictionary *)fieldTypes 
{
    try {
        if ([user length]>0 && [password length]>0) {
            BOOL ok = [self authUser:user pass:password database:dbname];
            if (!ok) {
                return;
            }
        }
        NSString *col = [NSString stringWithFormat:@"%@.%@", dbname, collectionname];
        mongo::BSONObjBuilder b;
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        for (int i=0; i<[fields count]; i++) {
            NSString *fieldName = [fields objectAtIndex:i];
            NSString *ft = [fieldTypes objectForKey:fieldName];
            id aValue = [insertData objectForKey:fieldName];
            if (aValue == [NSString nullValue])
                b.appendNull([fieldName UTF8String]);
            else if ([ft isEqualToString:@"varstring"] || [ft isEqualToString:@"string"])
                b.append([fieldName UTF8String], [aValue UTF8String]);
            else if ([ft isEqualToString:@"float"])
                b.append([fieldName UTF8String], [aValue floatValue]);
            else if ([ft isEqualToString:@"double"] || [ft isEqualToString:@"decimal"])
                b.append([fieldName UTF8String], [aValue doubleValue]);
            else if ([ft isEqualToString:@"longlong"])
                b.append([fieldName UTF8String], [aValue longLongValue]);
            else if ([ft isEqualToString:@"bool"])
                b.append([fieldName UTF8String], [aValue boolValue]);
            else if ([ft isEqualToString:@"int24"] || [ft isEqualToString:@"long"])
                b.append([fieldName UTF8String], [aValue intValue]);
            else if ([ft isEqualToString:@"tiny"] || [ft isEqualToString:@"short"])
                b.append([fieldName UTF8String], [aValue shortValue]);
            else if ([ft isEqualToString:@"date"]) {
                time_t timestamp = [aValue timeIntervalSince1970];
                b.appendDate([fieldName UTF8String], timestamp);
            }else if ([ft isEqualToString:@"datetime"] || [ft isEqualToString:@"timestamp"] || [ft isEqualToString:@"year"]) {
                time_t timestamp = [aValue timeIntervalSince1970];
                b.appendTimeT([fieldName UTF8String], timestamp);
            }else if ([ft isEqualToString:@"time"]) {
                [dateFormatter setDateFormat:@"HH:mm:ss"];
                NSDate *dateFromString = [dateFormatter dateFromString:aValue];
                time_t timestamp = [dateFromString timeIntervalSince1970];
                b.appendTimeT([fieldName UTF8String], timestamp);
            }else if ([ft isEqualToString:@"blob"]) {
                if ([aValue isKindOfClass:[NSString class]]) {
                    b.append([fieldName UTF8String], [aValue UTF8String]);
                }else {
                    int bLen = [aValue length];
                    mongo::BinDataType binType = (mongo::BinDataType)0;
                    const char *bData = (char *)[aValue bytes];
                    b.appendBinData([fieldName UTF8String], bLen, binType, bData);
                }
            }
        }
        [dateFormatter release];
        mongo::BSONObj insertDataBSON = b.obj();
        mongo::BSONObj emptyBSON;
        if (insertDataBSON == emptyBSON) {
            return;
        }
        if (self.replicaConnexion) {
            self.replicaConnexion->insert(std::string([col UTF8String]), insertDataBSON);
        }else {
            self.connexion->insert(std::string([col UTF8String]), insertDataBSON);
        }
        NSLog(@"Find in db with filetype: %@.%@", dbname, collectionname);
    }catch (mongo::DBException &e) {
        NSRunAlertPanel(@"Error", [NSString stringWithUTF8String:e.what()], @"OK", nil, nil);
    }
}

- (NSArray *) indexInDB:(NSString *)dbname 
         collection:(NSString *)collectionname 
               user:(NSString *)user 
           password:(NSString *)password
{
    try {
        if ([user length]>0 && [password length]>0) {
            BOOL ok = [self authUser:user pass:password database:dbname];
            if (!ok) {
                return nil;
            }
        }
        NSString *col = [NSString stringWithFormat:@"%@.%@", dbname, collectionname];
        std::auto_ptr<mongo::DBClientCursor> cursor;
        if (self.replicaConnexion) {
            cursor = self.replicaConnexion->getIndexes(std::string([col UTF8String]));
        }else {
            cursor = self.connexion->getIndexes(std::string([col UTF8String]));
        }
        NSMutableArray *response = [[NSMutableArray alloc] init];
        while( cursor->more() )
        {
            mongo::BSONObj b = cursor->next();
            NSString *name = [[NSString alloc] initWithUTF8String:b.getStringField("name")];
            NSMutableDictionary *item = [[NSMutableDictionary alloc] initWithCapacity:4];
            [item setObject:@"name" forKey:@"name"];
            [item setObject:@"String" forKey:@"type"];
            [item setObject:name forKey:@"value"];
            [item setObject:[[self class] bsonDictWrapper:b] forKey:@"child"];
            [response addObject:item];
            [name release];
            [item release];
        }
        NSLog(@"Show indexes in db: %@.%@", dbname, collectionname);
        return [response autorelease];
    }catch (mongo::DBException &e) {
        NSRunAlertPanel(@"Error", [NSString stringWithUTF8String:e.what()], @"OK", nil, nil);
    }
    return nil;
}

- (void) ensureIndexInDB:(NSString *)dbname 
         collection:(NSString *)collectionname 
               user:(NSString *)user 
           password:(NSString *)password 
         indexData:(NSString *)indexData
{
    try {
        if ([user length]>0 && [password length]>0) {
            BOOL ok = [self authUser:user pass:password database:dbname];
            if (!ok) {
                return;
            }
        }
        NSString *col = [NSString stringWithFormat:@"%@.%@", dbname, collectionname];
        mongo::BSONObj indexDataBSON;
        if ([indexData isPresent]) {
            try{
                indexDataBSON = mongo::fromjson([indexData UTF8String]);
            }catch (mongo::MsgAssertionException &e) {
                NSRunAlertPanel(@"Error", [NSString stringWithUTF8String:e.what()], @"OK", nil, nil);
                return;
            }
        }
        if (self.replicaConnexion) {
            self.replicaConnexion->ensureIndex(std::string([col UTF8String]), indexDataBSON);
        }else {
            self.connexion->ensureIndex(std::string([col UTF8String]), indexDataBSON);
        }
        NSLog(@"Ensure index in db: %@.%@", dbname, collectionname);
    }catch (mongo::DBException &e) {
        NSRunAlertPanel(@"Error", [NSString stringWithUTF8String:e.what()], @"OK", nil, nil);
    }
}

- (void) reIndexInDB:(NSString *)dbname 
              collection:(NSString *)collectionname 
                    user:(NSString *)user 
                password:(NSString *)password
{
    try {
        if ([user length]>0 && [password length]>0) {
            BOOL ok = [self authUser:user pass:password database:dbname];
            if (!ok) {
                return;
            }
        }
        NSString *col = [NSString stringWithFormat:@"%@.%@", dbname, collectionname];
        if (self.replicaConnexion) {
            self.replicaConnexion->reIndex(std::string([col UTF8String]));
        }else {
            self.connexion->reIndex(std::string([col UTF8String]));
        }
        NSLog(@"Reindex in db: %@.%@", dbname, collectionname);
    }catch (mongo::DBException &e) {
        NSRunAlertPanel(@"Error", [NSString stringWithUTF8String:e.what()], @"OK", nil, nil);
    }
}

- (void) dropIndexInDB:(NSString *)dbname 
              collection:(NSString *)collectionname 
                    user:(NSString *)user 
                password:(NSString *)password 
               indexName:(NSString *)indexName
{
    try {
        if ([user length]>0 && [password length]>0) {
            BOOL ok = [self authUser:user pass:password database:dbname];
            if (!ok) {
                return;
            }
        }
        NSString *col = [NSString stringWithFormat:@"%@.%@", dbname, collectionname];
        if (self.replicaConnexion) {
            self.replicaConnexion->dropIndex(std::string([col UTF8String]), [indexName UTF8String]);
        }else {
            self.connexion->dropIndex(std::string([col UTF8String]), [indexName UTF8String]);
        }
        NSLog(@"Drop index in db: %@.%@", dbname, collectionname);
    }catch (mongo::DBException &e) {
        NSRunAlertPanel(@"Error", [NSString stringWithUTF8String:e.what()], @"OK", nil, nil);
    }
}

- (long long int) countInDB:(NSString *)dbname 
                   collection:(NSString *)collectionname 
                         user:(NSString *)user 
                     password:(NSString *)password 
                     critical:(NSString *)critical 
{
    try {
        if ([user length]>0 && [password length]>0) {
            BOOL ok = [self authUser:user pass:password database:dbname];
            if (!ok) {
                return 0;
            }
        }
        NSString *col = [NSString stringWithFormat:@"%@.%@", dbname, collectionname];
        if (!critical) {
            critical = @"{}";
        }
        mongo::BSONObj criticalBSON = mongo::fromjson([critical UTF8String]);
        long long int counter;
        if (self.replicaConnexion) {
            counter = self.replicaConnexion->count(std::string([col UTF8String]), criticalBSON);
        }else {
            counter = self.connexion->count(std::string([col UTF8String]), criticalBSON);
        }
        NSLog(@"Count in db: %@.%@ %lld", dbname, collectionname, counter);
        return counter;
    }catch (mongo::DBException &e) {
        NSRunAlertPanel(@"Error", [NSString stringWithUTF8String:e.what()], @"OK", nil, nil);
    }
    return 0;
}

- (NSArray *)mapReduceInDB:dbname 
                       collection:collectionname 
                             user:user 
                         password:password 
                            mapJs:mapJs 
                         reduceJs:reduceJs 
                         critical:critical 
                           output:output
{
    try {
        if ([user length]>0 && [password length]>0) {
            BOOL ok = [self authUser:user pass:password database:dbname];
            if (!ok) {
                return nil;
            }
        }
        if (![mapJs isPresent] || ![reduceJs isPresent]) {
            return nil;
        }
        NSString *col = [NSString stringWithFormat:@"%@.%@", dbname, collectionname];
        mongo::BSONObj criticalBSON = mongo::fromjson([critical UTF8String]);
        mongo::BSONObj retval;
        if (self.replicaConnexion) {
            retval = self.replicaConnexion->mapreduce(std::string([col UTF8String]), std::string([mapJs UTF8String]), std::string([reduceJs UTF8String]), criticalBSON, std::string([output UTF8String]));
        }else {
            retval = self.connexion->mapreduce(std::string([col UTF8String]), std::string([mapJs UTF8String]), std::string([reduceJs UTF8String]), criticalBSON, std::string([output UTF8String]));
        }
        NSLog(@"Map reduce in db: %@.%@", dbname, collectionname);
        return [[self class] bsonDictWrapper:retval];
    }catch (mongo::DBException &e) {
        NSRunAlertPanel(@"Error", [NSString stringWithUTF8String:e.what()], @"OK", nil, nil);
    }
    return nil;
}

+ (double) diff:(NSString *)aName first:(mongo::BSONObj)a second:(mongo::BSONObj)b timeInterval:(NSTimeInterval)interval{
    std::string name = std::string([aName UTF8String]);
    mongo::BSONElement x = a.getFieldDotted( name.c_str() );
    mongo::BSONElement y = b.getFieldDotted( name.c_str() );
    if ( ! x.isNumber() || ! y.isNumber() )
        return -1;
    return ( y.number() - x.number() ) / interval;
}

+ (double) percent:(NSString *)aOut value:(NSString *)aVal first:(mongo::BSONObj)a second:(mongo::BSONObj)b {
    const char * outof = [aOut UTF8String];
    const char * val = [aVal UTF8String];
    double x = ( b.getFieldDotted( val ).number() - a.getFieldDotted( val ).number() );
    double y = ( b.getFieldDotted( outof ).number() - a.getFieldDotted( outof ).number() );
    if ( y == 0 )
        return 0;
    double p = x / y;
    p = (double)((int)(p * 1000)) / 10;
    return p;
}

+ (NSDictionary *) serverMonitor:(mongo::BSONObj)a second:(mongo::BSONObj)b currentDate:(NSDate *)now previousDate:(NSDate *)previous
{
    NSMutableDictionary *res = [[NSMutableDictionary alloc] initWithCapacity:14];
    [res setObject:now forKey:@"time"];
    NSTimeInterval interval = [now timeIntervalSinceDate:previous];
    if ( b["opcounters"].type() == mongo::Object ) {
        mongo::BSONObj ax = a["opcounters"].embeddedObject();
        mongo::BSONObj bx = b["opcounters"].embeddedObject();
        mongo::BSONObjIterator i( bx );
        while ( i.more() ){
            mongo::BSONElement e = i.next();
            NSString *key = [NSString stringWithUTF8String:e.fieldName()];
            [res setObject:[NSNumber numberWithInt:[self diff:key first:ax second:bx timeInterval:interval]] forKey:key];
        }
    }
    if ( b["backgroundFlushing"].type() == mongo::Object ){
        mongo::BSONObj ax = a["backgroundFlushing"].embeddedObject();
        mongo::BSONObj bx = b["backgroundFlushing"].embeddedObject();
        [res setObject:[NSNumber numberWithInt:[self diff:@"flushes" first:ax second:bx timeInterval:interval]] forKey:@"flushes"];
    }
    if ( b.getFieldDotted("mem.supported").trueValue() ){
        mongo::BSONObj bx = b["mem"].embeddedObject();
        [res setObject:[NSNumber numberWithInt:bx["mapped"].numberInt()] forKey:@"mapped"];
        [res setObject:[NSNumber numberWithInt:bx["virtual"].numberInt()] forKey:@"vsize"];
        [res setObject:[NSNumber numberWithInt:bx["resident"].numberInt()] forKey:@"res"];
    }
    if ( b["extra_info"].type() == mongo::Object ){
        mongo::BSONObj ax = a["extra_info"].embeddedObject();
        mongo::BSONObj bx = b["extra_info"].embeddedObject();
        if ( ax["page_faults"].type() || ax["page_faults"].type() )
            [res setObject:[NSNumber numberWithInt:[self diff:@"page_faults" first:ax second:bx timeInterval:interval]] forKey:@"faults"];
    }
    [res setObject:[NSNumber numberWithInt:[self percent:@"globalLock.totalTime" value:@"globalLock.lockTime" first:a second:b]] forKey:@"locked"];
    [res setObject:[NSNumber numberWithInt:[self percent:@"indexCounters.btree.accesses" value:@"indexCounters.btree.misses" first:a second:b]] forKey:@"misses"];
    [res setObject:[NSNumber numberWithInt:b.getFieldDotted( "connections.current" ).numberInt()] forKey:@"conn"];
    return (NSDictionary *)res;
}

- (void)fetchServerStatusDeltaCallback:(MongoQuery *)mongoQuery
{
    NSDictionary *serverStatusDelta;
    
    serverStatusDelta = [mongoQuery.parameters objectForKey:@"serverstatusdelta"];
    if ([_delegate respondsToSelector:@selector(mongoDB:serverStatusDeltaFetched:withMongoQuery:errorMessage:)]) {
        [_delegate mongoDB:self serverStatusDeltaFetched:serverStatusDelta withMongoQuery:mongoQuery errorMessage:[mongoQuery.parameters objectForKey:@"errormessage"]];
    }
}

- (MongoQuery *)fetchServerStatusDelta
{
    return [self addQueryInQueue:^(MongoQuery *mongoQuery){
        try {
            mongo::BSONObj currentStats;
            NSDate *currentDate;
            NSDictionary *serverStatusDelta = nil;
            
            if (self.replicaConnexion) {
                self.replicaConnexion->runCommand("admin", BSON("serverStatus"<<1), currentStats);
            }else {
                self.connexion->runCommand("admin", BSON("serverStatus"<<1), currentStats);
            }
            currentDate = [[NSDate alloc] init];
            if (_dateForDelta) {
                serverStatusDelta = [[self class] serverMonitor:*self.serverStatusForDelta second:currentStats currentDate:currentDate previousDate:_dateForDelta];
            }
            [_dateForDelta release];
            _dateForDelta = currentDate;
            *self.serverStatusForDelta = currentStats;
            
            if (serverStatusDelta) {
                [mongoQuery.mutableParameters setObject:serverStatusDelta forKey:@"serverstatusdelta"];
            }
        } catch( mongo::DBException &e ) {
            NSString *errorMessage;
            
            errorMessage = [[NSString alloc] initWithUTF8String:e.what()];
            [mongoQuery.mutableParameters setObject:errorMessage forKey:@"errormessage"];
            [errorMessage release];
        }
        [self performSelectorOnMainThread:@selector(fetchServerStatusDeltaCallback:) withObject:mongoQuery waitUntilDone:NO];
    }];
}

#pragma mark BSON to NSMutableArray
+ (NSArray *) bsonDictWrapper:(mongo::BSONObj)retval
{
    if (!retval.isEmpty())
    {
        std::set<std::string> fieldNames;
        retval.getFieldNames(fieldNames);
        NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:fieldNames.size()];
        for(std::set<std::string>::iterator it=fieldNames.begin();it!=fieldNames.end();++it)
        {
            mongo::BSONElement e = retval.getField((*it));
            NSString *fieldName = [[NSString alloc] initWithUTF8String:(*it).c_str()];
            NSMutableArray *child = [[NSMutableArray alloc] init];
            NSString *value;
            NSString *fieldType;
            if (e.type() == mongo::Array) {
                mongo::BSONObj b = e.embeddedObject();
                NSMutableArray *tmp = [[self bsonArrayWrapper:b] mutableCopy];
                if (tmp!=nil) {
                    [child release];
                    child = [tmp retain];
                    value = @"";
                }else {
                    value = @"[ ]";
                }

                fieldType = @"Array";
                [tmp release];
            }else if (e.type() == mongo::Object) {
                mongo::BSONObj b = e.embeddedObject();
                NSMutableArray *tmp = [[self bsonDictWrapper:b] mutableCopy];
                if (tmp!=nil) {
                    [child release];
                    child = [tmp retain];
                    value = @"";
                }else {
                    value = @"{ }";
                }

                fieldType = @"Object";
                [tmp release];
            }else{
                if (e.type() == mongo::jstNULL) {
                    fieldType = @"NULL";
                    value = @"NULL";
                }else if (e.type() == mongo::Bool) {
                    fieldType = @"Bool";
                    if (e.boolean()) {
                        value = @"YES";
                    }else {
                        value = @"NO";
                    }
                }else if (e.type() == mongo::NumberDouble) {
                    fieldType = @"Double";
                    value = [NSString stringWithFormat:@"%f", e.numberDouble()];
                }else if (e.type() == mongo::NumberInt) {
                    fieldType = @"Int";
                    value = [NSString stringWithFormat:@"%d", (int)(e.numberInt())];
                }else if (e.type() == mongo::Date) {
                    fieldType = @"Date";
                    mongo::Date_t dt = (time_t)e.date();
                    time_t timestamp = dt / 1000;
                    NSDate *someDate = [NSDate dateWithTimeIntervalSince1970:timestamp];
                    value = [someDate description];
                }else if (e.type() == mongo::Timestamp) {
                    fieldType = @"Timestamp";
                    time_t timestamp = (time_t)e.timestampTime();
                    NSDate *someDate = [NSDate dateWithTimeIntervalSince1970:timestamp];
                    value = [someDate description];
                }else if (e.type() == mongo::BinData) {
                    //int binlen;
                    fieldType = @"BinData";
                    //value = [NSString stringWithUTF8String:e.binData(binlen)];
                    value = @"binary";
                }else if (e.type() == mongo::NumberLong) {
                    fieldType = @"Long";
                    value = [NSString stringWithFormat:@"%qi", e.numberLong()];
                }else if ([fieldName isEqualToString:@"_id" ]) {
                    if (e.type() == mongo::jstOID)
                    {
                        fieldType = @"ObjectId";
                        value = [NSString stringWithUTF8String:e.__oid().str().c_str()];
                    }else {
                        fieldType = @"String";
                        value = [NSString stringWithUTF8String:e.str().c_str()];
                    }
                }else if (e.type() == mongo::jstOID) {
                    fieldType = @"ObjectId";
                    value = [NSString stringWithUTF8String:e.__oid().str().c_str()];
                }else {
                    fieldType = @"String";
                    value = [NSString stringWithUTF8String:e.str().c_str()];
                }
            }
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:4];
            [dict setObject:fieldName forKey:@"name"];
            [dict setObject:fieldType forKey:@"type"];
            [dict setObject:value forKey:@"value"];
            [dict setObject:child forKey:@"child"];
            [arr addObject:dict];
            [dict release];
            [fieldName release];
            [child release];
        }
        return [arr autorelease];
    }
    return nil;
}

+ (NSArray *) bsonArrayWrapper:(mongo::BSONObj)retval
{
    if (!retval.isEmpty())
    {
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        mongo::BSONElement idElm;
        BOOL hasId = retval.getObjectID(idElm);
        mongo::BSONObjIterator it (retval);
        unsigned int i=0;
        while(it.more())
        {
            mongo::BSONElement e = it.next();
            NSString *fieldName = [[NSString alloc] initWithFormat:@"%d", i];
            NSString *value;
            NSString *fieldType;
            NSMutableArray *child = [[NSMutableArray alloc] init];
            if (e.type() == mongo::Array) {
                mongo::BSONObj b = e.embeddedObject();
                NSMutableArray *tmp = [[self bsonArrayWrapper:b] mutableCopy];
                if (tmp == nil) {
                    value = @"[ ]";
                    if (hasId) {
                        [arr addObject:@"[ ]"];
                    }
                }else {
                    [child release];
                    child = [tmp retain];
                    value = @"";
                    if (hasId) {
                        [arr addObject:tmp];
                    }
                }
                fieldType = @"Array";
                [tmp release];
            }else if (e.type() == mongo::Object) {
                mongo::BSONObj b = e.embeddedObject();
                NSMutableArray *tmp = [[self bsonDictWrapper:b] mutableCopy];
                if (tmp == nil) {
                    value = @"";
                    if (hasId) {
                        [arr addObject:@"{ }"];
                    }
                }else {
                    [child release];
                    child = [tmp retain];
                    value = @"{ }";
                    if (hasId) {
                        [arr addObject:tmp];
                    }
                }
                fieldType = @"Object";
                [tmp release];
            }else{
                if (e.type() == mongo::jstNULL) {
                    fieldType = @"NULL";
                    value = @"NULL";
                }else if (e.type() == mongo::Bool) {
                    fieldType = @"Bool";
                    if (e.boolean()) {
                        value = @"YES";
                    }else {
                        value = @"NO";
                    }
                    if (hasId) {
                        [arr addObject:[NSNumber numberWithBool:e.boolean()]];
                    }
                }else if (e.type() == mongo::NumberDouble) {
                    fieldType = @"Double";
                    value = [NSString stringWithFormat:@"%f", e.numberDouble()];
                    if (hasId) {
                        [arr addObject:[NSNumber numberWithDouble:e.numberDouble()]];
                    }
                }else if (e.type() == mongo::NumberInt) {
                    fieldType = @"Int";
                    value = [NSString stringWithFormat:@"%d", (int)(e.numberInt())];
                    if (hasId) {
                        [arr addObject:[NSNumber numberWithInt:e.numberInt()]];
                    }
                }else if (e.type() == mongo::Date) {
                    fieldType = @"Date";
                    mongo::Date_t dt = (time_t)e.date();
                    time_t timestamp = dt / 1000;
                    NSDate *someDate = [NSDate dateWithTimeIntervalSince1970:timestamp];
                    value = [someDate description];
                    if (hasId) {
                        [arr addObject:[someDate description]];
                    }
                }else if (e.type() == mongo::Timestamp) {
                    fieldType = @"Timestamp";
                    time_t timestamp = (time_t)e.timestampTime();
                    NSDate *someDate = [NSDate dateWithTimeIntervalSince1970:timestamp];
                    value = [someDate description];
                    if (hasId) {
                        [arr addObject:[someDate description]];
                    }
                }else if (e.type() == mongo::BinData) {
                    fieldType = @"BinData";
                    //int binlen;
                    //value = [NSString stringWithUTF8String:e.binData(binlen)];
                    value = @"binary";
                    if (hasId) {
                        //[arr addObject:[NSString stringWithUTF8String:e.binData(binlen)]];
                        [arr addObject:@"binary"];
                    }
                }else if (e.type() == mongo::NumberLong) {
                    fieldType = @"Long";
                    value = [NSString stringWithFormat:@"%qi", e.numberLong()];
                    if (hasId) {
                        [arr addObject:[NSString stringWithFormat:@"%qi", e.numberLong()]];
                    }
                }else if (e.type() == mongo::jstOID) {
                    fieldType = @"ObjectId";
                    value = [NSString stringWithUTF8String:e.__oid().str().c_str()];
                }else {
                    fieldType = @"String";
                    value = [NSString stringWithUTF8String:e.str().c_str()];
                    if (hasId) {
                        [arr addObject:[NSString stringWithUTF8String:e.str().c_str()]];
                    }
                }
            }
            if (!hasId) {
                NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:4];
                [dict setObject:fieldName forKey:@"name"];
                [dict setObject:fieldType forKey:@"type"];
                [dict setObject:value forKey:@"value"];
                [dict setObject:child forKey:@"child"];
                [arr addObject:dict];
                [dict release];
            }
            [fieldName release];
            [child release];
            i ++;
        }
        return [arr autorelease];
    }
    return nil;
}

- (std::auto_ptr<mongo::DBClientCursor>) findAllCursorInDB:(NSString *)dbname collection:(NSString *)collectionname user:(NSString *)user password:(NSString *)password fields:(mongo::BSONObj) fields
{
    std::auto_ptr<mongo::DBClientCursor> cursor;
    try {
        if ([user length]>0 && [password length]>0) {
            BOOL ok = [self authUser:user pass:password database:dbname];
            if (!ok) {
                return cursor;
            }
        }
        NSString *col = [NSString stringWithFormat:@"%@.%@", dbname, collectionname];
        if (self.replicaConnexion) {
            cursor = self.replicaConnexion->query(std::string([col UTF8String]), mongo::Query(), 0, 0, &fields, mongo::QueryOption_SlaveOk | mongo::QueryOption_NoCursorTimeout);
        }else {
            cursor = self.connexion->query(std::string([col UTF8String]), mongo::Query(), 0, 0, &fields, mongo::QueryOption_SlaveOk | mongo::QueryOption_NoCursorTimeout);
        }
        return cursor;
    }catch (mongo::DBException &e) {
        NSRunAlertPanel(@"Error", [NSString stringWithUTF8String:e.what()], @"OK", nil, nil);
    }
    return cursor;
}

- (std::auto_ptr<mongo::DBClientCursor>) findCursorInDB:(NSString *)dbname 
                   collection:(NSString *)collectionname 
                         user:(NSString *)user 
                     password:(NSString *)password 
                     critical:(NSString *)critical 
                       fields:(NSString *)fields 
                         skip:(NSNumber *)skip 
                        limit:(NSNumber *)limit 
                         sort:(NSString *)sort
{
    std::auto_ptr<mongo::DBClientCursor> cursor;
    try {
        if ([user length]>0 && [password length]>0) {
            BOOL ok = [self authUser:user pass:password database:dbname];
            if (!ok) {
                return cursor;
            }
        }
        NSString *col = [NSString stringWithFormat:@"%@.%@", dbname, collectionname];
        mongo::BSONObj criticalBSON = mongo::fromjson([critical UTF8String]);
        mongo::BSONObj sortBSON = mongo::fromjson([sort UTF8String]);
        mongo::BSONObj fieldsToReturn;
        if ([fields isPresent]) {
            NSArray *keys = [[NSArray alloc] initWithArray:[fields componentsSeparatedByString:@","]];
            mongo::BSONObjBuilder builder;
            for (NSString *str in keys) {
                builder.append([str UTF8String], 1);
            }
            fieldsToReturn = builder.obj();
            [keys release];
        }
        if (self.replicaConnexion) {
            cursor = self.replicaConnexion->query(std::string([col UTF8String]), mongo::Query(criticalBSON).sort(sortBSON), [limit intValue], [skip intValue], &fieldsToReturn, mongo::QueryOption_SlaveOk | mongo::QueryOption_NoCursorTimeout);
        }else {
            cursor = self.connexion->query(std::string([col UTF8String]), mongo::Query(criticalBSON).sort(sortBSON), [limit intValue], [skip intValue], &fieldsToReturn, mongo::QueryOption_SlaveOk | mongo::QueryOption_NoCursorTimeout);
        }
        return cursor;
    }catch (mongo::DBException &e) {
        NSRunAlertPanel(@"Error", [NSString stringWithUTF8String:e.what()], @"OK", nil, nil);
    }
    return cursor;
}

- (void) updateBSONInDB:(NSString *)dbname 
         collection:(NSString *)collectionname 
               user:(NSString *)user 
           password:(NSString *)password 
           critical:(mongo::Query)critical 
             fields:(mongo::BSONObj)fields 
              upset:(BOOL)upset
{
    try {
        if ([user length]>0 && [password length]>0) {
            BOOL ok = [self authUser:user pass:password database:dbname];
            if (!ok) {
                return;
            }
        }
        NSString *col = [NSString stringWithFormat:@"%@.%@", dbname, collectionname];
        if (self.replicaConnexion) {
            self.replicaConnexion->update(std::string([col UTF8String]), critical, fields, upset);
        }else {
            self.connexion->update(std::string([col UTF8String]), critical, fields, upset);
        }
        NSLog(@"Update in db: %@.%@", dbname, collectionname);
    }catch (mongo::DBException &e) {
        NSRunAlertPanel(@"Error", [NSString stringWithUTF8String:e.what()], @"OK", nil, nil);
    }
}

- (NSArray *)databaseList
{
    return [_databaseList allKeys];
}

@end
