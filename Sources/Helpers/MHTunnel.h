//
//  Tunnel.h
//  MongoHub
//
//  Created by Syd on 10-12-15.
//  Copyright 2010 ThePeppersStudio.COM. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MHTunnel;

#define MHTunnelDomain @"MHTunnelDomain"

typedef enum {
    MHNoTunnelError = 0,
    MHConnectionRefusedTunnelError,
    MHConnectionErrorTunnelError,
    MHConnectionWrongPasswordTunnelError
} MHTunnelError;

@protocol MHTunnelDelegate<NSObject>
@optional
- (void)tunnelDidStart:(MHTunnel *)tunnel;
- (void)tunnelDidConnect:(MHTunnel *)tunnel;
- (void)tunnelDidStop:(MHTunnel *)tunnel;
- (void)tunnelDidFailToConnect:(MHTunnel *)tunnel withError:(NSError *)error;
@end

@interface MHTunnel : NSObject <NSCoding>
{
	id<MHTunnelDelegate>            _delegate;
	
	NSTask                          *_task;
    NSFileHandle                    *_fileHandle;
	NSMutableString                 *_pipeData;
    MHTunnelError                   _tunnelError;
	BOOL                            _running;
	
	NSString* uid;
	NSString* name;
	NSString* host;
	int port;
	NSString* user;
	NSString* password;
    NSString* keyfile;
	int aliveInterval;
	int aliveCountMax;
	BOOL tcpKeepAlive;
	BOOL compression;
	NSString* additionalArgs;
	NSMutableArray* portForwardings;
}

@property(retain) NSString* uid;
@property(retain) NSString* name;
@property(retain) NSString* host;
@property(assign) int port;
@property(retain) NSString* user;
@property(retain) NSString* password;
@property(retain) NSString* keyfile;
@property(assign) int aliveInterval;
@property(assign) int aliveCountMax;
@property(assign) BOOL tcpKeepAlive;
@property(assign) BOOL compression;
@property(retain) NSString* additionalArgs;
@property(retain) NSMutableArray* portForwardings;
@property(nonatomic, assign, readwrite) id<MHTunnelDelegate> delegate;
@property(nonatomic, assign, readonly, getter = isRunning) BOOL running;
@property(nonatomic, assign, readonly) MHTunnelError tunnelError;

+ (unsigned short)findFreeTCPPort;

- (BOOL)checkProcess;
- (void)start;
- (void)stop;
- (void)readStatus;

- (void)tunnelLoaded;
- (void)tunnelSaved;
- (void)tunnelRemoved;

- (void)addForwardingPortWithBindAddress:(NSString *)bindAddress bindPort:(unsigned short)bindPort hostAddress:(NSString *)hostAddress hostPort:(unsigned short)hostPort reverseForwarding:(BOOL)reverseForwarding;

- (BOOL)keychainItemExists;
- (BOOL)keychainAddItem;
- (BOOL)keychainModifyItem;
- (BOOL)keychainDeleteItem;
- (NSString *)keychainGetPassword;
- (NSString *)keychainGetPasswordFromItemRef:(SecKeychainItemRef)item;

@end
