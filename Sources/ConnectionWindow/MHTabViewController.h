//
//  MHTabViewController.h
//  MongoHub
//
//  Created by Jérôme Lebel on 02/12/11.
//  Copyright (c) 2011 fotonauts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MHTabTitleView;

@interface MHTabViewController : NSViewController
{
    IBOutlet MHTabTitleView *_tabTitleView;
    NSMutableArray *_tabControllers;
    NSUInteger _selectedTabIndex;
}

@property (nonatomic, assign, readwrite) NSUInteger selectedTabIndex;
@property (nonatomic, assign, readonly) NSUInteger tabCount;
@property (nonatomic, assign, readonly) NSArray *tabControllers;

- (void)addViewController:(NSViewController *)viewController;

@end
