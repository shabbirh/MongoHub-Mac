//
//  MHImportExportFeeback.h
//  MongoHub
//
//  Created by Jérôme Lebel on 31/01/2014.
//  Copyright (c) 2014 ThePeppersStudio.COM. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface MHImportExportFeeback : NSObject
{
    IBOutlet NSWindow                   *_window;
    IBOutlet NSTextField                *_label;
    IBOutlet NSProgressIndicator        *_progressIndicator;
}
@end
