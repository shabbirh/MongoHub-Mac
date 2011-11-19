//
//  MHFileExporter.m
//  MongoHub
//
//  Created by Jérôme Lebel on 19/11/11.
//  Copyright (c) 2011 ThePeppersStudio.COM. All rights reserved.
//

#import "MHFileExporter.h"
#import "MOD_public.h"

@implementation MHFileExporter

@synthesize collection = _collection, exportPath = _exportPath;

- (id)initWithCollection:(MODCollection *)collection exportPath:(NSString *)exportPath
{
    if (self = [self init]) {
        _collection = [collection retain];
        _exportPath = [exportPath retain];
    }
    return self;
}

- (void)dealloc
{
    [_collection release];
    [_exportPath release];
    [super dealloc];
}

- (BOOL)exportWithError:(NSError **)error
{
    BOOL result = YES;
    int fileDescriptor;
    
    *error = nil;
    fileDescriptor = open([_exportPath fileSystemRepresentation], O_WRONLY | O_CREAT | O_TRUNC, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
    if (fileDescriptor < 0) {
        printf("error %d\n", errno);
        perror("fichier");
        *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
        result = NO;
    } else {
        MODCursor *cursor;
        
        cursor = [_collection cursorWithCriteria:nil fields:nil skip:0 limit:0 sort:nil];
        [cursor forEachDocumentWithCallbackDocumentCallback:^(uint64_t index, NSDictionary *document) {
            NSString *jsonDocument;
            const char *cString;
        
            jsonDocument = [MODServer convertObjectToJson:document pretty:YES];
            cString = [jsonDocument UTF8String];
            write(fileDescriptor, cString, strlen(cString));
            return YES;
        } endCallback:^(uint64_t documentCounts, BOOL cursorStopped, MODQuery *mongoQuery) {
            close(fileDescriptor);
        }];
        
    }
    
    return result;
}

@end
