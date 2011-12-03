//
//  ResultsOutlineViewController.m
//  MongoHub
//
//  Created by Syd on 10-4-26.
//  Copyright 2010 MusicPeace.ORG. All rights reserved.
//

#import "ResultsOutlineViewController.h"

@implementation ResultsOutlineViewController

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
    [_outlineView deselectAll:nil];
    [_outlineView release];
    [_results release];
    [super dealloc];
}

- (void)awakeFromNib
{
    [_outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
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
- (int)outlineView:(NSOutlineView *)outlineView
numberOfChildrenOfItem:(id)item
{
    // If the item is the root item, return the number of mailboxes
    if ([outlineView levelForItem:item] == -1) {
        return [_results count];
    }
    // If the item is a root-level item (ie mailbox)
    return [[item objectForKey:@"child"] count];
}

// Return the data object associated with the specified item.
- (id)outlineView:(NSOutlineView *)outlineView
objectValueForTableColumn:(NSTableColumn *)tableColumn
           byItem:(id)item
{
    if([[tableColumn identifier] isEqualToString:@"name"])
    {
        return [item objectForKey:@"name"];
    }
    
    else if([[tableColumn identifier] isEqualToString:@"value"])
        return [item objectForKey:@"value"];
    else if([[tableColumn identifier] isEqualToString:@"type"])
        return [item objectForKey:@"type"];
    /*switch([outlineView levelForItem:item])
    {
            // If the item is a root-level item 
        case 0:
            if([[tableColumn identifier] isEqualToString:@"name"])
                return [item objectForKey:@"name" ];
            break;
            
        case 1:
            if([[tableColumn identifier] isEqualToString:@"name"])
            {
                return [item objectForKey:@"name"];
            }
            
            else if([[tableColumn identifier] isEqualToString:@"value"])
                return [item objectForKey:@"value"];
            else if([[tableColumn identifier] isEqualToString:@"type"])
                return [item objectForKey:@"type"];
            break;
    }*/
    
    return nil;
}

- (id)selectedItem
{
    NSInteger index = [_outlineView selectedRow];
    id item = nil;
  
    if (index != NSNotFound) {
        item = [_outlineView itemAtRow:index];
    }
    return item;
}

- (id)selectedDocument
{
    return [self rootForItem:[self selectedItem]];
}

#pragma mark -
#pragma mark NSOutlineView delegate methods
- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    switch ([_outlineView selectedRow]) {
        case -1:
            break;
        default:{
            break;
            id currentItem = [_outlineView itemAtRow:[_outlineView selectedRow]];
            if ([_outlineView isItemExpanded:currentItem]) {
                [_outlineView collapseItem:currentItem collapseChildren:NO];
            }else {
                [_outlineView expandItem:currentItem expandChildren:NO];
            }
            break;
        }
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
