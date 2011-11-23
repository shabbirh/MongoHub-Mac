//
//  MODHelper.h
//  MongoHub
//
//  Created by Jérôme Lebel on 20/09/11.
//  Copyright (c) 2011 ThePeppersStudio.COM. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MODSortedMutableDictionary;

@interface MODHelper : NSObject

+ (NSArray *)convertForOutlineWithObjects:(NSArray *)mongoObjects;
+ (NSArray *)convertForOutlineWithObject:(MODSortedMutableDictionary *)mongoObject;

@end
