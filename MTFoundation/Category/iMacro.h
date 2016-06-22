//
//  iMacro.h
//  MTFoundationDemo
//
//  Created by xiangbiying on 16/6/21.
//  Copyright © 2016年 xiangby. All rights reserved.
//

#ifndef iMacro_h
#define iMacro_h

#pragma mark time 
#define MINUTE 60
#define TENMINUTES (10 * MINUTE)
#define HOUR (60 * MINUTE)
#define DAY (24 * HOUR)
#define WEEK (7 * DAY)
#define MONTH (31 * DAY)   //2013.10.31
#define YEAR (12 * MONTH)   //2013.10.31

#pragma mark App Information
#define APP_NAME [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]

#define APP_VERSION_STRING [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]

#define APP_VERSION [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]

#pragma mark DEVICE Information
#define SCREEN_RECT [UIScreen mainScreen].bounds

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width

#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#define DEVICE_IS_IPAD  ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)

#define DEVICE_IS_IPHONE  ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)

#define DEVICE_IS_IPHONE4 ([UIScreen mainScreen].bounds.size.height < 568)

#define DEVICE_IS_IPHONE5 ([UIScreen mainScreen].bounds.size.height >= 568)

#define DEVICE_IS_IPHONE6 ([UIScreen mainScreen].bounds.size.height >= 667)

#define DEVICE_IS_PORTRAIT device_is_portrait()

#define DEVICE_IS_LANDSCAPE device_is_landscape()

#define DEVICE_IS_RETINA ([[UIScreen mainScreen] scale] > 1)

#define DEVICE_IS_SIMULATOR (NSNotFound != [[[UIDevice currentDevice] model] rangeOfString:@"Simulator"].location)

#define IOS_VERSION [[UIDevice currentDevice] systemVersion]

#define IOS7 [[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0

#define iOS6 ((([[UIDevice currentDevice].systemVersion intValue] >= 6) && ([[UIDevice currentDevice].systemVersion intValue] < 7)) ? YES : NO )

#define iOS5 ((([[UIDevice currentDevice].systemVersion intValue] >= 5) && ([[UIDevice currentDevice].systemVersion intValue] < 6)) ? YES : NO )

#define IOS_VERSION_Int [IOS_VERSION intValue]

#define CURRENT_INTERFACE_ORIEN [UIApplication sharedApplication].keyWindow.rootViewController.interfaceOrientation


#pragma mark UIColor
#define UIColorFromHexWithAlpha(hexValue, a) [UIColor colorWithRed:((float)((hexValue & 0xFF0000) >> 16))/255.0 green:((float)((hexValue & 0xFF00) >> 8))/255.0 blue:((float)(hexValue & 0xFF))/255.0 alpha:a]

#define UIColorFromHex(hexValue) UIColorFromHexWithAlpha(hexValue,1.0)

#define UIColorFromRGBA(r, g, b, a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]

#define UIColorFromRGB(r, g, b) UIColorFromRGBA(r,g,b,1.0)


#pragma mark other
#define RANDOM_0_1 (arc4random() / (float)0x100000000)

#endif /* iMacro_h */
