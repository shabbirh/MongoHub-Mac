//
//  ConnectionWindowController.m
//  MongoHub
//
//  Created by Syd on 10-4-25.
//  Copyright 2010 MusicPeace.ORG. All rights reserved.
//

#import "Configure.h"
#import "NSString+Extras.h"
#import "NSProgressIndicator+Extras.h"
#import "ConnectionWindowController.h"
#import "QueryWindowController.h"
#import "AddDBController.h"
#import "AddCollectionController.h"
#import "AuthWindowController.h"
#import "ImportWindowController.h"
#import "ExportWindowController.h"
#import "ResultsOutlineViewController.h"
#import "DatabasesArrayController.h"
#import "StatMonitorTableController.h"
#import "Connection.h"
#import "Sidebar.h"
#import "SidebarNode.h"
#import "Tunnel.h"
#import "MODServer.h"
#import "MODDatabase.h"
#import "MODQuery.h"
#import "MODHelper.h"

@interface ConnectionWindowController()
- (void)closeMongoDB;
- (void)fetchServerStatusDelta;
@end

@implementation ConnectionWindowController

@synthesize managedObjectContext;
@synthesize databaseArrayController;
@synthesize resultsOutlineViewController;
@synthesize conn;
@synthesize mongoServer;
@synthesize mongoDatabase;
@synthesize sidebar;
@synthesize loaderIndicator;
@synthesize monitorButton;
@synthesize reconnectButton;
@synthesize statMonitorTableController;
@synthesize databases;
@synthesize collections;
@synthesize selectedDB;
@synthesize selectedCollection;
@synthesize sshTunnel;
@synthesize addDBController;
@synthesize addCollectionController;
@synthesize resultsTitle;
@synthesize bundleVersion;
@synthesize authWindowController;
@synthesize importWindowController;
@synthesize exportWindowController;


- (id)init
{
    if (self = [super initWithWindowNibName:@"ConnectionWindow"]) {
        
    }
    return self;
}

- (void)dealloc
{
    [self closeMongoDB];
    [managedObjectContext release];
    [databaseArrayController release];
    [resultsOutlineViewController release];
    [conn release];
    [sidebar release];
    [databases release];
    [collections release];
    [selectedDB release];
    [selectedCollection release];
    [sshTunnel release];
    [addDBController release];
    [addCollectionController release];
    [resultsTitle release];
    [loaderIndicator release];
    [reconnectButton release];
    [monitorButton release];
    [statMonitorTableController release];
    [bundleVersion release];
    [authWindowController release];
    [importWindowController release];
    [exportWindowController release];
    [super dealloc];
}

- (void)closeMongoDB
{
    [_serverMonitorTimer invalidate];
    [_serverMonitorTimer release];
    _serverMonitorTimer = nil;
    [mongoServer release];
    mongoServer = nil;
    [mongoDatabase release];
    mongoDatabase = nil;
}

- (void) tunnelStatusChanged: (Tunnel*) tunnel status: (NSString*) status {
    NSLog(@"SSH TUNNEL STATUS: %@", status);
    if( [status isEqualToString: @"CONNECTED"] ){
        exitThread = YES;
        [self connect:YES];
    }
}

- (void)didConnect
{
    [loaderIndicator stop];
    
    if (![conn.defaultdb isPresent]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addDB:) name:kNewDBWindowWillClose object:nil];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addCollection:) name:kNewCollectionWindowWillClose object:nil];
    [reconnectButton setEnabled:YES];
    [monitorButton setEnabled:YES];
    [self reloadSidebar];
    [self showServerStatus:nil];
}

- (void)didFailToConnectWithError:(NSError *)error
{
    [loaderIndicator stop];
    NSRunAlertPanel(@"Error", [error localizedDescription], @"OK", nil, nil);
}

