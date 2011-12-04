//
//  MHTabViewController.m
//  MongoHub
//
//  Created by Jérôme Lebel on 02/12/11.
//  Copyright (c) 2011 ThePeppersStudio.COM. All rights reserved.
//

#import "MHTabViewController.h"
#import "MHTabTitleView.h"
#import "MHTabItemViewController.h"

@implementation MHTabViewController

@synthesize tabControllers = _tabControllers;

- (void)dealloc
{
    for (MHTabItemViewController *controller in _tabControllers) {
        [controller removeObserver:self forKeyPath:@"title"];
    }
    [_tabControllers release];
    [super dealloc];
}

- (void)awakeFromNib
{
    _selectedTabIndex = NSNotFound;
    _tabControllers = [[NSMutableArray alloc] init];
}

- (void)addViewController:(MHTabItemViewController *)viewController
{
    if ([_tabControllers indexOfObject:viewController] == NSNotFound) {
        [_tabControllers addObject:viewController];
        [viewController addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
        viewController.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        [_tabTitleView setNeedsDisplay:YES];
        self.selectedTabIndex = [_tabControllers count] - 1;
    }
}

- (void)removeViewController:(MHTabItemViewController *)viewController
{
    NSUInteger index;
    
    index = [_tabControllers indexOfObject:viewController];
    if (index != NSNotFound) {
        [viewController removeObserver:self forKeyPath:@"title"];
        [_tabControllers removeObjectAtIndex:index];
        [_tabTitleView setNeedsDisplay:YES];
    }
}

- (NSUInteger)tabCount
{
    return [_tabControllers count];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isKindOfClass:[MHTabItemViewController class]]) {
        NSUInteger index;
        
        index = [_tabControllers indexOfObject:object];
        NSAssert(index != NSNotFound, @"unknown tab");
        [_tabTitleView setNeedsDisplayInRect:[_tabTitleView rectForTabTitleAtIndex:index]];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (NSUInteger)selectedTabIndex
{
    return _selectedTabIndex;
}

- (void)setSelectedTabIndex:(NSUInteger)index
{
    if (index != _selectedTabIndex) {
        NSRect rect;
        
        rect = self.view.bounds;
        [self willChangeValueForKey:@"selectedTabIndex"];
        [_selectedTabView removeFromSuperview];
        _selectedTabView = [[_tabControllers objectAtIndex:index] view];
        [self.view addSubview:_selectedTabView];
        rect.size.height -= _tabTitleView.frame.size.height;
        _selectedTabView.frame = rect;
        [_tabTitleView setNeedsDisplay:YES];
        _selectedTabIndex = index;
        [self didChangeValueForKey:@"selectedTabIndex"];
    }
}

@end
