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
@property(nonatomic, assign) CGSize parentSize;
@property(nonatomic, assign) CGPoint centerPoint;
@property(nonatomic, assign) CGFloat rotate; //旋转的弧度值
@property(nonatomic, assign) CGFloat stickerWidth;
@property(nonatomic, assign) CGFloat duration;

@end
