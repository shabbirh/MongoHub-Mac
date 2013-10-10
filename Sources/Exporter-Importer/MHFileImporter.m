//
//  MHFileImporter.m
//  MongoHub
//
//  Created by Jérôme Lebel on 23/11/11.
//  Copyright (c) 2011 ThePeppersStudio.COM. All rights reserved.
//

#import "MHFileImporter.h"
#import "MOD_public.h"

#define BUFFER_SIZE (100*1024*1024)

@interface MHFileImporter()
@property (nonatomic, assign, readwrite) NSUInteger importedDocumentCount;
@property (nonatomic, assign, readwrite) NSUInteger fileSize;
@property (nonatomic, assign, readwrite) NSUInteger fileRead;
@end

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
        MODRagelJsonParser *parser = [[MODRagelJsonParser alloc] init];
        NSMutableString *line = [[NSMutableString alloc] init];
        NSMutableArray *documents = [[NSMutableArray alloc] init];
        
        buffer = malloc(BUFFER_SIZE);
        readCount = availableCount = read(fileDescriptor, buffer, BUFFER_SIZE - 1);
        buffer[availableCount] = 0;
        while (readCount > 0) {
            const char *eol;
            
            eol = strpbrk(buffer, "\n\r");
            if (eol) {
                NSString *tmp;
                
                tmp = [[NSString alloc] initWithBytes:buffer length:eol - buffer encoding:NSUTF8StringEncoding];
                [line appendString:tmp];
                [tmp release];
                if (line.length > 0) {
                    id document;
                    
                    document = [parser parseJson:line];
                    *error = parser.error;
                    if (document) {
                        [documents addObject:document];
                        if (documents.count >= 100) {
                            [_latestQuery release];
                            _latestQuery = [[_collection insertWithDocuments:documents callback:^(MODQuery *query) {
                                if (query.error) {
                                    [_errorForDocument setObject:query.error forKey:[NSNumber numberWithLongLong:documentStarting]];
                                }
                            }] retain];
                            documentStarting = totalCount + parsedCount;
                            self.importedDocumentCount += documents.count;
                            [documents release];
                            documents = [[NSMutableArray alloc] init];
                        }
                    } else {
                        break;
                    }
                }
                while (*eol == '\n' || *eol == '\r') {
                    eol++;
                }
                
            }
            parsedCount = parsedCount + [parser parseJsonWithCstring:buffer + parsedCount error:error];
            if ([parser parsingDone]) {
                NSArray *documents;
                
                documents = [[NSArray alloc] initWithObjects:(id)[parser mainObject], nil];
                [_latestQuery release];
                _latestQuery = [[_collection insertWithDocuments:documents callback:^(MODQuery *query) {
                    if (query.error) {
                        [_errorForDocument setObject:query.error forKey:[NSNumber numberWithLongLong:documentStarting]];
                    }
                }] retain];
                [documents release];
                documentStarting = totalCount + parsedCount;
            } else {
                memmove(buffer, buffer + parsedCount, availableCount - parsedCount + 1);
                totalCount += parsedCount;
                availableCount = readCount - parsedCount;
                parsedCount = 0;
                readCount = read(fileDescriptor, buffer + availableCount, BUFFER_SIZE - availableCount - 1);
                if (readCount > 0) {
                    availableCount += readCount;
                    buffer[availableCount] = 0;
                }
            }
            
        }
        close(fileDescriptor);
        free(buffer);
        result = YES;
        [line release];
        [parser release];
        parser = nil;
    }
    [_latestQuery waitUntilFinished];
    return result;
}

@end
