//
//  MHTabViewController.m
//  MongoHub
//
//  Created by Jérôme Lebel on 02/12/11.
//  Copyright (c) 2011 ThePeppersStudio.COM. All rights reserved.
//

#import "MHTabViewController.h"
#import "MHTabTitleView.h"

@implementation MHTabViewController

@synthesize selectedTabIndex = _selectedTabIndex, tabControllers = _tabControllers;

- (void)dealloc
{
    [_tabControllers release];
    [super dealloc];
}

- (void)awakeFromNib
{
    _tabControllers = [[NSMutableArray alloc] init];
}

- (void)addViewController:(NSViewController *)viewController
{
    if ([_tabControllers indexOfObject:viewController] == NSNotFound) {
        [viewController addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
        [_tabControllers addObject:viewController];
        [_tabTitleView setNeedsDisplay:YES];
    }
}

- (void)removeViewController:(NSViewController *)viewController
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
    if ([object isKindOfClass:[NSViewController class]]) {
        NSUInteger index;
        
        index = [_tabControllers indexOfObject:object];
        NSAssert(index != NSNotFound, @"unknown tab");
        [_tabTitleView setNeedsDisplayInRect:[_tabTitleView rectForTabTitleAtIndex:index]];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
