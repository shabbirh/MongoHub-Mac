//
//  MODHelper.m
//  MongoHub
//
//  Created by Jérôme Lebel on 20/09/11.
//  Copyright (c) 2011 ThePeppersStudio.COM. All rights reserved.
//

#import "MODHelper.h"
#import "MODObjectId.h"

@interface MODHelper()
+ (NSMutableDictionary *)convertForOutlineWithValue:(id)dataValue dataKey:(NSString *)dataKey;
@end

@implementation MODHelper

+ (NSArray *)convertForOutlineWithObjects:(NSArray *)mongoObjects
{
    NSMutableArray *result;
    
    result = [NSMutableArray arrayWithCapacity:[mongoObjects count]];
    for (NSDictionary *object in mongoObjects) {
        NSMutableDictionary *dict;
        
        dict = [self convertForOutlineWithValue:[object objectForKey:@"_id"] dataKey:@"_id"];
        if (dict == nil) {
            dict = [NSMutableDictionary dictionary];
        }
        [dict setObject:[self convertForOutlineWithObject:object] forKey:@"child"];
        [result addObject:dict];
    }
    return result;
}

+ (NSArray *)convertForOutlineWithObject:(NSDictionary *)mongoObject
{
    NSMutableArray *result;
    
    result = [NSMutableArray array];
    for (NSString *dataKey in [[mongoObject allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        NSMutableDictionary *value;
        
        value = [self convertForOutlineWithValue:[mongoObject objectForKey:dataKey] dataKey:dataKey];
        if (value) {
            [result addObject:value];
        }
    }
    return result;
}

+ (NSMutableDictionary *)convertForOutlineWithValue:(id)dataValue dataKey:(NSString *)dataKey
{
    NSArray *child = nil;
    NSString *value = nil;
    NSString *type;
    NSMutableDictionary *result = nil;
    
    if ([dataValue isKindOfClass:[NSNumber class]]) {
        if (strcmp([dataValue objCType], @encode(double)) == 0 || strcmp([dataValue objCType], @encode(float)) == 0) {
            type = @"Double";
            value = [dataValue description];
        } else if (strcmp([dataValue objCType], @encode(int)) == 0 || strcmp([dataValue objCType], @encode(long long)) == 0) {
            type = @"Integer";
            value = [dataValue description];
        } else if (strcmp([dataValue objCType], @encode(BOOL)) == 0) {
            type = @"Boolean";
            if ([dataValue boolValue]) {
                value = @"YES";
            } else {
                value = @"NO";
            }
        } else {
            NSLog(@"%s %@ %@", [dataValue objCType], dataValue, dataKey);
        }
    } else if ([dataValue isKindOfClass:[NSDate class]]) {
        type = @"Date";
        value = [dataValue description];
    } else if ([dataValue isKindOfClass:[MODObjectId class]]) {
        type = @"Object id";
        value = [dataValue description];
    } else if ([dataValue isKindOfClass:[NSString class]]) {
        type = @"String";
        value = dataValue;
    } else if ([dataValue isKindOfClass:[NSNull class]]) {
        type = @"NULL";
        value = @"NULL";
    } else if ([dataValue isKindOfClass:[NSDictionary class]]) {
        value = @"";
        type = @"Object";
        child = [self convertForOutlineWithObject:dataValue];
    } else if ([dataValue isKindOfClass:[NSArray class]]) {
        NSInteger ii, count;
        
        count = [dataValue count];
        value = @"";
        type = @"Array";
        child = [NSMutableArray arrayWithCapacity:[dataValue count]];
        for (ii = 0; ii < count; ii++) {
            NSString *arrayDataKey;
            id arrayDataValue;
            
            arrayDataValue = [dataValue objectAtIndex:ii];
            arrayDataKey = [[NSString alloc] initWithFormat:@"%ld", ii];
            [(NSMutableArray *)child addObject:[self convertForOutlineWithValue:arrayDataValue dataKey:arrayDataKey]];
            [arrayDataKey release];
        }
    } else {
        NSLog(@"type %@ value %@", [dataValue class], dataValue);
    }
    if (value) {
        result = [NSMutableDictionary dictionaryWithCapacity:4];
        [result setValue:value forKey:@"value"];
        [result setValue:dataKey forKey:@"name"];
        [result setValue:type forKey:@"type"];
        if (child) {
            [result setValue:child forKey:@"child"];
        }
    }
    return result;
}

@end
