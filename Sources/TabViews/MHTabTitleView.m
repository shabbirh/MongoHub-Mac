//
//  MHTabTitleView.m
//  MongoHub
//
//  Created by Jérôme Lebel on 30/11/11.
//  Copyright (c) 2011 ThePeppersStudio.COM. All rights reserved.
//

#import "MHTabTitleView.h"
#import "MHTabViewController.h"

#define CLOSE_BUTTON_SIZE 15.0
#define CLOSE_BUTTON_MARGIN 20.0

static NSImage *_closeButtonImage;

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
    if (!_closeButtonImage) {
        NSSize size = { CLOSE_BUTTON_SIZE, CLOSE_BUTTON_SIZE };
        
        _closeButtonImage = [[NSImage imageNamed:@"removemenu"] retain];
        [_closeButtonImage setScalesWhenResized:YES];
        [_closeButtonImage setSize:size];
    }
    
    return self;
}

- (void)dealloc
{
    [_titleCell release];
    [super dealloc];
}

- (NSRect)_closeButtonRect
{
    NSRect result;
    
    result = self.bounds;
    result.origin.x += 5.0;
    result.origin.y = (result.size.height - CLOSE_BUTTON_SIZE) / 2.0;
    result.size.width = result.size.height = CLOSE_BUTTON_SIZE;
    
    return result;
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
    _showCloseButton = YES;
    [self setNeedsDisplayInRect:[self _closeButtonRect]];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    _showCloseButton = NO;
    [self setNeedsDisplayInRect:[self _closeButtonRect]];
}

- (void)setFrame:(NSRect)frameRect
{
    [self removeTrackingRect:_trakingTag];
    [super setFrame:frameRect];
    _trakingTag = [self addTrackingRect:self.bounds owner:self userData:nil assumeInside:NO];
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect titleRect = self.bounds;
    NSRect closeButtonRect = [self _closeButtonRect];
    
    _titleCell.highlighted = _selected;
    [_titleCell drawBezelWithFrame:self.bounds inView:self];
    
    titleRect.size.height -= 7;
    titleRect.origin.x += CLOSE_BUTTON_MARGIN;
    titleRect.size.width -= CLOSE_BUTTON_MARGIN * 2.0;
    [_titleCell drawTitle:_titleCell.attributedTitle withFrame:titleRect inView:self];
    if (_showCloseButton && NSIntersectsRect(dirtyRect, closeButtonRect)) {
        [_closeButtonImage drawInRect:closeButtonRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    }
    
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if (NSPointInRect([self convertPoint:theEvent.locationInWindow fromView:nil], [self _closeButtonRect])) {
        [_tabViewController removeTabItemViewController:[_tabViewController tabItemViewControlletAtIndex:self.tag]];
    } else {
        _tabViewController.selectedTabIndex = self.tag;
    }
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
