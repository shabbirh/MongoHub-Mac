//
//  MHTunnel.m
//  MongoHub
//
//  Created by Syd on 10-12-15.
//  Copyright 2010 ThePeppersStudio.COM. All rights reserved.
//

#import "MHTunnel.h"
#import <Security/Security.h>
#import "NSString+Extras.h"

#import <assert.h>
#import <errno.h>
#import <stdbool.h>
#import <stdlib.h>
#import <stdio.h>
#import <sys/sysctl.h>
#import <netinet/in.h>

typedef struct kinfo_proc kinfo_proc;

@interface MHTunnel ()
@property(nonatomic, assign, readwrite) MHTunnelError tunnelError;
@property(nonatomic, assign, readwrite, getter = isRunning) BOOL running;
@property(nonatomic, assign, readwrite, getter = isConnected) BOOL connected;
@end

static int GetBSDProcessList(kinfo_proc **procList, size_t *procCount)
// Returns a list of all BSD processes on the system.  This routine
// allocates the list and puts it in *procList and a count of the
// number of entries in *procCount.  You are responsible for freeing
// this list (use "free" from System framework).
// On success, the function returns 0.
// On error, the function returns a BSD errno value.
{
    int                 err;
    kinfo_proc *        result;
    bool                done;
    static const int    name[] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0 };
    // Declaring name as const requires us to cast it when passing it to
    // sysctl because the prototype doesn't include the const modifier.
    size_t              length;
    
    assert( procList != NULL);
    assert(*procList == NULL);
    assert(procCount != NULL);
    
    *procCount = 0;
    
    // We start by calling sysctl with result == NULL and length == 0.
    // That will succeed, and set length to the appropriate length.
    // We then allocate a buffer of that size and call sysctl again
    // with that buffer.  If that succeeds, we're done.  If that fails
    // with ENOMEM, we have to throw away our buffer and loop.  Note
    // that the loop causes use to call sysctl with NULL again; this
    // is necessary because the ENOMEM failure case sets length to
    // the amount of data returned, not the amount of data that
    // could have been returned.
    
    result = NULL;
    done = false;
    do {
        assert(result == NULL);
        
        // Call sysctl with a NULL buffer.
        
        length = 0;
        err = sysctl( (int *) name, (sizeof(name) / sizeof(*name)) - 1,
                     NULL, &length,
                     NULL, 0);
        if (err == -1) {
            err = errno;
        }
        
        // Allocate an appropriately sized buffer based on the results
        // from the previous call.
        
        if (err == 0) {
            result = malloc(length);
            if (result == NULL) {
                err = ENOMEM;
            }
        }
        
        // Call sysctl again with the new buffer.  If we get an ENOMEM
        // error, toss away our buffer and start again.
        
        if (err == 0) {
            err = sysctl((int *) name, (sizeof(name) / sizeof(*name)) - 1,
                         result, &length,
                         NULL, 0);
            if (err == -1) {
                err = errno;
            }
            if (err == 0) {
                done = true;
            } else if (err == ENOMEM) {
                assert(result != NULL);
                free(result);
                result = NULL;
                err = 0;
            }
        }
    } while (err == 0 && ! done);
    
    // Clean up and establish post conditions.
    
    if (err != 0 && result != NULL) {
        free(result);
        result = NULL;
    }
    *procList = result;
    if (err == 0) {
        *procCount = length / sizeof(kinfo_proc);
    }
    
    assert( (err == 0) == (*procList != NULL) );
    
    return err;
}


static int GetFirstChildPID(int pid)
/*" Returns the parent process id 
 for the given process id (pid). "*/
{
    int pidFound = -1;
    
    kinfo_proc* plist = nil;
    size_t len = 0;
    GetBSDProcessList(&plist,&len);
    
    if (plist != nil) {
        for (int i = 0;i<len;i++) {
            if (plist[i].kp_eproc.e_ppid == pid) {
                pidFound = plist[i].kp_proc.p_pid;
                break;
            }
        }
        
        free(plist);
    }
    
    return pidFound;
}

@implementation MHTunnel

