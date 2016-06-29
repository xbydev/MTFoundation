//
//  CxFlowView.m
//  Fling
//
//  Created by xiangbiying on 15/7/23.
//  Copyright (c) 2015年 . All rights reserved.
//

#import "CxCollectionView.h"
#import "UIView+mt.h"

@implementation CxCollectionView

-(void)layoutSubviews {
    
    CGFloat pos_x = self.contentInsets.left;
    CGFloat pos_y = self.contentInsets.top;
    CGFloat height = 0;
    
    for (UIView* subview in self.subviews) {
        
        if (pos_x + [subview width] + self.padding.width > [self width] - self.contentInsets.right) {
            
            if (pos_x > self.contentInsets.left) {
                
                pos_x = self.contentInsets.left;
                pos_y += [subview height] + self.padding.height;
                
            }
            
        }
        
        subview.position = CGPointMake(pos_x, pos_y);
        
        pos_x += [subview width] + self.padding.width;
        
        height = pos_y + [subview height];
    }
    
    height += self.contentInsets.bottom;
    
    [self setHeight:height];
    
}

@end
