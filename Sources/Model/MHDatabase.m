//
//  MHDatabase.m
//  MongoHub
//
//  Created by Syd on 10-4-24.
//  Copyright 2010 MusicPeace.ORG. All rights reserved.
//

#import "MHDatabase.h"

#define MAX_QUERY_PER_COLLECTION 20
#define QUERY_HISTORY_KEY @"query_history"

@implementation MHDatabase

@dynamic name;
@dynamic user;
@dynamic password;
@dynamic connection;

- (NSArray *)queryHistoryWithCollection:(NSString *)collectionName
{
    NSString *absolute;
    
    absolute = [NSString stringWithFormat:@"%@.%@", name, collectionName];
    return [[[NSUserDefaults standardUserDefaults] dictionaryForKey:QUERY_HISTORY_KEY] objectForKey:absolute];
}

- (void)addNewQuery:(NSDictionary *)query withCollectionName:(NSString *)collectionName
{
    NSMutableArray *history;
    NSMutableDictionary *allHistory;
    NSString *absolute;
    
    absolute = [[NSString alloc] initWithFormat:@"%@.%@", name, collectionName];
    allHistory = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:QUERY_HISTORY_KEY] mutableCopy];
    history = [[allHistory objectForKey:absolute] mutableCopy];
    
    [query retain];
    [history removeObject:query];
    [history insertObject:query atIndex:0];
    while ([history count] > MAX_QUERY_PER_COLLECTION) {
        [history removeLastObject];
    }
    [allHistory setObject:history forKey:absolute];
    [[NSUserDefaults standardUserDefaults] setObject:allHistory forKey:QUERY_HISTORY_KEY];
    
    [absolute release];
    [allHistory release];
    [history release];
    [query release];
}

@end
