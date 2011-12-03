//
//  MHTabTitleView.m
//  MongoHub
//
//  Created by Jérôme Lebel on 30/11/11.
//  Copyright (c) 2011 ThePeppersStudio.COM. All rights reserved.
//

#import "MHTabTitleView.h"

@implementation MHTabTitleView

@synthesize dataSource = _dataSource;

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
    }
    
    return self;
}

- (void)dealloc
{
    [_titleCell release];
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSUInteger count, ii, selectedIndex;
    NSRect titleRect;
    NSUInteger width;
    
    selectedIndex = [_dataSource tabtitleViewSelectedIndex:self];
    titleRect = [self bounds];
    count = [_dataSource tabTitleViewTabCount:self];
    width = titleRect.size.width / count;
    titleRect.size.width = width;
    [_titleCell setState:NSOffState];
    for (ii = 0; ii < count; ii++) {
        _titleCell.highlighted = ii == selectedIndex;
        [_titleCell setTitle:[_dataSource tabTitleView:self tabTitleAtIndex:ii]];
        [_titleCell drawWithFrame:titleRect inView:self];
    }
}

@end
