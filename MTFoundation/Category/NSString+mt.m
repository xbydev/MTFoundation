//
//  NSString+mt.m
//  MTFoundationDemo
//
//  Created by xiangbiying on 16/6/21.
//  Copyright © 2016年 xiangby. All rights reserved.
//

#import "NSString+mt.h"
#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
#import "iMacro.h"

#import <CommonCrypto/CommonDigest.h>

@implementation NSString (mt)

+(NSString*) macAddress {
    int                    mib[6];
    size_t                len;
    char                *buf;
    unsigned char        *ptr;
    struct if_msghdr    *ifm;
    struct sockaddr_dl    *sdl;
    
    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;
    
    if ((mib[5] = if_nametoindex("en0")) == 0) {
        printf("Error: if_nametoindex error/n");
        return nil;
    }
    
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 1/n");
        return nil;
    }
    
    if ((buf = malloc(len)) == NULL) {
        printf("Could not allocate memory. error!/n");
        return nil;
    }
    
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 2");
        return nil;
    }
    
    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    
    NSString *outstring = [NSString stringWithFormat:@"%02x-%02x-%02x-%02x-%02x-%02x", *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
    free(buf);
    
    return  [outstring uppercaseString];
}

+(NSString*) URLEncodedWtihDictionary:(NSDictionary*)dictionary {
    NSMutableString* string = [[NSMutableString alloc] init];
    NSArray* keys = dictionary.allKeys;
    for (int i = 0; i < keys.count; i++) {
        NSString* key = [keys objectAtIndex:i] ;
        NSString* value = [dictionary objectForKey:key];
        key = [key URLEncodedString2];
        value = [[value description] URLEncodedString2];
        [string appendFormat:@"%@=%@", key, value];
        if (i < keys.count - 1) {
            [string appendString:@"&"];
        }
    }
    return [NSString stringWithString:string];
}

+(NSString*) stringRandom:(int)count {
    NSMutableString* mstr = [NSMutableString string];
    for (int i = 0; i < count; i++) {
        int a = 65 + 25 * RANDOM_0_1;
        [mstr appendFormat:@"%c", a];
    }
    return mstr;
}

+(NSString*) peerId {
    
    static NSString* peerId;
    
    if (!peerId) {
        NSString* sys_version = [[UIDevice currentDevice] systemVersion];
        if ([sys_version floatValue] >= 7) {
            //        NSUUID* uuid = [ASIdentifierManager sharedManager].advertisingIdentifier;
            //        return [[[uuid UUIDString] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"-"]] componentsJoinedByString:@""];
            
            NSUserDefaults* udef = [NSUserDefaults standardUserDefaults];
            peerId = [udef objectForKey:@"peerId"];
            if (!peerId) {
                NSArray* options = @[@"0",@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",
                                     @"A",@"B",@"C",@"D",@"E",@"F"];
                NSMutableString* str = [NSMutableString string];
                for (int i = 0; i < 12; i++) {
                    int index = round((options.count - 1) * RANDOM_0_1);
                    [str appendString:options[index]];
                }
                peerId = [NSString stringWithString:str];
                [udef setObject:peerId forKey:@"peerId"];
                [udef synchronize];
            }
            
        } else {
            peerId = [[[self macAddress] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"-"]] componentsJoinedByString:@""];
        }
    }
    
    return peerId;
}

+(NSString*) formateIntegerValue:(NSInteger)aIntValue{
    
    NSString *result = @"0";
    if(aIntValue < 0){
        result = @"0";
    }else if (aIntValue > 999)
    {
        result = [NSString stringWithFormat:@"%.1fk", aIntValue / 1000.0];
        
        //        if (aIntValue > 9999) {
        //            result = [NSString stringWithFormat:@"%.1fw", aIntValue / 10000.0];
        //        }
        
        if (aIntValue > 999999) {
            result = @"99w+";
        }
    }else{
        
        result = [NSString stringWithFormat:@"%ld", aIntValue];
    }
    return result;
}

- (NSString *) MD5
{
    const char *cStr = [self UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return  [output uppercaseString];
    
}

-(NSString *) URLEncodedString2 {
    NSString *result = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(__bridge CFStringRef)self,NULL, CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                                             kCFStringEncodingUTF8));
    return result;
}

