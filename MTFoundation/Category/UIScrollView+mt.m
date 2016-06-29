//
//  UIScrollView+mt.m
//  MTFoundationDemo
//
//  Created by xiangbiying on 16/6/29.
//  Copyright © 2016年 xiangby. All rights reserved.
//

#import "UIScrollView+mt.h"
#import "UIView+mt.h"

@implementation UIScrollView (mt)

-(void) scrollToBottom:(BOOL)animated {
    UIEdgeInsets insets = self.contentInset;
    float dist = self.contentSize.height + insets.top + insets.bottom - [self height];
    if (dist > 0) {
        [self setContentOffset:CGPointMake(0, dist) animated:animated];
    }
}

-(void) scrollToTop:(BOOL)animated {
    UIEdgeInsets insets = self.contentInset;
    [self setContentOffset:CGPointMake(0, - insets.top) animated:animated];
}

@end
