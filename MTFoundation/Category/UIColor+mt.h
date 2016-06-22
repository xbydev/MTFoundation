//
//  UIColor+mt.h
//  MTFoundationDemo
//
//  Created by xiangbiying on 16/6/21.
//  Copyright © 2016年 xiangby. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (mt)

+(UIColor*) color255WithRed:(int)red green:(int)green blue:(int)blue alpha:(int)alpha;

+(UIColor*) colorWithHexString: (NSString *)stringToConvert;

+(UIColor*) colorWithWord:(NSString*)word;

+(UIColor*) colorWithString:(NSString *)string;

//-(NSString*) toHexString;

-(float) red;

-(float) green;

-(float) blue;

-(float) alpha;


@end
