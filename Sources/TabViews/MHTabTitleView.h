//
//  MHTabTitleView.h
//  MongoHub
//
//  Created by Jérôme Lebel on 30/11/11.
//  Copyright (c) 2011 ThePeppersStudio.COM. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MHTabViewController;

@interface MHTabTitleView : NSControl
{
    MHTabViewController *_tabViewController;
    NSButtonCell *_titleCell;
    NSTrackingRectTag _trakingTag;
    BOOL _selected;
    BOOL _showCloseButton;
}

@property(nonatomic, assign, readwrite) BOOL selected;
@property(nonatomic, assign, readwrite) MHTabViewController *tabViewController;

@end
