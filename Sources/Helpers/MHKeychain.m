//
//  MHKeychain.m
//  MongoHub
//
//  Created by Jérôme Lebel on 25/10/2013.
//  Copyright (c) 2013 ThePeppersStudio.COM. All rights reserved.
//

#import "MHKeychain.h"
#import <Security/Security.h>

@implementation MHKeychain

+ (NSMutableDictionary *)queryForService:(NSString *)service account:(NSString *)account label:(NSString *)label description:(NSString *)description password:(NSString *)password
{
    NSMutableDictionary *query = [[NSMutableDictionary alloc] init];
    
    [query setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
    if (service)
        [query setObject:service forKey:(id)kSecAttrService];
    if (account)
        [query setObject:account forKey:(id)kSecAttrAccount];
    if (label)
        [query setObject:label forKey:(id)kSecLabelItemAttr];
    if (description)
        [query setObject:description forKey:(id)kSecDescriptionItemAttr];
    if (password)
        [query setObject:password forKey:(id)kSecValueRef];
    
    return [query autorelease];
}

+ (BOOL)addItemWithService:(NSString *)service account:(NSString *)account name:(NSString *)name kind:(NSString *)kind password:(NSString *)password
{
    NSDictionary *query;
    OSErr status;
    
    query = [self queryForService:service account:account label:@"mongo label" description:@"mongo description" password:password];
    
    status = SecItemAdd((CFDictionaryRef)query, NULL);
    if (status != 0) {
        NSLog(@"Error getting item: %d for %@ %@ %@ %@\n", (int)status, service, account, name, kind);
    }
    
    return !status;
}

+ (NSString *)passwordWithService:(NSString *)service account:(NSString *)account name:(NSString *)name kind:(NSString *)kind
{
    NSMutableDictionary *query;
    CFTypeRef result;
    OSErr status;
    
    query = [self queryForService:service account:account label:@"mongo label" description:@"mongo description" password:nil];
    [query setObject:(id)kCFBooleanTrue forKey:kSecReturnData];
	[query setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
    
	status = SecItemCopyMatching((CFDictionaryRef)query, &result);
    if (status != noErr) {
        return nil;
    } else {
        return [[[NSString alloc] initWithUTF8String:[(NSData *)result bytes]] autorelease];
    }
}

+ (BOOL)updateItemWithService:(NSString *)service account:(NSString *)account name:(NSString *)name kind:(NSString *)kind password:(NSString *)password
{
    NSDictionary *query;
    OSErr status;
    
    query = [self queryForService:service account:account label:@"mongo label" description:@"mongo description" password:password];
    
    status = SecItemUpdate((CFDictionaryRef)query, NULL);
    if (status != 0) {
        NSLog(@"Error updating item: %d for %@ %@ %@ %@\n", (int)status, service, account, name, kind);
    }
    
    return !status;
}

+ (NSString *)deleteItemWithService:(NSString *)service account:(NSString *)account name:(NSString *)name kind:(NSString *)kind
{
    NSDictionary *query;
    OSErr status;
    
    query = [self queryForService:service account:account label:@"mongo label" description:@"mongo description" password:nil];
    
    status = SecItemDelete((CFDictionaryRef)query);
    if (status != 0) {
        NSLog(@"Error deleting item: %d for %@ %@ %@ %@\n", (int)status, service, account, name, kind);
    }
    
    return !status;
}

@end