@synthesize uid;
@synthesize name = _name;
@synthesize host = _host;
@synthesize port = _port;
@synthesize user = _user;
@synthesize password = _password;
@synthesize keyfile = _keyfile;
@synthesize aliveInterval = _aliveInterval;
@synthesize aliveCountMax = _aliveCountMax;
@synthesize tcpKeepAlive = _tcpKeepAlive;
@synthesize compression = _compression;
@synthesize additionalArgs = _additionalArgs;
@synthesize portForwardings = _portForwardings;
@synthesize delegate = _delegate;
@synthesize running = _running;
@synthesize tunnelError = _tunnelError;
@synthesize connected = _connected;

static BOOL testLocalPortAvailable(unsigned short port)
{
    CFSocketRef socket;
    struct sockaddr_in addr4;
	CFDataRef addressData;
    BOOL freePort;
    
    NSLog(@"test %d", (int)port);
    CFSocketContext socketCtxt = {0, [MHTunnel class], (const void*(*)(const void*))&CFRetain, (void(*)(const void*))&CFRelease, (CFStringRef(*)(const void *))&CFCopyDescription };
    socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, (CFSocketCallBack)NULL, &socketCtxt);
    
    memset(&addr4, 0, sizeof(addr4));
    addr4.sin_len = sizeof(addr4);
    addr4.sin_family = AF_INET;
    addr4.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    addr4.sin_port = htons(port);
    addressData = CFDataCreateWithBytesNoCopy(NULL, (const UInt8*)&addr4, sizeof(addr4), kCFAllocatorNull);
    freePort = CFSocketSetAddress(socket, addressData) == kCFSocketSuccess;
    CFRelease(addressData);

    if (socket) {
        CFSocketInvalidate(socket);
        CFRelease(socket);
    }
    NSLog(@"\tresult %@", freePort?@"available":@"used");
    
    return freePort;
}

+ (unsigned short)findFreeTCPPort
{
    unsigned short port = 40000;
    BOOL freePort = NO;
    
    while (port != 0 && !freePort) {
        port++;
        freePort = testLocalPortAvailable(port);
    }
    return port;
}

- (id)init
{
    if (self = [super init]) {
        uid = [[NSString UUIDString] retain];
        _portForwardings = [[NSMutableArray alloc] init];
    }
    
    return (self);
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [self init]) {
        uid = [coder decodeObjectForKey:@"uid"];
        _name = [coder decodeObjectForKey:@"name"];
        _host = [coder decodeObjectForKey:@"host"];
        _port = [coder decodeIntForKey:@"port"];
        _user = [coder decodeObjectForKey:@"user"];
        _password = [coder decodeObjectForKey:@"password"];
        _keyfile = [coder decodeObjectForKey:@"keyfile"];
        _aliveInterval = [coder decodeIntForKey:@"aliveInterval"];
        _aliveCountMax = [coder decodeIntForKey:@"aliveCountMax"];
        _tcpKeepAlive = [coder decodeBoolForKey:@"tcpKeepAlive"];
        _compression = [coder decodeBoolForKey:@"compression"];
        _additionalArgs = [coder decodeObjectForKey:@"additionalArgs"];
        _portForwardings = [coder decodeObjectForKey:@"portForwardings"];
        
        [self tunnelLoaded];
    }
    
    return (self);
}

- (void)dealloc
{
    [self stop];
    self.uid = nil;
    self.name = nil;
    self.host = nil;
    self.user = nil;
    self.password = nil;
    self.keyfile = nil;
    self.additionalArgs = nil;
    self.portForwardings = nil;
    [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:uid forKey:@"uid"];
    [coder encodeObject:_name forKey:@"name"];
    [coder encodeObject:_host forKey:@"host"];
    [coder encodeInt:_port forKey:@"port"];
    [coder encodeObject:_user forKey:@"user"];
    [coder encodeObject:_password forKey:@"password"];
    [coder encodeObject:_keyfile forKey:@"keyfile"];
    [coder encodeInt:_aliveInterval forKey:@"aliveInterval"];
    [coder encodeInt:_aliveCountMax forKey:@"aliveCountMax"];
    [coder encodeBool:_tcpKeepAlive forKey:@"tcpKeepAlive"];
    [coder encodeBool:_compression forKey:@"compression"];
    [coder encodeObject:_additionalArgs forKey:@"additionalArgs"];
    [coder encodeObject:_portForwardings forKey:@"portForwardings"];
    
    [self tunnelSaved];
}

