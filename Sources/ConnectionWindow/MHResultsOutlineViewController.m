//
//  MHResultsOutlineViewController.m
//  MongoHub
//
//  Created by Syd on 10-4-26.
//  Copyright 2010 MusicPeace.ORG. All rights reserved.
//

#import "MHResultsOutlineViewController.h"

@implementation MHResultsOutlineViewController

@synthesize outlineView = _outlineView;

- (id)init
{
    if (self = [super init]) {
        _results = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    [_results release];
    [super dealloc];
}

- (void)awakeFromNib
{
    [_outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    [_outlineView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
}

- (NSArray *)selectedDocuments
{
    NSMutableArray *documents;
    
    documents = [NSMutableArray array];
    [[_outlineView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        id currentItem = [_outlineView itemAtRow:idx];
        
        [documents addObject:[self rootForItem:currentItem]];
    }];
    return documents;
}

#pragma mark -
#pragma mark NSOutlineView dataSource methods

// Returns the child item at the specified index of a given item.
- (id)outlineView:(NSOutlineView *)outlineView
            child:(int)index
               ofItem:(id)item
{
    // If the item is the root item, return the corresponding mailbox object
    if ([outlineView levelForItem:item] == -1) {
        return [_results objectAtIndex:index];
    }
    
    // If the item is a root-level item (ie mailbox)
    return [[item objectForKey:@"child" ] objectAtIndex:index];
}

// Returns a Boolean value that indicates wheter a given item is expandable.
- (BOOL)outlineView:(NSOutlineView *)outlineView
   isItemExpandable:(id)item
{
    // If the item is a root-level item (ie mailbox) and it has emails in it, return true
    if (([[item objectForKey:@"child"] count] != 0)) {
        return true;
    } else {
        return false;
    }
}

// Returns the number of child items encompassed by a given item.
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    // If the item is the root item, return the number of mailboxes
    if ([outlineView levelForItem:item] == -1) {
        return [_results count];
    }
    // If the item is a root-level item (ie mailbox)
    return [[item objectForKey:@"child"] count];
}

// Return the data object associated with the specified item.
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if ([[tableColumn identifier] isEqualToString:@"name"]) {
        return [item objectForKey:@"name"];
    } else if([[tableColumn identifier] isEqualToString:@"value"]) {
        return [item objectForKey:@"value"];
    } else if([[tableColumn identifier] isEqualToString:@"type"]) {
        return [item objectForKey:@"type"];
    }
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteboard
{
    NSMutableString *string;
    
    string = [[NSMutableString alloc] init];
    for (NSDictionary *item in items) {
        [string appendString:[[self rootForItem:item] objectForKey:@"beautified"]];
        [string appendString:@"\n"];
    }
    [pasteboard setString:string forType:NSStringPboardType];
    [pasteboard setString:[NSString stringWithFormat:@"%p", self] forType:@"OutlineViewControllerAddress"];
    return YES;
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id < NSDraggingInfo >)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
    // Add code here to validate the drop
    return NSDragOperationNone;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id < NSDraggingInfo >)info item:(id)item childIndex:(NSInteger)index{
    return NO;
}

#pragma mark -
#pragma mark NSOutlineView delegate methods
- (void)outlineViewSelectionIsChanging:(NSNotification *)notification
{
    if (!_checkingSelection) {
        _checkingSelection = YES;
        [[_outlineView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            id currentItem = [_outlineView itemAtRow:idx];
            
            if ([currentItem objectForKey:@"objectvalue"] == nil) {
                NSIndexSet *indexSet;
                
                [_outlineView deselectRow:idx];
                indexSet = [[NSIndexSet alloc] initWithIndex:[_outlineView rowForItem:[self rootForItem:currentItem]]];
                [_outlineView selectRowIndexes:indexSet byExtendingSelection:YES];
            }
        }];
        _checkingSelection = NO;
    }
}


#pragma mark helper methods
- (id)rootForItem:(id)item
{
    id parentItem = [_outlineView parentForItem:item];
    if (parentItem) {
        return [self rootForItem:parentItem];
    }else {
        return item;
    }

}

- (NSArray *)results
{
    return _results;
}

- (void)setResults:(NSArray *)results
{
    if (results != _results) {
        [_results release];
        _results = [results copy];
    }
    [_outlineView reloadData];
}

@end
