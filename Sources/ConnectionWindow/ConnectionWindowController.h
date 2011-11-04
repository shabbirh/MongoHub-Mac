//
//  ConnectionWindowController.h
//  MongoHub
//
//  Created by Syd on 10-4-25.
//  Copyright 2010 MusicPeace.ORG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Tunnel.h"
#import "MHServerItem.h"

@class BWSheetController;
@class DatabasesArrayController;
@class StatMonitorTableController;
@class AddDBController;
@class AddCollectionController;
@class AuthWindowController;
@class ImportWindowController;
@class ExportWindowController;
@class ResultsOutlineViewController;
@class MHConnectionStore;
@class MODServer;
@class MODDatabase;
@class MODCollection;

@interface ConnectionWindowController : NSWindowController
{
    IBOutlet NSMenu *createCollectionOrDatabaseMenu;
    IBOutlet DatabasesArrayController *_databaseStoreArrayController;
    IBOutlet ResultsOutlineViewController *resultsOutlineViewController;
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
    NSMutableArray *_databases;
    Tunnel *sshTunnel;
    AddDBController *addDBController;
    AddCollectionController *addCollectionController;
    AuthWindowController *authWindowController;
    ImportWindowController *importWindowController;
    ExportWindowController *exportWindowController;
    IBOutlet NSTextField *bundleVersion;
    BOOL exitThread;
    BOOL monitorStopped;
    
    NSDictionary *previousServerStatusForDelta;
}

@property (nonatomic, retain) ResultsOutlineViewController *resultsOutlineViewController;
@property (nonatomic, retain) MHConnectionStore *connectionStore;
@property (nonatomic, retain) MODServer *mongoServer;
@property (nonatomic, retain) NSMutableArray *databases;
@property (nonatomic, retain) Tunnel *sshTunnel;
@property (nonatomic, retain) NSTextField *resultsTitle;
@property (nonatomic, retain) NSProgressIndicator *loaderIndicator;
@property (nonatomic, retain) NSButton *monitorButton;
@property (nonatomic, retain) NSButton *reconnectButton;
@property (nonatomic, retain) StatMonitorTableController *statMonitorTableController;
@property (nonatomic, retain) AddDBController *addDBController;
@property (nonatomic, retain) AddCollectionController *addCollectionController;
@property (nonatomic, retain) NSTextField *bundleVersion;
@property (nonatomic, retain) AuthWindowController *authWindowController;
@property (nonatomic, retain) ImportWindowController *importWindowController;
@property (nonatomic, retain) ExportWindowController *exportWindowController;
@property (nonatomic, readonly, assign) NSManagedObjectContext *managedObjectContext;

- (IBAction)reconnect:(id)sender;
- (IBAction)showServerStatus:(id)sender;
- (IBAction)showCollStats:(id)sender;
- (IBAction)createDatabase:(id)sender;
- (IBAction)createCollection:(id)sender;
- (IBAction)importFromMySQL:(id)sender;
- (IBAction)exportToMySQL:(id)sender;
- (void)dropCollection:(NSString *)collectionname 
                 ForDB:(NSString *)dbname;
- (void)createDB;
- (void)createCollectionForDB:(NSString *)dbname;
- (IBAction)dropDBorCollection:(id)sender;
- (void)dropDB;
- (IBAction)query:(id)sender;
- (IBAction)showAuth:(id)sender;
-(void) checkTunnel;
- (void) connect:(BOOL)haveHostAddress;
- (void) tunnelStatusChanged: (Tunnel*) tunnel status: (NSString*) status;
- (void)dropWarning:(NSString *)msg;

- (IBAction)startMonitor:(id)sender;
- (IBAction)stopMonitor:(id)sender;
@end

@interface ConnectionWindowController(NSOutlineViewDataSource) <NSOutlineViewDataSource>
@end

@interface ConnectionWindowController(MHServerItemDelegateCategory)<MHServerItemDelegate>
@end