- (void)_connected
{
    if (!_connected) {
        if ([_delegate respondsToSelector:@selector(tunnelDidConnect:)]) [_delegate tunnelDidConnect:self];
        self.connected = YES;
    }
}

- (void)start
{
    if (!self.isRunning) {
        NSPipe *pipe;
        
        self.running = YES;
        
        _task = [[NSTask alloc] init];
        pipe = [NSPipe pipe];
        
        _fileHandle = [[pipe fileHandleForReading] retain];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileHandleNotification:) name:nil object:_fileHandle];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskNotification:) name:NSTaskDidTerminateNotification object:_task];
        [_task setLaunchPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"SSHCommand" ofType:@"sh"]];
        [_task setArguments:[self prepareSSHCommandArgs]];
        [_task setStandardOutput:pipe];
        //The magic line that keeps your log where it belongs
        [_task setStandardInput:[NSPipe pipe]];
        
        [_task launch];
        /*NSData *output = [[pipe fileHandleForReading] readDataToEndOfFile];
        NSString *string = [[[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding] autorelease];
        
        NSLog(@"\n%@\n", string);*/
        self.tunnelError = MHNoTunnelError;
        [_fileHandle waitForDataInBackgroundAndNotify];
        if ([_delegate respondsToSelector:@selector(tunnelDidStart:)]) [_delegate tunnelDidStart:self];
    }
}

- (void)stop
{
    [_task terminate];
}

- (void)fileHandleNotification:(NSNotification *)notification
{
    if ([notification.name isEqualToString:NSFileHandleDataAvailableNotification]) {
        [self readStatus];
        [_fileHandle waitForDataInBackgroundAndNotify];
    }
}

- (void)taskNotification:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSTaskDidTerminateNotification object:_task];
    [_task release];
    _task = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:_fileHandle];
    [_fileHandle release];
    _fileHandle = nil;
    self.running = NO;
    self.connected = NO;
    _tunnelError = MHNoTunnelError;
    if ([_delegate respondsToSelector:@selector(tunnelDidStop:)]) [_delegate tunnelDidStop:self];
}

- (void)readStatus
{
    if (_running && self.tunnelError == MHNoTunnelError) {
        NSString *pipeStr = [[[NSString alloc] initWithData:[_fileHandle availableData] encoding:NSASCIIStringEncoding] autorelease];
        NSLog(@"%@", pipeStr);
        NSRange r = [pipeStr rangeOfString:@"CONNECTED"];
        if (r.location != NSNotFound) {
            [self _connected];
            return;
        }
        
        r = [pipeStr rangeOfString:@"CONNECTION_ERROR"];
        if (r.location != NSNotFound) {
            self.tunnelError = MHConnectionErrorTunnelError;
            
            if ([_delegate respondsToSelector:@selector(tunnelDidFailToConnect:withError:)]) [_delegate tunnelDidFailToConnect:self withError:[NSError errorWithDomain:MHTunnelDomain code:_tunnelError userInfo:nil]];
            return;
        }
        
        r = [pipeStr rangeOfString:@"CONNECTION_REFUSED"];
        if (r.location != NSNotFound) {
            self.tunnelError = MHConnectionRefusedTunnelError;
            
            if ([_delegate respondsToSelector:@selector(tunnelDidFailToConnect:withError:)]) [_delegate tunnelDidFailToConnect:self withError:[NSError errorWithDomain:MHTunnelDomain code:_tunnelError userInfo:nil]];
            return;
        }
        
        r = [pipeStr rangeOfString:@"WRONG_PASSWORD"];
        if (r.location != NSNotFound) {
            self.tunnelError = MHConnectionWrongPasswordTunnelError;
            
            if ([_delegate respondsToSelector:@selector(tunnelDidFailToConnect:withError:)]) [_delegate tunnelDidFailToConnect:self withError:[NSError errorWithDomain:MHTunnelDomain code:_tunnelError userInfo:nil]];
            return;
        }
    }
}

