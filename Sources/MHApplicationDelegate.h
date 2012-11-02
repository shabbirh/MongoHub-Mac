//
//  MHApplicationDelegate.h
//  MongoHub
//
//  Created by Syd on 10-4-24.
//  Copyright MusicPeace.ORG 2010 . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MHConnectionEditorWindowController.h"

@class ConnectionsCollectionView;
@class ConnectionsArrayController;
@class MHConnectionStore;
@class MHConnectionEditorWindowController;
@class SUUpdater;

@interface MHApplicationDelegate : NSObject <NSApplicationDelegate, NSCollectionViewDelegate>
{
    IBOutlet NSWindow                       *_window;
    
    NSPersistentStoreCoordinator            *persistentStoreCoordinator;
    NSManagedObjectModel                    *managedObjectModel;
    NSManagedObjectContext                  *managedObjectContext;
    MHConnectionEditorWindowController      *_addConnectionWindowController;
    NSMutableArray                          *_editConnectionWindowControllers;
    
    IBOutlet ConnectionsCollectionView      *connectionsCollectionView;
    IBOutlet ConnectionsArrayController     *connectionsArrayController;
    IBOutlet NSTextField                    *bundleVersion;
  
    IBOutlet NSPanel                        *supportPanel;
    IBOutlet SUUpdater                      *updater;
}

@property (nonatomic, retain, readonly) NSWindow *window;

@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, retain) ConnectionsCollectionView *connectionsCollectionView;
@property (nonatomic, retain) ConnectionsArrayController *connectionsArrayController;
@property (nonatomic, retain) NSTextField *bundleVersion;

- (void)saveConnections;
- (IBAction)showAddConnectionPanel:(id)sender;
- (IBAction)showEditConnectionPanel:(id)sender;
- (IBAction)deleteConnection:(id)sender;
- (IBAction)resizeConnectionItemView:(id)sender;
- (IBAction)showConnectionWindow:(id)sender;
- (BOOL)isOpenedConnection:(MHConnectionStore *)aConnection;
- (void)doubleClick:(id)sender;

- (IBAction)openSupportPanel:(id)sender;
- (IBAction)closeSupportPanel:(id)sender;
- (IBAction)openFeatureRequestBugReport:(id)sender;

@end

@interface MHApplicationDelegate (MHConnectionEditorWindowControllerDelegate) <MHConnectionEditorWindowControllerDelegate>
@end