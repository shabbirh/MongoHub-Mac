//
//  MHTabTitleView.m
//  MongoHub
//
//  Created by Jérôme Lebel on 30/11/11.
//  Copyright (c) 2011 ThePeppersStudio.COM. All rights reserved.
//

#import "MHTabTitleView.h"
#import "MHTabViewController.h"

@implementation MHTabTitleView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        _titleCell = [[NSButtonCell alloc] init];
        _titleCell.imagePosition = NSNoImage;
        _titleCell.buttonType = NSMomentaryPushInButton;
        _titleCell.bordered = YES;
        _titleCell.bezelStyle = NSShadowlessSquareBezelStyle;
        _titleCell.lineBreakMode = NSLineBreakByTruncatingHead;
    }
    
    return self;
}

- (void)dealloc
{
    [_titleCell release];
    [super dealloc];
}

- (NSRect)rectForTabTitleAtIndex:(NSUInteger)index
{
    NSRect result;
    NSUInteger count;
    
    count = [[_tabViewController tabControllers] count];
    result = self.bounds;
    result.size.width = result.size.width / count;
    result.origin.x = result.size.width * index;
    return result;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSArray *tabControllers;
    NSUInteger count, ii, selectedIndex;
    
    tabControllers = [_tabViewController tabControllers];
    selectedIndex = [_tabViewController selectedTabIndex];
    count = [tabControllers count];
    [_titleCell setState:NSOffState];
    for (ii = 0; ii < count; ii++) {
        NSRect titleRect;
        
        titleRect = [self rectForTabTitleAtIndex:ii];
        if (NSIntersectsRect(titleRect, dirtyRect)) {
            _titleCell.highlighted = ii != selectedIndex;
            [_titleCell setTitle:[[tabControllers objectAtIndex:ii] title]];
            [_titleCell drawWithFrame:titleRect inView:self];
        }
    }
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint mousePoint;
    NSArray *tabControllers;
    NSUInteger count, ii, selectedIndex;
    
    mousePoint = [self convertPoint:theEvent.locationInWindow fromView:nil];
    tabControllers = [_tabViewController tabControllers];
    selectedIndex = [_tabViewController selectedTabIndex];
    count = [tabControllers count];
    [_titleCell setState:NSOffState];
    for (ii = 0; ii < count; ii++) {
        NSRect titleRect;
        
        titleRect = [self rectForTabTitleAtIndex:ii];
        if (NSPointInRect(mousePoint, titleRect)) {
            _tabViewController.selectedTabIndex = ii;
            break;
        }
    }
}

@end
