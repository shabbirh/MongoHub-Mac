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

#define TAB_HEIGHT 30.0

@implementation MHTabViewController

@synthesize tabControllers = _tabControllers;

- (void)dealloc
{
    for (MHTabItemViewController *controller in _tabControllers) {
        [controller removeObserver:self forKeyPath:@"title"];
    }
    [_tabControllers release];
    [_tabTitleViewes release];
    [self.view removeObserver:self forKeyPath:@"frame"];
    [super dealloc];
}

- (void)awakeFromNib
{
    if (_tabControllers == nil) {
        _selectedTabIndex = NSNotFound;
        _tabControllers = [[NSMutableArray alloc] init];
        _tabTitleViewes = [[NSMutableArray alloc] init];
        [self.view addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (NSRect)_rectForTabTitleAtIndex:(NSUInteger)index
{
    NSRect result;
    NSUInteger count;
    
    count = [_tabControllers count];
    result = self.view.bounds;
    result.origin.y += result.size.height - TAB_HEIGHT;
    result.size.height = TAB_HEIGHT;
    result.size.width = result.size.width / count;
    result.origin.x = result.size.width * index;
    return result;
}

- (void)_removeCurrentTabItemViewController
{
    [_selectedTabView removeFromSuperview];
    _selectedTabView = nil;
}

- (void)_tabItemViewControllerWithIndex:(NSInteger)index
{
    if (_selectedTabIndex != NSNotFound && _selectedTabIndex < [_tabTitleViewes count]) {
        [[_tabTitleViewes objectAtIndex:_selectedTabIndex] setNeedsDisplay:YES];
        [[_tabTitleViewes objectAtIndex:_selectedTabIndex] setSelected:NO];
    }
    _selectedTabIndex = index;
    if (_selectedTabIndex != NSNotFound) {
        NSRect rect;
        
        [[_tabTitleViewes objectAtIndex:_selectedTabIndex] setNeedsDisplay:YES];
        rect = self.view.bounds;
        _selectedTabView = [[_tabControllers objectAtIndex:_selectedTabIndex] view];
        [self.view addSubview:_selectedTabView];
        rect.size.height -= TAB_HEIGHT;
        _selectedTabView.frame = rect;
        [[_tabTitleViewes objectAtIndex:_selectedTabIndex] setSelected:YES];
    }
}

- (void)_updateTitleViewes
{
    NSUInteger ii = 0;
    
    for (MHTabTitleView *titleView in _tabTitleViewes) {
        titleView.frame = [self _rectForTabTitleAtIndex:ii];
        titleView.selected = self.selectedTabIndex == ii;
        titleView.tag = ii;
        ii++;
    }
}

- (void)addTabItemViewController:(MHTabItemViewController *)tabItemViewController
{
    if ([_tabControllers indexOfObject:tabItemViewController] == NSNotFound) {
        MHTabTitleView *titleView;
        
        tabItemViewController.tabViewController = self;
        [_tabControllers addObject:tabItemViewController];
        tabItemViewController.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        titleView = [[MHTabTitleView alloc] initWithFrame:self.view.bounds];
        titleView.tabViewController = self;
        titleView.stringValue = tabItemViewController.title;
        [_tabTitleViewes addObject:titleView];
        [self.view addSubview:titleView];
        [titleView release];
        [tabItemViewController addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
        
        self.selectedTabIndex = [_tabControllers count] - 1;
        [self _updateTitleViewes];
    }
}

- (void)removeTabItemViewController:(MHTabItemViewController *)tabItemViewController
{
    NSUInteger index;
    
    index = [_tabControllers indexOfObject:tabItemViewController];
    if (index != NSNotFound) {
        [self willChangeValueForKey:@"selectedTabIndex"];
        [self _removeCurrentTabItemViewController];
        [tabItemViewController removeObserver:self forKeyPath:@"title"];
        [_tabControllers removeObjectAtIndex:index];
        [[_tabTitleViewes objectAtIndex:index] removeFromSuperview];
        [_tabTitleViewes removeObjectAtIndex:index];
        if ([_tabControllers count] == 0) {
            [self _tabItemViewControllerWithIndex:NSNotFound];
        } else if (_selectedTabIndex == 0) {
            [self _tabItemViewControllerWithIndex:0];
        } else {
            [self _tabItemViewControllerWithIndex:_selectedTabIndex - 1];
        }
        [self _updateTitleViewes];
        [self didChangeValueForKey:@"selectedTabIndex"];
    }
}

- (NSUInteger)tabCount
{
    return [_tabControllers count];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.view) {
        [self _updateTitleViewes];
    } else if ([object isKindOfClass:[MHTabItemViewController class]]) {
        NSUInteger index;
        
        index = [_tabControllers indexOfObject:object];
        NSAssert(index != NSNotFound, @"unknown tab");
        [[_tabTitleViewes objectAtIndex:index] setStringValue:[object title]];
        [[_tabTitleViewes objectAtIndex:index] setNeedsDisplay:YES];
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
        [self willChangeValueForKey:@"selectedTabIndex"];
        [self _removeCurrentTabItemViewController];
        [self _tabItemViewControllerWithIndex:index];
        [self didChangeValueForKey:@"selectedTabIndex"];
    }
}

- (void)selectTabItemViewController:(MHTabItemViewController *)tabItemViewController
{
    NSInteger index;
    
    index = [_tabControllers indexOfObject:tabItemViewController];
    if (index != NSNotFound) {
        self.selectedTabIndex = index;
    }
}

- (MHTabItemViewController *)selectedTabItemViewController
{
    if (self.selectedTabIndex == NSNotFound) {
        return nil;
    } else {
        return [_tabControllers objectAtIndex:self.selectedTabIndex];
    }
}

- (MHTabItemViewController *)tabItemViewControlletAtIndex:(NSInteger)index
{
    return [_tabControllers objectAtIndex:index];
}

@end
