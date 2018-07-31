//
//  VideoAudioEdit.h
//  MTFoundation
//
//  Created by xiangbiying on 2018/7/23.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CMTimeRange.h>
#import <AVFoundation/AVFoundation.h>
#import "MTVideoConstant.h"

@interface VideoAudioEdit : NSObject
/**
 进度block
 */
@property (nonatomic,copy)CompositionProgress progressBlock;

/**
 截取视频某时刻的画面
 
 @param videoUrl 视频地址
 @param requestedTimes cmtime 数组
 */
- (void)getThumbImageOfVideo:(NSURL *_Nonnull)videoUrl forTimes:(NSArray<NSValue *> *_Nonnull)requestedTimes complete:(CompleteBlock _Nullable )complete;


/**
 将图片合成为视频
 
 @param images 图片数组
 @param videoName 视频名字
 @param successBlcok 视频地址
 */
- (void)compositionVideoWithImage:(NSArray <UIImage *>*_Nonnull)images videoName:(NSString *_Nonnull)videoName success:(SuccessBlcok _Nullable )successBlcok;



/**
 将图片合成为视频 并加上音乐
 
 @param images 图片数组
 @param videoName 视频名字
 @param audioUrl 音频地砖
 @param successBlcok 返回视频地址
 */
- (void)compositionVideoWithImage:(NSArray <UIImage *>*_Nonnull)images videoName:(NSString *_Nonnull)videoName audio:(NSURL*_Nullable)audioUrl success:(SuccessBlcok _Nullable )successBlcok;

/**
 视频水印
 
 @param videoUrl 视频地址
 @param videoName 视频名字
 @param successBlcok 返回
 */
- (void)watermarkForVideo:(NSURL *_Nonnull)videoUrl videoName:(NSString *_Nonnull)videoName success:(SuccessBlcok _Nullable )successBlcok;



/**
 将图片与音乐组合成固定时间长度的视频
 
 @param images 图片数组
 @param videoName 视频名字
 @param audioUrl 音频地址
 @param duration 视频时长
 @param successBlcok 返回视频地址
 */

- (void)compositionVideoWithImage:(NSArray <UIImage *>*_Nonnull)images videoSize:(CGSize)videoSize imageDuration:(CGFloat)duration videoName:(NSString *_Nonnull)videoName audio:(NSURL*_Nullable)audioUrl success:(SuccessBlcok _Nullable )successBlcok;

/**
 给视频添加文字水印
 @param videoUrl 视频地址
 @param videoName 视频名字
 @param successBlcok 返回
 */
- (void)addTextWatermarks:(NSArray *)textWatermarks ForVideo:(NSURL *_Nonnull)videoUrl videoName:(NSString *_Nonnull)videoName success:(SuccessBlcok _Nullable )successBlcok;

@end
