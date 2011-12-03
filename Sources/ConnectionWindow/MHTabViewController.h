//
//  MHTabViewController.h
//  MongoHub
//
//  Created by Jérôme Lebel on 02/12/11.
//  Copyright (c) 2011 fotonauts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MHTabTitleView.h"

@interface MHTabViewController : NSViewController<MHTabTitleViewDataSource>
{
    IBOutlet MHTabTitleView *_tabTitleView;
    NSMutableArray *_tabItems;
    NSUInteger _selectedTabIndex;
}

@property (nonatomic, assign, readwrite) NSUInteger selectedTabIndex;

- (void)addViewController:(NSViewController *)viewController;

@end