- (void)connect:(BOOL)haveHostAddress {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [loaderIndicator start];
    [reconnectButton setEnabled:NO];
    [monitorButton setEnabled:NO];
    if (!haveHostAddress && [conn.usessh intValue] == 1) {
        NSString *portForward = [[NSString alloc] initWithFormat:@"L:%@:%@:%@:%@", conn.bindaddress, conn.bindport, conn.host, conn.hostport];
        NSMutableArray *portForwardings = [[NSMutableArray alloc] initWithObjects:portForward, nil];
        [portForward release];
        if (!sshTunnel)
            sshTunnel =[[Tunnel alloc] init];
        [sshTunnel setDelegate:self];
        [sshTunnel setUser:conn.sshuser];
        [sshTunnel setHost:conn.sshhost];
        [sshTunnel setPassword:conn.sshpassword];
        [sshTunnel setKeyfile:conn.sshkeyfile];
        [sshTunnel setPort:[conn.sshport intValue]];
        [sshTunnel setPortForwardings:portForwardings];
        [sshTunnel setAliveCountMax:3];
        [sshTunnel setAliveInterval:30];
        [sshTunnel setTcpKeepAlive:YES];
        [sshTunnel setCompression:YES];
        [sshTunnel start];
        [portForwardings release];
        [pool drain];
        return;
    }else {
        [self closeMongoDB];
        mongoServer = [[MODServer alloc] init];
        mongoServer.userName = conn.adminuser;
        mongoServer.password = conn.adminpass;
        if ([conn.userepl intValue] == 1) {
            NSArray *tmp = [conn.servers componentsSeparatedByString:@","];
            NSMutableArray *hosts = [[NSMutableArray alloc] initWithCapacity:[tmp count]];
            for (NSString *h in tmp) {
                NSString *host = [h stringByTrimmingWhitespace];
                if ([host length] == 0) {
                    continue;
                }
                [hosts addObject:host];
            }
            [mongoServer connectWithReplicaName:conn.repl_name hosts:hosts callback:^(BOOL connected, MODQuery *mongoQuery) {
                if (connected) {
                    [self didConnect];
                } else {
                    [self didFailToConnectWithError:mongoQuery.error];
                }
            }];
            [hosts release];
        } else {
            NSString *hostaddress;
            
            if ([conn.usessh intValue] == 1) {
                hostaddress = [[NSString alloc] initWithFormat:@"127.0.0.1:%@", conn.bindport];
            } else {
                hostaddress = [[NSString alloc] initWithFormat:@"%@:%@", conn.host, conn.hostport];
            }
            [mongoServer connectWithHostName:hostaddress callback:^(BOOL connected, MODQuery *mongoQuery) {
                if (connected) {
                    [self didConnect];
                } else {
                    [self didFailToConnectWithError:mongoQuery.error];
                }
            }];
            [hostaddress release];
        }
    }
    [pool drain];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    self.collections = [NSMutableArray array];
    self.databases = [NSMutableArray array];
    exitThread = NO;
    NSString *appVersion = [[NSString alloc] initWithFormat:@"version(%@[%@])", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey] ];
    [bundleVersion setStringValue: appVersion];
    [appVersion release];
    [self connect:NO];
    if ([conn.usessh intValue]==1) {
        [NSThread detachNewThreadSelector: @selector(checkTunnel) toTarget:self withObject:nil ];
    }
    [sidebar setDoubleAction:@selector(sidebarDoubleAction:)];
}

- (void)sidebarDoubleAction:(id)sender
{
    [self query:sender];
}

- (IBAction)reconnect:(id)sender
{
    [self connect:NO];
    if ([conn.usessh intValue]==1) {
        [NSThread detachNewThreadSelector: @selector(checkTunnel) toTarget:self withObject:nil ];
    }
}

- (void)checkTunnel {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    while(!exitThread){
		@synchronized(self){
            if ([sshTunnel running] == NO){
                [sshTunnel start];
            }else if( [sshTunnel running] == YES && [sshTunnel checkProcess] == NO ){
                [sshTunnel stop];
                [NSThread sleepForTimeInterval:2];
                [sshTunnel start];
            }
            [sshTunnel readStatus];
		}
		[NSThread sleepForTimeInterval:3];
	}
    [pool drain];
    [NSThread exit];
}

- (void)windowWillClose:(NSNotification *)notification {
    if ([sshTunnel running]) {
        [sshTunnel stop];
    }
    //exitThread = YES;
    resultsOutlineViewController = nil;
    self.selectedDB = nil;
    self.selectedCollection = nil;
    [super release];
}

