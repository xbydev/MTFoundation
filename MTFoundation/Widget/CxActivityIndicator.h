//
//  MyActivityIndicatorView.h
//  common
//
//  Created by xiangbiying on 12-4-25.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CxActivityIndicatorDelegate;

//enum _xlkkais {
//    MyActivityIndicatorStyleWhite,
//    MyActivityIndicatorStyleGray
//};

@interface CxActivityIndicator : UIView {
    
    NSTimer* _timer;
    
    BOOL _superviewUserInteractionEnabled;
    
    UILabel* _titleLabel;
    
    UIView* _backView;
}

@property (nonatomic) UIActivityIndicatorViewStyle style;

@property (strong,nonatomic) UIView* loadingView;

@property (nonatomic) float backgroundRadius; 

@property (nonatomic) float backgroundAlpha;

@property (nonatomic) BOOL backgroundHidden;

@property (nonatomic) BOOL frozen;

@property (nonatomic) NSTimeInterval timeout;

@property (assign,nonatomic) id<CxActivityIndicatorDelegate> delegate;

@property (copy,nonatomic) NSString* title;

@property (assign) BOOL tapToDismissEnabled;

-(void) showInView:(UIView*)view;

-(void) dismiss;

@end

@protocol CxActivityIndicatorDelegate <NSObject>

@optional
-(void) activityIndicator:(CxActivityIndicator*)view loadingTimeout:(NSTimeInterval)timeout;

-(BOOL) activityIndicatorDismissOnTap:(CxActivityIndicator*)view;

@end