- (NSArray *)prepareSSHCommandArgs
{
    NSMutableString *pfs = [[NSMutableString alloc] init];
    NSArray *result;
    
    for (NSString *pf in _portForwardings) {
        NSArray* pfa = [pf componentsSeparatedByString:@":"];
        if (pfa.count == 4) {
            [pfs appendFormat:@"%@ -%@ %@:%@:%@", pfs, [pfa objectAtIndex:0], [pfa objectAtIndex:1], [pfa objectAtIndex:2], [pfa objectAtIndex:3]];
        } else if ([[pfa objectAtIndex:1] length] == 0) {
                [pfs appendFormat:@"%@ -%@ %@:%@:%@", pfs, [pfa objectAtIndex:0], [pfa objectAtIndex:2], [pfa objectAtIndex:3], [pfa objectAtIndex:4]];
        } else {
            [pfs appendFormat:@"%@ -%@ %@:%@:%@:%@", pfs, [pfa objectAtIndex:0], [pfa objectAtIndex:1], [pfa objectAtIndex:2], [pfa objectAtIndex:3], [pfa objectAtIndex:4]];
        }
    }
    
    NSString* cmd;
    if ([_password isNotEqualTo:@""]|| [_keyfile isEqualToString:@""]) {
        cmd = [[NSString alloc] initWithFormat:@"ssh -N -o ConnectTimeout=28 %@%@%@%@%@%@-p %d %@@%@",
               [_additionalArgs length] > 0 ? [NSString stringWithFormat:@"%@ ", _additionalArgs] :@"",
               [pfs length] > 0 ? [NSString stringWithFormat:@"%@ ",pfs] : @"",
               _aliveInterval > 0 ? [NSString stringWithFormat:@"-o ServerAliveInterval=%d ",_aliveInterval] : @"",
               _aliveCountMax > 0 ? [NSString stringWithFormat:@"-o ServerAliveCountMax=%d ",_aliveCountMax] : @"",
               _tcpKeepAlive == YES ? @"-o TCPKeepAlive=yes " : @"",
               _compression == YES ? @"-C " : @"",
               _port, _user, _host];
    } else {
        cmd = [[NSString alloc] initWithFormat:@"ssh -N -o ConnectTimeout=28 %@%@%@%@%@%@-p %d -i %@ %@@%@",
               [_additionalArgs length] > 0 ? [NSString stringWithFormat:@"%@ ", _additionalArgs] : @"",
               [pfs length] > 0 ? [NSString stringWithFormat:@"%@ ",pfs] : @"",
               _aliveInterval > 0 ? [NSString stringWithFormat:@"-o ServerAliveInterval=%d ",_aliveInterval] : @"",
               _aliveCountMax > 0 ? [NSString stringWithFormat:@"-o ServerAliveCountMax=%d ",_aliveCountMax] : @"",
               _tcpKeepAlive == YES ? @"-o TCPKeepAlive=yes " : @"",
               _compression == YES ? @"-C " : @"",
               _port, _keyfile, _user, _host];
    }

    
    NSLog(@"cmd: %@", cmd);
    result = [NSArray arrayWithObjects:cmd, _password, nil];
    [pfs release];
    [cmd release];
    return result;
}

- (void)addForwardingPortWithBindAddress:(NSString *)bindAddress bindPort:(unsigned short)bindPort hostAddress:(NSString *)hostAddress hostPort:(unsigned short)hostPort reverseForwarding:(BOOL)reverseForwarding
{
    NSString *forwardPort;
    
    forwardPort = [[NSString alloc] initWithFormat:@"%@%@%@:%d:%@:%d", reverseForwarding?@"R":@"L", bindAddress?bindAddress:@"", bindAddress?@":":@"", (int)bindPort, hostAddress, (int)hostPort];
    [_portForwardings addObject:forwardPort];
    [forwardPort release];
}

- (void)tunnelLoaded
{
    if (uid == nil || [uid length] == 0) {
        CFUUIDRef uidref = CFUUIDCreate(nil);
        uid = (NSString *)CFUUIDCreateString(nil, uidref);
        CFRelease(uidref);
    }
    
    if ([self keychainItemExists]) {
        _password = [self keychainGetPassword];
    } else {
        _password = @"";
    }
}

- (void)tunnelSaved
{
    if ([self keychainItemExists]) {
        [self keychainModifyItem];
    } else {
        [self keychainAddItem];
    }
}

- (void)tunnelRemoved
{
    if([self keychainItemExists]) {
        [self keychainDeleteItem];
    }
}

