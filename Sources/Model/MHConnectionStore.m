//
//  MHConnectionStore.m
//  MongoHub
//
//  Created by Syd on 10-4-24.
//  Copyright 2010 MusicPeace.ORG. All rights reserved.
//

#import "MHConnectionStore.h"

#define MAX_QUERY_PER_COLLECTION 20
#define QUERY_HISTORY_KEY @"query_history"

@implementation MHConnectionStore

@dynamic host;
@dynamic hostport;
@dynamic servers;
@dynamic repl_name;
@dynamic alias;
@dynamic adminuser;
@dynamic adminpass;
@dynamic defaultdb;
@dynamic databases;
@dynamic userepl;

@dynamic usessh;
@dynamic sshhost;
@dynamic sshport;
@dynamic sshuser;
@dynamic sshpassword;
@dynamic sshkeyfile;
@dynamic bindaddress;
@dynamic bindport;

- (NSArray *)queryHistoryWithDatabaseName:(NSString *)databaseName collectionName:(NSString *)collectionName
{
    NSString *absolute;
    
    absolute = [NSString stringWithFormat:@"%@.%@", databaseName, collectionName];
    return [[[NSUserDefaults standardUserDefaults] dictionaryForKey:QUERY_HISTORY_KEY] objectForKey:absolute];
}

- (void)addNewQuery:(NSDictionary *)query withDatabaseName:(NSString *)databaseName collectionName:(NSString *)collectionName
{
    NSMutableArray *history;
    NSMutableDictionary *allHistory;
    NSString *absolute;
    
    absolute = [[NSString alloc] initWithFormat:@"%@.%@", databaseName, collectionName];
    allHistory = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:QUERY_HISTORY_KEY] mutableCopy];
    if (allHistory == nil) {
        allHistory = [[NSMutableDictionary alloc] init];
    }
    history = [[allHistory objectForKey:absolute] mutableCopy];
    if (history == nil) {
        history = [[NSMutableArray alloc] init];
    }
    
    [query retain];
    [history removeObject:query];
    [history insertObject:query atIndex:0];
    while ([history count] > MAX_QUERY_PER_COLLECTION) {
        [history removeLastObject];
    }
    [allHistory setObject:history forKey:absolute];
    [[NSUserDefaults standardUserDefaults] setObject:allHistory forKey:QUERY_HISTORY_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [absolute release];
    [allHistory release];
    [history release];
    [query release];
}

@end
