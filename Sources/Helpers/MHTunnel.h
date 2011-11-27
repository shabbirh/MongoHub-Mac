//
//  Tunnel.h
//  MongoHub
//
//  Created by Syd on 10-12-15.
//  Copyright 2010 ThePeppersStudio.COM. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MHTunnel;

@protocol MHTunnelDelegate<NSObject>
- (void)tunnelStatusChanged:(MHTunnel *)tunnel status:(NSString *)status;
@end

@interface MHTunnel : NSObject <NSCoding>
{
	id<MHTunnelDelegate> delegate;
	
	NSTask *_task;
    NSFileHandle *_fileHandle;
	NSMutableString* pipeData;
	NSString* retStatus;
	BOOL isRunning;
	
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

- (BOOL)running; 
- (BOOL)checkProcess;
- (void)start;
- (void)stop;
- (void)readStatus;
- (NSArray *)prepareSSHCommandArgs;

- (void)tunnelLoaded;
- (void)tunnelSaved;
- (void)tunnelRemoved;

- (BOOL)keychainItemExists;
- (BOOL)keychainAddItem;
- (BOOL)keychainModifyItem;
- (BOOL)keychainDeleteItem;
- (NSString *)keychainGetPassword;
- (NSString *)keychainGetPasswordFromItemRef:(SecKeychainItemRef)item;

@end
