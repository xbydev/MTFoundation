//
//  NSDate+mt.h
//  MTFoundationDemo
//
//  Created by xiangbiying on 16/6/21.
//  Copyright © 2016年 xiangby. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (mt)

+(id) dateWithYear:(int)year Month:(int)month Day:(int)day;

+(id) dateWithYear:(int)year Month:(int)month Day:(int)day Hour:(int)hour Minute:(int)minute;

+(id) dateWithTimestamp:(NSString*)timestamp;

-(id) dateByAddingDays:(int)days;

-(id) yesterday;

-(id) tomorrow;

-(NSInteger) year;

-(NSInteger) month;

-(NSInteger) day;

-(NSInteger) hour;

-(NSInteger) minute;

-(NSInteger) second;

-(NSInteger) weekday;

-(BOOL) isEqualToYMD:(NSDate *)date;

-(int) dayIntervalSinceDate:(NSDate *)date;

-(NSString *) weiboTimeline;

-(NSString *)descriptionForYMD;

-(NSString *)descriptionForYMDT;

+(BOOL)isCurrentDay:(NSDate *)aDate;

+(BOOL)isYestorday:(NSDate *)aDate;

@end
