//
//  MHPreferenceController.h
//  MongoHub
//
//  Created by Jérôme Lebel on 23/10/13.
//  Copyright (c) 2013 ThePeppersStudio.COM. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define MHPreferenceControllerClosing           @"MHPreferenceControllerClosing"

@interface MHPreferenceController : NSViewController
{
    IBOutlet NSWindow                   *_window;
    IBOutlet NSButton                   *_betaSoftwareButton;
}
@property (nonatomic, strong, readonly) NSWindow *window;

+ (MHPreferenceController *)preferenceController;

- (IBAction)openWindow:(id)sender;
- (IBAction)betaSoftwareAction:(id)sender;
@end