- (BOOL)keychainItemExists
{
    SecKeychainSearchRef search;
    SecKeychainAttributeList list;
    SecKeychainAttribute attributes[3];
    
    NSString *keychainItemName = [NSString stringWithFormat:@"SSHTunnel <%@>", uid];
    NSString *keychainItemKind = @"application password";
    
    attributes[0].tag = kSecAccountItemAttr;
    attributes[0].data = (void *)[uid UTF8String];
    attributes[0].length = [uid length];
    
    attributes[1].tag = kSecDescriptionItemAttr;
    attributes[1].data = (void *)[keychainItemKind UTF8String];
    attributes[1].length = [keychainItemKind length];
    
    attributes[2].tag = kSecLabelItemAttr;
    attributes[2].data = (void *)[keychainItemName UTF8String];
    attributes[2].length = [keychainItemName length];
    
    list.count = 3;
    list.attr = attributes;
    
    OSErr result = SecKeychainSearchCreateFromAttributes(NULL, kSecGenericPasswordItemClass, &list, &search);
    
    if (result != noErr) {
        NSLog (@"Error status %d from SecKeychainSearchCreateFromAttributes\n", result);
        return FALSE;
    }
    
    uint itemsFound = 0;
    SecKeychainItemRef item;
    
    while (SecKeychainSearchCopyNext(search, &item) == noErr) {
        CFRelease (item);
        itemsFound++;
    }
    
    CFRelease (search);
    return itemsFound > 0;
}

- (BOOL)keychainAddItem
{
    SecKeychainItemRef item;
    SecKeychainAttributeList list;
    SecKeychainAttribute attributes[3];
    
    NSString *keychainItemName = [NSString stringWithFormat:@"SSHTunnel <%@>", uid];
    NSString *keychainItemKind = @"application password";
    
    attributes[0].tag = kSecAccountItemAttr;
    attributes[0].data = (void *)[uid UTF8String];
    attributes[0].length = [uid length];
    
    attributes[1].tag = kSecDescriptionItemAttr;
    attributes[1].data = (void *)[keychainItemKind UTF8String];
    attributes[1].length = [keychainItemKind length];
    
    attributes[2].tag = kSecLabelItemAttr;
    attributes[2].data = (void *)[keychainItemName UTF8String];
    attributes[2].length = [keychainItemName length];    
    
    list.count = 3;
    list.attr = attributes;
    
    OSStatus status = SecKeychainItemCreateFromContent(kSecGenericPasswordItemClass, &list, [_password length], [_password UTF8String], NULL,NULL,&item);
    if (status != 0) {
        NSLog(@"Error creating new item: %d for %@\n", (int)status, keychainItemName);
    }
    
    return !status;
}

- (BOOL)keychainModifyItem
{
    SecKeychainItemRef item;
    SecKeychainSearchRef search;
    OSStatus status;
    OSErr result;
    SecKeychainAttributeList list;
    SecKeychainAttribute attributes[3];
    
    NSString *keychainItemName = [NSString stringWithFormat:@"SSHTunnel <%@>", uid];
    NSString *keychainItemKind = @"application password";
    
    attributes[0].tag = kSecAccountItemAttr;
    attributes[0].data = (void *)[uid UTF8String];
    attributes[0].length = [uid length];
    
    attributes[1].tag = kSecDescriptionItemAttr;
    attributes[1].data = (void *)[keychainItemKind UTF8String];
    attributes[1].length = [keychainItemKind length];
    
    attributes[2].tag = kSecLabelItemAttr;
    attributes[2].data = (void *)[keychainItemName UTF8String];
    attributes[2].length = [keychainItemName length];
    
    list.count = 3;
    list.attr = attributes;
    
    result = SecKeychainSearchCreateFromAttributes(NULL, kSecGenericPasswordItemClass, &list, &search);
    NSLog(@"%hd", result);
    SecKeychainSearchCopyNext (search, &item);
    status = SecKeychainItemModifyContent(item, &list, [_password length], [_password UTF8String]);
    
    if (status != 0) {
        NSLog(@"Error modifying item: %d", (int)status);
    }
    
    CFRelease (item);
    CFRelease(search);
    
    return !status;
}

