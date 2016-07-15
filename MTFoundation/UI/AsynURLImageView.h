//
//  AsynURLImageView.h
//  MTFoundationDemo
//
//  Created by xiangbiying on 16/7/15.
//  Copyright © 2016年 xiangby. All rights reserved.
//

#import "CxURLImageView.h"

@interface AsynURLImageView : CxURLImageView

@property (assign,nonatomic) BOOL cachesLongTime;

+(NSString*) imageCachesPath;

+(void) cleanCaches;

+(void) cleanCachesIfExceedLimits;

@end