- (void)reloadSidebar
{
    [loaderIndicator start];
    [mongoServer fetchDatabaseListWithCallback:^(NSArray *list, MODQuery *mongoQuery) {
        [loaderIndicator stop];
        self.selectedDB = nil;
        self.selectedCollection = nil;
        [self.collections removeAllObjects];
        [self.databases removeAllObjects];
        if ([conn.defaultdb isPresent]) {
            [self.databases addObject:conn.defaultdb];
        } else if (list != nil) {
            [self.databases addObjectsFromArray:list];
        } else if (mongoQuery.error) {
            NSRunAlertPanel(@"Error", [mongoQuery.error localizedDescription], @"OK", nil, nil);
        }
        [databases sortUsingSelector:@selector(compare:)];
        
        [databaseArrayController clean:conn databases:databases];
        [sidebar removeItem:@"1"];
        [sidebar removeItem:@"2"];
        [sidebar addSection:@"1" caption:@"DATABASES"];
        unsigned int i=1;
        for (NSString *db in databases) {
            [sidebar addChild:@"1" key:[NSString stringWithFormat:@"1.%d", i] caption:db icon:[NSImage imageNamed:@"dbicon.png"] action:@selector(useDB:) target:self];
            i++;
        }
        [sidebar reloadData];
        [sidebar expandItem:@"1"];
    }];
}

- (void)getCollectionList
{
    [loaderIndicator start];
    [mongoDatabase fetchCollectionListWithCallback:^(NSArray *collectionList, MODQuery *mongoQuery) {
        [loaderIndicator stop];
        if ([self mongoDatabase] == [mongoQuery.parameters objectForKey:@"mongodatabase"]) {
            [self.collections removeAllObjects];
            if (collectionList) {
                [self.collections addObjectsFromArray:collectionList];
            } else if (mongoQuery.error) {
                NSRunAlertPanel(@"Error", [mongoQuery.error localizedDescription], @"OK", nil, nil);
            }
            [sidebar removeItem:@"2"];
            [sidebar addSection:@"2" caption:[[self.selectedDB caption] uppercaseString]];
            [self.collections sortUsingSelector:@selector(compare:)];
            unsigned int i = 1;
            for (NSString *collection in self.collections) {
                [sidebar addChild:@"2" key:[NSString stringWithFormat:@"2.%d", i] caption:collection icon:[NSImage imageNamed:@"collectionicon.png"] action:@selector(useCollection:) target:self];
                i ++ ;
            }
            [sidebar reloadData];
            [sidebar setBadge:[self.selectedDB nodeKey] count:[self.collections count]];
            [sidebar expandItem:@"2"];
            [self showDBStats:nil];
        }
    }];
}

- (void)useDB:(id)sender {
    NSString *dbname = [sender caption];
    Database *db = [databaseArrayController dbInfo:conn name:dbname];
    
    [mongoDatabase release];
    mongoDatabase = [[mongoServer databaseForName:dbname] retain];
    mongoDatabase.userName = db.user;
    mongoDatabase.password = db.password;
    [mongoCollection release];
    mongoCollection = nil;
    if (![[self.selectedDB caption] isEqualToString:dbname]) {
        self.selectedDB = (SidebarNode *)sender;
    }
    self.selectedCollection = nil;
    [self getCollectionList];
}

- (void)useCollection:(id)sender
{
    NSString *collectionname = [sender caption];
    if ([collectionname length] > 0) {
        self.selectedCollection = (SidebarNode *)sender;
        [mongoCollection release];
        mongoCollection = [[mongoDatabase collectionForName:collectionname] retain];
        [self showCollStats:nil];
    }
}

- (IBAction)showServerStatus:(id)sender 
{
    [loaderIndicator start];
    [resultsTitle setStringValue:[NSString stringWithFormat:@"Server %@:%@ stats", conn.host, conn.hostport]];
    [mongoServer fetchServerStatusWithCallback:^(NSDictionary *serverStatus, MODQuery *mongoQuery) {
        [loaderIndicator stop];
        if (mongoServer == [mongoQuery.parameters objectForKey:@"mongoserver"]) {
            [resultsOutlineViewController.results removeAllObjects];
            if (serverStatus) {
                [resultsOutlineViewController.results addObjectsFromArray:[MODHelper convertForOutlineWithObject:serverStatus]];
            } else if (mongoQuery.error) {
                NSRunAlertPanel(@"Error", [mongoQuery.error localizedDescription], @"OK", nil, nil);
            }
            [resultsOutlineViewController.myOutlineView reloadData];
        }
    }];
}

