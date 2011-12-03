//
//  MHTabViewController.m
//  MongoHub
//
//  Created by Jérôme Lebel on 02/12/11.
//  Copyright (c) 2011 ThePeppersStudio.COM. All rights reserved.
//

#import "MHTabViewController.h"

@implementation MHTabViewController

@synthesize selectedTabIndex = _selectedTabIndex;

- (void)dealloc
{
    [_tabItems release];
    [super dealloc];
}

- (void)awakeFromNib
{
    _tabItems = [[NSMutableArray alloc] init];
}

- (void)addViewController:(NSViewController *)viewController
{
    if ([_tabItems indexOfObject:viewController] == NSNotFound) {
        [_tabItems addObject:viewController];
        [_tabTitleView setNeedsDisplay:YES];
    }
}

- (NSUInteger)tabTitleViewTabCount:(MHTabTitleView *)tabTitleView
{
    return [_tabItems count];
}

- (NSString *)tabTitleView:(MHTabTitleView *)tabTitleView tabTitleAtIndex:(NSUInteger)index
{
    return [[_tabItems objectAtIndex:index] title];
}

- (NSUInteger)tabtitleViewSelectedIndex:(MHTabTitleView *)tabTitleView
{
    return _selectedTabIndex;
}

@end
