//
//  UIView+mt.h
//  MTFoundationDemo
//
//  Created by xiangbiying on 16/6/29.
//  Copyright © 2016年 xiangby. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (mt)

@property (strong,nonatomic) id userData;

@property (nonatomic) CGSize size;

@property (nonatomic) CGPoint position;

@property (nonatomic) CGFloat centerX;

@property (nonatomic) CGFloat centerY;

+(id) viewWithNib:(NSString*)nib owner:(id)owner;

+(id) viewWithNib;

-(void) offset:(CGPoint)point;

-(void) setPosition:(CGPoint)position;

-(CGPoint) position;

-(CGPoint) boundsCenter;

-(CGFloat) left;

-(CGFloat) top;

-(CGFloat) right;

-(CGFloat) bottom;

-(CGFloat) width;

-(CGFloat) height;

-(void) setWidth:(CGFloat)width;

-(void) setHeight:(CGFloat)height;

-(void) setLeft:(CGFloat)lef;

-(void) setRight:(CGFloat)right;

-(void) setTop:(CGFloat)top;

-(void) setBottom:(CGFloat)bottom;

-(void) clearSubviews;

-(void) replaceView:(UIView*)view atIndex:(int)index;

-(void) replaceView:(UIView*)view withView:(UIView*)newView;

-(UIView*) viewAtIndex:(int)index;

-(void) removeViewAtIndex:(int)index;

-(void) transitionToAddSubview:(UIView*)view duration:(NSTimeInterval)duration;

-(void) transitionToRemoveFromSuperview:(NSTimeInterval)duration;

-(void) makeFlexibleSize;

-(BOOL) pointInsideFrame:(CGPoint)location;

-(NSInteger) indexOfView:(UIView*)view;

-(UITapGestureRecognizer*) addTapGestureRecognizer:(id)target forAction:(SEL)action;

-(UILongPressGestureRecognizer*) addLongPressGestureRecognizer:(id)target forAction:(SEL)action;

-(void) makeFrameIntegral;

-(void) layoutSubviewsInCenter:(float)margin;

-(UIImage*) snapshotImage;

-(id) findSuperViewWithClass:(Class)clazz;

-(void)giveBorderWithCornerRadious:(CGFloat)radius borderColor:(UIColor *)borderColor andBorderWidth:(CGFloat)borderWidth;

@end
