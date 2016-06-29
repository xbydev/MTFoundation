//
//  NTHttpRequest.h
//  MTFoundationDemo
//
//  Created by xiangbiying on 16/6/29.
//  Copyright © 2016年 xiangby. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NTHttpRequest : NSMutableURLRequest

+(id) requestWithURL:(NSString*)url params:(NSDictionary*)params;

+(id) requestWithURL:(NSString*)url query:(NSString*)query;

+(id) postWithURL:(NSString*)url params:(NSDictionary*)params;

+(id) postWithURL:(NSString*)url query:(NSString*)query;

+(id) postWithURL:(NSString*)url jsonObject:(id)object;

@end
