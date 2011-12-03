//
//  MHStatusViewController.h
//  MongoHub
//
//  Created by Jérôme Lebel on 02/12/11.
//  Copyright (c) 2011 ThePeppersStudio.COM. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ResultsOutlineViewController, MODServer, MHConnectionStore, MHDatabaseItem, MHCollectionItem, MODQuery;

@interface MHStatusViewController : NSViewController
{
    IBOutlet ResultsOutlineViewController *_resultsOutlineViewController;
    MODServer *_mongoServer;
    MHConnectionStore *_connectionStore;
}

@property (nonatomic, retain, readwrite) MODServer *mongoServer;
@property (nonatomic, retain, readwrite) MHConnectionStore *connectionStore;

+ (MHStatusViewController *)loadNewViewController;

- (MODQuery *)showServerStatus;
- (MODQuery *)showDatabaseStatusWithDatabaseItem:(MHDatabaseItem *)databaseItem;
- (MODQuery *)showCollectionStatusWithCollectionItem:(MHCollectionItem *)collectionItem;

@end
