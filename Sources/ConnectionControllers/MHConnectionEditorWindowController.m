//
//  MHConnectionEditorWindowControllerDelegate.m
//  MongoHub
//
//  Created by Jérôme Lebel on 19/08/12.
//  Copyright (c) 2012 ThePeppersStudio.COM. All rights reserved.
//

#import "MHConnectionEditorWindowController.h"
#import "MHConnectionStore.h"
#import "DatabasesArrayController.h"
#import "mongo.h"

@interface MHConnectionEditorWindowController ()
- (void)_updateSSHFields;
- (void)_updateReplFields;
@end

@implementation MHConnectionEditorWindowController

@synthesize editedConnectionStore = _editedConnectionStore;
@synthesize delegate = _delegate;
@synthesize newConnection = _newConnection;

- (id)init
{
    self = [super initWithWindowNibName:@"MHConnectionEditorWindowController"];
    return self;
}

- (void)dealloc
{
    self.editedConnectionStore = nil;
    [super dealloc];
}

- (void)windowDidLoad
{
    [_hostportTextField.cell setPlaceholderString:[NSString stringWithFormat:@"%d", MONGO_DEFAULT_PORT]];
    [_sshuserTextField.cell setPlaceholderString:[NSProcessInfo.processInfo.environment objectForKey:@"USER" ]];
    if (self.editedConnectionStore) {
        [_hostTextField setStringValue:self.editedConnectionStore.host];
        if (self.editedConnectionStore.hostport.stringValue.longLongValue == 0) {
            [_hostportTextField setStringValue:@""];
        } else {
            [_hostportTextField setStringValue:self.editedConnectionStore.hostport.stringValue];
        }
        if (self.editedConnectionStore.servers) [_serversTextField setStringValue:self.editedConnectionStore.servers];
        if (self.editedConnectionStore.repl_name) [_replnameTextField setStringValue:self.editedConnectionStore.repl_name];
        [_usereplCheckBox setState:self.editedConnectionStore.userepl.boolValue?NSOnState:NSOffState];
        [_aliasTextField setStringValue:self.editedConnectionStore.alias];
        if (self.editedConnectionStore.adminuser) [_adminuserTextField setStringValue:self.editedConnectionStore.adminuser];
        if (self.editedConnectionStore.adminpass) [_adminpassTextField setStringValue:self.editedConnectionStore.adminpass];
        if (self.editedConnectionStore.defaultdb) [_defaultdbTextField setStringValue:self.editedConnectionStore.defaultdb];
        if (self.editedConnectionStore.sshhost) [_sshhostTextField setStringValue:self.editedConnectionStore.sshhost];
        if (self.editedConnectionStore.sshport.stringValue.longLongValue == 0) {
            [_sshportTextField setStringValue:@""];
        } else {
            [_sshportTextField setStringValue:self.editedConnectionStore.sshport.stringValue];
        }
        if (self.editedConnectionStore.sshuser) [_sshuserTextField setStringValue:self.editedConnectionStore.sshuser];
        if (self.editedConnectionStore.sshpassword) [_sshpasswordTextField setStringValue:self.editedConnectionStore.sshpassword];
        if (self.editedConnectionStore.sshkeyfile) [_sshkeyfileTextField setStringValue:self.editedConnectionStore.sshkeyfile];
        [_usesshCheckBox setState:self.editedConnectionStore.usessh.boolValue?NSOnState:NSOffState];
        _addSaveButton.title = NSLocalizedString(@"Save", @"Save connection (after updating)");
        _newConnection = NO;
        self.window.title = self.editedConnectionStore.alias;
    } else {
        [_hostTextField setStringValue:@""];
        [_hostportTextField setStringValue:@""];
        [_serversTextField setStringValue:@""];
        [_replnameTextField setStringValue:@""];
        [_usereplCheckBox setState:NSOffState];
        [_aliasTextField setStringValue:@""];
        [_adminuserTextField setStringValue:@""];
        [_adminpassTextField setStringValue:@""];
        [_defaultdbTextField setStringValue:@""];
        [_sshhostTextField setStringValue:@""];
        [_sshportTextField setStringValue:@""];
        [_sshuserTextField setStringValue:@""];
        [_sshpasswordTextField setStringValue:@""];
        [_sshkeyfileTextField setStringValue:@""];
        [_usesshCheckBox setState:NSOffState];
        _newConnection = YES;
        _addSaveButton.title = NSLocalizedString(@"Add", @"Add connection");
        self.window.title = NSLocalizedString(@"New Connection", @"New Connection");
    }
    [_sshhostTextField setEnabled:_usereplCheckBox.state == NSOnState];
    [_sshuserTextField setEnabled:_usereplCheckBox.state == NSOnState];
    [_sshportTextField setEnabled:_usereplCheckBox.state == NSOnState];
    [_sshpasswordTextField setEnabled:_usereplCheckBox.state == NSOnState];
    [_sshkeyfileTextField setEnabled:_usereplCheckBox.state == NSOnState];
    [_selectKeyFileButton setEnabled:_usereplCheckBox.state == NSOnState];
    [_serversTextField setEnabled:_usereplCheckBox.state == NSOnState];
    [_replnameTextField setEnabled:_usereplCheckBox.state == NSOnState];
    [self _updateSSHFields];
    [self _updateReplFields];
    [super windowDidLoad];
}

