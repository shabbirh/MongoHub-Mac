//
//  ImportWindowController.m
//  MongoHub
//
//  Created by Syd on 10-6-16.
//  Copyright 2010 ThePeppersStudio.COM. All rights reserved.
//

#import "ImportWindowController.h"
#import "Configure.h"
#import "DatabasesArrayController.h"
#import "Database.h"
#import "Connection.h"
#import "NSString+Extras.h"
#import "MODServer.h"
#import "MODDatabase.h"
#import "MODCollection.h"
#import <MCPKit/MCPKit.h>

@implementation ImportWindowController
@synthesize dbname;
@synthesize conn;
@synthesize db;
@synthesize mongoServer;
@synthesize databasesArrayController;
@synthesize managedObjectContext;
@synthesize dbsArrayController;
@synthesize tablesArrayController;
@synthesize hostTextField;
@synthesize portTextField;
@synthesize userTextField;
@synthesize passwdTextField;
@synthesize chunkSizeTextField;
@synthesize collectionTextField;
@synthesize progressIndicator;
@synthesize tablesPopUpButton;

- (id)init {
    self = [super initWithWindowNibName:@"Import"];
    return self;
}

- (void)dealloc {
    [dbname release];
    [managedObjectContext release];
    [databasesArrayController release];
    [conn release];
    [db release];
    [mongoServer release];
    [dbsArrayController release];
    [tablesArrayController release];
    [hostTextField release];
    [portTextField release];
    [userTextField release];
    [passwdTextField release];
    [chunkSizeTextField release];
    [collectionTextField release];
    [progressIndicator release];
    [tablesPopUpButton release];
    [super dealloc];
}

- (void)windowDidLoad {
    //NSLog(@"New Connection Window Loaded");
    [super windowDidLoad];
}

- (void)windowWillClose:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] postNotificationName:kImportWindowWillClose object:dbname];
    dbname = nil;
    db = nil;
    [dbsArrayController setContent:nil];
    [tablesArrayController setContent:nil];
    [progressIndicator setDoubleValue:0.0];
}

- (IBAction)import:(id)sender {
    [progressIndicator setUsesThreadedAnimation:YES];
    [progressIndicator startAnimation: self];
    [progressIndicator setDoubleValue:0];
    NSString *collection = [collectionTextField stringValue];
    int chunkSize = [chunkSizeTextField intValue];
    if ([collection length] == 0) {
        NSRunAlertPanel(@"Error", @"Collection name can not be empty!", @"OK", nil, nil);
        return;
    }
    if (chunkSize == 0) {
        NSRunAlertPanel(@"Error", @"Chunk Size can not be 0!", @"OK", nil, nil);
        return;
    }
    [self doImportFromTable:[tablesPopUpButton titleOfSelectedItem] toCollection:collection withChundSize:chunkSize];
}

- (long long int)importCount:(NSString *)tableName
{
    NSString *query = [[NSString alloc] initWithFormat:@"select count(*) counter from %@", tableName];
    MCPResult *theResult = [db queryString:query];
    [query release];
    NSArray *row = [theResult fetchRowAsArray];
    NSLog(@"count: %@", [row objectAtIndex:0]);
    return [[row objectAtIndex:0] intValue];
}

- (void)updateProgressIndicatorWithNumber:(NSNumber *)number
{
    [progressIndicator setDoubleValue:[number doubleValue]];
}

- (void)importDone:(id)unused
{
    [progressIndicator setDoubleValue:1.0];
    [progressIndicator stopAnimation:nil];
}

