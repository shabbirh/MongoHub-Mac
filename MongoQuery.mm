//
//  MongoQuery.m
//  MongoHub
//
//  Created by Jérôme Lebel on 30/08/11.
//  Copyright (c) 2011 fotonauts.com. All rights reserved.
//

#import "MongoQuery.h"
#import "MongoDB_internal.h"

@implementation MongoQuery

@synthesize parameters = _parameters, userInfo = _userInfo, startDate = _startDate, endDate = _endDate;

- (id)init
{
    if (self = [super init]) {
        _userInfo = [[NSMutableDictionary alloc] init];
        _parameters = [[NSMutableDictionary alloc] init];
        _callbackTargets = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [self removeBlockOperation];
    [_startDate release];
    [_endDate release];
    [_parameters release];
    [_userInfo release];
    [_callbackTargets release];
    [super dealloc];
}

- (NSMutableDictionary *)mutableParameters
{
    return _parameters;
}

- (void)setMutableParameters:(NSMutableDictionary *)parameters
{
    [_parameters release];
    _parameters = [parameters retain];
}

- (void)starts
{
    NSAssert(_startDate == nil, @"already started");
    NSAssert(_endDate == nil, @"weird");
    _startDate = [[NSDate alloc] init];
}

- (void)ends
{
    NSAssert(_startDate != nil, @"needs to be started");
    NSAssert(_endDate == nil, @"already ended");
    _endDate = [[NSDate alloc] init];
    for (id<MongoQueryCallbackTarget> target in _callbackTargets) {
        [target mongoQueryDidFinish:self];
    }
}

- (NSTimeInterval)duration
{
    return [_endDate timeIntervalSinceDate:_startDate];
}

- (void)removeBlockOperation
{
    @synchronized(self) {
        [_blockOperation removeObserver:self forKeyPath:@"isFinished"];
        _blockOperation = nil;
    }
}

- (NSBlockOperation *)blockOperation
{
    return _blockOperation;
}

- (void)setBlockOperation:(NSBlockOperation *)blockOperation
{
    _blockOperation = blockOperation;
    [_blockOperation addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (_blockOperation == object) {
        [self removeBlockOperation];
    }
}

- (void)waitUntilFinished
{
    NSBlockOperation *operation;
    
    @synchronized(self) {
        operation = [_blockOperation retain];
    }
    [operation waitUntilFinished];
    [operation release];
}

- (void)addCallbackWithTarget:(id<MongoQueryCallbackTarget>)target
{
    [_callbackTargets addObject:target];
}

@end
