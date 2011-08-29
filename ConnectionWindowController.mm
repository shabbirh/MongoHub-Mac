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
#import "MongoDB.h"
#import "Tunnel.h"

@interface ConnectionWindowController()
- (void)closeMongoDB;
@end

@interface ConnectionWindowController(MongoDBDelegate)<MongoDBDelegate>
@end

@implementation ConnectionWindowController

@synthesize managedObjectContext;
@synthesize databaseArrayController;
@synthesize resultsOutlineViewController;
@synthesize conn;
@synthesize mongoDB = _mongoDB;
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
    _mongoDB.delegate = nil;
    [_mongoDB release];
    _mongoDB = nil;
}

- (void) tunnelStatusChanged: (Tunnel*) tunnel status: (NSString*) status {
    NSLog(@"SSH TUNNEL STATUS: %@", status);
    if( [status isEqualToString: @"CONNECTED"] ){
        exitThread = YES;
        [self connect:YES];
    }
}

- (void)connect:(BOOL)haveHostAddress {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [loaderIndicator start];
    [reconnectButton setEnabled:NO];
    [monitorButton setEnabled:NO];
    if (!haveHostAddress && [conn.usessh intValue]==1) {
        NSString *portForward = [[NSString alloc] initWithFormat:@"L:%@:%@:%@:%@", conn.hostport, conn.host, conn.sshhost, conn.bindport];
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
        //[sshTunnel start];
        [portForwardings release];
        [pool drain];
        return;
    }else {
        [self closeMongoDB];
        _mongoDB = [[MongoDB alloc] init];
        _mongoDB.delegate = self;
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
            [_mongoDB connectWithReplicaName:conn.repl_name hosts:hosts databaseName:conn.defaultdb userName:conn.adminuser password:conn.adminpass];
            [hosts release];
        }else{
            NSString *hostaddress = [[NSString alloc] initWithFormat:@"%@:%@", conn.host, conn.hostport];
            [_mongoDB connectWithHostName:hostaddress databaseName:conn.defaultdb userName:conn.adminuser password:conn.adminpass];
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
    [_mongoDB fetchDatabaseList];
}

- (void)useDB:(id)sender {
    NSString *dbname = [[NSString alloc] initWithFormat:@"%@", [sender caption]];
    Database *db = [databaseArrayController dbInfo:conn name:dbname];
    
    if (![[self.selectedDB caption] isEqualToString:dbname]) {
        self.selectedDB = (SidebarNode *)sender;
    }
    self.selectedCollection = nil;
    [loaderIndicator start];
    [_mongoDB fetchCollectionListWithDatabaseName:dbname userName:db.user password:db.password];
    [dbname release];
}

- (void)useCollection:(id)sender
{
    NSString *collectionname = [[NSString alloc] initWithFormat:@"%@", [sender caption] ];
    if ([collectionname isPresent]) {
        self.selectedCollection = (SidebarNode *)sender;
        [self showCollStats:nil];
    }
    [collectionname release];
}

- (IBAction)showServerStatus:(id)sender 
{
    [loaderIndicator start];
    [resultsTitle setStringValue:[NSString stringWithFormat:@"Server %@:%@ stats", conn.host, conn.hostport]];
    [_mongoDB fetchServerStatus];
    
}

- (IBAction)showDBStats:(id)sender 
{
    if (self.selectedDB == nil) {
        NSRunAlertPanel(@"Error", @"Please specify a database!", @"OK", nil, nil);
        return;
    }
    [loaderIndicator start];
    [resultsTitle setStringValue:[NSString stringWithFormat:@"Database %@ stats", [self.selectedDB caption]]];
    
    Database *db = [databaseArrayController dbInfo:conn name:[self.selectedDB caption]];
    [_mongoDB fetchDatabaseStatsWithDatabaseName:[self.selectedDB caption] userName:db.user password:db.password];
}

- (IBAction)showCollStats:(id)sender 
{
    if (self.selectedDB == nil || self.selectedCollection == nil) {
        NSRunAlertPanel(@"Error", @"Please specify a collection!", @"OK", nil, nil);
        return;
    }
    [loaderIndicator start];
    [resultsTitle setStringValue:[NSString stringWithFormat:@"Collection %@.%@ stats", [self.selectedDB caption], [self.selectedCollection caption]]];
    Database *db = [databaseArrayController dbInfo:conn name:[self.selectedDB caption] ];
    [_mongoDB fetchCollectionStatsWithCollectionName:[self.selectedCollection caption] databaseName:[self.selectedDB caption] userName:db.user password:db.password];
}

- (IBAction)createDBorCollection:(id)sender
{
    if (self.selectedCollection) {
        [self createCollectionForDB:[self.selectedDB caption]];
    }else {
        [self createDB];
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
    [_mongoDB fetchDatabaseStatsWithDatabaseName:[[sender object] objectForKey:@"dbname"] userName:[[sender object] objectForKey:@"user"] password:[[sender object] objectForKey:@"password"]];
    [self reloadSidebar];
}

- (void)addCollection:(id)sender
{
    if (![sender object]) {
        return;
    }
    NSString *dbname = [[sender object] objectForKey:@"dbname"];
    NSString *collectionname = [[sender object] objectForKey:@"collectionname"];
    Database *db = [databaseArrayController dbInfo:conn name:dbname];
    [_mongoDB createCollectionWithName:collectionname databaseName:dbname userName:db.user password:db.password];
    [loaderIndicator start];
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
    Database *db = [databaseArrayController dbInfo:conn name:[self.selectedDB caption]];
    [_mongoDB dropCollectionWithName:collectionname databaseName:dbname userName:db.user password:db.password];
    [loaderIndicator start];
}

- (void)dropDB
{
    if ([conn.defaultdb isPresent]) {
        NSRunAlertPanel(@"Error", @"Could not drop database!", @"OK", nil, nil);
        return;
    }
    Database *db = [databaseArrayController dbInfo:conn name:[self.selectedDB caption]];
    [loaderIndicator start];
    [_mongoDB dropDatabaseWithName:[self.selectedDB caption] userName:db.user password:db.password];
}

- (IBAction)query:(id)sender
{
    if (!self.selectedCollection) {
        NSRunAlertPanel(@"Error", @"Please choose a collection!", @"OK", nil, nil);
        return;
    }
    
    QueryWindowController *queryWindowController = [[QueryWindowController alloc] init];
    queryWindowController.managedObjectContext = self.managedObjectContext;
    queryWindowController.conn = conn;
    queryWindowController.dbname = [self.selectedDB caption];
    queryWindowController.collectionname = [self.selectedCollection caption];
    queryWindowController.mongoDB = _mongoDB;
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
    importWindowController.mongoDB = _mongoDB;
    importWindowController.dbname = [self.selectedDB caption];
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
    exportWindowController.mongoDB = _mongoDB;
    exportWindowController.dbname = [self.selectedDB caption];
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
        [_mongoDB fetchServerStatusDelta];
        _serverMonitorTimer = [[NSTimer scheduledTimerWithTimeInterval:1 target:_mongoDB selector:@selector(fetchServerStatusDelta) userInfo:nil repeats:YES] retain];
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

@end

@implementation ConnectionWindowController(MongoDBDelegate)

- (void)mongoDBConnectionSucceded:(MongoDB *)mongoDB
{
    NSAssert(mongoDB == _mongoDB, @"wrong database");
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

- (void)mongoDBConnectionFailed:(MongoDB *)mongoDB withErrorMessage:(NSString *)errorMessage
{
    NSAssert(mongoDB == _mongoDB, @"wrong database");
    [loaderIndicator stop];
    NSRunAlertPanel(@"Error", errorMessage, @"OK", nil, nil);
}

- (void)mongoDB:(MongoDB *)mongoDB databaseListFetched:(NSArray *)list withErrorMessage:(NSString *)errorMessage
{
    NSAssert(mongoDB == _mongoDB, @"wrong database");
    [loaderIndicator stop];
    self.selectedDB = nil;
    self.selectedCollection = nil;
    [self.collections removeAllObjects];
    [self.databases removeAllObjects];
    if ([conn.defaultdb isPresent]) {
        [self.databases addObject:conn.defaultdb];
    } else if (list != nil) {
        [self.databases addObjectsFromArray:list];
    } else if (errorMessage) {
        NSRunAlertPanel(@"Error", errorMessage, @"OK", nil, nil);
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
}

- (void)mongoDB:(MongoDB *)mongoDB serverStatusFetched:(NSArray *)serverStatus withErrorMessage:(NSString *)errorMessage
{
    NSAssert(mongoDB == _mongoDB, @"wrong database");
    [loaderIndicator stop];
    [resultsOutlineViewController.results removeAllObjects];
    if (serverStatus) {
        [resultsOutlineViewController.results addObjectsFromArray:serverStatus];
    } else if (errorMessage) {
        NSRunAlertPanel(@"Error", errorMessage, @"OK", nil, nil);
    }
    [resultsOutlineViewController.myOutlineView reloadData];
}

- (void)mongoDB:(MongoDB *)mongoDB collectionListFetched:(NSArray *)collectionList withDatabaseName:(NSString *)databaseName errorMessage:(NSString *)errorMessage
{
    NSAssert(mongoDB == _mongoDB, @"wrong database");
    [loaderIndicator stop];
    if ([[self.selectedDB caption] isEqualToString:databaseName]) {
        [self.collections removeAllObjects];
        if (collectionList) {
            [self.collections addObjectsFromArray:collectionList];
        } else if (errorMessage) {
            NSRunAlertPanel(@"Error", errorMessage, @"OK", nil, nil);
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
}

- (void)mongoDB:(MongoDB *)mongoDB databaseStatsFetched:(NSArray *)databaseStats withDatabaseName:(NSString *)databaseName errorMessage:(NSString *)errorMessage
{
    NSAssert(mongoDB == _mongoDB, @"wrong database");
    [loaderIndicator stop];
        [resultsOutlineViewController.results removeAllObjects];
        if (databaseStats) {
            [resultsOutlineViewController.results addObjectsFromArray:databaseStats];
        } else if (errorMessage) {
            NSRunAlertPanel(@"Error", errorMessage, @"OK", nil, nil);
        }
        [resultsOutlineViewController.myOutlineView reloadData];
}

- (void)mongoDB:(MongoDB *)mongoDB collectionStatsFetched:(NSArray *)collectionStats withDatabaseName:(NSString *)databaseName collectionName:(NSString *)collectionName errorMessage:(NSString *)errorMessage
{
    NSAssert(mongoDB == _mongoDB, @"wrong database");
    [loaderIndicator stop];
    if ([[self.selectedDB caption] isEqualToString:databaseName] && [[self.selectedCollection caption] isEqualToString:collectionName]) {
        [resultsOutlineViewController.results removeAllObjects];
        if (collectionStats) {
            [resultsOutlineViewController.results addObjectsFromArray:collectionStats];
        } else if (errorMessage) {
            NSRunAlertPanel(@"Error", errorMessage, @"OK", nil, nil);
        }
        [resultsOutlineViewController.myOutlineView reloadData];
    }
}

- (void)mongoDB:(MongoDB *)mongoDB serverStatusDeltaFetched:(NSDictionary *)serverStatusDelta withErrorMessage:(NSString *)errorMessage
{
    if (serverStatusDelta) {
        [statMonitorTableController addObject:serverStatusDelta];
    }
}

- (void)mongoDB:(MongoDB *)mongoDB databaseDropedWithName:(NSString *)databaseName errorMessage:(NSString *)errorMessage
{
    NSAssert(mongoDB == _mongoDB, @"wrong database");
    [loaderIndicator stop];
    [self reloadSidebar];
    if (errorMessage) {
        NSRunAlertPanel(@"Error", errorMessage, @"OK", nil, nil);
    }
}

- (void)mongoDB:(MongoDB *)mongoDB collectionCreatedWithName:(NSString *)collectionName databaseName:(NSString *)databaseName errorMessage:(NSString *)errorMessage
{
    NSAssert(mongoDB == _mongoDB, @"wrong database");
    [loaderIndicator stop];
    if (errorMessage) {
        NSRunAlertPanel(@"Error", errorMessage, @"OK", nil, nil);
    }
    if ([[self.selectedDB caption] isEqualToString:databaseName]) {
        [sidebar selectItem:[self.selectedDB nodeKey]];
    }
}

- (void)mongoDB:(MongoDB *)mongoDB collectionDropedWithName:(NSString *)collectionName databaseName:(NSString *)databaseName errorMessage:(NSString *)errorMessage
{
    NSAssert(mongoDB == _mongoDB, @"wrong database");
    [loaderIndicator stop];
    if (errorMessage) {
        NSRunAlertPanel(@"Error", errorMessage, @"OK", nil, nil);
    }
    if ([[self.selectedDB caption] isEqualToString:databaseName]) {
        [sidebar selectItem:[self.selectedDB nodeKey]];
    }
}

@end
