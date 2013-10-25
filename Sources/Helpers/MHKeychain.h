//
//  MHKeychain.h
//  MongoHub
//
//  Created by Jérôme Lebel on 25/10/2013.
//  Copyright (c) 2013 ThePeppersStudio.COM. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MHKeychain : NSObject
    
+ (BOOL)addItemWithService:(NSString *)service account:(NSString *)account name:(NSString *)name kind:(NSString *)kind password:(NSString *)password;
+ (NSString *)passwordWithService:(NSString *)service account:(NSString *)account name:(NSString *)name kind:(NSString *)kind;
+ (BOOL)updateItemWithService:(NSString *)service account:(NSString *)account name:(NSString *)name kind:(NSString *)kind password:(NSString *)password;
+ (NSString *)deleteItemWithService:(NSString *)service account:(NSString *)account name:(NSString *)name kind:(NSString *)kind;

@end
