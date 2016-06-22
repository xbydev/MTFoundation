//
//  NSDate+mt.m
//  MTFoundationDemo
//
//  Created by xiangbiying on 16/6/21.
//  Copyright © 2016年 xiangby. All rights reserved.
//

#import "NSDate+mt.h"
#import "iMacro.h"

@implementation NSDate (mt)

+(id) dateWithYear:(int)year Month:(int)month Day:(int)day {
    return [NSDate dateWithYear:year Month:month Day:day Hour:0 Minute:0];
}

+(id) dateWithYear:(int)year Month:(int)month Day:(int)day Hour:(int)hour Minute:(int)minute {
    NSDateComponents* comp = [[NSDateComponents alloc] init];
    [comp setYear:year];
    [comp setMonth:month];
    [comp setDay:day];
    [comp setHour:hour];
    [comp setMinute:minute];
    [comp setSecond:0]; //2014.4.11
    
    NSCalendar* calendar = [NSCalendar currentCalendar];
    return [calendar dateFromComponents:comp];
}

+(id) dateWithTimestamp:(NSString*)timestamp {
    NSTimeInterval interval = [timestamp longLongValue];
    return [NSDate dateWithTimeIntervalSince1970:interval];
}

-(id) dateByAddingDays:(int)days {
    NSTimeInterval interval = 86400 * days;
    return [self dateByAddingTimeInterval:interval];
}

-(id) yesterday {
    return [self dateByAddingDays:-1];
}

-(id) tomorrow {
    return [self dateByAddingDays:1];
}

-(NSInteger) year {
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* comp = [calendar components:NSYearCalendarUnit fromDate:self];
    return comp.year;
}

-(NSInteger) month {
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* comp = [calendar components:NSMonthCalendarUnit fromDate:self];
    return comp.month;
}

-(NSInteger) day {
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* comp = [calendar components:NSDayCalendarUnit fromDate:self];
    return comp.day;
}

-(NSInteger) hour {
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* comp = [calendar components:NSHourCalendarUnit fromDate:self];
    return comp.hour;
}

-(NSInteger) minute {
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* comp = [calendar components:NSMinuteCalendarUnit fromDate:self];
    return comp.minute;
}

-(NSInteger) second {
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* comp = [calendar components:NSSecondCalendarUnit fromDate:self];
    return comp.second;
}

-(NSInteger) weekday {
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* comp = [calendar components:NSWeekdayCalendarUnit fromDate:self];
    return comp.weekday;
}

-(BOOL) isEqualToYMD:(NSDate *)date {
    //return [self year] == [date year] && [self month] == [date month] && [self day] == [date day];
    
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* comp = [calendar components:
                              NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:self];
    NSDateComponents* comp2 = [calendar components:
                               NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:date];
    
    return comp.year == comp2.year && comp.month == comp2.month && comp.day == comp2.day;
}

-(int) dayIntervalSinceDate:(NSDate *)date {
    NSTimeInterval interval = [self timeIntervalSinceDate:date];
    return interval / 86400;
}

-(NSString *) weiboTimeline {
    
    int interval = -[self timeIntervalSinceNow];
    
    if (interval <= 0) {
        
        //nothing
        
    } else if(interval < MINUTE) {
        
        return [NSString stringWithFormat:@"%d秒前", interval];
        
    } else if(interval < HOUR) {
        
        return [NSString stringWithFormat:@"%d分钟前", interval / 60];
        
    } else if(interval < DAY) {
        
        return [NSString stringWithFormat:@"今天%02zd:%02zd", [self hour], [self minute]];
        
    } else if(interval < DAY * 2) {
        
        return [NSString stringWithFormat:@"昨天%02zd:%02zd", [self hour], [self minute]];
    }
    
    NSInteger year = [self year];
    
    if (year == [[NSDate date] year]) {
        return [NSString stringWithFormat:@"%zd月%zd日 %02zd:%02zd", [self month],
                [self day], [self hour], [self minute]];
        
    } else {
        return [NSString stringWithFormat:@"%zd年%zd月%zd日 %02zd:%02zd", year, [self month],
                [self day], [self hour], [self minute]];
    }
}

-(NSString *)descriptionForYMD {
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* comp = [calendar components:
                              NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:self];
    return [NSString stringWithFormat:@"%zd-%.2zd-%.2zd",comp.year,comp.month,comp.day];
}

-(NSString *)descriptionForYMDT {
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* comp = [calendar components:
                              NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit fromDate:self];
    return [NSString stringWithFormat:@"%zd-%.2zd-%.2zd %.2zd:%.2zd",comp.year,comp.month,comp.day,comp.hour,comp.minute];
}

+ (BOOL)isCurrentDay:(NSDate *)aDate{
    if (aDate==nil) return NO;
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:[NSDate date]];
    NSDate *today = [cal dateFromComponents:components];
    components = [cal components:(NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:aDate];
    NSDate *otherDate = [cal dateFromComponents:components];
    if([today isEqualToDate:otherDate])
        return YES;
    
    return NO;
}

+(BOOL)isYestorday:(NSDate *)aDate{
    if (aDate==nil) return NO;
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *yesterdayComponents = [cal components:(NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:[[NSDate date] yesterday]];
    NSDate *today = [cal dateFromComponents:yesterdayComponents];
    NSDateComponents *components = [cal components:(NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:aDate];
    NSDate *otherDate = [cal dateFromComponents:components];
    if([today isEqualToDate:otherDate])
        return YES;
    
    return NO;
    
    
}

@end
