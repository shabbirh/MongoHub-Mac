//
//  MHFileImporter.h
//  MongoHub
//
//  Created by Jérôme Lebel on 23/11/11.
//  Copyright (c) 2011 ThePeppersStudio.COM. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MODCollection, MODQuery;

@interface MHFileImporter : NSObject
{
    NSString *_importPath;
    MODCollection *_collection;
    NSMutableDictionary *_errorForDocument;
    MODQuery *_latestQuery;
    NSUInteger                      _importedDocumentCount;
    NSUInteger                      _fileRead;
}

- (id)initWithCollection:(MODCollection *)collection importPath:(NSString *)importPath;
- (BOOL)importWithError:(NSError **)error;

@property (nonatomic, retain, readonly) NSString *importPath;
@property (nonatomic, retain, readonly) MODCollection *collection;
@property (nonatomic, assign, readonly) NSUInteger importedDocumentCount;
@property (nonatomic, assign, readonly) NSUInteger fileRead;

@end
