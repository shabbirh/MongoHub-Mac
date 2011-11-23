//
//  MHFileImporter.m
//  MongoHub
//
//  Created by Jérôme Lebel on 23/11/11.
//  Copyright (c) 2011 ThePeppersStudio.COM. All rights reserved.
//

#import "MHFileImporter.h"

@implementation MHFileImporter

@synthesize collection = _collection, importPath = _importPath;

- (id)initWithCollection:(MODCollection *)collection importPath:(NSString *)importPath
{
    if (self = [self init]) {
        _collection = [collection retain];
        _importPath = [importPath retain];
    }
    return self;
}

- (void)dealloc
{
    [_collection release];
    [_importPath release];
    [super dealloc];
}

- (BOOL)importWithError:(NSError **)error
{
    NSAssert(error != nil, @"need to set error variable");
    *error = nil;
    return YES;
}

@end
