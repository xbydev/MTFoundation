//
//  MTVideoConstant.h
//  MTFoundation
//
//  Created by xiangbiying on 2018/7/23.
//

#ifndef MTVideoConstant_h
#define MTVideoConstant_h

/**
 合成类型
 */
typedef NS_ENUM(NSInteger,CompositionType) {
    VideoToVideo = 0,//视频加视频频-视频（可细分）
    VideoToAudio,//视频加视频-音频
    VideoAudioToVideo,//视频加音频-视频
    VideoAudioToAudio,//视频加音频-音频
    AudioToAudio,//音频加音频-音频
};

/**
 合成成功block
 @param fileUrl 合成后的地址
 */
typedef void(^SuccessBlcok)(NSURL *fileUrl);


/**
 预处理成功block
 @param playItem 预处理成功
 */
typedef void(^PreSuccessBlcok)(AVPlayerItem *playItem);


/**
 预处理成功block,含有composition 和 videoComposition 信息
 */
typedef void(^PreSuccessDetailBlcok)(AVPlayerItem *playItem,AVMutableComposition *composition,AVMutableVideoComposition *videoComposition);


/**
 合成进度block
 @param progress 进度
 */
typedef void(^CompositionProgress)(CGFloat progress);


/**
 @param image 图片
 @param error 错误
 */
typedef  void(^CompleteBlock)(UIImage * _Nullable image,NSError * _Nullable error);

#endif /* MTVideoConstant_h */
