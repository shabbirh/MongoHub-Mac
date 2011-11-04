//
//  MHDatabase.m
//  MongoHub
//
//  Created by Syd on 10-4-24.
//  Copyright 2010 MusicPeace.ORG. All rights reserved.
//

#import "MHDatabase.h"


@implementation MHDatabase

@dynamic name;
@dynamic user;
@dynamic password;
@dynamic connection;

- (NSArray *)queryHistoryWithCollection:(NSString *)collectionName
{
    NSString *absolute;
    
    absolute = [NSString stringWithFormat:@"%@.%@", name, collectionName];
    return [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"query_history"] objectForKey:absolute];
}

- (void)addNewQuery:(NSDictionary *)query withCollectionName:(NSString *)collectionName
{
    NSMutableArray *history;
    NSMutableDictionary *allHistory;
    NSString *absolute;
    
    absolute = [[NSString alloc] initWithFormat:@"%@.%@", name, collectionName];
    allHistory = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"query_history"] mutableCopy];
    history = [[allHistory objectForKey:absolute] mutableCopy];
    
    [query retain];
    [history removeObject:query];
    [history insertObject:query atIndex:0];
    [allHistory setObject:history forKey:absolute];
    [[NSUserDefaults standardUserDefaults] setObject:allHistory forKey:@"query_history"];
    
    [absolute release];
    [allHistory release];
    [history release];
    [query release];
}

@end
