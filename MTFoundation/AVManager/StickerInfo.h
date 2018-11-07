//
//  StickerInfo.h
//  MTFoundation
//
//  Created by xiangbiying on 2018/8/11.
//

#import <Foundation/Foundation.h>

@interface StickerInfo : NSObject

@property(nonatomic, copy) UIImage* stickerImg;

@property(nonatomic, assign) CGFloat startTime;
@property(nonatomic, assign) CGFloat duration;

@property(nonatomic, assign) CGFloat startX;
@property(nonatomic, assign) CGFloat startY;
@property(nonatomic, assign) CGFloat stickerWidth;
@property(nonatomic, assign) CGFloat stickerHeight;

@property(nonatomic, assign) CGAffineTransform transform;
@property(nonatomic, assign) CATransform3D transformForComposition;

@property(nonatomic, assign) CGSize parentSize;
@property(nonatomic, assign) CGPoint centerPoint;
@property(nonatomic, assign) CGFloat rotate; //旋转的弧度值

@property(nonatomic, assign) NSInteger stickerTag;

@end
