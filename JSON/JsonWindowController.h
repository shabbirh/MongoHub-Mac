//
//  JsonWindowController.h
//  MongoHub
//
//  Created by Syd on 10-12-27.
//  Copyright 2010 ThePeppersStudio.COM. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UKSyntaxColoredTextViewController.h"
#import "MongoQuery.h"

@class DatabasesArrayController;
@class Connection;
@class MongoDB;
@class MongoCollection;

#ifndef UKSCTD_DEFAULT_TEXTENCODING
#define UKSCTD_DEFAULT_TEXTENCODING		NSUTF8StringEncoding
#endif

@interface JsonWindowController : NSWindowController <UKSyntaxColoredTextViewDelegate, MongoQueryCallbackTarget>
{
    NSManagedObjectContext *managedObjectContext;
    DatabasesArrayController *databasesArrayController;
    Connection *conn;
    MongoDB *mongoDB;
    MongoCollection *_mongoCollection;
    NSString *dbname;
    NSString *collectionname;
    NSDictionary *jsonDict;
    IBOutlet NSTextView *myTextView;
    IBOutlet NSProgressIndicator *progress;
    IBOutlet NSTextField *status;
    UKSyntaxColoredTextViewController *syntaxColoringController;
}

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) DatabasesArrayController *databasesArrayController;
@property (nonatomic, retain) MongoDB *mongoDB;
@property (nonatomic, retain) NSString *dbname;
@property (nonatomic, retain) NSString *collectionname;
@property (nonatomic, retain) Connection *conn;
@property (nonatomic, retain) NSDictionary *jsonDict;
@property (nonatomic, retain) NSTextView *myTextView;
@property (nonatomic, readwrite, retain) MongoCollection *mongoCollection;

-(IBAction) save:(id)sender;
-(IBAction)	recolorCompleteFile: (id)sender;

@end