- (IBAction)showDBStats:(id)sender 
{
    if (self.selectedDB == nil) {
        NSRunAlertPanel(@"Error", @"Please specify a database!", @"OK", nil, nil);
        return;
    }
    [loaderIndicator start];
    [resultsTitle setStringValue:[NSString stringWithFormat:@"Database %@ stats", [self.selectedDB caption]]];
    
    [mongoDatabase fetchDatabaseStatsWithCallback:^(NSDictionary *databaseStats, MODQuery *mongoQuery) {
        [loaderIndicator stop];
        [resultsOutlineViewController.results removeAllObjects];
        if (databaseStats) {
            [resultsOutlineViewController.results addObjectsFromArray:[MODHelper convertForOutlineWithObject:databaseStats]];
        } else if (mongoQuery.error) {
            NSRunAlertPanel(@"Error", [mongoQuery.error localizedDescription], @"OK", nil, nil);
        }
        [resultsOutlineViewController.myOutlineView reloadData];
    }];
}

- (IBAction)showCollStats:(id)sender 
{
    if (self.selectedDB == nil || self.selectedCollection == nil) {
        NSRunAlertPanel(@"Error", @"Please specify a collection!", @"OK", nil, nil);
        return;
    }
    [loaderIndicator start];
    [resultsTitle setStringValue:[NSString stringWithFormat:@"Collection %@.%@ stats", [self.selectedDB caption], [self.selectedCollection caption]]];
    [mongoCollection fetchDatabaseStatsWithCallback:^(NSDictionary *stats, MODQuery *mongoQuery) {
        [loaderIndicator stop];
        [resultsOutlineViewController.results removeAllObjects];
        if (stats) {
            [resultsOutlineViewController.results addObjectsFromArray:[MODHelper convertForOutlineWithObject:stats]];
        } else if (mongoQuery.error) {
            NSRunAlertPanel(@"Error", [mongoQuery.error localizedDescription], @"OK", nil, nil);
        }
        [resultsOutlineViewController.myOutlineView reloadData];
    }];
}

- (void)menuWillOpen:(NSMenu *)menu
{
    if (menu == createCollectionOrDatabaseMenu) {
        [[menu itemWithTag:2] setEnabled:self.selectedDB != nil];
    }
}

- (IBAction)createDatabase:(id)sender
{
    [self createDB];
}

- (IBAction)createCollection:(id)sender
{
    if (self.selectedDB) {
        [self createCollectionForDB:[self.selectedDB caption]];
    }
}

- (void)createCollectionForDB:(NSString *)dbname
{
    if (!addCollectionController) {
        addCollectionController = [[AddCollectionController alloc] init];
    }
    addCollectionController.dbname = dbname;
    [addCollectionController showWindow:self];
}

- (void)createDB
{
    if ([conn.defaultdb isPresent]) {
        NSRunAlertPanel(@"Error", @"Could not create database!", @"OK", nil, nil);
        return;
    }
    if (!addDBController)
    {
        addDBController = [[AddDBController alloc] init];
    }
    addDBController.managedObjectContext = self.managedObjectContext;
    addDBController.conn = self.conn;
    [addDBController showWindow:self];
}

- (void)addDB:(id)sender
{
    if (![sender object]) {
        return;
    }
    [mongoDatabase release];
    mongoDatabase = [[mongoServer databaseForName:[[sender object] objectForKey:@"dbname"]] retain];
    mongoDatabase.userName = [[sender object] objectForKey:@"user"];
    mongoDatabase.password = [[sender object] objectForKey:@"password"];
    [mongoDatabase fetchDatabaseStatsWithCallback:nil];
    [self reloadSidebar];
}

- (void)addCollection:(id)sender
{
    if (![sender object]) {
        return;
    }
    NSString *collectionname = [[sender object] objectForKey:@"collectionname"];
    [loaderIndicator start];
    [mongoDatabase createCollectionWithName:collectionname callback:^(MODQuery *mongoQuery) {
        [loaderIndicator stop];
        if (mongoQuery.error) {
            NSRunAlertPanel(@"Error", [mongoQuery.error localizedDescription], @"OK", nil, nil);
        }
        [self getCollectionList];
    }];
}

- (IBAction)dropDBorCollection:(id)sender
{
    if (self.selectedCollection) {
        [self dropWarning:[NSString stringWithFormat:@"COLLECTION:%@", [self.selectedCollection caption]]];
    }else {
        [self dropWarning:[NSString stringWithFormat:@"DB:%@", [self.selectedDB caption]]];
    }
}

- (void)dropCollection:(NSString *)collectionname ForDB:(NSString *)dbname
{
    [loaderIndicator start];
    [mongoDatabase dropCollectionWithName:collectionname callback:^(MODQuery *mongoQuery) {
        [loaderIndicator stop];
        if (mongoQuery.error) {
            NSRunAlertPanel(@"Error", [mongoQuery.error localizedDescription], @"OK", nil, nil);
        } else {
            [self getCollectionList];
        }
    }];
}

