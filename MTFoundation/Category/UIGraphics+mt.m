//
//  UIGraphics+mt.m
//  MTFoundationDemo
//
//  Created by xiangbiying on 16/6/29.
//  Copyright © 2016年 xiangby. All rights reserved.
//

#import "UIGraphics+mt.h"

void CGContextRoundRectPath(CGContextRef ctx, CGRect rect, CGFloat radius) {
    CGContextBeginPath(ctx);
    
    float x = rect.origin.x;
    float y = rect.origin.y;
    float width = rect.size.width;
    float height = rect.size.height;
    
    CGContextTranslateCTM(ctx, x, y);
    
    CGContextMoveToPoint(ctx, 0, radius);
    CGContextAddArcToPoint(ctx, 0, 0, radius, 0, radius);
    CGContextAddLineToPoint(ctx, width - radius, 0);
    CGContextAddArcToPoint(ctx, width, 0, width, radius, radius);
    CGContextAddLineToPoint(ctx, width, height - radius);
    CGContextAddArcToPoint(ctx, width, height, width - radius, height, radius);
    CGContextAddLineToPoint(ctx, radius, height);
    CGContextAddArcToPoint(ctx, 0, height, 0, height - radius, radius);
    CGContextClosePath(ctx);
    
    CGContextTranslateCTM(ctx, -x, -y);
}

void CGContextFillRoundRect(CGContextRef ctx, CGRect rect, CGFloat radius) {
    CGContextRoundRectPath(ctx, rect, radius);
    CGContextFillPath(ctx);
}

void CGContextFillToastBox(CGContextRef ctx, CGRect rect, CGFloat radius, CGPoint arrow, CGSize arrowSize) {
    CGContextFillRoundRect(ctx, rect, radius);
    
    CGContextBeginPath(ctx);
    
    if (arrow.x == rect.origin.x) {
        
        CGContextMoveToPoint(ctx, arrow.x, arrow.y - arrowSize.width/2);
        CGContextAddLineToPoint(ctx, arrow.x - arrowSize.height, arrow.y);
        CGContextAddLineToPoint(ctx, arrow.x, arrow.y + arrowSize.width/2);
        
    } else if(arrow.x == rect.origin.x + rect.size.width) {
        
        CGContextMoveToPoint(ctx, arrow.x, arrow.y - arrowSize.width/2);
        CGContextAddLineToPoint(ctx, arrow.x + arrowSize.height, arrow.y);
        CGContextAddLineToPoint(ctx, arrow.x, arrow.y + arrowSize.width/2);
        
    } else if(arrow.y == rect.origin.y) {
        
        CGContextMoveToPoint(ctx, arrow.x - arrowSize.width/2, arrow.y);
        CGContextAddLineToPoint(ctx, arrow.x, arrow.y - arrowSize.height);
        CGContextAddLineToPoint(ctx, arrow.x + arrowSize.width/2, arrow.y);
        
    } else if(arrow.y == rect.origin.y + rect.size.height) {
        
        CGContextMoveToPoint(ctx, arrow.x - arrowSize.width/2, arrow.y);
        CGContextAddLineToPoint(ctx, arrow.x, arrow.y + arrowSize.height);
        CGContextAddLineToPoint(ctx, arrow.x + arrowSize.width/2, arrow.y);
        
    }
    
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);
}

void CGContextDrawImageAdjust(CGContextRef ctx, CGImageRef image, float x, float y) {
    
    CGFloat width = CGImageGetWidth(image);
    CGFloat height = CGImageGetHeight(image);
    
    CGContextDrawImageAdjustInRect(ctx, image, CGRectMake(x, y, width, height));
}

void CGContextDrawImageAdjustInRect(CGContextRef ctx, CGImageRef image, CGRect rect) {
    
    CGContextSaveGState(ctx);
    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, 0, - rect.size.height - rect.origin.y * 2);
    
    CGContextDrawImage(ctx, rect, image);
    
    CGContextRestoreGState(ctx);
}
