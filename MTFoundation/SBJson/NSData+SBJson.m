//
//  NSData+XL.m
//  NetworkBase
//
//  Created by xiangby on 12-8-14.
//  Copyright (c) 2012年 xiangby. All rights reserved.
//

#import "NSData+SBJson.h"
#import "SBJson.h"

@implementation NSData (json)

-(id) jsonFormat {
    SBJsonParser* parser = [[SBJsonParser alloc] init];
    return [parser objectWithData:self];
}

-(NSString*) string {
    return [[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding];
}

@end
