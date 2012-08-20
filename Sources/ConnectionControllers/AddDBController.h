//
//  AddDBController.h
//  MongoHub
//
//  Created by Syd on 10-4-28.
//  Copyright 2010 ThePeppersStudio.COM. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class DatabasesArrayController;
@class MHConnectionStore;

@interface AddDBController : NSWindowController {
    IBOutlet NSTextField *dbname;
    IBOutlet NSTextField *user;
    IBOutlet NSSecureTextField *password;
    IBOutlet DatabasesArrayController   *_databasesArrayController;
    
    NSMutableDictionary *dbInfo;
    MHConnectionStore *conn;
    NSManagedObjectContext              *_managedObjectContext;
}

@property (nonatomic, retain) NSTextField *dbname;
@property (nonatomic, retain) NSTextField *user;
@property (nonatomic, retain) NSSecureTextField *password;
@property (nonatomic, retain) NSMutableDictionary *dbInfo;
@property (nonatomic, retain) MHConnectionStore *conn;
@property (nonatomic, retain) DatabasesArrayController *databasesArrayController;
@property(nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

- (IBAction)add:(id)sender;
- (IBAction)cancel:(id)sender;
- (void)saveAction;
@end
