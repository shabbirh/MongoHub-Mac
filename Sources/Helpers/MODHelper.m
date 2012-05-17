//
//  MODHelper.m
//  MongoHub
//
//  Created by Jérôme Lebel on 20/09/11.
//  Copyright (c) 2011 ThePeppersStudio.COM. All rights reserved.
//

#import "MODHelper.h"
#import "MOD_public.h"
#import "NSString+Extras.h"

@interface MODHelper()
+ (NSMutableDictionary *)convertForOutlineWithValue:(id)dataValue dataKey:(NSString *)dataKey;
@end

@implementation MODHelper

+ (NSArray *)convertForOutlineWithObjects:(NSArray *)mongoObjects
{
    NSMutableArray *result;
    
    result = [NSMutableArray arrayWithCapacity:[mongoObjects count]];
    for (MODSortedMutableDictionary *object in mongoObjects) {
        id idValue = nil;
        NSString *idValueName = nil;
        NSMutableDictionary *dict;
        
        idValue = [object objectForKey:@"_id"];
        idValueName = @"_id";
        if (!idValue) {
            idValue = [object objectForKey:@"name"];
            idValueName = @"name";
        }
        if (!idValue && [object count] > 0) {
            idValueName = [[object sortedKeys] objectAtIndex:0];
            idValue = [object objectForKey:idValueName];
        }
        if (idValue) {
            dict = [self convertForOutlineWithValue:idValue dataKey:idValueName];
        }
        if (dict == nil) {
            dict = [NSMutableDictionary dictionary];
        }
        [dict setObject:[self convertForOutlineWithObject:object] forKey:@"child"];
        [dict setObject:[MODServer convertObjectToJson:object pretty:YES] forKey:@"beautified"];
        [dict setObject:object forKey:@"objectvalue"];
        [result addObject:dict];
    }
    return result;
}

+ (NSArray *)convertForOutlineWithObject:(MODSortedMutableDictionary *)mongoObject
{
    NSMutableArray *result;
    
    result = [NSMutableArray array];
    for (NSString *dataKey in mongoObject.sortedKeys) {
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
        value = [dataValue tengenString];
    } else if ([dataValue isKindOfClass:[MODRegex class]]) {
        type = @"Regex";
        value = [dataValue tengenString];
    } else if ([dataValue isKindOfClass:[MODTimestamp class]]) {
        type = @"Timestamp";
        value = [dataValue tengenString];
    } else if ([dataValue isKindOfClass:[MODBinary class]]) {
        type = @"Binary";
        value = [dataValue tengenString];
    } else if ([dataValue isKindOfClass:[MODDBRef class]]) {
        type = @"Ref";
        value = [dataValue tengenString];
    } else if ([dataValue isKindOfClass:[NSString class]]) {
        type = @"String";
        value = dataValue;
    } else if ([dataValue isKindOfClass:[NSNull class]]) {
        type = @"NULL";
        value = @"NULL";
    } else if ([dataValue isKindOfClass:[MODSortedMutableDictionary class]]) {
        value = @"";
        type = @"Object";
        child = [self convertForOutlineWithObject:dataValue];
    } else if ([dataValue isKindOfClass:[MODSymbol class]]) {
        type = @"Symbol";
        value = [dataValue value];
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
        NSAssert(NO, @"unknown type type %@ value %@", [dataValue class], dataValue);
    }
    if (value) {
        result = [NSMutableDictionary dictionaryWithCapacity:4];
        [result setObject:value forKey:@"value"];
        [result setObject:dataKey forKey:@"name"];
        [result setObject:type forKey:@"type"];
        [result setObject:dataValue forKey:@"objectvalueid"];
        //[result setObject:jsonString forKey:@"raw"];
        //[result setObject:jsonStringb forKey:@"beautified"];
        if (child) {
            [result setValue:child forKey:@"child"];
        }
    }
    return result;
}

@end