- (void)dropDB
{
    if ([conn.defaultdb isPresent]) {
        NSRunAlertPanel(@"Error", @"Could not drop database!", @"OK", nil, nil);
        return;
    }
    [loaderIndicator start];
    [mongoServer dropDatabaseWithName:[self.selectedDB caption] callback:^(MODQuery *mongoQuery) {
        [loaderIndicator stop];
        [self reloadSidebar];
        if (mongoQuery.error) {
            NSRunAlertPanel(@"Error", [mongoQuery.error localizedDescription], @"OK", nil, nil);
        }
    }];
}

- (IBAction)query:(id)sender
{
    if (!self.selectedCollection) {
        NSRunAlertPanel(@"Error", @"Please choose a collection!", @"OK", nil, nil);
        return;
    }
    QueryWindowController *queryWindowController = [[QueryWindowController alloc] init];
    queryWindowController.mongoCollection = mongoCollection;
    queryWindowController.managedObjectContext = self.managedObjectContext;
    queryWindowController.conn = conn;
    [queryWindowController showWindow:sender];
}

- (IBAction)showAuth:(id)sender
{
    if ([conn.defaultdb isPresent]) {
        NSRunAlertPanel(@"Error", @"Could not auth for database!", @"OK", nil, nil);
        return;
    }
    
    if (!self.selectedDB) 
    {
        NSRunAlertPanel(@"Error", @"Please choose a database!", @"OK", nil, nil);
        return;
    }
    if (!authWindowController)
    {
        authWindowController = [[AuthWindowController alloc] init];
    }
    Database *db = [databaseArrayController dbInfo:conn name:[self.selectedDB caption]];
    if (db) {
        [authWindowController.userTextField setStringValue:db.user];
        [authWindowController.passwordTextField setStringValue:db.password];
    }else {
        [authWindowController.userTextField setStringValue:@""];
        [authWindowController.passwordTextField setStringValue:@""];
    }
    authWindowController.managedObjectContext = self.managedObjectContext;
    authWindowController.conn = self.conn;
    authWindowController.dbname = [self.selectedDB caption];
    [authWindowController showWindow:self];
}

- (IBAction)importFromMySQL:(id)sender
{
    if (self.selectedDB == nil) {
        NSRunAlertPanel(@"Error", @"Please specify a database!", @"OK", nil, nil);
        return;
    }
    if (!importWindowController)
    {
        importWindowController = [[ImportWindowController alloc] init];
    }
    importWindowController.managedObjectContext = self.managedObjectContext;
    importWindowController.conn = self.conn;
    importWindowController.mongoServer = mongoServer;
    importWindowController.dbname = [self.selectedDB caption];
    if (self.selectedCollection) {
        [exportWindowController.collectionTextField setStringValue:[self.selectedCollection caption]];
    }
    [importWindowController showWindow:self];
}

- (IBAction)exportToMySQL:(id)sender
{
    if (self.selectedDB == nil) {
        NSRunAlertPanel(@"Error", @"Please specify a database!", @"OK", nil, nil);
        return;
    }
    if (!exportWindowController)
    {
        exportWindowController = [[ExportWindowController alloc] init];
    }
    exportWindowController.managedObjectContext = self.managedObjectContext;
    exportWindowController.conn = self.conn;
    exportWindowController.mongoServer = mongoServer;
    exportWindowController.dbname = [self.selectedDB caption];
    if (self.selectedCollection) {
        [exportWindowController.collectionTextField setStringValue:[self.selectedCollection caption]];
    }
    [exportWindowController showWindow:self];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSAlertFirstButtonReturn)
    {
        if (self.selectedCollection) {
            [self dropCollection:[self.selectedCollection caption] ForDB:[self.selectedDB caption]];
        }else {
            [self dropDB];
        }
    }
}

- (void)dropWarning:(NSString *)msg
{
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:[NSString stringWithFormat:@"Drop this %@?", msg]];
    [alert setInformativeText:[NSString stringWithFormat:@"Dropped %@ cannot be restored.", msg]];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert beginSheetModalForWindow:[self window] modalDelegate:self
                     didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                        contextInfo:nil];
}

