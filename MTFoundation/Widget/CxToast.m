//
//  CxToast.m
//  common
//
//  Created by xiangbiying on 13-5-20.
//
//

#import "CxToast.h"
#import <QuartzCore/QuartzCore.h>
#import "NSObject+mt.h"

@implementation CxToast

-(void)setText:(NSString *)text {
    if (!_label) {
        _label = [[UILabel alloc] initWithFrame:self.bounds];
        _label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _label.backgroundColor = [UIColor clearColor];
        _label.textColor = [UIColor whiteColor];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.font = [UIFont systemFontOfSize:12];
        [self addSubview:_label];
    }
    _label.text = text;
}

-(NSString *)text {
    return _label.text;
}

-(void) showInView:(UIView*)view duration:(NSTimeInterval)duration {
    if (!_bgView) {
        UIView* bgview = [[UIView alloc] initWithFrame:self.bounds];
        bgview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        bgview.backgroundColor = [UIColor blackColor];
        bgview.alpha = 0.7;
        [self addSubview:bgview];
        [self sendSubviewToBack:bgview];
        _bgView = bgview;
    }
    
    self.clipsToBounds = YES;
    self.layer.cornerRadius = 5;
    
    self.alpha = 0;
    [view addSubview:self];
    
    [UIView animateWithDuration:0.25 animations:^{
        
        self.alpha = 1;
        
    } completion:^(BOOL finished) {
        if (duration > 0) {
            [self syncTaskOnMain:^{
                
                [self dismiss];
                
            } after:duration];
        }
    }];
}

-(void) dismiss {
    [UIView animateWithDuration:0.25 animations:^{
        
        self.alpha = 0;
        
    } completion:^(BOOL finished) {
        
        self.alpha = 1;
        [self removeFromSuperview];
        
    }];
}

-(CGSize)sizeThatFits:(CGSize)size {
    CGSize fit_size = [_label sizeThatFits:size];
    return CGSizeMake(fit_size.width + 10, fit_size.height + 10);
}

@end
