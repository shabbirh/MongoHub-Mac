//
//  MHCollectionItem.h
//  MongoHub
//
//  Created by Jérôme Lebel on 24/10/11.
//  Copyright (c) 2011 ThePeppersStudio.COM. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MHDatabaseItem;

@interface MHCollectionItem : NSObject
{
    NSString *_name;
    MHDatabaseItem *_databaseItem;
}

@property (nonatomic, readonly, retain) NSString *name;
@property (nonatomic, readonly, assign) MHDatabaseItem *databaseItem;

- (id)initWithDatabaseItem:(MHDatabaseItem *)databaseItem name:(NSString *)name;

@end
