//
//  NTHttpRequest.m
//  MTFoundationDemo
//
//  Created by xiangbiying on 16/6/29.
//  Copyright © 2016年 xiangby. All rights reserved.
//

#import "NTHttpRequest.h"
#import "NSString+mt.h"
#import "SBJsonWriter.h"

@implementation NTHttpRequest

+(id) requestWithURL:(NSString*)url params:(NSDictionary*)params {
    NSString* query = [NSString URLEncodedWtihDictionary:params];
    return [self requestWithURL:url query:query];
}

+(id) requestWithURL:(NSString*)url query:(NSString*)query {
    if (query && ![query isEqual:@""]) {
        if ([url rangeOfString:@"?"].location != NSNotFound) {
            url = [NSString stringWithFormat:@"%@&%@", url, query];
        } else {
            url = [NSString stringWithFormat:@"%@?%@", url, query];
        }
    }
    
    NTHttpRequest* req = [[self alloc] initWithURL:[NSURL URLWithString:url]];
    [req setHTTPMethod:@"GET"];
    return req;
}

+(id) postWithURL:(NSString*)url params:(NSDictionary*)params {
    NSString* query = [NSString URLEncodedWtihDictionary:params];
    return [self postWithURL:url query:query];
}

+(id) postWithURL:(NSString*)url query:(NSString*)query {
    NTHttpRequest* req = [[self alloc] initWithURL:[NSURL URLWithString:url]];
    [req setHTTPMethod:@"POST"];
    [req setHTTPBody:[query dataUsingEncoding:NSUTF8StringEncoding]];
    return req;
}

+(id)postWithURL:(NSString *)url jsonObject:(id)object {
    NTHttpRequest* req = [[self alloc] initWithURL:[NSURL URLWithString:url]];
    [req setHTTPMethod:@"POST"];
    
    SBJsonWriter *writer = [[SBJsonWriter alloc] init];
    NSData* data = [writer dataWithObject:object];
    [req setHTTPBody:data];
    return req;
}

@end
