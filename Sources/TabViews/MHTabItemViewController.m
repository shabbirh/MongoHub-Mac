//
//  MHTabItemViewController.m
//  MongoHub
//
//  Created by Jérôme Lebel on 04/12/11.
//  Copyright (c) 2011 ThePeppersStudio.COM. All rights reserved.
//

#import "MHTabItemViewController.h"
#import "MHTabViewController.h"

@implementation MHTabItemViewController

@synthesize tabViewController = _tabViewController;

- (void)select
{
    [_tabViewController selectTabItemViewController:self];
}

@end
