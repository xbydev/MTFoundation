//
//  UIGraphics+mt.h
//  MTFoundationDemo
//
//  Created by xiangbiying on 16/6/29.
//  Copyright © 2016年 xiangby. All rights reserved.
//

#import <UIKit/UIKit.h>

void CGContextRoundRectPath(CGContextRef ctx, CGRect rect, CGFloat radius);

void CGContextFillRoundRect(CGContextRef ctx, CGRect rect, CGFloat radius);

void CGContextFillToastBox(CGContextRef ctx, CGRect rect, CGFloat radius, CGPoint arrow, CGSize arrowSize);

void CGContextDrawImageAdjust(CGContextRef ctx, CGImageRef image, float x, float y);

void CGContextDrawImageAdjustInRect(CGContextRef ctx, CGImageRef image, CGRect rect);
