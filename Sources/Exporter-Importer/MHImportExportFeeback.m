//
//  MHImportExportFeeback.m
//  MongoHub
//
//  Created by Jérôme Lebel on 31/01/2014.
//  Copyright (c) 2014 ThePeppersStudio.COM. All rights reserved.
//

#import "MHImportExportFeeback.h"

@implementation MHImportExportFeeback

- (id)init
{
    self = [super init];
    if (self) {
        [NSBundle loadNibNamed:@"MHImportExportFeeback" owner:self];
    }
    return self;
}

- (void)displayForWindow:(NSWindow *)window
{
    [NSApp beginSheet:_window modalForWindow:window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)close
{
    [NSApp endSheet:_window];
}

- (void)sheetDidEnd:(NSWindow *)window returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    
}

- (void)setLabel:(NSString *)label
{
    [_label setStringValue:label];
}

- (void)setMaxValue:(double)maxValue
{
    [_progressIndicator setMaxValue:maxValue];
}

- (void)setProgressValue:(double)progressValue
{
    [_progressIndicator setDoubleValue:progressValue];
}

@end
