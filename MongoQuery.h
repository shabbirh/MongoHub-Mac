//
//  MongoQuery.h
//  MongoHub
//
//  Created by Jérôme Lebel on 30/08/11.
//  Copyright (c) 2011 fotonauts.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MongoQuery;

@protocol MongoQueryCallbackTarget<NSObject>
- (void)mongoQueryDidFinish:(MongoQuery *)mongoQuery;
@end

@interface MongoQuery : NSObject
{
    NSBlockOperation    *_blockOperation;
    NSMutableDictionary *_userInfo;
    NSMutableDictionary *_parameters;
    NSDate              *_startDate;
    NSDate              *_endDate;
    NSMutableArray      *_callbackTargets;
}

- (void)waitUntilFinished;
- (void)addCallbackWithTarget:(id<MongoQueryCallbackTarget>)target;

@property (nonatomic, readonly, retain) NSDictionary *parameters;
@property (nonatomic, readwrite, retain) NSMutableDictionary *userInfo;
@property (nonatomic, readonly, retain) NSDate *startDate;
@property (nonatomic, readonly, retain) NSDate *endDate;
@property (nonatomic, readonly, assign) NSTimeInterval duration;

@end
