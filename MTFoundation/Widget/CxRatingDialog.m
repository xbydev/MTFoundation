//
//  RatingDialog.m
//  MemoLite
//
//  Created by xiangbiying on 12-1-30.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "CxRatingDialog.h"
#import "NSFileManager+mt.h"
#import "iMacro.h"

static NSMutableArray* g_ratingDialogs;

@implementation CxRatingDialog

@synthesize appID = _appID;
@synthesize message = _message;
@synthesize remindInterval = _remindInterval;
@synthesize internationalized = _internationalized;

-(BOOL) showIfNeed {
    NSDate* now = [NSDate date];
    
    NSString* rating_store = LIBRARY_PATH(RATING_STORE);
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithContentsOfFile:rating_store];
    if (dict == nil) {
        dict = [NSMutableDictionary dictionaryWithCapacity:3];
    }
    
    BOOL has_rated = [[dict objectForKey:@"has_rated"] boolValue];
    if (!has_rated) {
        if (self.remindInterval > 0) {
            NSDate* date = [dict objectForKey:@"date"];
            if (date) {
                if ([now timeIntervalSinceDate:date] >= self.remindInterval) {
                    [dict setValue:now forKey:@"date"];
                    [dict writeToFile:rating_store atomically:YES];
                    [self show];
                    return YES;
                }
            } else {
                [dict setValue:now forKey:@"date"];
                [dict writeToFile:rating_store atomically:YES];
            }
        } else if (self.remindLaunchTimes > 0) {
            int launch_times = [[dict objectForKey:@"launch_times"] intValue];
            launch_times += 1;
            if (launch_times >= self.remindLaunchTimes) {
                [dict setObject:@(0) forKey:@"launch_times"];
                [dict writeToFile:rating_store atomically:YES];
                [self show];
                return YES;
            } else {
                [dict setObject:@(launch_times) forKey:@"launch_times"];
                [dict writeToFile:rating_store atomically:YES];
            }
        }
    }

    return NO;
}

-(void)show {
    NSString* message = self.message;
    
    NSString* cancel_title = self.internationalized ? LOCAL(@"Cancel") : @"残忍拒绝";
    NSString* goahead_title = self.internationalized ? LOCAL(@"Go ahead") : @"前往评分";
    NSString* remind_title = self.internationalized ? LOCAL(@"Remind me later") : @"以后提醒";
    
    UIAlertView* dialog = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:self 
                cancelButtonTitle:cancel_title 
                otherButtonTitles:goahead_title, remind_title, nil];
    [dialog show];
    
    _dialog = dialog;
    
    if (!g_ratingDialogs) {
        g_ratingDialogs = [[NSMutableArray alloc] initWithCapacity:3];
    }
    
    [g_ratingDialogs addObject:self];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != 2) {
        
        if (buttonIndex == alertView.firstOtherButtonIndex) {
            NSString* url;
            if (IOS_VERSION_Int < 7) {
                url = [NSString stringWithFormat:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@", self.appID];
            } else {
                url = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/app/id%@", self.appID];
            }
            
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
        }
       
        NSString* rating_store = LIBRARY_PATH(RATING_STORE);
        NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithContentsOfFile:rating_store];
        if (dict == nil) {
            dict = [NSMutableDictionary dictionaryWithCapacity:5];
        }
        
        [dict setObject:@(YES) forKey:@"has_rated"];
        [dict writeToFile:rating_store atomically:YES];
        
    }
    
    [g_ratingDialogs removeObject:self];
}

-(void)dealloc {
    _dialog.delegate = nil;
}

@end