-(NSString*) URLDecodedString2 {
    char words[self.length];
    int k = 0;
    
    for (int i = 0; i < self.length; i++, k++) {
        unichar ch = [self characterAtIndex:i];
        if (ch == '%') {
            NSString* s = [self substringWithRange:NSMakeRange(i+1, 2)];
            int n = [s hexIntValue];
            if (n >= 128) {
                n -= 256;
            }
            words[k] = n;
            i += 2;
        } else {
            words[k] = ch;
        }
    }
    
    words[k] = 0;
    
    return [NSString stringWithUTF8String:words];
}

-(int) hexIntValue {
    NSString* hex = [self lowercaseString];
    if ([hex hasPrefix:@"0x"]) {
        hex = [hex substringFromIndex:2];
    }
    int ret = 0;
    const char* ch = [hex UTF8String];
    int length = (int)hex.length;
    for (int i = length - 1; i >= 0; i--) {
        if (ch[i] >= '0' && ch[i] <= '9') {
            ret += (ch[i] - '0') * powf(16, (length - 1 - i));
        } else if(ch[i] >= 'a' && ch[i] <= 'f') {
            ret += (ch[i] - 'a' + 10) * powf(16, (length - 1 - i));
        }
    }
    return ret;
}

-(NSString*)capitalizedFirstLetter {
    if (self.length > 0) {
        return [[[self substringToIndex:1] uppercaseString] stringByAppendingString:
                [self substringFromIndex:1]];
    }
    return self;
}

-(BOOL) matchesWithPattern:(NSString*)pattern {
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:
                                  pattern options:0 error:nil];
    NSTextCheckingResult* ret = [regex firstMatchInString:self options:0
                                                    range:NSMakeRange(0, self.length)];
    
    return NSEqualRanges(ret.range, NSMakeRange(0, self.length));
}

-(int) charValue {
    return [self intValue];
}

-(CGSize) sizeWithFont:(UIFont*)font maxSize:(CGSize)maxSize {
    CGSize size;
    
    if (IOS_VERSION_Int < 7) {//not surport ios 6
//        size = [self sizeWithFont:font constrainedToSize:maxSize];
    } else {
        size = [self boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin attributes:
                @{NSFontAttributeName:font} context:nil].size;
    }
    
    return size;
}

-(NSString *)trim {
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end


@implementation NSString (JavaLikeStringHandle)

- (NSString *)substringWithBeginIndex:(NSInteger)beginIndex endIndex:(NSInteger)endIndex
{
    if (endIndex >= beginIndex && endIndex <= self.length) {
        return [self substringWithRange:NSMakeRange(beginIndex, endIndex - beginIndex)];
    }
    return nil;
}

- (NSString *)substringWithOutRange:(NSRange)range{
    
    if (range.location >= self.length) {
        
        return self;
    }else if (range.location + range.length > self.length){
        
        return [self substringToIndex:range.location];
    }else if (range.location < 1){
        
        return [self substringFromIndex:range.length];
    }else{
        
        NSString *subStr1 = [self substringToIndex:range.location];
        NSString *subStr2 = [self substringFromIndex:range.location + range.length];
        
        NSString *result = [NSString stringWithFormat:@"%@%@",subStr1,subStr2];
        
        return result;
    }
    
    return nil;
}

- (NSInteger)find:(NSString *)str fromIndex:(NSInteger)fromInex reverse:(BOOL)reverse{
    return [self find:str fromIndex:fromInex reverse:reverse caseSensitive:NO];
}

- (NSInteger)find:(NSString *)str fromIndex:(NSInteger)fromInex reverse:(BOOL)reverse caseSensitive:(BOOL)caseSensitive{
    if (fromInex > self.length) {
        return -1;
    }
    NSRange searchRange = reverse ? NSMakeRange(0, fromInex) : NSMakeRange(fromInex, self.length - fromInex);
    NSStringCompareOptions options = (caseSensitive ? NSLiteralSearch : NSCaseInsensitiveSearch);
    if (reverse) {
        options |= NSBackwardsSearch;
    }
    NSRange range = [self rangeOfString:str
                                options:options
                                  range:searchRange];
    return range.location == NSNotFound ? -1 : range.location;
}

- (NSInteger)find:(NSString *)str fromIndex:(NSInteger)fromInex
{
    return [self find:str fromIndex:fromInex reverse:NO];
}

- (NSInteger)find:(NSString *)str
{
    return [self find:str fromIndex:0];
}

@end
