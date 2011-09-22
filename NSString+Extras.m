//
//  NSString+Extras.m
//  MongoHub
//
//  Created by Syd on 10-4-28.
//  Copyright 2010 ThePeppersStudio.COM. All rights reserved.
//

#import "NSString+Extras.h"


@implementation NSString (Extras)

+ (NSString*)stringFromResource:(NSString*)resourceName
{
    NSString *path = [[NSBundle mainBundle] pathForResource:resourceName ofType:nil];
    return [NSString stringWithContentsOfFile:path usedEncoding:nil error:nil];
}

# pragma Comparing

- (NSString *)escapeQuotes
{
    NSMutableString *result;
    NSUInteger ii = 0, count = [self length];
    
    result = [self mutableCopy];
    while (ii < count) {
        if ([result characterAtIndex:ii] == '"' || [result characterAtIndex:ii] == '\\') {
            [result insertString:@"\\" atIndex:ii];
            ii++;
            count++;
        } else if ([result characterAtIndex:ii] == '\n') {
            [result deleteCharactersInRange:NSMakeRange(ii, 1)];
            [result insertString:@"\\n" atIndex:ii];
            ii++;
            count++;
        } else if ([result characterAtIndex:ii] == '\r') {
            [result deleteCharactersInRange:NSMakeRange(ii, 1)];
            [result insertString:@"\\r" atIndex:ii];
            ii++;
            count++;
        } else if ([result characterAtIndex:ii] == '\t') {
            [result deleteCharactersInRange:NSMakeRange(ii, 1)];
            [result insertString:@"\\t" atIndex:ii];
            ii++;
            count++;
        }
        ii++;
    }
    return [result autorelease];
}

- (BOOL)startsWithString:(NSString*)otherString
{
    return [self rangeOfString:otherString].location == 0;
}

- (BOOL)endsWithString:(NSString*)otherString
{
    return [self rangeOfString:otherString].location == [self length]-[otherString length];
}

- (BOOL)isPresent
{
    return ![self isEqualToString:@""];
}

- (NSComparisonResult)compareCaseInsensitive:(NSString*)other
{
    NSString *selfString = [self lowercaseString];
    NSString *otherString = [other lowercaseString];
    return [selfString compare:otherString];
}

- (NSString*)stringByPercentEscapingCharacters:(NSString*)characters
{
    return [(NSString*)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self, NULL, (CFStringRef)characters, kCFStringEncodingUTF8) autorelease];
}

- (NSString*)stringByEscapingURL
{
    return [self stringByPercentEscapingCharacters:@";/?:@&=+$,"];    
}

- (NSString*)stringByUnescapingURL
{
    return [(NSString*)CFURLCreateStringByReplacingPercentEscapes(NULL, (CFStringRef)self, CFSTR("")) autorelease];
}

- (BOOL)containsString:(NSString *)aString
{
    return [self containsString:aString ignoringCase:NO];
}

- (BOOL)containsString:(NSString *)aString ignoringCase:(BOOL)flag
{
    unsigned mask = (flag ? NSCaseInsensitiveSearch : 0);
    return [self rangeOfString:aString options:mask].length > 0;
}

- (int)countSubstring:(NSString *)aString ignoringCase:(BOOL)flag
{
    unsigned mask = (flag ? NSCaseInsensitiveSearch : 0);
    return [self rangeOfString:aString options:mask].length;
}

- (NSString *)stringByTrimmingWhitespace
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

+ (NSNull *)nullValue
{
    return [NSNull null];
}

+ (NSString*)UUIDString
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return [(NSString *)string autorelease];
}


@end
