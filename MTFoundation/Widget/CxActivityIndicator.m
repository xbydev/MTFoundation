//
//  MyActivityIndicatorView.m
//  common
//
//  Created by xiangbiying on 12-4-25.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "CxActivityIndicator.h"
#import "UIView+mt.h"
#import "iMacro.h"
#import "UIGraphics+mt.h"

@interface CxActivityIndicator ()

-(void) _init;

-(void) dismissIfTimeout;

@end

@implementation CxActivityIndicator

@synthesize style = _style;
@synthesize loadingView = _loadingView;
@synthesize frozen = _frozen;
@synthesize timeout = _timeout;
@synthesize delegate = _delegate;

@synthesize backgroundRadius = _backgroundRadius;
@synthesize backgroundAlpha = _backgroundAlpha;
@synthesize backgroundHidden = _backgroundHidden;

-(id)init {
    if (self = [super init]) {
        [self _init];
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self _init];
    }
    return self;
}

-(void)_init {
    self.backgroundColor = [UIColor clearColor];
    self.style = UIActivityIndicatorViewStyleWhite;
    self.backgroundRadius = 10;
    self.backgroundAlpha = 0.7;
}

-(void) showInView:(UIView*)view {
    
    if (!_loadingView) {
//        UIActivityIndicatorViewStyle style;
//        if (self.style == MyActivityIndicatorStyleGray) {
//            style = UIActivityIndicatorViewStyleWhite;
//        } else {
//            style = UIActivityIndicatorViewStyleGray;
//        }
        UIView* loading_view = [[UIActivityIndicatorView alloc]
                                initWithActivityIndicatorStyle:self.style];
        self.loadingView = loading_view; 
    }
    
    if ([_loadingView isKindOfClass:[UIActivityIndicatorView class]]) {
        UIActivityIndicatorView* loading_view = (UIActivityIndicatorView*)_loadingView;
        [loading_view startAnimating];
    }
    
    if (_titleLabel) {
        float offy = ([self height] - [_loadingView height] - [_titleLabel height]) / 2;
        _loadingView.position = CGPointMake(([self width] - [_loadingView width]) / 2, offy);
        _titleLabel.position = CGPointMake(0, offy + [_loadingView height]);
    } else {
        _loadingView.center = [self boundsCenter];
    }
    
    if (_frozen) {
        _superviewUserInteractionEnabled = view.userInteractionEnabled;
        view.userInteractionEnabled = NO;
    }
    
    self.center = CGPointMake([view width]/2, [view height]/2);
    [view transitionToAddSubview:self duration:0.3];
    
    if (_tapToDismissEnabled) {
        _backView = [[UIView alloc] initWithFrame:view.bounds];
        _backView.backgroundColor = [UIColor clearColor];
        [_backView addTapGestureRecognizer:self forAction:@selector(tapToDismiss)];
        [view insertSubview:_backView belowSubview:self];
    }
    
    [_timer invalidate];
    if (_timeout > 0) {
        NSTimer* timer = [NSTimer scheduledTimerWithTimeInterval:_timeout target:self 
                         selector:@selector(dismissIfTimeout) userInfo:nil repeats:NO];
        SET_PROPERTY(_timer, timer);
    }
}

-(void)dismiss { 
    if (_frozen) {
        self.superview.userInteractionEnabled = _superviewUserInteractionEnabled;
    }
    
    [self transitionToRemoveFromSuperview:0.3];
    
    [_backView removeFromSuperview];
    
    [_timer invalidate];
    RNIL(_timer);
}

-(void)setLoadingView:(UIView *)view {
    SET_PROPERTY(_loadingView, view);
    view.center = [self boundsCenter];
    [self addSubview:view];
}

-(void)setTitle:(NSString *)title {
    if (title) {
        if (!_titleLabel) {
            _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [self width], 32)];
            _titleLabel.backgroundColor = [UIColor clearColor];
            _titleLabel.font = [UIFont systemFontOfSize:12];
            _titleLabel.minimumFontSize = 1;
            _titleLabel.textAlignment = UITextAlignmentCenter;
            if (self.style == UIActivityIndicatorViewStyleGray) {
                _titleLabel.textColor = [UIColor grayColor];
            } else {
                _titleLabel.textColor = [UIColor whiteColor];
            }
            [self addSubview:_titleLabel];
        }
        _titleLabel.text = title;
    } else {
        [_titleLabel removeFromSuperview];
        _titleLabel = nil;
    }
}

-(NSString *)title {
    return _titleLabel.text;
}

- (void)drawRect:(CGRect)rect {
    if (!_backgroundHidden) {
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextSaveGState(ctx);
        CGContextSetAlpha(ctx, self.backgroundAlpha);
        if (self.style == UIActivityIndicatorViewStyleGray) {
            CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
        } else {
            CGContextSetFillColorWithColor(ctx, [UIColor blackColor].CGColor);
        }
        CGContextFillRoundRect(ctx, self.bounds, self.backgroundRadius);
        CGContextRestoreGState(ctx);
    }
}

-(void)dismissIfTimeout {
    [self dismiss];
    if ([_delegate respondsToSelector:@selector(activityIndicator:loadingTimeout:)]) {
        [_delegate activityIndicator:self loadingTimeout:_timeout];
    }
}

-(void) tapToDismiss {
    BOOL dimissed = YES;
    if ([_delegate respondsToSelector:@selector(activityIndicatorDismissOnTap:)]) {
        dimissed = [_delegate activityIndicatorDismissOnTap:self];
    }
    if (dimissed) {
        [self dismiss];
    }
}

-(void)dealloc {
    self.delegate = nil;
    [_timer invalidate];
}


@end
