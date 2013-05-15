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

@synthesize connectionStore = _connectionStore;
@synthesize delegate = _delegate;
@synthesize newConnection = _newConnection;

- (id)init
{
    self = [super initWithWindowNibName:@"MHConnectionEditorWindowController"];
    return self;
}

- (void)dealloc
{
    [_connectionStore release];
    [super dealloc];
}

- (void)windowDidLoad
{
    [_hostportTextField.cell setPlaceholderString:[NSString stringWithFormat:@"%d", MONGO_DEFAULT_PORT]];
    if (_connectionStore) {
        [_hostTextField setStringValue:_connectionStore.host];
        if (_connectionStore.hostport.stringValue.longLongValue == 0) {
            [_hostportTextField setStringValue:@""];
        } else {
            [_hostportTextField setStringValue:_connectionStore.hostport.stringValue];
        }
        if (_connectionStore.servers) [_serversTextField setStringValue:_connectionStore.servers];
        if (_connectionStore.repl_name) [_replnameTextField setStringValue:_connectionStore.repl_name];
        [_usereplCheckBox setState:_connectionStore.userepl.boolValue?NSOnState:NSOffState];
        [_aliasTextField setStringValue:_connectionStore.alias];
        if (_connectionStore.adminuser) [_adminuserTextField setStringValue:_connectionStore.adminuser];
        if (_connectionStore.adminpass) [_adminpassTextField setStringValue:_connectionStore.adminpass];
        if (_connectionStore.defaultdb) [_defaultdbTextField setStringValue:_connectionStore.defaultdb];
        if (_connectionStore.sshhost) [_sshhostTextField setStringValue:_connectionStore.sshhost];
        if (_connectionStore.sshport.stringValue.longLongValue == 0) {
            [_sshportTextField setStringValue:@""];
        } else {
            [_sshportTextField setStringValue:_connectionStore.sshport.stringValue];
        }
        if (_connectionStore.sshuser) [_sshuserTextField setStringValue:_connectionStore.sshuser];
        if (_connectionStore.sshpassword) [_sshpasswordTextField setStringValue:_connectionStore.sshpassword];
        if (_connectionStore.sshkeyfile) [_sshkeyfileTextField setStringValue:_connectionStore.sshkeyfile];
        [_usesshCheckBox setState:_connectionStore.usessh.boolValue?NSOnState:NSOffState];
        _addSaveButton.title = NSLocalizedString(@"Save", @"Save connection (after updating)");
        _newConnection = NO;
        self.window.title = _connectionStore.alias;
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

- (NSManagedObjectContext *)managedObjectContext
{
    return _delegate.managedObjectContext;
}

- (IBAction)cancelAction:(id)sender
{
    [_delegate connectionWindowControllerDidCancel:self];
    [self close];
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
    if (items.count == 1 && [items objectAtIndex:0] != _connectionStore) {
        NSBeginAlertSheet(NSLocalizedString(@"Error", @"Error"), NSLocalizedString(@"OK", @"OK"), nil, nil, self.window, nil, nil, nil, nil, NSLocalizedString(@"Name already in use!", @""));
        return;
    }
    if (!_connectionStore) {
        _connectionStore = [[_connectionsArrayController newObject] retain];
    }
    _connectionStore.host = hostName;
    _connectionStore.hostport = [NSNumber numberWithLongLong:hostPort];
    _connectionStore.servers = replicaServers;
    _connectionStore.repl_name = replicaName;
    _connectionStore.userepl = [NSNumber numberWithBool:useReplica];
    _connectionStore.alias = alias;
    _connectionStore.adminuser = [_adminuserTextField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    _connectionStore.adminpass = _adminpassTextField.stringValue;
    _connectionStore.defaultdb = defaultdb;
    _connectionStore.sshhost = sshHost;
    _connectionStore.sshport = [NSNumber numberWithLongLong:sshPort];
    _connectionStore.sshuser = _sshuserTextField.stringValue;
    _connectionStore.sshpassword = _sshpasswordTextField.stringValue;
    _connectionStore.sshkeyfile = _sshkeyfileTextField.stringValue;
    _connectionStore.usessh = [NSNumber numberWithBool:useSSH];
    if (_newConnection) {
        [_connectionsArrayController addObject:_connectionStore];
    }
    [_delegate connectionWindowControllerDidValidate:self];
    [self close];
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
