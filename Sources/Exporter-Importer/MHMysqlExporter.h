//
//  MHMysqlExporter.h
//  MongoHub
//
//  Created by Jérôme Lebel on 27/11/11.
//  Copyright (c) 2011 ThePeppersStudio.COM. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MODCollection;

@interface MHMysqlExporter : NSObject
{
    MODCollection *_collection;
}

- (id)initWithCollection:(MODCollection *)collection;
- (BOOL)exportWithError:(NSError **)error;

@end
