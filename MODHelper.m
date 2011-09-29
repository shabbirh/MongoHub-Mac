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

static void convertValueToJson(NSMutableString *result, int indent, id value, NSString *key, BOOL pretty);

static void addIdent(NSMutableString *result, int indent)
{
    int ii = 0;
    
    while (ii < indent) {
        [result appendString:@"  "];
        ii++;
    }
}

static void convertDictionaryToJson(NSMutableString *result, int indent, NSDictionary *value, BOOL pretty)
{
    BOOL first = YES;
    
    [result appendString:@"{"];
    if (pretty) {
        [result appendString:@"\n"];
    }
    for (NSString *key in [[value allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        if (first) {
            first = NO;
        } else {
            [result appendString:@",\n"];
        }
        convertValueToJson(result, indent + 1, [value objectForKey:key], key, pretty);
    }
    if (pretty) {
        [result appendString:@"\n"];
        addIdent(result, indent);
    }
    [result appendString:@"}"];
}

static void convertArrayToJson(NSMutableString *result, int indent, NSArray *value, BOOL pretty)
{
    BOOL first = YES;
    
    [result appendString:@"["];
    if (pretty) {
        [result appendString:@"\n"];
    }
    for (id arrayValue in value) {
        if (first) {
            first = NO;
        } else {
            [result appendString:@",\n"];
        }
        convertValueToJson(result, indent + 1, arrayValue, nil, pretty);
    }
    if (pretty) {
        [result appendString:@"\n"];
        addIdent(result, indent);
    }
    [result appendString:@"]"];
}

static void convertValueToJson(NSMutableString *result, int indent, id value, NSString *key, BOOL pretty)
{
    if (pretty) {
        addIdent(result, indent);
    }
    if (key) {
        [result appendString:@"\""];
        [result appendString:[key escapeQuotes]];
        [result appendString:@"\": "];
    }
    if ([value isKindOfClass:[NSString class]]) {
        [result appendString:@"\""];
        [result appendString:[value escapeQuotes]];
        [result appendString:@"\""];
    } else if ([value isKindOfClass:[NSDate class]]) {
        [result appendFormat:@"%f", [value timeIntervalSince1970] * 1000];
    } else if ([value isKindOfClass:[NSNull class]]) {
        [result appendString:@"null"];
    } else if ([value isKindOfClass:[NSDictionary class]]) {
        convertDictionaryToJson(result, indent, value, pretty);
    } else if ([value isKindOfClass:[NSArray class]]) {
        convertArrayToJson(result, indent, value, pretty);
    } else if ([value isKindOfClass:[NSNumber class]]) {
        if (strcmp([value objCType], @encode(BOOL)) == 0) {
            if ([value boolValue]) {
                [result appendString:@"true"];
            } else {
                [result appendString:@"false"];
            }
        } else {
            [result appendString:[value description]];
        }
    } else if ([value isKindOfClass:[MODObjectId class]]) {
        [result appendString:[value jsonValue]];
    } else if ([value isKindOfClass:[MODDataRegex class]]) {
        [result appendString:[value jsonValue]];
    } else if ([value isKindOfClass:[MODTimestamp class]]) {
        [result appendString:[value jsonValue]];
    } else if ([value isKindOfClass:[MODDataBinary class]]) {
        [result appendString:[value jsonValue]];
    } else if ([value isKindOfClass:[MODDataRef class]]) {
        [result appendString:[value jsonValue]];
    }
}

@implementation MODHelper

+ (NSString *)convertObjectToJson:(NSDictionary *)object pretty:(BOOL)pretty
{
    NSMutableString *result;
    
    result = [NSMutableString string];
    convertDictionaryToJson(result, 0, object, pretty);
    return result;
}

+ (NSArray *)convertForOutlineWithObjects:(NSArray *)mongoObjects
{
    NSMutableArray *result;
    
    result = [NSMutableArray arrayWithCapacity:[mongoObjects count]];
    for (NSDictionary *object in mongoObjects) {
        id idValue;
        NSString *idValueName;
        NSMutableDictionary *dict;
        
        idValue = [object objectForKey:@"_id"];
        idValueName = @"_id";
        if (!idValue) {
            idValue = [object objectForKey:@"name"];
            idValueName = @"name";
        }
        dict = [self convertForOutlineWithValue:idValue dataKey:idValueName];
        if (dict == nil) {
            dict = [NSMutableDictionary dictionary];
        }
        [dict setObject:[self convertForOutlineWithObject:object] forKey:@"child"];
        [dict setObject:[self convertObjectToJson:object pretty:YES] forKey:@"beautified"];
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
        value = [dataValue tengenString];
    } else if ([dataValue isKindOfClass:[MODDataRegex class]]) {
        type = @"Regex";
        value = [dataValue tengenString];
    } else if ([dataValue isKindOfClass:[MODTimestamp class]]) {
        type = @"Timestamp";
        value = [dataValue tengenString];
    } else if ([dataValue isKindOfClass:[MODDataBinary class]]) {
        type = @"Binary";
        value = [dataValue tengenString];
    } else if ([dataValue isKindOfClass:[MODDataRef class]]) {
        type = @"Ref";
        value = [dataValue tengenString];
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
        [result setObject:value forKey:@"value"];
        [result setObject:dataKey forKey:@"name"];
        [result setObject:type forKey:@"type"];
        //[result setObject:jsonString forKey:@"raw"];
        //[result setObject:jsonStringb forKey:@"beautified"];
        if (child) {
            [result setValue:child forKey:@"child"];
        }
    }
    return result;
}

@end
