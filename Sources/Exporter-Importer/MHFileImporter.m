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
@property (nonatomic, assign, readwrite) NSUInteger fileRead;
@end

@implementation MHFileImporter

@synthesize collection = _collection, importPath = _importPath, importedDocumentCount = _importedDocumentCount, fileRead = _fileRead;

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
        size_t availableCount = 0;
        size_t parsedCount = 0;
        size_t totalCount = 0;
        size_t documentStarting = 0;
        MODRagelJsonParser *parser = [[MODRagelJsonParser alloc] init];
        NSMutableString *line = [[NSMutableString alloc] init];
        NSMutableArray *documents = [[NSMutableArray alloc] init];
        
        buffer = malloc(BUFFER_SIZE);
        availableCount = read(fileDescriptor, buffer, BUFFER_SIZE);
        self.fileRead += availableCount;
        while (availableCount > 0) {
            const char *eol;
            
            eol = strpbrk(buffer, "\n\r");
            if (eol || availableCount < BUFFER_SIZE) {
                NSString *tmp;
                
                if (eol) {
                    tmp = [[NSString alloc] initWithBytes:buffer length:eol - buffer encoding:NSUTF8StringEncoding];
                } else {
                    tmp = [[NSString alloc] initWithBytes:buffer length:availableCount encoding:NSUTF8StringEncoding];
                }
                [line appendString:tmp];
                [tmp release];
                if (line.length > 0) {
                    id document;
                    
                    document = [parser parseJson:line withError:error];
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
                if (eol) {
                    while (*eol == '\n' || *eol == '\r') {
                        eol++;
                    }
                }
                [line release];
                if (eol && eol - buffer < availableCount) {
                    line = [[NSMutableString alloc] initWithBytes:eol length:availableCount - (eol - buffer) encoding:NSUTF8StringEncoding];
                } else {
                    line = [[NSMutableString alloc] init];
                }
            } else {
                NSString *tmp;
                
                tmp = [[NSString alloc] initWithBytes:buffer length:availableCount encoding:NSUTF8StringEncoding];
                [line appendString:tmp];
                [tmp release];
            }
            availableCount = read(fileDescriptor, buffer, BUFFER_SIZE);
            self.fileRead += availableCount;
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