- (IBAction)startMonitor:(id)sender {
    if (!_serverMonitorTimer) {
        _serverMonitorTimer = [[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(fetchServerStatusDelta) userInfo:nil repeats:YES] retain];
        [self fetchServerStatusDelta];
    }
    [NSApp beginSheet:monitorPanel modalForWindow:self.window modalDelegate:self didEndSelector:@selector(monitorPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
    NSLog(@"startMonitor");
}

- (IBAction)stopMonitor:(id)sender
{
    [NSApp endSheet:monitorPanel];
}

- (void)monitorPanelDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [monitorPanel close];
    [_serverMonitorTimer invalidate];
    [_serverMonitorTimer release];
    _serverMonitorTimer = nil;
}

static int percentage(NSNumber *previousValue, NSNumber *previousOutOfValue, NSNumber *value, NSNumber *outOfValue)
{
    double valueDiff = [value doubleValue] - [previousValue doubleValue];
    double outOfValueDiff = [outOfValue doubleValue] - [previousOutOfValue doubleValue];
    return (outOfValueDiff == 0) ? 0.0 : (valueDiff * 100.0 / outOfValueDiff);
}

- (void)fetchServerStatusDelta
{
    [resultsTitle setStringValue:[NSString stringWithFormat:@"Server %@:%@ stats", conn.host, conn.hostport]];
    [mongoServer fetchServerStatusWithCallback:^(NSDictionary *serverStatus, MODQuery *mongoQuery) {
        [loaderIndicator stop];
        if (mongoServer == [mongoQuery.parameters objectForKey:@"mongoserver"]) {
            NSMutableDictionary *diff = [[NSMutableDictionary alloc] init];
            
            if (previousServerStatusForDelta) {
                NSNumber *number;
                NSDate *date;
                
                for (NSString *key in [[serverStatus objectForKey:@"opcounters"] allKeys]) {
                    number = [[NSNumber alloc] initWithInteger:[[[serverStatus objectForKey:@"opcounters"] objectForKey:key] integerValue] - [[[previousServerStatusForDelta objectForKey:@"opcounters"] objectForKey:key] integerValue]];
                    [diff setObject:number forKey:key];
                    [number release];
                }
                [diff setObject:[[serverStatus objectForKey:@"mem"] objectForKey:@"mapped"] forKey:@"mapped"];
                [diff setObject:[[serverStatus objectForKey:@"mem"] objectForKey:@"virtual"] forKey:@"vsize"];
                [diff setObject:[[serverStatus objectForKey:@"mem"] objectForKey:@"resident"] forKey:@"res"];
                number = [[NSNumber alloc] initWithInteger:[[[serverStatus objectForKey:@"extra_info"] objectForKey:@"page_faults"] integerValue] - [[[previousServerStatusForDelta objectForKey:@"extra_info"] objectForKey:@"page_faults"] integerValue]];
                [diff setObject:number forKey:@"faults"];
                [number release];
                number = [[NSNumber alloc] initWithInteger:percentage([[previousServerStatusForDelta objectForKey:@"globalLock"] objectForKey:@"lockTime"],
                                                                      [[previousServerStatusForDelta objectForKey:@"globalLock"] objectForKey:@"totalTime"],
                                                                      [[serverStatus objectForKey:@"globalLock"] objectForKey:@"lockTime"],
                                                                      [[serverStatus objectForKey:@"globalLock"] objectForKey:@"totalTime"])];
                [diff setObject:number forKey:@"locked"];
                [number release];
                number = [[NSNumber alloc] initWithInteger:percentage([[[previousServerStatusForDelta objectForKey:@"indexCounters"] objectForKey:@"btree"] objectForKey:@"misses"],
                                                                      [[[previousServerStatusForDelta objectForKey:@"indexCounters"] objectForKey:@"btree"] objectForKey:@"accesses"],
                                                                      [[[serverStatus objectForKey:@"indexCounters"] objectForKey:@"btree"] objectForKey:@"misses"],
                                                                      [[[serverStatus objectForKey:@"indexCounters"] objectForKey:@"btree"] objectForKey:@"accesses"])];
                [diff setObject:number forKey:@"misses"];
                [number release];
                date = [[NSDate alloc] init];
                [diff setObject:[[serverStatus objectForKey:@"connections"] objectForKey:@"current"] forKey:@"conn"];
                [diff setObject:date forKey:@"time"];
                [date release];
                [statMonitorTableController addObject:diff];
            }
            if (previousServerStatusForDelta) {
                [previousServerStatusForDelta release];
            }
            previousServerStatusForDelta = [serverStatus retain];
        }
    }];
}

@end