- (void)modalForWindow:(NSWindow *)window
{
    [NSApp beginSheet:self.window modalForWindow:window modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];
}

- (void)didEndSheet:(NSWindow *)window returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [self.window orderOut:self];
}

- (NSManagedObjectContext *)managedObjectContext
{
    return _delegate.managedObjectContext;
}

- (IBAction)cancelAction:(id)sender
{
    [_delegate connectionWindowControllerDidCancel:self];
    [NSApp endSheet:self.window];
}

- (IBAction)addSaveAction:(id)sender
{
    NSString *hostName;
    long long hostPort;
    long long sshPort;
    NSString *defaultdb;
    NSString *alias;
    NSString *sshHost;
    NSString *replicaServers;
    NSString *replicaName;
    BOOL useSSH;
    BOOL useReplica;
    
    hostName = [_hostTextField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    hostPort = [_hostportTextField.stringValue longLongValue];
    defaultdb = [_defaultdbTextField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    alias = [_aliasTextField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    sshHost = [_sshhostTextField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    useSSH = _usesshCheckBox.state == NSOnState;
    useReplica = _usereplCheckBox.state == NSOnState;
    replicaServers = [_serversTextField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    replicaName = [_replnameTextField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    sshPort = [_sshportTextField.stringValue longLongValue];
    
    if ([hostName isEqualToString:@"flame.mongohq.com"] && defaultdb.length == 0) {
        NSBeginAlertSheet(NSLocalizedString(@"Error", @"Error"), NSLocalizedString(@"OK", @"OK"), nil, nil, self.window, nil, nil, nil, nil, NSLocalizedString(@"DB should not be empty if you are using mongohq", @""));
        return;
    }
    if (hostPort < 0 || hostPort > 65535) {
        NSBeginAlertSheet(NSLocalizedString(@"Error", @"Error"), NSLocalizedString(@"OK", @"OK"), nil, nil, self.window, nil, nil, nil, nil, NSLocalizedString(@"Host port should be between 1 and 65535 (or empty)", @""));
        return;
    }
    if (alias.length < 1) {
        NSBeginAlertSheet(NSLocalizedString(@"Error", @"Error"), NSLocalizedString(@"OK", @"OK"), nil, nil, self.window, nil, nil, nil, nil, NSLocalizedString(@"Name should not be less than 1 charaters", @""));
        return;
    }
    if (useSSH && sshHost.length == 0) {
        NSBeginAlertSheet(NSLocalizedString(@"Error", @"Error"), NSLocalizedString(@"OK", @"OK"), nil, nil, self.window, nil, nil, nil, nil, NSLocalizedString(@"Tunneling requires SSH Host!", @""));
        return;
    }
    if (useSSH && (sshPort < 0 || sshPort > 65535)) {
        NSBeginAlertSheet(NSLocalizedString(@"Error", @"Error"), NSLocalizedString(@"OK", @"OK"), nil, nil, self.window, nil, nil, nil, nil, NSLocalizedString(@"ssh port should be between 1 and 65535 (or empty)", @""));
        return;
    }
    if (useReplica && (replicaServers.length == 0 || replicaName.length == 0)) {
        NSBeginAlertSheet(NSLocalizedString(@"Error", @"Error"), NSLocalizedString(@"OK", @"OK"), nil, nil, self.window, nil, nil, nil, nil, NSLocalizedString(@"Name already in use!", @""));
        return;
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"alias=%@", alias];
    NSArray *items = [_connectionsArrayController itemsUsingFetchPredicate:predicate];
    if (items.count == 1 && [items objectAtIndex:0] != self.editedConnectionStore) {
        NSBeginAlertSheet(NSLocalizedString(@"Error", @"Error"), NSLocalizedString(@"OK", @"OK"), nil, nil, self.window, nil, nil, nil, nil, NSLocalizedString(@"Name already in use!", @""));
        return;
    }
    if (!self.editedConnectionStore) {
        self.editedConnectionStore = [[_connectionsArrayController newObject] retain];
    }
    self.editedConnectionStore.host = hostName;
    self.editedConnectionStore.hostport = [NSNumber numberWithLongLong:hostPort];
    self.editedConnectionStore.servers = replicaServers;
    self.editedConnectionStore.repl_name = replicaName;
    self.editedConnectionStore.userepl = [NSNumber numberWithBool:useReplica];
    self.editedConnectionStore.alias = alias;
    self.editedConnectionStore.adminuser = [_adminuserTextField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.editedConnectionStore.adminpass = _adminpassTextField.stringValue;
    self.editedConnectionStore.defaultdb = defaultdb;
    self.editedConnectionStore.sshhost = sshHost;
    self.editedConnectionStore.sshport = [NSNumber numberWithLongLong:sshPort];
    self.editedConnectionStore.sshuser = _sshuserTextField.stringValue;
    self.editedConnectionStore.sshpassword = _sshpasswordTextField.stringValue;
    self.editedConnectionStore.sshkeyfile = _sshkeyfileTextField.stringValue;
    self.editedConnectionStore.usessh = [NSNumber numberWithBool:useSSH];
    if (_newConnection) {
        [_connectionsArrayController addObject:self.editedConnectionStore];
    }
    [_delegate connectionWindowControllerDidValidate:self];
    [NSApp endSheet:self.window];
}

- (IBAction)enableSSH:(id)sender
{
    [self _updateSSHFields];
}

- (IBAction)enableRepl:(id)sender
{
    [self _updateReplFields];
}

- (IBAction)chooseKeyPathAction:(id)sender
{
    NSOpenPanel *tvarNSOpenPanelObj = [NSOpenPanel openPanel];
    NSInteger tvarNSInteger = [tvarNSOpenPanelObj runModal];
    if (tvarNSInteger == NSOKButton) {
        NSLog(@"doOpen we have an OK button");
        //NSString * tvarDirectory = [tvarNSOpenPanelObj directory];
        //NSLog(@"doOpen directory = %@",tvarDirectory);
        NSString * tvarFilename = [[tvarNSOpenPanelObj URL] path];
        NSLog(@"doOpen filename = %@",tvarFilename);
        [_sshkeyfileTextField setStringValue:tvarFilename];
    } else if (tvarNSInteger == NSCancelButton) {
        NSLog(@"doOpen we have a Cancel button");
        return;
    } else {
        NSLog(@"doOpen tvarInt not equal 1 or zero = %ld",(long int)tvarNSInteger);
        return;
    } // end if
}

- (void)_updateSSHFields
{
    BOOL useSSH;
    
    useSSH = [_usesshCheckBox state] == NSOnState;
    [_sshhostTextField setEnabled:useSSH];
    [_sshuserTextField setEnabled:useSSH];
    [_sshportTextField setEnabled:useSSH];
    [_sshpasswordTextField setEnabled:useSSH];
    [_sshkeyfileTextField setEnabled:useSSH];
    [_selectKeyFileButton setEnabled:useSSH];
}

- (void)_updateReplFields
{
    BOOL useRepl;
    
    useRepl = _usereplCheckBox.state == NSOnState;
    [_serversTextField setEnabled:useRepl];
    [_replnameTextField setEnabled:useRepl];
}

@end
