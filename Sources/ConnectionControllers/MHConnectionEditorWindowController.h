//
//  MHConnectionEditorWindowController.h
//  MongoHub
//
//  Created by Jérôme Lebel on 19/08/12.
//  Copyright (c) 2012 ThePeppersStudio.COM. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MHConnectionStore;
@class MHConnectionEditorWindowController;
@class ConnectionsArrayController;

@protocol MHConnectionEditorWindowControllerDelegate <NSObject>
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
- (void)connectionWindowControllerDidCancel:(MHConnectionEditorWindowController *)controller;
- (void)connectionWindowControllerDidValidate:(MHConnectionEditorWindowController *)controller;
@end

@interface MHConnectionEditorWindowController : NSWindowController
{
    IBOutlet NSTextField                *_hostTextField;
    IBOutlet NSTextField                *_hostportTextField;
    IBOutlet NSButton                   *_usereplCheckBox;
    IBOutlet NSTextField                *_serversTextField;
    IBOutlet NSTextField                *_replnameTextField;
    IBOutlet NSTextField                *_aliasTextField;
    IBOutlet NSTextField                *_adminuserTextField;
    IBOutlet NSSecureTextField          *_adminpassTextField;
    IBOutlet NSTextField                *_defaultdbTextField;
    IBOutlet NSButton                   *_usesshCheckBox;
    IBOutlet NSTextField                *_sshhostTextField;
    IBOutlet NSTextField                *_sshportTextField;
    IBOutlet NSTextField                *_sshuserTextField;
    IBOutlet NSSecureTextField          *_sshpasswordTextField;
    IBOutlet NSTextField                *_sshkeyfileTextField;
    IBOutlet ConnectionsArrayController *_connectionsArrayController;
    IBOutlet NSButton                   *_selectKeyFileButton;
    IBOutlet NSButton                   *_addSaveButton;
    
    MHConnectionStore                   *_editedConnectionStore;
    BOOL                                _newConnection;
    id<MHConnectionEditorWindowControllerDelegate> _delegate;
}
@property(nonatomic, retain, readwrite) MHConnectionStore *editedConnectionStore;
@property(nonatomic, assign, readwrite) id<MHConnectionEditorWindowControllerDelegate> delegate;
@property(nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property(nonatomic, assign, readonly, getter=isNewConnetion) BOOL newConnection;

- (IBAction)cancelAction:(id)sender;
- (IBAction)addSaveAction:(id)sender;
- (IBAction)chooseKeyPathAction:(id)sender;

@end
