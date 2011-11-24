//
//  MHFileImporter.m
//  MongoHub
//
//  Created by Jérôme Lebel on 23/11/11.
//  Copyright (c) 2011 ThePeppersStudio.COM. All rights reserved.
//

#import "MHFileImporter.h"
#import "MOD_public.h"

#define BUFFER_SIZE (1024*1024*1024)

@implementation MHFileImporter

@synthesize collection = _collection, importPath = _importPath;

- (id)initWithCollection:(MODCollection *)collection importPath:(NSString *)importPath
{
    if (self = [self init]) {
        _collection = [collection retain];
        _importPath = [importPath retain];
        _errorForDocument = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_collection release];
    [_importPath release];
    [_errorForDocument release];
    [_latestQuery release];
    [super dealloc];
}

- (BOOL)importWithError:(NSError **)error
{
    int fileDescriptor;
    BOOL result;
    
    NSAssert(error != nil, @"need to set error variable");
    *error = nil;
    
    fileDescriptor = open([_importPath fileSystemRepresentation], O_RDONLY, 0);
    if (fileDescriptor < 0) {
        printf("error %d\n", errno);
        perror("fichier");
        *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
        result = NO;
    } else {
        char *buffer;
        size_t readCount = 0;
        size_t availableCount = 0;
        size_t parsedCount = 0;
        size_t totalCount = 0;
        size_t documentStarting = 0;
        MODJsonToObjectParser *parser = nil;
        
        buffer = malloc(BUFFER_SIZE);
        readCount = availableCount = read(fileDescriptor, buffer, BUFFER_SIZE - 1);
        while (readCount > 0) {
            availableCount += readCount;
            buffer[availableCount] = 0;
            if (!parser) {
                parser = [[MODJsonToObjectParser alloc] init];
                parser.multiPartParsing = YES;
            }
            parsedCount = parsedCount + [parser parseJsonWithCstring:buffer + parsedCount error:error];
            if ([parser parsingDone]) {
                NSArray *documents;
                
                documents = [[NSArray alloc] initWithObjects:(id)[parser mainObject], nil];
                NSLog(@"%@", [parser mainObject]);
                [_latestQuery release];
                _latestQuery = [[_collection insertWithDocuments:documents callback:^(MODQuery *query) {
                    if (query.error) {
                        [_errorForDocument setObject:query.error forKey:[NSNumber numberWithLongLong:documentStarting]];
                    }
                }] retain];
                [documents release];
                [parser release];
                parser = nil;
                documentStarting = totalCount + parsedCount;
            } else {
                memmove(buffer, buffer + parsedCount, availableCount - parsedCount + 1);
                totalCount += parsedCount;
                availableCount = readCount - parsedCount;
                parsedCount = 0;
                readCount = read(fileDescriptor, buffer + availableCount, BUFFER_SIZE - availableCount - 1);
            }
            
        }
        close(fileDescriptor);
        result = YES;
    }
    return result;
}

@end
