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
    result.origin.y = (int)((result.size.height - CLOSE_BUTTON_SIZE) / 2.0);
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
    _showCloseButton = [self mouse:[self convertPoint:[self.window convertScreenToBase:[NSEvent mouseLocation]] fromView:nil] inRect:self.bounds];
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect titleRect = self.bounds;
    NSRect closeButtonRect = [self _closeButtonRect];
    
    _titleCell.highlighted = _selected || _titleHit;
    [_titleCell drawBezelWithFrame:self.bounds inView:self];
    
    titleRect.size.height -= 7;
    titleRect.origin.x += CLOSE_BUTTON_MARGIN;
    titleRect.size.width -= CLOSE_BUTTON_MARGIN * 2.0;
    [_titleCell drawTitle:_titleCell.attributedTitle withFrame:titleRect inView:self];
    if (_showCloseButton && NSIntersectsRect(dirtyRect, closeButtonRect)) {
        if (_closeButtonHit) {
            [[NSColor darkGrayColor] set];
        } else {
            [[NSColor lightGrayColor] set];
        }
        NSRectFill(closeButtonRect);
        if (_closeButtonHit) {
            [[NSColor blackColor] set];
        } else {
            [[NSColor darkGrayColor] set];
        }
        NSFrameRectWithWidth(closeButtonRect, 1.0);
        [_closeButtonImage drawInRect:closeButtonRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    }
    
}

static NSComparisonResult orderFromView(id view1, id view2, void *current)
{
    if (view1 == current) {
        return NSOrderedDescending;
    } else if (view2 == current) {
        return NSOrderedAscending;
    } else {
        return NSOrderedSame;
    }
}
//{NSOrderedAscending = -1, NSOrderedSame, NSOrderedDescending}

- (void)mouseDown:(NSEvent *)theEvent
{
    BOOL keepOn = YES;
    BOOL titleHit = YES;
    BOOL closeButtonHit;
    NSPoint locationInView;
    NSPoint locationInWindow;
    NSPoint firstLocationInView;
    NSRect closeButtonRect = [self _closeButtonRect];
    BOOL startToDrag = NO;
    BOOL firstClickInCloseButton;
    NSRect originalFrame = self.frame;
    
    [self.superview sortSubviewsUsingFunction:orderFromView context:self];
    locationInWindow = [theEvent locationInWindow];
    firstLocationInView = locationInView = [self convertPoint:locationInWindow fromView:nil];
    firstClickInCloseButton = [self mouse:firstLocationInView inRect:closeButtonRect];
    while (keepOn) {
        locationInWindow = [theEvent locationInWindow];
        if (!startToDrag && !firstClickInCloseButton && pow(firstLocationInView.x - locationInView.x, 2) >= 100) {
            startToDrag = YES;
        }
        locationInView = [self convertPoint:locationInWindow fromView:nil];
        titleHit = [self mouse:locationInView inRect:self.bounds];
        closeButtonHit = !startToDrag && [self mouse:locationInView inRect:closeButtonRect];
        
        if (closeButtonHit != _closeButtonHit || (titleHit || startToDrag) != _titleHit) {
            _closeButtonHit = closeButtonHit;
            _titleHit = titleHit || startToDrag;
            [self setNeedsDisplay];
        }
        switch ([theEvent type]) {
            case NSLeftMouseDragged:
                if (startToDrag) {
                    NSRect newFrame;
                    NSPoint locationInSuperview;
                    
                    newFrame = self.frame;
                    newFrame.origin.x += locationInView.x - firstLocationInView.x;
                    locationInSuperview = [self.superview convertPoint:locationInWindow fromView:nil];
                    if (locationInSuperview.x < originalFrame.origin.x && self.tag > 0) {
                        [_tabViewController moveTabItemFromIndex:self.tag toIndex:self.tag - 1];
                        originalFrame = self.frame;
                    } else if (locationInSuperview.x > originalFrame.origin.x + originalFrame.size.width && self.tag < _tabViewController.tabCount - 1) {
                        [_tabViewController moveTabItemFromIndex:self.tag toIndex:self.tag + 1];
                        originalFrame = self.frame;
                    }
                    if (newFrame.origin.x < 0) {
                        newFrame.origin.x = 0;
                    } else if (newFrame.origin.x + newFrame.size.width > self.superview.bounds.origin.x + self.superview.bounds.size.width) {
                        newFrame.origin.x = self.superview.bounds.origin.x + self.superview.bounds.size.width - newFrame.size.width;
                    }
                    self.frame = newFrame;
                }
                break;
            case NSLeftMouseUp:
                if (closeButtonHit) {
                    [_tabViewController removeTabItemViewController:[_tabViewController tabItemViewControlletAtIndex:self.tag]];
                } else if (titleHit) {
                    _tabViewController.selectedTabIndex = self.tag;
                }
                keepOn = NO;
                break;
            default:
                /* Ignore any other kind of event. */
                break;
        }
        if (keepOn) {
            theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
        }
    };
    self.frame = originalFrame;
    _titleHit = NO;
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
