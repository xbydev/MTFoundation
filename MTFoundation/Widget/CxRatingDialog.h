//
//  RatingDialog.h
//  MemoLite
//
//  Created by xiangbiying on 12-1-30.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define RATING_STORE @"rating_store"

@interface CxRatingDialog : NSObject <UIAlertViewDelegate> {

    UIAlertView* _dialog;

}

@property (strong,nonatomic) NSString* appID;

@property (strong,nonatomic) NSString* message;

@property (nonatomic) NSTimeInterval remindInterval;

@property (nonatomic) int remindLaunchTimes;

@property (nonatomic) BOOL internationalized;

-(BOOL) showIfNeed;

-(void)show;

@end
