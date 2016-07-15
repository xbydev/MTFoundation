//
//  BounceButton.m
//  MTFoundationDemo
//
//  Created by xiangbiying on 16/7/15.
//  Copyright © 2016年 xiangby. All rights reserved.
//

#import "BounceButton.h"

@implementation BounceButton

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    [UIView animateWithDuration:0.1 delay:0 options:0 animations:^{
        
        self.transform = CGAffineTransformMakeScale(1.2, 1.2);
        
    } completion:^(BOOL finished) {
        
        [UIView animateWithDuration:0.1 delay:0 options:0 animations:^{
            
            self.transform = CGAffineTransformMakeScale(0.9, 0.9);
            
        } completion:^(BOOL finished) {
            
            [UIView animateWithDuration:0.1 delay:0 options:0 animations:^{
                
                self.transform = CGAffineTransformIdentity;
                
            } completion:^(BOOL finished) {
                
                
            }];
            
        }];
        
    }];
    
    [super touchesBegan:touches withEvent:event];
}

@end
