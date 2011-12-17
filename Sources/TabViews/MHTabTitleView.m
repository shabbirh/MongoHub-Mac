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

@synthesize selected = _selected, tabViewController = _tabViewController;

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

- (void)viewDidMoveToSuperview
{
    _trakingTag = [self addTrackingRect:self.bounds owner:self userData:nil assumeInside:NO];
    [super viewDidMoveToSuperview];
}

- (void)removeFromSuperview
{
    [self removeTrackingRect:_trakingTag];
    [super removeFromSuperview];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
}

- (void)mouseExited:(NSEvent *)theEvent
{
}

- (void)setFrame:(NSRect)frameRect
{
    [self removeTrackingRect:_trakingTag];
    [super setFrame:frameRect];
    _trakingTag = [self addTrackingRect:self.bounds owner:self userData:nil assumeInside:NO];
}

- (void)drawRect:(NSRect)dirtyRect
{
    _titleCell.highlighted = _selected;
    [_titleCell drawBezelWithFrame:self.bounds inView:self];
    
    if (_titleCell.title.length > 0) {
        NSRect titleRect = self.bounds;
        
        titleRect.size.height -= 7;
        titleRect.origin.x += 20;
        titleRect.size.width -= 40;
        [_titleCell drawTitle:_titleCell.attributedTitle withFrame:titleRect inView:self];
    }
}

- (void)mouseDown:(NSEvent *)theEvent
{
    _tabViewController.selectedTabIndex = self.tag;
}

- (void)setStringValue:(NSString *)aString
{
    _titleCell.title = aString;
}

- (NSString *)stringValue
{
    return _titleCell.title;
}

@end
