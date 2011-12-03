//
//  MHStatusViewController.m
//  MongoHub
//
//  Created by Jérôme Lebel on 02/12/11.
//  Copyright (c) 2011 ThePeppersStudio.COM. All rights reserved.
//

#import "MHStatusViewController.h"
#import "MHConnectionStore.h"
#import "MHDatabaseItem.h"
#import "MHCollectionItem.h"
#import "MOD_public.h"
#import "ResultsOutlineViewController.h"
#import "MODHelper.h"

@implementation MHStatusViewController

@synthesize mongoServer = _mongoServer, connectionStore = _connectionStore;

+ (MHStatusViewController *)loadNewViewController
{
    return [[[MHStatusViewController alloc] initWithNibName:@"MHStatusViewController" bundle:nil] autorelease];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}


- (MODQuery *)showServerStatus
{
    MODQuery *result;
    
    self.title = [NSString stringWithFormat:@"%@:%@", _connectionStore.host, _connectionStore.hostport];
    result = [_mongoServer fetchServerStatusWithCallback:^(MODSortedMutableDictionary *serverStatus, MODQuery *mongoQuery) {
        if (_mongoServer == [mongoQuery.parameters objectForKey:@"mongoserver"]) {
            if (serverStatus) {
                _resultsOutlineViewController.results = [MODHelper convertForOutlineWithObject:serverStatus];
            } else {
                _resultsOutlineViewController.results = [NSArray array];
                if (mongoQuery.error) {
                    NSRunAlertPanel(@"Error", [mongoQuery.error localizedDescription], @"OK", nil, nil);
                }
            }
        }
    }];
    return result;
}

- (MODQuery *)showDatabaseStatusWithDatabaseItem:(MHDatabaseItem *)databaseItem
{
    MODQuery *result;
    
    if (databaseItem) {
        self.title = [NSString stringWithFormat:@"Database %@ stats", databaseItem.name];
        
        result = [databaseItem.mongoDatabase fetchDatabaseStatsWithCallback:^(MODSortedMutableDictionary *databaseStats, MODQuery *mongoQuery) {
            if (databaseStats) {
                _resultsOutlineViewController.results = [MODHelper convertForOutlineWithObject:databaseStats];
            } else {
                _resultsOutlineViewController.results = [NSArray array];
                if (mongoQuery.error) {
                    NSRunAlertPanel(@"Error", [mongoQuery.error localizedDescription], @"OK", nil, nil);
                }
            }
        }];
    }
    return result;
}

- (MODQuery *)showCollectionStatusWithCollectionItem:(MHCollectionItem *)collectionItem
{
    MODQuery *result = nil;
    
    if (collectionItem) {
        self.title = [NSString stringWithFormat:@"Collection %@.%@ stats", collectionItem.databaseItem.name, collectionItem.name];
        result = [collectionItem.mongoCollection fetchCollectionStatsWithCallback:^(MODSortedMutableDictionary *stats, MODQuery *mongoQuery) {
            if (stats) {
                _resultsOutlineViewController.results = [MODHelper convertForOutlineWithObject:stats];
            } else {
                _resultsOutlineViewController.results = [NSArray array];
                if (mongoQuery.error) {
                    NSRunAlertPanel(@"Error", [mongoQuery.error localizedDescription], @"OK", nil, nil);
                }
            }
        }];
    }
    return result;
}

@end
