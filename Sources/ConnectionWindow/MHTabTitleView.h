//
//  MHTabTitleView.h
//  MongoHub
//
//  Created by Jérôme Lebel on 30/11/11.
//  Copyright (c) 2011 ThePeppersStudio.COM. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MHTabTitleView;

@protocol MHTabTitleViewDataSource <NSObject>
- (NSUInteger)tabtitleViewSelectedIndex:(MHTabTitleView *)tabTitleView;
- (NSUInteger)tabTitleViewTabCount:(MHTabTitleView *)tabTitleView;
- (NSString *)tabTitleView:(MHTabTitleView *)tabTitleView tabTitleAtIndex:(NSUInteger)index;
@end

@interface MHTabTitleView : NSControl
{
    IBOutlet id<MHTabTitleViewDataSource> _dataSource;
    IBOutlet NSButtonCell *_button;
    NSButtonCell *_titleCell;
}

@property (nonatomic, assign, readwrite) id<MHTabTitleViewDataSource> dataSource;

@end
