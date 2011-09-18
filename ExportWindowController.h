//
//  ExportWindowController.h
//  MongoHub
//
//  Created by Syd on 10-6-22.
//  Copyright 2010 ThePeppersStudio.COM. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class Connection;
@class DatabasesArrayController;
@class MCPConnection;
@class MODServer;
@class MODCollection;
@class FieldMapTableController;

@interface ExportWindowController : NSWindowController {
    NSManagedObjectContext *managedObjectContext;
    DatabasesArrayController *databasesArrayController;
    NSString *dbname;
    Connection *conn;
    MODServer *mongoServer;
    MODCollection *mongoCollection;
    MCPConnection *db;
    IBOutlet NSArrayController *dbsArrayController;
    IBOutlet NSArrayController *tablesArrayController;
    IBOutlet NSTextField *hostTextField;
    IBOutlet NSTextField *portTextField;
    IBOutlet NSTextField *userTextField;
    IBOutlet NSSecureTextField *passwdTextField;
    IBOutlet NSTextField *collectionTextField;
    IBOutlet NSProgressIndicator *progressIndicator;
    IBOutlet NSPopUpButton *tablesPopUpButton;
    IBOutlet FieldMapTableController *fieldMapTableController;
}

@property (nonatomic, retain) Connection *conn;
@property (nonatomic, retain) MCPConnection *db;
@property (nonatomic, retain) MODServer *mongoServer;
@property (nonatomic, retain) MODCollection *mongoCollection;
@property (nonatomic, retain) DatabasesArrayController *databasesArrayController;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSString *dbname;
@property (nonatomic, retain) NSArrayController *dbsArrayController;
@property (nonatomic, retain) NSArrayController *tablesArrayController;
@property (nonatomic, retain) NSTextField *hostTextField;
@property (nonatomic, retain) NSTextField *portTextField;
@property (nonatomic, retain) NSTextField *userTextField;
@property (nonatomic, retain) NSSecureTextField *passwdTextField;
@property (nonatomic, retain) NSTextField *collectionTextField;
@property (nonatomic, retain) NSProgressIndicator *progressIndicator;
@property (nonatomic, retain) NSPopUpButton *tablesPopUpButton;
@property (nonatomic, retain) FieldMapTableController *fieldMapTableController;

- (void)initInterface;
- (IBAction)connect:(id)sender;
- (IBAction)export:(id)sender;
- (IBAction)showTables:(id)sender;
- (IBAction)showFields:(id)sender;
- (int64_t)exportCount:(NSString *)collection user:(NSString *)user password:(NSString *)password;
- (void)doExportToTable:(NSString *)tableName data:(id)bsonObj fieldTypes:(NSDictionary *)fieldTypes;
@end
