//
//  VideoEditManager.m
//  ChuangKe
//
//  Created by xiangbiying on 2018/8/14.
//  Copyright © 2018年 lelemi. All rights reserved.
//

#import "VideoEditManager.h"
//#import <MTFoundation/SelectAssetInfo.h>
#import "SelectAssetInfo.h"
#import "StickerInfo.h"

@interface VideoEditManager()

@property(nonatomic, strong, readwrite) AVPlayerItem *currentPlayerItem;
@property(nonatomic, strong, readwrite) AVMutableComposition *compositon;
@property(nonatomic, strong, readwrite) AVMutableVideoComposition *videoCompositon;

@end

@implementation VideoEditManager

+ (instancetype)shareVideoEidtManager{
    static VideoEditManager *videoEditManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!videoEditManager) {
            videoEditManager = [[VideoEditManager alloc] init];
            NSString *cache=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
            videoEditManager.compressedVideoDir = [NSString stringWithFormat:@"%@/compressedVideoDir",cache];
        }
    });
    return videoEditManager;
}

- (CALayer *)builidStickerLayerWithInfo:(StickerInfo *)info destViewSize:(CGSize)destSize{
    CALayer *overlayLayer = [CALayer layer];
    [overlayLayer setContents:(id)[info.stickerImg CGImage]];
    
    //    if (videoSize.width > 0 && info.parentSize.width > 0) {
    //        CGFloat centerX = videoSize.width * info.centerPoint.x / info.parentSize.width;
    //        CGFloat centerY = videoSize.height * info.centerPoint.y / info.parentSize.height;
    //        CGFloat width = videoSize.width * info.stickerWidth / info.parentSize.width;
    //        overlayLayer.frame = CGRectMake(centerX - width/2, centerY - width/2, width, width);
    //    }else{
    //        overlayLayer.frame = CGRectZero;
    //    }
    
    CGSize size1 = destSize;
    CGSize size2 = info.parentSize;
    NSLog(@"the size1 is %@",NSStringFromCGSize(size1));
    NSLog(@"the size2 is %@",NSStringFromCGSize(size2));
    
    overlayLayer.frame = CGRectMake(info.startX, info.startY, info.stickerWidth, info.stickerHeight);
    overlayLayer.affineTransform = info.transform;
    [overlayLayer setMasksToBounds:YES];
    
    
    //    CABasicAnimation *animation =
    //    [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    //    animation.duration = info.duration;
    //    animation.repeatCount = 0;
    //    //    animation.autoreverses=YES;
    //    // rotate from 0 to 360
    //    animation.fromValue=[NSNumber numberWithFloat:0];
    //    animation.toValue=[NSNumber numberWithFloat:info.rotate];
    //    animation.beginTime = info.startTime;
    //    [animation setRemovedOnCompletion:NO];
    //    animation.fillMode = kCAFillModeForwards;
    //    [overlayLayer addAnimation:animation forKey:@"rotation"];
    
    CABasicAnimation *animation1 = [CABasicAnimation animationWithKeyPath:@"opacity"];
    [animation1 setDuration:0];
    [animation1 setFromValue:[NSNumber numberWithFloat:1.0]];
    [animation1 setToValue:[NSNumber numberWithFloat:0.0]];
    [animation1 setBeginTime:info.startTime + info.duration];
    [animation1 setRemovedOnCompletion:NO];
    [animation1 setFillMode:kCAFillModeForwards];
    [overlayLayer addAnimation:animation1 forKey:@"animateOpacity"];
    
    return overlayLayer;
}

- (CALayer *)builidStickerLayerWithInfo:(StickerInfo *)info{
    CALayer *overlayLayer = [CALayer layer];
    [overlayLayer setContents:(id)[info.stickerImg CGImage]];
    
    //    if (videoSize.width > 0 && info.parentSize.width > 0) {
    //        CGFloat centerX = videoSize.width * info.centerPoint.x / info.parentSize.width;
    //        CGFloat centerY = videoSize.height * info.centerPoint.y / info.parentSize.height;
    //        CGFloat width = videoSize.width * info.stickerWidth / info.parentSize.width;
    //        overlayLayer.frame = CGRectMake(centerX - width/2, centerY - width/2, width, width);
    //    }else{
    //        overlayLayer.frame = CGRectZero;
    //    }
    overlayLayer.frame = CGRectMake(info.startX, info.startY, info.stickerWidth, info.stickerHeight);
    overlayLayer.affineTransform = info.transform;
    [overlayLayer setMasksToBounds:YES];
    
    
    //    CABasicAnimation *animation =
    //    [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    //    animation.duration = info.duration;
    //    animation.repeatCount = 0;
    //    //    animation.autoreverses=YES;
    //    // rotate from 0 to 360
    //    animation.fromValue=[NSNumber numberWithFloat:0];
    //    animation.toValue=[NSNumber numberWithFloat:info.rotate];
    //    animation.beginTime = info.startTime;
    //    [animation setRemovedOnCompletion:NO];
    //    animation.fillMode = kCAFillModeForwards;
    //    [overlayLayer addAnimation:animation forKey:@"rotation"];
    
    CABasicAnimation *animation1 = [CABasicAnimation animationWithKeyPath:@"opacity"];
    [animation1 setDuration:0];
    [animation1 setFromValue:[NSNumber numberWithFloat:1.0]];
    [animation1 setToValue:[NSNumber numberWithFloat:0.0]];
    [animation1 setBeginTime:info.startTime + info.duration];
    [animation1 setRemovedOnCompletion:NO];
    [animation1 setFillMode:kCAFillModeForwards];
    [overlayLayer addAnimation:animation1 forKey:@"animateOpacity"];
    
    return overlayLayer;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        _selectPHAssets = [NSMutableArray new];
        _stickerInfosArr = [NSMutableArray new];
        _audioInfosArr = [NSMutableArray new];
    }
    return self;
}

- (void)addSelectAssetInfo:(SelectAssetInfo *)info{
    [_selectPHAssets addObject:info];
}

- (void)clearSelectedAsset{
    [_selectPHAssets removeAllObjects];
}

- (void)resetEditManager{
    [self clearSelectedAsset];
    _selectPHAssets = [NSMutableArray new];
    _stickerInfosArr = [NSMutableArray new];
    _audioInfosArr = [NSMutableArray new];
    
    _startSubtitleInfo = nil;
    _endSubtitleInfo = nil;
    _currentPlayerItem = nil;
}

- (void)updateCurrentPlayerItem:(AVPlayerItem *)playerItem{
    self.currentPlayerItem = playerItem;
}

- (void)updateComposition:(AVMutableComposition *)compositon videoCompositon:(AVMutableVideoComposition *)videoCompositon{
    self.compositon = compositon;
    self.videoCompositon = videoCompositon;
}

@end
