//
//  ConnectionWindowController.h
//  MongoHub
//
//  Created by Syd on 10-4-25.
//  Copyright 2010 MusicPeace.ORG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MHServerItem.h"
#import "MHTunnel.h"

@class BWSheetController;
@class DatabasesArrayController;
@class StatMonitorTableController;
@class AddDBController;
@class AddCollectionController;
@class AuthWindowController;
@class MHMysqlImportWindowController;
@class MHMysqlExportWindowController;
@class MHResultsOutlineViewController;
@class MHConnectionStore;
@class MODServer;
@class MODDatabase;
@class MODCollection;
@class MODSortedMutableDictionary;
@class MHTabTitleView;
@class MHStatusViewController;
@class MHTabViewController;

@interface ConnectionWindowController : NSWindowController <MHTunnelDelegate>
{
    IBOutlet NSMenu *createCollectionOrDatabaseMenu;
    IBOutlet DatabasesArrayController *_databaseStoreArrayController;
    
    MHStatusViewController *_statusViewController;
    IBOutlet MHTabViewController *_tabViewController;
    IBOutlet NSSplitView *_splitView;
    
    MHServerItem *_serverItem;
    MHConnectionStore *_connectionStore;
    MODServer *_mongoServer;
    NSTimer *_serverMonitorTimer;
    IBOutlet NSOutlineView *_databaseCollectionOutlineView;
    IBOutlet NSTextField *resultsTitle;
    IBOutlet NSProgressIndicator *loaderIndicator;
    IBOutlet NSButton *reconnectButton;
    IBOutlet NSButton *monitorButton;
    IBOutlet NSPanel *monitorPanel;
    IBOutlet StatMonitorTableController *statMonitorTableController;
    IBOutlet NSToolbar *_toolbar;
    NSMutableArray *_databases;
    MHTunnel *sshTunnel;
    AddDBController *addDBController;
    AddCollectionController *addCollectionController;
    AuthWindowController *authWindowController;
    MHMysqlImportWindowController *_mysqlImportWindowController;
    MHMysqlExportWindowController *_mysqlExportWindowController;
    IBOutlet NSTextField *bundleVersion;
    BOOL exitThread;
    BOOL monitorStopped;
    
    IBOutlet NSView *_mainTabView;
    IBOutlet MHTabTitleView *_tabTitleView;
    
    MODSortedMutableDictionary *previousServerStatusForDelta;
}

@property (nonatomic, retain) MHConnectionStore *connectionStore;
@property (nonatomic, retain) MODServer *mongoServer;
@property (nonatomic, retain) NSMutableArray *databases;
@property (nonatomic, retain) MHTunnel *sshTunnel;
@property (nonatomic, retain) NSTextField *resultsTitle;
@property (nonatomic, retain) NSProgressIndicator *loaderIndicator;
@property (nonatomic, retain) NSButton *monitorButton;
@property (nonatomic, retain) NSButton *reconnectButton;
@property (nonatomic, retain) StatMonitorTableController *statMonitorTableController;
@property (nonatomic, retain) AddDBController *addDBController;
@property (nonatomic, retain) AddCollectionController *addCollectionController;
@property (nonatomic, retain) NSTextField *bundleVersion;
@property (nonatomic, retain) AuthWindowController *authWindowController;
@property (nonatomic, retain) MHMysqlImportWindowController *mysqlImportWindowController;
@property (nonatomic, retain) MHMysqlExportWindowController *mysqlExportWindowController;
@property (nonatomic, readonly, assign) NSManagedObjectContext *managedObjectContext;

- (IBAction)reconnect:(id)sender;
- (IBAction)showServerStatus:(id)sender;
- (IBAction)showCollStats:(id)sender;
- (IBAction)createDatabase:(id)sender;
- (IBAction)createCollection:(id)sender;
- (IBAction)importFromMySQL:(id)sender;
- (IBAction)exportToMySQL:(id)sender;
- (IBAction)importFromFile:(id)sender;
- (IBAction)exportToFile:(id)sender;
- (void)dropCollection:(NSString *)collectionname 
                 ForDB:(NSString *)dbname;
- (void)createDB;
- (void)createCollectionForDB:(NSString *)dbname;
- (IBAction)dropDBorCollection:(id)sender;
- (void)dropDB;
- (IBAction)query:(id)sender;
- (IBAction)showAuth:(id)sender;
- (void)checkTunnel;
- (void)connect:(BOOL)haveHostAddress;
- (void)tunnelStatusChanged:(MHTunnel *)tunnel status:(NSString *)status;
- (void)dropWarning:(NSString *)msg;

- (IBAction)startMonitor:(id)sender;
- (IBAction)stopMonitor:(id)sender;
@end

@interface ConnectionWindowController(NSOutlineViewDataSource) <NSOutlineViewDataSource>
@end

@interface ConnectionWindowController(MHServerItemDelegateCategory)<MHServerItemDelegate>
@end