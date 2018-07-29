//
//  TextWaterMarkInfo.h
//  MTFoundation
//
//  Created by xiangbiying on 2018/7/24.
//

#import <Foundation/Foundation.h>

@interface TextWaterMarkInfo : NSObject

@property(nonatomic, copy) NSString* text;
@property(nonatomic, assign) NSInteger fontSize;
@property(nonatomic, assign) CGFloat startY;
@property(nonatomic, strong) UIColor* textColor;

@end
