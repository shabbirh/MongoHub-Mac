//
//  MHTabViewController.h
//  MongoHub
//
//  Created by Jérôme Lebel on 02/12/11.
//  Copyright (c) 2011 fotonauts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MHTabTitleView, MHTabItemViewController;

@interface MHTabViewController : NSViewController
{
    IBOutlet MHTabTitleView *_tabTitleView;
    NSView *_selectedTabView;
    NSMutableArray *_tabControllers;
    NSUInteger _selectedTabIndex;
}

@property (nonatomic, assign, readwrite) NSUInteger selectedTabIndex;
@property (nonatomic, assign, readonly) NSUInteger tabCount;
@property (nonatomic, assign, readonly) NSArray *tabControllers;
@property (nonatomic, assign, readonly) MHTabItemViewController *selectedTabItemViewController;

- (void)addTabItemViewController:(MHTabItemViewController *)tabItemViewController;
- (void)removeTabItemViewController:(MHTabItemViewController *)tabItemViewController;
- (void)selectTabItemViewController:(MHTabItemViewController *)tabItemViewController;

@end
