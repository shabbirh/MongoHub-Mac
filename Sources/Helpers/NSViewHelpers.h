//
//  NSViewHelpers.h
//  MongoHub
//
//  Created by Jérôme Lebel on 11/07/12.
//  Copyright (c) 2012 ThePeppersStudio.COM. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSViewHelpers : NSObject
{
}

+ (void)setColor:(NSColor *)destinationColor fromColor:(NSColor *)originColor toTarget:(id)target withSelector:(SEL)selector delay:(NSInteger)delay;
+ (void)cancelColorForTarget:(id)target selector:(SEL)selector;

@end
