//
//  MHCollectionItem.m
//  MongoHub
//
//  Created by Jérôme Lebel on 24/10/11.
//  Copyright (c) 2011 ThePeppersStudio.COM. All rights reserved.
//

#import "MHCollectionItem.h"

@implementation MHCollectionItem

@synthesize name = _name, databaseItem = _databaseItem;

- (id)initWithDatabaseItem:(MHDatabaseItem *)databaseItem name:(NSString *)name
{
    if (self = [self init]) {
        _name = [name retain];
        _databaseItem = databaseItem;
    }
    return self;
}

- (void)dealloc
{
    [_name release];
    [super dealloc];
}

@end