- (BOOL)keychainDeleteItem
{
    SecKeychainItemRef item;
    SecKeychainSearchRef search;
    OSStatus status = 0;
    OSErr result;
    SecKeychainAttributeList list;
    SecKeychainAttribute attributes[3];
    uint itemsFound = 0;
    
    NSString *keychainItemName = [NSString stringWithFormat:@"SSHTunnel <%@>", uid];
    NSString *keychainItemKind = @"application password";
    
    attributes[0].tag = kSecAccountItemAttr;
    attributes[0].data = (void *)[uid UTF8String];
    attributes[0].length = [uid length];
    
    attributes[1].tag = kSecDescriptionItemAttr;
    attributes[1].data = (void *)[keychainItemKind UTF8String];
    attributes[1].length = [keychainItemKind length];
    
    attributes[2].tag = kSecLabelItemAttr;
    attributes[2].data = (void *)[keychainItemName UTF8String];
    attributes[2].length = [keychainItemName length];
    
    list.count = 3;
    list.attr = attributes;
    
    result = SecKeychainSearchCreateFromAttributes(NULL, kSecGenericPasswordItemClass, &list, &search);
    NSLog(@"%hd", result);
    while (SecKeychainSearchCopyNext (search, &item) == noErr) {
        itemsFound++;
    }
    if (itemsFound) {
        status = SecKeychainItemDelete(item);
    }
    
    if (status != 0) {
        NSLog(@"Error deleting item: %d\n", (int)status);
    }
    CFRelease (item);
    CFRelease (search);
    
    return !status;
}

- (NSString *)keychainGetPassword
{
    SecKeychainItemRef item;
    SecKeychainSearchRef search;
    OSErr result;
    SecKeychainAttributeList list;
    SecKeychainAttribute attributes[3];
    
    NSString *keychainItemName = [NSString stringWithFormat:@"SSHTunnel <%@>", uid];
    NSString *keychainItemKind = @"application password";
    
    attributes[0].tag = kSecAccountItemAttr;
    attributes[0].data = (void *)[uid UTF8String];
    attributes[0].length = [uid length];
    
    attributes[1].tag = kSecDescriptionItemAttr;
    attributes[1].data = (void *)[keychainItemKind UTF8String];
    attributes[1].length = [keychainItemKind length];
    
    attributes[2].tag = kSecLabelItemAttr;
    attributes[2].data = (void *)[keychainItemName UTF8String];
    attributes[2].length = [keychainItemName length];
    
    
    list.count = 3;
    list.attr = attributes;
    
    result = SecKeychainSearchCreateFromAttributes(NULL, kSecGenericPasswordItemClass, &list, &search);
    
    if (result != noErr) {
        NSLog(@"status %d from SecKeychainSearchCreateFromAttributes\n", result);
    }
    
    NSString *pass = @"";
    if (SecKeychainSearchCopyNext (search, &item) == noErr) {
        pass = [self keychainGetPasswordFromItemRef:item];
        if(!pass) {
            pass = @"";
        }
        CFRelease (item);
        CFRelease (search);
    }
    
    return pass;
}

- (NSString *)keychainGetPasswordFromItemRef:(SecKeychainItemRef)item
{
    NSString *retPass = nil;
    
    UInt32 length;
    char *pass;
    SecKeychainAttribute attributes[8];
    SecKeychainAttributeList list;
    OSStatus status;
    
    attributes[0].tag = kSecAccountItemAttr;
    attributes[1].tag = kSecDescriptionItemAttr;
    attributes[2].tag = kSecLabelItemAttr;
    attributes[3].tag = kSecModDateItemAttr;
    
    list.count = 4;
    list.attr = attributes;
    
    status = SecKeychainItemCopyContent (item, NULL, &list, &length, (void **)&pass);
    
    if (status == noErr) {
        if (pass != NULL) {
            
            // copy the password into a buffer so we can attach a
            // trailing zero byte in order to be able to print
            // it out with printf
            char passwordBuffer[1024];
            
            if (length > 1023) {
                length = 1023; // save room for trailing \0
            }
            strncpy (passwordBuffer, pass, length);
            
            passwordBuffer[length] = '\0';
            
            retPass = [NSString stringWithUTF8String:passwordBuffer];
        }
        
        SecKeychainItemFreeContent (&list, pass);
        
        return retPass;
    } else {
        printf("Error getting password = %d\n", (int)status);
        return @"";
    }
}

@end
