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
    IBOutlet MHTabViewController *_tabViewController;
    NSButtonCell *_titleCell;
}

- (NSRect)rectForTabTitleAtIndex:(NSUInteger)index;

@end