- (void)doImportFromTable:(NSString *)tableName toCollection:(NSString *)collectionName withChundSize:(int)chunkSize
{
    [mongoServer copyWithCallback:^(MODServer *copyServer, MODQuery *mongoQuery) {
        MODCollection *copyCollection;
        
        copyCollection = [[copyServer databaseForName:dbname] collectionForName:collectionName];
        if (!copyServer) {
            NSRunAlertPanel(@"Error", @"Can not create a second connection to the mongo server.", @"OK", nil, nil);
            return;
        }
        dispatch_queue_t myQueue = dispatch_queue_create("com.mongohub.mysql", 0);
        
        dispatch_async(myQueue, ^() {
            long long total = [self importCount:tableName];
            long long ii = 0;
            
            while (ii < total) {
                NSString *query = [[NSString alloc] initWithFormat:@"select * from %@ limit %lld, %lld", tableName, ii, chunkSize];
                MCPResult *theResult = [db queryString:query];
                 
                [query release];
                if ([theResult numOfRows] == 0) {
                     return;
                }
                while (NSDictionary *row = [theResult fetchRowAsDictionary]) {
                    NSMutableArray *documents;
                    void (^callback)(MODQuery *mongoQuery);
                    
                    ii++;
                    documents = [[NSMutableArray alloc] initWithObjects:row, nil];
                    if (ii == total) {
                        callback = ^(MODQuery *mongoQuery) {
                            [self importDone:nil];
                        };
                    } else if (ii % 10 == 0) {
                        callback = ^(MODQuery *mongoQuery) {
                            [progressIndicator setDoubleValue:(double)ii/(double)total];
                        };
                    } else {
                        callback = nil;
                    }
                    [copyCollection insertWithDocuments:documents callback:callback];
                    [documents release];
                }
            }
        });
    }];
}

- (IBAction)connect:(id)sender {
    if (db) {
        [dbsArrayController setContent:nil];
        [tablesArrayController setContent:nil];
        [progressIndicator setDoubleValue:0.0];
        [db release];
    }
    db = [[MCPConnection alloc] initToHost:[hostTextField stringValue] withLogin:[userTextField stringValue] usingPort:[portTextField intValue]];
    [db setPassword:[passwdTextField stringValue]];
    [db connect];
    NSLog(@"Connect: %d", [db isConnected]);
    if (![db isConnected])
    {
        NSRunAlertPanel(@"Error", @"Could not connect to the mysql server!", @"OK", nil, nil);
    }
    [db queryString:@"SET NAMES utf8"];
    [db queryString:@"SET CHARACTER SET utf8"];
    [db queryString:@"SET COLLATION_CONNECTION='utf8_general_ci'"];
    [db setEncoding:@"utf8"];
    MCPResult *dbs = [db listDBs];
    NSArray *row;
    NSMutableArray *databases = [[NSMutableArray alloc] initWithCapacity:[dbs numOfRows]];
    while ((row = [dbs fetchRowAsArray])) {
        NSDictionary *database = [[NSDictionary alloc] initWithObjectsAndKeys:[row objectAtIndex:0], @"name", nil];
        [databases addObject:database];
        [database release];
    }
    [dbsArrayController setContent:databases];
    [databases release];
}

- (IBAction)showTables:(id)sender
{
    NSString *dbn;
    if (sender == nil && [[dbsArrayController arrangedObjects] count] > 0) {
        dbn = [[[dbsArrayController arrangedObjects] objectAtIndex:0] objectForKey:@"name"];
    }else {
        NSPopUpButton *pb = sender;
        dbn = [NSString stringWithString:[pb titleOfSelectedItem]];
    }
    if ([dbn length] == 0) {
        return;
    }
    [db selectDB:dbn];
    MCPResult *tbs = [db listTables];
    NSArray *row;
    NSMutableArray *tables = [[NSMutableArray alloc] initWithCapacity:[tbs numOfRows]];
    while ((row = [tbs fetchRowAsArray])) {
        NSDictionary *table = [[NSDictionary alloc] initWithObjectsAndKeys:[row objectAtIndex:0], @"name", nil];
        [tables addObject:table];
        [table release];
    }
    [tablesArrayController setContent:tables];
    [tables release];
}

@end
