//
//  MHPreferenceController.m
//  MongoHub
//
//  Created by Jérôme Lebel on 23/10/13.
//  Copyright (c) 2013 ThePeppersStudio.COM. All rights reserved.
//

#import "MHPreferenceController.h"

@implementation MHPreferenceController

@synthesize window = _window;

+ (MHPreferenceController *)preferenceController
{
    MHPreferenceController *result;
    result = [[[MHPreferenceController alloc] initWithNibName:@"MHPreferenceController" bundle:NSBundle.mainBundle] autorelease];
    [result loadView];
    return result;
}

- (IBAction)openWindow:(id)sender
{
    [_window makeKeyAndOrderFront:sender];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MHPreferenceControllerClosing object:self];
}

@end
