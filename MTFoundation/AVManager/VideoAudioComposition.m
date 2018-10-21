//
//  VideoAudioComposition.m
//  MTFoundation
//
//  Created by xiangbiying on 2018/7/24.
//

#import "VideoAudioComposition.h"
#import "MTFileManager.h"
#import "SelectAssetInfo.h"
#import "RecordAudioInfo.h"

#define degreesToRadians( degrees ) ( ( degrees ) / 180.0 * M_PI )

static NSString *const kCompositionPath = @"GLComposition";

@implementation VideoAudioComposition


- (NSString *)compositionPath
{
    return [MTFileManager createCacheFileDir:kCompositionPath];
}

- (void)compositionVideoUrl:(NSURL *)videoUrl videoTimeRange:(CMTimeRange)videoTimeRange audioUrl:(NSURL *)audioUrl audioTimeRange:(CMTimeRange)audioTimeRange success:(SuccessBlcok)successBlcok
{
    NSCAssert(_compositionName.length > 0, @"请输入转换后的名字");
    NSString *outPutFilePath = [[self compositionPath] stringByAppendingPathComponent:_compositionName];
    
    //存在该文件
    if ([MTFileManager fileExistsAtPath:outPutFilePath]) {
        [MTFileManager clearCachesWithFilePath:outPutFilePath];
    }
    
    // 创建可变的音视频组合
    AVMutableComposition *composition = [AVMutableComposition composition];
    // 音频通道
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    // 视频通道 枚举 kCMPersistentTrackID_Invalid = 0
    AVMutableCompositionTrack *videoTrack = nil;
    
    // 视频采集
    AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    
    videoTimeRange = [self fitTimeRange:videoTimeRange avUrlAsset:videoAsset];
    
    // 音频采集
    AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:audioUrl options:nil];
    
    audioTimeRange = [self fitTimeRange:audioTimeRange avUrlAsset:audioAsset];
    
    
    if (CMTimeCompare(videoTimeRange.duration,audioTimeRange.duration))
    {
        audioTimeRange.duration = videoTimeRange.duration;
    }
    //在测试中发现 VideoAudioToAudio如果不用 视频通道  就不要去创建 否则会失败
    videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];

    // 音频采集通道
    AVAssetTrack *audioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    // 加入合成轨道之中
    [audioTrack insertTimeRange:audioTimeRange ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];
    
    //  视频采集通道
    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    //  把采集轨道数据加入到可变轨道之中
    [videoTrack insertTimeRange:videoTimeRange ofTrack:videoAssetTrack atTime:kCMTimeZero error:nil];
    
    [self composition:composition storePath:outPutFilePath success:successBlcok];
}

- (void)speedVideo:(NSURL *)videoUrl withSpeed:(CGFloat)speed success:(SuccessBlcok)successBlcok{
    CGFloat fastRate = speed; //比如3.0倍加速
    
    AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    CGFloat timeScale = videoAsset.duration.timescale;
    
    // 这里的startTime和endTime都是秒，需要乘以timeScale来组成CMTime
    CMTime startTime = CMTimeMake(0 * timeScale, timeScale);
    CMTime duration = CMTimeMake(videoAsset.duration.value * timeScale, timeScale);
    CMTimeRange fastRange = CMTimeRangeMake(startTime, duration);
    CMTime scaledDuration = CMTimeMake(duration.value / fastRate, timeScale);
    
    AVAssetTrack *assetVideoTrack = nil;
    AVAssetTrack *assetAudioTrack = nil;
    // Check if the asset contains video and audio tracks
    if ([[videoAsset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        assetVideoTrack = [videoAsset tracksWithMediaType:AVMediaTypeVideo][0];
        
        AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        if (assetVideoTrack) {
            // 把采集轨道数据加入到可变轨道之中
            [videoTrack insertTimeRange:fastRange ofTrack:assetVideoTrack atTime:kCMTimeZero error:nil];
        }
    }
    
    if ([[videoAsset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
        assetAudioTrack = [videoAsset tracksWithMediaType:AVMediaTypeAudio][0];
        
        // 音频通道
        AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        if (assetAudioTrack) {
            // 加入合成轨道之中
            [audioTrack insertTimeRange:fastRange ofTrack:assetAudioTrack atTime:kCMTimeZero error:nil];
        }
    }
    
    // 处理视频轨
    [[composition tracksWithMediaType:AVMediaTypeVideo] enumerateObjectsUsingBlock:^(AVMutableCompositionTrack * _Nonnull videoTrack, NSUInteger idx, BOOL * _Nonnull stop) {
        [videoTrack scaleTimeRange:fastRange toDuration:scaledDuration];
    }];
    
    // 处理音频轨
    [[composition tracksWithMediaType:AVMediaTypeAudio] enumerateObjectsUsingBlock:^(AVMutableCompositionTrack * _Nonnull audioTrack, NSUInteger idx, BOOL * _Nonnull stop) {
        // 这里需要注意，如果音频和视频的timescale不一致，那么这里需要重新计算音频需要裁剪的区间，否则会出现音频视频裁剪区间错位的问题
//        [audioTrack removeTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(2, 1))]; //消音
        //        [audioTrack insertEmptyTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(5, timeScale))];
                [audioTrack scaleTimeRange:fastRange toDuration:scaledDuration];
    }];
    
    NSString *outPutFilePath = [[self compositionPath] stringByAppendingPathComponent:@"abc.mp4"];
    //存在该文件
    if ([MTFileManager fileExistsAtPath:outPutFilePath]) {
        [MTFileManager clearCachesWithFilePath:outPutFilePath];
    }
    [self composition:composition storePath:outPutFilePath success:successBlcok];
}

- (void)preSpeedVideo:(NSURL *)videoUrl withSpeed:(CGFloat)speed success:(PreSuccessBlcok)successBlcok{
    CGFloat fastRate = speed; //比如3.0倍加速
    AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    CGFloat timeScale = videoAsset.duration.timescale;
    // 这里的startTime和endTime都是秒，需要乘以timeScale来组成CMTime
    CMTime startTime = CMTimeMake(0 * timeScale, timeScale);
    CMTime duration = CMTimeMake(videoAsset.duration.value * timeScale, timeScale);
    CMTimeRange fastRange = CMTimeRangeMake(startTime, duration);
    CMTime scaledDuration = CMTimeMake(duration.value / fastRate, timeScale);
    
    AVAssetTrack *assetVideoTrack = nil;
    AVAssetTrack *assetAudioTrack = nil;
    // Check if the asset contains video and audio tracks
    if ([[videoAsset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        assetVideoTrack = [videoAsset tracksWithMediaType:AVMediaTypeVideo][0];
        AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        if (assetVideoTrack) {
            // 把采集轨道数据加入到可变轨道之中
            [videoTrack insertTimeRange:fastRange ofTrack:assetVideoTrack atTime:kCMTimeZero error:nil];
        }
    }
    
    if ([[videoAsset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
        assetAudioTrack = [videoAsset tracksWithMediaType:AVMediaTypeAudio][0];
        // 音频通道
        AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        if (assetAudioTrack) {
            // 加入合成轨道之中
            [audioTrack insertTimeRange:fastRange ofTrack:assetAudioTrack atTime:kCMTimeZero error:nil];
        }
    }
    
    // 处理视频轨
    [[composition tracksWithMediaType:AVMediaTypeVideo] enumerateObjectsUsingBlock:^(AVMutableCompositionTrack * _Nonnull videoTrack, NSUInteger idx, BOOL * _Nonnull stop) {
        [videoTrack scaleTimeRange:fastRange toDuration:scaledDuration];
    }];
    
    // 处理音频轨
    [[composition tracksWithMediaType:AVMediaTypeAudio] enumerateObjectsUsingBlock:^(AVMutableCompositionTrack * _Nonnull audioTrack, NSUInteger idx, BOOL * _Nonnull stop) {
        // 这里需要注意，如果音频和视频的timescale不一致，那么这里需要重新计算音频需要裁剪的区间，否则会出现音频视频裁剪区间错位的问题
        //        [audioTrack removeTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(2, 1))]; //消音
        //        [audioTrack insertEmptyTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(5, timeScale))];
        [audioTrack scaleTimeRange:fastRange toDuration:scaledDuration];
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // 调用播放方法
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:composition];
//        playerItem.audioMix = mutableAudioMix;
        successBlcok(playerItem);
    });
}

- (void)roateVideo:(NSURL *)videoUrl withDegree:(NSInteger)degree isFirstRotate:(BOOL)isFirst success:(SuccessBlcok)successBlcok{
    AVMutableVideoCompositionInstruction *instruction = nil;
    AVMutableVideoCompositionLayerInstruction *layerInstruction = nil;
    CGAffineTransform t1;
    CGAffineTransform t2;
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    
    AVAssetTrack *assetVideoTrack = nil;
    AVAssetTrack *assetAudioTrack = nil;
    // Check if the asset contains video and audio tracks
    if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        assetVideoTrack = [asset tracksWithMediaType:AVMediaTypeVideo][0];
    }
    if ([[asset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
        assetAudioTrack = [asset tracksWithMediaType:AVMediaTypeAudio][0];
    }
    
    CMTime insertionPoint = kCMTimeZero;
    NSError *error = nil;
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    // Insert the video and audio tracks from AVAsset
    if (assetVideoTrack != nil) {
        AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:assetVideoTrack atTime:insertionPoint error:&error];
    }
    if (assetAudioTrack != nil) {
        AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:assetAudioTrack atTime:insertionPoint error:&error];
    }
    
     AVMutableVideoComposition *mutableVideoComposition = [AVMutableVideoComposition videoComposition];

    if (degree == 90) {
        if (isFirst) {
            t1 = CGAffineTransformMakeTranslation(assetVideoTrack.naturalSize.width, assetVideoTrack.naturalSize.height);
            t2 = CGAffineTransformRotate(t1,M_PI);
            mutableVideoComposition.renderSize = CGSizeMake(assetVideoTrack.naturalSize.width,assetVideoTrack.naturalSize.height);
        }else{
            t1 = CGAffineTransformMakeTranslation(assetVideoTrack.naturalSize.height,0.0);
            t2 = CGAffineTransformRotate(t1,M_PI_2);
            mutableVideoComposition.renderSize = CGSizeMake(assetVideoTrack.naturalSize.height,assetVideoTrack.naturalSize.width);
        }
    }else if (degree == 180){
        t1 = CGAffineTransformMakeTranslation(assetVideoTrack.naturalSize.width, assetVideoTrack.naturalSize.height);
        t2 = CGAffineTransformRotate(t1,M_PI);
        mutableVideoComposition.renderSize = CGSizeMake(assetVideoTrack.naturalSize.width,assetVideoTrack.naturalSize.height);
    }else if (degree == 270){
        t1 = CGAffineTransformMakeTranslation(0.0, assetVideoTrack.naturalSize.width);
        t2 = CGAffineTransformRotate(t1,M_PI_2*3.0);
        mutableVideoComposition.renderSize = CGSizeMake(assetVideoTrack.naturalSize.height,assetVideoTrack.naturalSize.width);
    }else{
        t1 = CGAffineTransformMakeTranslation(0.0, 0);
        t2 = CGAffineTransformRotate(t1,M_PI_2*4.0);
        mutableVideoComposition.renderSize = CGSizeMake(assetVideoTrack.naturalSize.width,assetVideoTrack.naturalSize.height);
    }

    mutableVideoComposition.frameDuration = CMTimeMake(1, 30);
    
    // The rotate transform is set on a layer instruction
    instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [composition duration]);
    layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:(composition.tracks)[0]];
    [layerInstruction setTransform:t2 atTime:kCMTimeZero];
    
    instruction.layerInstructions = @[layerInstruction];
    mutableVideoComposition.instructions = @[instruction];
    
    NSString *outPutFilePath = [[self compositionPath] stringByAppendingPathComponent:self.compositionName];
    //存在该文件
    if ([MTFileManager fileExistsAtPath:outPutFilePath]) {
        [MTFileManager clearCachesWithFilePath:outPutFilePath];
    }
    [self composition:composition videoCompositon:mutableVideoComposition audioMix:nil storePath:outPutFilePath success:successBlcok];
}

- (void)compositionVideoUrl:(NSURL *)videoUrl videoTimeRange:(CMTimeRange)videoTimeRange mergeVideoUrl:(NSURL *)mergeVideoUrl mergeVideoTimeRange:(CMTimeRange)mergeVideoTimeRange success:(SuccessBlcok)successBlcok
{
    switch (_compositionType) {
        case VideoToVideo:
        {
            NSArray *timeRanges = [NSArray arrayWithObjects:[NSValue valueWithCMTimeRange:videoTimeRange],[NSValue valueWithCMTimeRange:mergeVideoTimeRange] ,nil];
            [self compositionVideos:@[videoUrl,mergeVideoUrl] timeRanges:timeRanges success:successBlcok];
        }
            break;
        case VideoToAudio:{
            NSArray *timeRanges = [NSArray arrayWithObjects:[NSValue valueWithCMTimeRange:videoTimeRange],[NSValue valueWithCMTimeRange:mergeVideoTimeRange] ,nil];
            [self compositionAudios:@[videoUrl,mergeVideoUrl] timeRanges:timeRanges success:successBlcok];
        }
            break;
        default:
            break;
    }
}

- (void)compositionVideos:(NSArray<NSURL *> *)videos timeRanges:(NSArray<NSValue *> *)timeRanges success:(SuccessBlcok)successBlcok
{
    [self compositionMedia:videos timeRanges:timeRanges type:0 success:successBlcok];
}

- (void)compositionAudios:(NSArray<NSURL *> *)audios timeRanges:(NSArray<NSValue *> *)timeRanges success:(SuccessBlcok)successBlcok
{
    [self compositionMedia:audios timeRanges:timeRanges type:1 success:successBlcok];
}

#pragma mark == private method
- (void)compositionMedia:(NSArray<NSURL *> *)media timeRanges:(NSArray<NSValue *> *)timeRanges type:(NSInteger)type success:(SuccessBlcok)successBlcok
{
    NSCAssert(_compositionName.length > 0, @"请输入转换后的名字");
    NSCAssert((timeRanges.count == 0 || timeRanges.count == media.count), @"请输入正确的timeRange");
    NSString *outPutFilePath = [[self compositionPath] stringByAppendingPathComponent:_compositionName];
    
    //存在该文件
    if ([MTFileManager fileExistsAtPath:outPutFilePath]) {
        [MTFileManager clearCachesWithFilePath:outPutFilePath];
    }
    
    // 创建可变的音视频组合
    AVMutableComposition *composition = [AVMutableComposition composition];
    if (type == 0) {
        // 视频通道
        AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        // 音频通道
        AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        CMTime atTime = kCMTimeZero;
        
        for (int i = 0;i < media.count;i ++) {
            NSURL *url = media[i];
            CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, kCMTimeZero);
            if (timeRanges.count > 0) {
                timeRange = [timeRanges[i] CMTimeRangeValue];
            }
            
            // 视频采集
            AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:url options:nil];
            timeRange = [self fitTimeRange:timeRange avUrlAsset:videoAsset];
            
            // 视频采集通道
            AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
            // 把采集轨道数据加入到可变轨道之中
            [videoTrack insertTimeRange:timeRange ofTrack:videoAssetTrack atTime:atTime error:nil];
            
            // 音频采集通道
            AVAssetTrack *audioAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
            // 加入合成轨道之中
            [audioTrack insertTimeRange:timeRange ofTrack:audioAssetTrack atTime:atTime error:nil];
            
            atTime = CMTimeAdd(atTime, timeRange.duration);
        }
    }else{
        // 音频通道
        AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        CMTime atTime = kCMTimeZero;
        
        for (int i = 0;i < media.count;i ++) {
            NSURL *url = media[i];
            CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, kCMTimeZero);
            if (timeRanges.count > 0) {
                timeRange = [timeRanges[i] CMTimeRangeValue];
            }
            
            // 音频采集
            AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:url options:nil];
            timeRange = [self fitTimeRange:timeRange avUrlAsset:audioAsset];
            
            // 音频采集通道
            AVAssetTrack *audioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
            // 加入合成轨道之中
            [audioTrack insertTimeRange:timeRange ofTrack:audioAssetTrack atTime:atTime error:nil];
            
            atTime = CMTimeAdd(atTime, timeRange.duration);
        }
    }
    [self composition:composition storePath:outPutFilePath success:successBlcok];
}


//得到合适的时间
- (CMTimeRange)fitTimeRange:(CMTimeRange)timeRange avUrlAsset:(AVURLAsset *)avUrlAsset
{
    CMTimeRange fitTimeRange = timeRange;
    
    if (CMTimeCompare(avUrlAsset.duration,timeRange.duration))
    {
        fitTimeRange.duration = avUrlAsset.duration;
    }
    if (CMTimeCompare(timeRange.duration,kCMTimeZero))
    {
        fitTimeRange.duration = avUrlAsset.duration;
    }
    return fitTimeRange;
}

- (void)composition:(AVMutableComposition *)avComposition
          storePath:(NSString *)storePath
            success:(SuccessBlcok)successBlcok{
    [self composition:avComposition videoCompositon:nil audioMix:nil storePath:storePath success:successBlcok];
}
//输出  AVMutableAudioMix *mutableAudioMix;
- (void)composition:(AVMutableComposition *)avComposition
    videoCompositon:(AVMutableVideoComposition*)videoComposition
           audioMix:(AVMutableAudioMix*)mutableAudioMix
          storePath:(NSString *)storePath
            success:(SuccessBlcok)successBlcok
{
    // 创建一个输出
    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset:avComposition presetName:AVAssetExportPresetHighestQuality];
    assetExport.outputFileType = AVFileTypeMPEG4;
    if (videoComposition) {
        assetExport.videoComposition = videoComposition;
    }
    if (mutableAudioMix) {
        assetExport.audioMix = mutableAudioMix;
    }
    // 输出地址
    assetExport.outputURL = [NSURL fileURLWithPath:storePath];
    // 优化
    assetExport.shouldOptimizeForNetworkUse = YES;
    
    __block NSTimer *timer = nil;
    
    timer = [NSTimer scheduledTimerWithTimeInterval:0.05 repeats:YES block:^(NSTimer * _Nonnull timer) {
        NSLog(@" 打印信息:%f",assetExport.progress);
        if (self.progressBlock) {
            self.progressBlock(assetExport.progress);
        }
    }];
    
    
    // 合成完毕
    [assetExport exportAsynchronouslyWithCompletionHandler:^{
        if (timer) {
            [timer invalidate];
            timer = nil;
        }
        // 回到主线程
        switch (assetExport.status) {
            case AVAssetExportSessionStatusUnknown:
                NSLog(@"exporter Unknow");
                break;
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"exporter Canceled");
                break;
            case AVAssetExportSessionStatusFailed:
                NSLog(@"%@", [NSString stringWithFormat:@"exporter Failed%@",assetExport.error.description]);
                break;
            case AVAssetExportSessionStatusWaiting:
                NSLog(@"exporter Waiting");
                break;
            case AVAssetExportSessionStatusExporting:
                NSLog(@"exporter Exporting");
                break;
            case AVAssetExportSessionStatusCompleted:
                NSLog(@"exporter Completed");
                dispatch_async(dispatch_get_main_queue(), ^{
                    // 调用播放方法
                    successBlcok([NSURL fileURLWithPath:storePath]);
                });
                break;
        }
    }];
}

- (void)replaceAudioInVideo:(NSURL *)videoUrl withAudio:(NSURL *)audioUrl atRange:(CMTimeRange)timeRange atVolume:(CGFloat)volume success:(SuccessBlcok)successBlcok{
    
    AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    AVAssetTrack *assetVideoTrack = nil;
    AVAssetTrack *assetAudioTrack = nil;
    // Check if the asset contains video and audio tracks
    if ([[videoAsset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        assetVideoTrack = [videoAsset tracksWithMediaType:AVMediaTypeVideo][0];
    }
    if ([[videoAsset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
        assetAudioTrack = [videoAsset tracksWithMediaType:AVMediaTypeAudio][0];
    }
    
    NSError *error = nil;
    AVMutableComposition *mutableComposition = [AVMutableComposition composition];
    if (assetVideoTrack != nil) {
        AVMutableCompositionTrack *compositionVideoTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [videoAsset duration]) ofTrack:assetVideoTrack atTime:kCMTimeZero error:&error];
    }
    if (assetAudioTrack != nil) {
        AVMutableCompositionTrack *compositionAudioTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [videoAsset duration]) ofTrack:assetAudioTrack atTime:kCMTimeZero error:&error];
        
        //去掉timeRange这段音频
        [compositionAudioTrack removeTimeRange:timeRange];
        //然后在timeRange这段上插入空白。
        [compositionAudioTrack insertEmptyTimeRange:timeRange];
        //        //去掉第2-6s的音频
        //        CGFloat originTimeScale = asset.duration.timescale;
        //        CMTime originTrimStartTime = CMTimeMake(2 * originTimeScale, originTimeScale);
        //        CMTime originTrimEndTime = CMTimeMake(6 * originTimeScale, originTimeScale);
        //        [compositionAudioTrack removeTimeRange:CMTimeRangeMake(originTrimStartTime, originTrimEndTime)];
        //        [compositionAudioTrack insertEmptyTimeRange:CMTimeRangeMake(originTrimStartTime, originTrimEndTime)];
    }
    
    AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:audioUrl options:nil];
    AVAssetTrack *replaceAudioTrack = [audioAsset tracksWithMediaType:AVMediaTypeAudio][0];
    
    // Step 3
    // Add custom audio track to the composition
    AVMutableCompositionTrack *compositonReplaceAudioTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    CMTime audioDuration = audioAsset.duration;
    CGFloat audioValue = audioDuration.value;
    CGFloat audioTimescale = audioDuration.timescale;
    CGFloat audioNatureDur = audioValue/audioTimescale;
    
    CMTime timeRangeDuration = timeRange.duration;
    CGFloat timeRangeValue = timeRangeDuration.value;
    CGFloat timeRangeTimescale = timeRangeDuration.timescale;
    CGFloat timeRangeNatureDur = timeRangeValue/timeRangeTimescale;
    
    if (audioNatureDur > timeRangeNatureDur) {
        [compositonReplaceAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, timeRangeDuration) ofTrack:replaceAudioTrack atTime:kCMTimeZero error:&error];
    }else{
        [compositonReplaceAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset.duration) ofTrack:replaceAudioTrack atTime:kCMTimeZero error:&error];
    }
    
    AVMutableAudioMixInputParameters *mixParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compositonReplaceAudioTrack];
    [mixParameters setVolumeRampFromStartVolume:volume toEndVolume:volume timeRange:timeRange];
    
    AVMutableAudioMix *mutableAudioMix = [AVMutableAudioMix audioMix];
    mutableAudioMix.inputParameters = @[mixParameters];
    
    NSString *outPutFilePath = [[self compositionPath] stringByAppendingPathComponent:@"xxoo.mp4"];
    //存在该文件
    if ([MTFileManager fileExistsAtPath:outPutFilePath]) {
        [MTFileManager clearCachesWithFilePath:outPutFilePath];
    }
    [self composition:mutableComposition videoCompositon:nil audioMix:mutableAudioMix storePath:outPutFilePath success:successBlcok];
}

- (void)replaceAudioInVideo:(NSURL *)videoUrl withAudio:(NSURL *)audioUrl atVideoPosition:(CGFloat)videoPosition atVolume:(CGFloat)volume success:(SuccessBlcok)successBlcok{
    
    AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    AVAssetTrack *assetVideoTrack = nil;
    AVAssetTrack *assetAudioTrack = nil;
    // Check if the asset contains video and audio tracks
    if ([[videoAsset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        assetVideoTrack = [videoAsset tracksWithMediaType:AVMediaTypeVideo][0];
    }
    if ([[videoAsset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
        assetAudioTrack = [videoAsset tracksWithMediaType:AVMediaTypeAudio][0];
    }
    
    AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:audioUrl options:nil];
    
    CMTime startTime = CMTimeMake(videoPosition, 1);
    CMTimeRange timeRange = CMTimeRangeMake(startTime, audioAsset.duration);
    
    NSError *error = nil;
    AVMutableComposition *mutableComposition = [AVMutableComposition composition];
    if (assetVideoTrack != nil) {
        AVMutableCompositionTrack *compositionVideoTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [videoAsset duration]) ofTrack:assetVideoTrack atTime:kCMTimeZero error:&error];
    }
    if (assetAudioTrack != nil) {
        AVMutableCompositionTrack *compositionAudioTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [videoAsset duration]) ofTrack:assetAudioTrack atTime:kCMTimeZero error:&error];
        
        //去掉timeRange这段音频
        [compositionAudioTrack removeTimeRange:timeRange];
        //然后在timeRange这段上插入空白。
        [compositionAudioTrack insertEmptyTimeRange:timeRange];
        //        //去掉第2-6s的音频
        //        CGFloat originTimeScale = asset.duration.timescale;
        //        CMTime originTrimStartTime = CMTimeMake(2 * originTimeScale, originTimeScale);
        //        CMTime originTrimEndTime = CMTimeMake(6 * originTimeScale, originTimeScale);
        //        [compositionAudioTrack removeTimeRange:CMTimeRangeMake(originTrimStartTime, originTrimEndTime)];
        //        [compositionAudioTrack insertEmptyTimeRange:CMTimeRangeMake(originTrimStartTime, originTrimEndTime)];
    }
    
    AVAssetTrack *replaceAudioTrack = [audioAsset tracksWithMediaType:AVMediaTypeAudio][0];
    
    // Step 3
    // Add custom audio track to the composition
    AVMutableCompositionTrack *compositonReplaceAudioTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    CMTime audioDuration = audioAsset.duration;
    CGFloat audioValue = audioDuration.value;
    CGFloat audioTimescale = audioDuration.timescale;
    CGFloat audioNatureDur = audioValue/audioTimescale;
    
    CMTime timeRangeDuration = timeRange.duration;
    CGFloat timeRangeValue = timeRangeDuration.value;
    CGFloat timeRangeTimescale = timeRangeDuration.timescale;
    CGFloat timeRangeNatureDur = timeRangeValue/timeRangeTimescale;
    
    if (audioNatureDur > timeRangeNatureDur) {
        [compositonReplaceAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, timeRangeDuration) ofTrack:replaceAudioTrack atTime:kCMTimeZero error:&error];
    }else{
        [compositonReplaceAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset.duration) ofTrack:replaceAudioTrack atTime:kCMTimeZero error:&error];
    }
    
    AVMutableAudioMixInputParameters *mixParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compositonReplaceAudioTrack];
    [mixParameters setVolumeRampFromStartVolume:volume toEndVolume:volume timeRange:timeRange];
    
    AVMutableAudioMix *mutableAudioMix = [AVMutableAudioMix audioMix];
    mutableAudioMix.inputParameters = @[mixParameters];
    
    NSString *outPutFilePath = [[self compositionPath] stringByAppendingPathComponent:_compositionName];
    //存在该文件
    if ([MTFileManager fileExistsAtPath:outPutFilePath]) {
        [MTFileManager clearCachesWithFilePath:outPutFilePath];
    }
    [self composition:mutableComposition videoCompositon:nil audioMix:mutableAudioMix storePath:outPutFilePath success:successBlcok];
}

- (void)preReplaceAudioInVideo:(NSURL *)videoUrl withAudio:(NSURL *)audioUrl atVideoPosition:(CGFloat)videoPosition atVolume:(CGFloat)volume success:(PreSuccessBlcok)successBlcok{
    AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    AVAssetTrack *assetVideoTrack = nil;
    AVAssetTrack *assetAudioTrack = nil;
    // Check if the asset contains video and audio tracks
    if ([[videoAsset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        assetVideoTrack = [videoAsset tracksWithMediaType:AVMediaTypeVideo][0];
    }
    if ([[videoAsset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
        assetAudioTrack = [videoAsset tracksWithMediaType:AVMediaTypeAudio][0];
    }
    
    AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:audioUrl options:nil];
    
    CMTime startTime = CMTimeMake(videoPosition, 1);
    CMTimeRange timeRange = CMTimeRangeMake(startTime, audioAsset.duration);
    
    NSError *error = nil;
    AVMutableComposition *mutableComposition = [AVMutableComposition composition];
    if (assetVideoTrack != nil) {
        AVMutableCompositionTrack *compositionVideoTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [videoAsset duration]) ofTrack:assetVideoTrack atTime:kCMTimeZero error:&error];
    }
    if (assetAudioTrack != nil) {
        AVMutableCompositionTrack *compositionAudioTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [videoAsset duration]) ofTrack:assetAudioTrack atTime:kCMTimeZero error:&error];
        
        //去掉timeRange这段音频
        [compositionAudioTrack removeTimeRange:timeRange];
        //然后在timeRange这段上插入空白。
        [compositionAudioTrack insertEmptyTimeRange:timeRange];
        //        //去掉第2-6s的音频
        //        CGFloat originTimeScale = asset.duration.timescale;
        //        CMTime originTrimStartTime = CMTimeMake(2 * originTimeScale, originTimeScale);
        //        CMTime originTrimEndTime = CMTimeMake(6 * originTimeScale, originTimeScale);
        //        [compositionAudioTrack removeTimeRange:CMTimeRangeMake(originTrimStartTime, originTrimEndTime)];
        //        [compositionAudioTrack insertEmptyTimeRange:CMTimeRangeMake(originTrimStartTime, originTrimEndTime)];
    }
    
    AVAssetTrack *replaceAudioTrack = [audioAsset tracksWithMediaType:AVMediaTypeAudio][0];
    
    // Step 3
    // Add custom audio track to the composition
    AVMutableCompositionTrack *compositonReplaceAudioTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    CMTime audioDuration = audioAsset.duration;
    CGFloat audioValue = audioDuration.value;
    CGFloat audioTimescale = audioDuration.timescale;
    CGFloat audioNatureDur = audioValue/audioTimescale;
    
    CMTime timeRangeDuration = timeRange.duration;
    CGFloat timeRangeValue = timeRangeDuration.value;
    CGFloat timeRangeTimescale = timeRangeDuration.timescale;
    CGFloat timeRangeNatureDur = timeRangeValue/timeRangeTimescale;
    
    if (audioNatureDur > timeRangeNatureDur) {
        [compositonReplaceAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, timeRangeDuration) ofTrack:replaceAudioTrack atTime:timeRange.start error:&error];
    }else{
        [compositonReplaceAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset.duration) ofTrack:replaceAudioTrack atTime:timeRange.start error:&error];
    }
    
    AVMutableAudioMixInputParameters *mixParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compositonReplaceAudioTrack];
    [mixParameters setVolumeRampFromStartVolume:volume toEndVolume:volume timeRange:timeRange];
    
    AVMutableAudioMix *mutableAudioMix = [AVMutableAudioMix audioMix];
    mutableAudioMix.inputParameters = @[mixParameters];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // 调用播放方法
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:mutableComposition];
        playerItem.audioMix = mutableAudioMix;
        successBlcok(playerItem);
    });
    
}

- (void)preReplaceAudioInVideo:(NSURL *)videoUrl withAudioInfos:(NSArray *)audioInfoArr atVolume:(CGFloat)volume success:(PreSuccessBlcok)successBlcok{
    
    AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    AVAssetTrack *assetVideoTrack = nil;
    AVAssetTrack *assetAudioTrack = nil;
    // Check if the asset contains video and audio tracks
    if ([[videoAsset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        assetVideoTrack = [videoAsset tracksWithMediaType:AVMediaTypeVideo][0];
    }
    if ([[videoAsset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
        assetAudioTrack = [videoAsset tracksWithMediaType:AVMediaTypeAudio][0];
    }
    
    NSMutableArray *mixArray = [NSMutableArray new];
    if (audioInfoArr.count > 0) {
        for (RecordAudioInfo *audioInfo in audioInfoArr) {
            
            AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:audioInfo.audioUrl] options:nil];
            
            CMTime startTime = CMTimeMake(audioInfo.startTime, 1);
            CMTimeRange timeRange = CMTimeRangeMake(startTime, audioAsset.duration);
            
            NSError *error = nil;
            
            if (!self.composition) {
                self.composition = [AVMutableComposition composition];
                if (assetVideoTrack != nil) {
                    AVMutableCompositionTrack *compositionVideoTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
                    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [videoAsset duration]) ofTrack:assetVideoTrack atTime:kCMTimeZero error:&error];
                }
                if (assetAudioTrack != nil) {
                    AVMutableCompositionTrack *compositionAudioTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
                    [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [videoAsset duration]) ofTrack:assetAudioTrack atTime:kCMTimeZero error:&error];
                    
                    //去掉timeRange这段音频
                    [compositionAudioTrack removeTimeRange:timeRange];
                    //然后在timeRange这段上插入空白。
                    [compositionAudioTrack insertEmptyTimeRange:timeRange];
                }
                
                AVAssetTrack *replaceAudioTrack = [audioAsset tracksWithMediaType:AVMediaTypeAudio][0];
                
                // Step 3
                // Add custom audio track to the composition
                AVMutableCompositionTrack *compositonReplaceAudioTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
                
                CMTime audioDuration = audioAsset.duration;
                CGFloat audioValue = audioDuration.value;
                CGFloat audioTimescale = audioDuration.timescale;
                CGFloat audioNatureDur = audioValue/audioTimescale;
                
                CMTime timeRangeDuration = timeRange.duration;
                CGFloat timeRangeValue = timeRangeDuration.value;
                CGFloat timeRangeTimescale = timeRangeDuration.timescale;
                CGFloat timeRangeNatureDur = timeRangeValue/timeRangeTimescale;
                
                if (audioNatureDur > timeRangeNatureDur) {
                    [compositonReplaceAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, timeRangeDuration) ofTrack:replaceAudioTrack atTime:timeRange.start error:&error];
                }else{
                    [compositonReplaceAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset.duration) ofTrack:replaceAudioTrack atTime:timeRange.start error:&error];
                }
                
                AVMutableAudioMixInputParameters *mixParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compositonReplaceAudioTrack];
                [mixParameters setVolumeRampFromStartVolume:volume toEndVolume:volume timeRange:timeRange];
                [mixArray addObject:mixParameters];
            }else{
                NSArray *tracks = [self.composition tracksWithMediaType:AVMediaTypeAudio];
                if (tracks.count > 0) {
                    AVMutableCompositionTrack *compositionAudioTrack = tracks[0];
                    //去掉timeRange这段音频
                    [compositionAudioTrack removeTimeRange:timeRange];
                    //然后在timeRange这段上插入空白。
                    [compositionAudioTrack insertEmptyTimeRange:timeRange];
                }
                
                AVAssetTrack *replaceAudioTrack = [audioAsset tracksWithMediaType:AVMediaTypeAudio][0];
                
                // Step 3
                // Add custom audio track to the composition
                AVMutableCompositionTrack *compositonReplaceAudioTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
                
                CMTime audioDuration = audioAsset.duration;
                CGFloat audioValue = audioDuration.value;
                CGFloat audioTimescale = audioDuration.timescale;
                CGFloat audioNatureDur = audioValue/audioTimescale;
                
                CMTime timeRangeDuration = timeRange.duration;
                CGFloat timeRangeValue = timeRangeDuration.value;
                CGFloat timeRangeTimescale = timeRangeDuration.timescale;
                CGFloat timeRangeNatureDur = timeRangeValue/timeRangeTimescale;
                
                if (audioNatureDur > timeRangeNatureDur) {
                    [compositonReplaceAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, timeRangeDuration) ofTrack:replaceAudioTrack atTime:timeRange.start error:&error];
                }else{
                    [compositonReplaceAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset.duration) ofTrack:replaceAudioTrack atTime:timeRange.start error:&error];
                }
                
                AVMutableAudioMixInputParameters *mixParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compositonReplaceAudioTrack];
                [mixParameters setVolumeRampFromStartVolume:volume toEndVolume:volume timeRange:timeRange];
                [mixArray addObject:mixParameters];
            }
        }
    }
    
    AVMutableAudioMix *mutableAudioMix = [AVMutableAudioMix audioMix];
    mutableAudioMix.inputParameters = mixArray;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // 调用播放方法
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
        playerItem.audioMix = mutableAudioMix;
        successBlcok(playerItem);
    });
}

- (void)preReplaceAudioInPlayerItem:(AVPlayerItem *)playerItem withAudioInfos:(NSArray *)audioInfoArr atVolume:(CGFloat)volume success:(PreSuccessBlcok)successBlcok{
    
    AVAsset *videoAsset = playerItem.asset;
    
    AVAssetTrack *assetVideoTrack = nil;
    AVAssetTrack *assetAudioTrack = nil;
    // Check if the asset contains video and audio tracks
    if ([[videoAsset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        assetVideoTrack = [videoAsset tracksWithMediaType:AVMediaTypeVideo][0];
    }
    if ([[videoAsset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
        assetAudioTrack = [videoAsset tracksWithMediaType:AVMediaTypeAudio][0];
    }
    
    if (!self.composition) {
        self.composition = [AVMutableComposition composition];
    }
    
    if (assetVideoTrack != nil) {
        AVMutableCompositionTrack *compositionVideoTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionVideoTrack setPreferredTransform:videoAsset.preferredTransform];
        [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [videoAsset duration]) ofTrack:assetVideoTrack atTime:kCMTimeZero error:nil];
    }
    
    AVMutableCompositionTrack *compositionAudioTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    if (assetAudioTrack != nil) {
        [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [videoAsset duration]) ofTrack:assetAudioTrack atTime:kCMTimeZero error:nil];
    }else{
        [compositionAudioTrack insertEmptyTimeRange:CMTimeRangeMake(kCMTimeZero, [videoAsset duration])];
    }
    
    NSMutableArray *mixArray = [NSMutableArray new];
    if (audioInfoArr.count > 0) {
        for (RecordAudioInfo *audioInfo in audioInfoArr) {
            
            AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:audioInfo.audioUrl] options:nil];
            
            CMTime startTime = CMTimeMake(audioInfo.startTime, 1);
            CMTimeRange timeRange = CMTimeRangeMake(startTime, audioAsset.duration);
            
            NSError *error = nil;
            
            //将超出视频长度的audio排除。
            if (startTime.value/startTime.timescale < videoAsset.duration.value/videoAsset.duration.timescale) {
                CGFloat audioNatureDur = audioAsset.duration.value/audioAsset.duration.timescale;
                CGFloat startTimeValue = startTime.value/startTime.timescale;
                CGFloat videoDuration = videoAsset.duration.value/videoAsset.duration.timescale;
                
                CMTimeRange compoRange = kCMTimeRangeZero;
                if (startTimeValue + audioNatureDur < videoDuration) {
                    //去掉timeRange这段音频
                    [compositionAudioTrack removeTimeRange:timeRange];
                    //然后在timeRange这段上插入空白。
                    [compositionAudioTrack insertEmptyTimeRange:timeRange];
                    compoRange = timeRange;
                }else{
                    CGFloat realDuration = videoDuration - startTimeValue;
                    CMTime durationTime = CMTimeMake(realDuration, 1);
                    CMTimeRange realTimeRange = CMTimeRangeMake(startTime, durationTime);
                    [compositionAudioTrack removeTimeRange:realTimeRange];
                    //然后在timeRange这段上插入空白。
                    [compositionAudioTrack insertEmptyTimeRange:realTimeRange];
                    compoRange = realTimeRange;
                }
                
                AVAssetTrack *replaceAudioTrack = [audioAsset tracksWithMediaType:AVMediaTypeAudio][0];
                // Step 3
                // Add custom audio track to the composition
                AVMutableCompositionTrack *compositonReplaceAudioTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
                
                [compositonReplaceAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, compoRange.duration) ofTrack:replaceAudioTrack atTime:compoRange.start error:&error];
                
                AVMutableAudioMixInputParameters *mixParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compositonReplaceAudioTrack];
                [mixParameters setVolumeRampFromStartVolume:volume toEndVolume:volume timeRange:compoRange];
                [mixArray addObject:mixParameters];
            }
            
//            if (!self.composition) {
//                self.composition = [AVMutableComposition composition];
//
//                if (assetAudioTrack != nil) {
//                    AVMutableCompositionTrack *compositionAudioTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
//                    [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [videoAsset duration]) ofTrack:assetAudioTrack atTime:kCMTimeZero error:&error];
//
//                    //去掉timeRange这段音频
//                    [compositionAudioTrack removeTimeRange:timeRange];
//                    //然后在timeRange这段上插入空白。
//                    [compositionAudioTrack insertEmptyTimeRange:timeRange];
//                }else{
//
//                }
//
//                AVAssetTrack *replaceAudioTrack = [audioAsset tracksWithMediaType:AVMediaTypeAudio][0];
//
//                // Step 3
//                // Add custom audio track to the composition
//                AVMutableCompositionTrack *compositonReplaceAudioTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
//
//                CMTime audioDuration = audioAsset.duration;
//                CGFloat audioValue = audioDuration.value;
//                CGFloat audioTimescale = audioDuration.timescale;
//                CGFloat audioNatureDur = audioValue/audioTimescale;
//
//                CMTime timeRangeDuration = timeRange.duration;
//                CGFloat timeRangeValue = timeRangeDuration.value;
//                CGFloat timeRangeTimescale = timeRangeDuration.timescale;
//                CGFloat timeRangeNatureDur = timeRangeValue/timeRangeTimescale;
//
//                if (audioNatureDur > timeRangeNatureDur) {
//                    [compositonReplaceAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, timeRangeDuration) ofTrack:replaceAudioTrack atTime:timeRange.start error:&error];
//                }else{
//                    [compositonReplaceAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset.duration) ofTrack:replaceAudioTrack atTime:timeRange.start error:&error];
//                }
//
//                AVMutableAudioMixInputParameters *mixParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compositonReplaceAudioTrack];
//                [mixParameters setVolumeRampFromStartVolume:volume toEndVolume:volume timeRange:timeRange];
//                [mixArray addObject:mixParameters];
//            }else{
//                NSArray *tracks = [self.composition tracksWithMediaType:AVMediaTypeAudio];
//                if (tracks.count > 0) {
//                    AVMutableCompositionTrack *compositionAudioTrack = tracks[0];
//                    //去掉timeRange这段音频
//                    [compositionAudioTrack removeTimeRange:timeRange];
//                    //然后在timeRange这段上插入空白。
//                    [compositionAudioTrack insertEmptyTimeRange:timeRange];
//                }
//
//                AVAssetTrack *replaceAudioTrack = [audioAsset tracksWithMediaType:AVMediaTypeAudio][0];
//
//                // Step 3
//                // Add custom audio track to the composition
//                AVMutableCompositionTrack *compositonReplaceAudioTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
//
//                CMTime audioDuration = audioAsset.duration;
//                CGFloat audioValue = audioDuration.value;
//                CGFloat audioTimescale = audioDuration.timescale;
//                CGFloat audioNatureDur = audioValue/audioTimescale;
//
//                CMTime timeRangeDuration = timeRange.duration;
//                CGFloat timeRangeValue = timeRangeDuration.value;
//                CGFloat timeRangeTimescale = timeRangeDuration.timescale;
//                CGFloat timeRangeNatureDur = timeRangeValue/timeRangeTimescale;
//
//                if (audioNatureDur > timeRangeNatureDur) {
//                    [compositonReplaceAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, timeRangeDuration) ofTrack:replaceAudioTrack atTime:timeRange.start error:&error];
//                }else{
//                    [compositonReplaceAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset.duration) ofTrack:replaceAudioTrack atTime:timeRange.start error:&error];
//                }
//
//                AVMutableAudioMixInputParameters *mixParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compositonReplaceAudioTrack];
//                [mixParameters setVolumeRampFromStartVolume:volume toEndVolume:volume timeRange:timeRange];
//                [mixArray addObject:mixParameters];
//            }
        }
    }
    
    AVMutableAudioMix *mutableAudioMix = [AVMutableAudioMix audioMix];
    mutableAudioMix.inputParameters = mixArray;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // 调用播放方法
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
        playerItem.audioMix = mutableAudioMix;
        successBlcok(playerItem);
    });
}

- (void)preClipVideo:(NSURL *)videoUrl atStartTime:(CGFloat)startTime stopTime:(CGFloat)stopTime success:(PreSuccessBlcok)successBlcok{
    
    AVAsset *videoAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    AVAssetTrack *assetVideoTrack = nil;
    AVAssetTrack *assetAudioTrack = nil;
    
    // Check if the asset contains video and audio tracks
    if ([[videoAsset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        assetVideoTrack = [videoAsset tracksWithMediaType:AVMediaTypeVideo][0];
    }
    if ([[videoAsset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
        assetAudioTrack = [videoAsset tracksWithMediaType:AVMediaTypeAudio][0];
    }
    
    CMTime start = CMTimeMakeWithSeconds(startTime, videoAsset.duration.timescale);
    CMTime duration = CMTimeMakeWithSeconds(stopTime - startTime, videoAsset.duration.timescale);
    CMTimeRange range = CMTimeRangeMake(start, duration);
    
    CMTime insertionPoint = kCMTimeZero;
    NSError *error = nil;
    
    CMTime assetDuration = videoAsset.duration;
    
    if (!self.composition) {
        self.composition = [AVMutableComposition composition];
    }
    
    if(assetVideoTrack != nil) {
        AVMutableCompositionTrack *compositionVideoTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionVideoTrack setPreferredTransform:assetVideoTrack.preferredTransform];
        [compositionVideoTrack insertTimeRange:CMTimeRangeMake(insertionPoint, assetDuration) ofTrack:assetVideoTrack atTime:insertionPoint error:&error];
        //            [compositionVideoTrack removeTimeRange:range];
    }
    if(assetAudioTrack != nil) {
        AVMutableCompositionTrack *compositionAudioTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionAudioTrack insertTimeRange:CMTimeRangeMake(insertionPoint, assetDuration) ofTrack:assetAudioTrack atTime:insertionPoint error:&error];
        //            [compositionAudioTrack removeTimeRange:range];
    }
    
    [self.composition removeTimeRange:range];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // 调用播放方法
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
        
        successBlcok(playerItem);
    });
    
//    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
//    playerItem.videoComposition = self.videoComposition;
}

- (void)clipVideo:(NSURL *)videoUrl atStartTime:(CGFloat)startTime stopTime:(CGFloat)stopTime success:(SuccessBlcok)successBlcok{
    
    AVAsset *anAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:anAsset];
    if ([compatiblePresets containsObject:AVAssetExportPresetMediumQuality]) {
        
        AVAssetExportSession *assetExport = [[AVAssetExportSession alloc]
                              initWithAsset:anAsset presetName:AVAssetExportPresetPassthrough];
        // Implementation continues.
        NSString *outPutFilePath = [[self compositionPath] stringByAppendingPathComponent:_compositionName];
        //存在该文件
        if ([MTFileManager fileExistsAtPath:outPutFilePath]) {
            [MTFileManager clearCachesWithFilePath:outPutFilePath];
        }
        
        NSURL *furl = [NSURL fileURLWithPath:outPutFilePath];
        
        assetExport.outputURL = furl;
        assetExport.outputFileType = AVFileTypeMPEG4;
        
        CMTime start = CMTimeMakeWithSeconds(startTime, anAsset.duration.timescale);
        CMTime duration = CMTimeMakeWithSeconds(stopTime - startTime, anAsset.duration.timescale);
        CMTimeRange range = CMTimeRangeMake(start, duration);
        assetExport.timeRange = range;
        
        [assetExport exportAsynchronouslyWithCompletionHandler:^{
            // 回到主线程
            switch (assetExport.status) {
                case AVAssetExportSessionStatusUnknown:
                    NSLog(@"exporter Unknow");
                    break;
                case AVAssetExportSessionStatusCancelled:
                    NSLog(@"exporter Canceled");
                    break;
                case AVAssetExportSessionStatusFailed:
                    NSLog(@"%@", [NSString stringWithFormat:@"exporter Failed%@",assetExport.error.description]);
                    break;
                case AVAssetExportSessionStatusWaiting:
                    NSLog(@"exporter Waiting");
                    break;
                case AVAssetExportSessionStatusExporting:
                    NSLog(@"exporter Exporting");
                    break;
                case AVAssetExportSessionStatusCompleted:
                    NSLog(@"exporter Completed");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        // 调用播放方法
                        successBlcok([NSURL fileURLWithPath:outPutFilePath]);
                    });
                    break;
            }
        }];
    }
}

- (void)preAddSticker:(NSArray *)stickerInfoArr toVideo:(NSURL *)videoUrl success:(PreSuccessBlcok)successBlcok{
    
    AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    
    if (!self.composition) {
        self.composition = [AVMutableComposition composition];
    }
    
    //合成轨道
    AVMutableCompositionTrack *videoCompositionTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVMutableCompositionTrack *audioCompositionTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    //视频采集
    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    AVAssetTrack *audioAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    //加入合成轨道
    [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration) ofTrack:videoAssetTrack atTime:kCMTimeZero error:nil];
    
    [audioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAssetTrack.timeRange.duration) ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];
    
    AVMutableVideoComposition *mutableVideoComposition = [AVMutableVideoComposition videoComposition];
    
    // The rotate transform is set on a layer instruction
    AVMutableVideoCompositionInstruction *videoCompostionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    videoCompostionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, [self.composition duration]);
    
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoCompositionTrack];
    
    videoCompostionInstruction.layerInstructions = @[layerInstruction];
    mutableVideoComposition.instructions = @[videoCompostionInstruction];
    
    //必须设置 下面的尺寸和时间
    mutableVideoComposition.renderSize = videoAssetTrack.naturalSize;
    mutableVideoComposition.frameDuration = CMTimeMake(1, 30);
    mutableVideoComposition.instructions = @[videoCompostionInstruction];
    
    [self addStickerLayerWithAVMutableVideoComposition:mutableVideoComposition withStickerInfo:stickerInfoArr];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // 调用播放方法
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
//        playerItem.videoComposition = mutableVideoComposition;
        
        successBlcok(playerItem);
    });
}

- (void)preAddSticker:(NSArray *)stickerInfoArr toPlayerItem:(AVPlayerItem *)playerItem success:(PreSuccessBlcok)successBlcok{
//    AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    AVAsset *videoAsset = playerItem.asset;
    
    if (!self.composition) {
        self.composition = [AVMutableComposition composition];
    }
    
    //合成轨道
    AVMutableCompositionTrack *videoCompositionTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVMutableCompositionTrack *audioCompositionTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    //视频采集
    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    AVAssetTrack *audioAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    //加入合成轨道
    [videoCompositionTrack setPreferredTransform:videoAssetTrack.preferredTransform];
    [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration) ofTrack:videoAssetTrack atTime:kCMTimeZero error:nil];
    
    [audioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAssetTrack.timeRange.duration) ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];
    
    AVMutableVideoComposition *mutableVideoComposition = [AVMutableVideoComposition videoComposition];
    
    // The rotate transform is set on a layer instruction
    AVMutableVideoCompositionInstruction *videoCompostionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    videoCompostionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, [self.composition duration]);
    
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoCompositionTrack];
    
    videoCompostionInstruction.layerInstructions = @[layerInstruction];
    mutableVideoComposition.instructions = @[videoCompostionInstruction];
    
    //必须设置 下面的尺寸和时间
    mutableVideoComposition.renderSize = videoAssetTrack.naturalSize;
    mutableVideoComposition.frameDuration = CMTimeMake(1, 30);
    mutableVideoComposition.instructions = @[videoCompostionInstruction];
    
    [self addStickerLayerWithAVMutableVideoComposition:mutableVideoComposition withStickerInfo:stickerInfoArr];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // 调用播放方法
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
        //        playerItem.videoComposition = mutableVideoComposition;
        
        successBlcok(playerItem);
    });
}

- (void)addSticker:(NSArray *)stickerInfoArr toVideo:(NSURL *)videoUrl success:(PreSuccessBlcok)successBlcok{
    
}

- (void)addSticker:(NSArray *)stickerInfoArr toPlayerItem:(AVPlayerItem *)playerItem success:(SuccessBlcok)successBlcok{
    AVAsset *videoAsset = playerItem.asset;
    
    if (!self.composition) {
        self.composition = [AVMutableComposition composition];
    }
    
    //合成轨道
    AVMutableCompositionTrack *videoCompositionTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVMutableCompositionTrack *audioCompositionTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVAssetTrack *videoAssetTrack = nil;
    AVAssetTrack *audioAssetTrack = nil;
    
    // Check if the asset contains video and audio tracks
    if ([[videoAsset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        videoAssetTrack = [videoAsset tracksWithMediaType:AVMediaTypeVideo][0];
    }
    if ([[videoAsset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
        audioAssetTrack = [videoAsset tracksWithMediaType:AVMediaTypeAudio][0];
    }
    
    if (videoAssetTrack) {
        //加入合成轨道
        [videoCompositionTrack setPreferredTransform:videoAssetTrack.preferredTransform];
        [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration) ofTrack:videoAssetTrack atTime:kCMTimeZero error:nil];
    }

    if (audioAssetTrack) {
        [audioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAssetTrack.timeRange.duration) ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];
    }
    
    AVMutableVideoComposition *mutableVideoComposition = [AVMutableVideoComposition videoComposition];
    
    // The rotate transform is set on a layer instruction
    AVMutableVideoCompositionInstruction *videoCompostionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    videoCompostionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, [self.composition duration]);
    
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoCompositionTrack];
    
    videoCompostionInstruction.layerInstructions = @[layerInstruction];
    mutableVideoComposition.instructions = @[videoCompostionInstruction];
    
    //必须设置 下面的尺寸和时间
    mutableVideoComposition.renderSize = videoAssetTrack.naturalSize;
    mutableVideoComposition.frameDuration = CMTimeMake(1, 30);
    mutableVideoComposition.instructions = @[videoCompostionInstruction];
    
    [self addStickerLayerWithAVMutableVideoComposition:mutableVideoComposition withStickerInfo:stickerInfoArr];
    
    NSString *outPutFilePath = [[self compositionPath] stringByAppendingPathComponent:@"sticker.mp4"];
    //存在该文件
    if ([MTFileManager fileExistsAtPath:outPutFilePath]) {
        [MTFileManager clearCachesWithFilePath:outPutFilePath];
    }
}

- (void)addStickerLayerWithAVMutableVideoComposition:(AVMutableVideoComposition*)mutableVideoComposition withStickerInfo:(NSArray*)stickerInfos
{
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    
    parentLayer.frame = CGRectMake(0, 0, mutableVideoComposition.renderSize.width, mutableVideoComposition.renderSize.height);
    videoLayer.frame = CGRectMake(0, 0, mutableVideoComposition.renderSize.width, mutableVideoComposition.renderSize.height);
    
    CGSize videoSize = mutableVideoComposition.renderSize;
    
    [parentLayer addSublayer:videoLayer];
    
    if (stickerInfos.count > 0) {
        for (StickerInfo *info in stickerInfos) {
            if (info.stickerImg) {
                CALayer *overlayLayer = [CALayer layer];
                [overlayLayer setContents:(id)[info.stickerImg CGImage]];
                
                if (videoSize.width > 0 && info.parentSize.width > 0) {
                    CGFloat centerX = videoSize.width * info.centerPoint.x / info.parentSize.width;
                    CGFloat centerY = videoSize.height * info.centerPoint.y / info.parentSize.height;
                    CGFloat width = videoSize.width * info.stickerWidth / info.parentSize.width;
                    overlayLayer.frame = CGRectMake(centerX - width/2, centerY - width/2, width, width);
                }else{
                    overlayLayer.frame = CGRectZero;
                }
                [overlayLayer setMasksToBounds:YES];
                
                CABasicAnimation *animation =
                [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
                animation.duration = info.duration;
                animation.repeatCount = 0;
                //    animation.autoreverses=YES;
                // rotate from 0 to 360
                animation.fromValue=[NSNumber numberWithFloat:info.rotate];
                animation.toValue=[NSNumber numberWithFloat:info.rotate];
                animation.beginTime = info.startTime;
                animation.fillMode = kCAFillModeForwards;
                [overlayLayer addAnimation:animation forKey:@"rotation"];
                
                animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
                [animation setDuration:0];
                [animation setFromValue:[NSNumber numberWithFloat:1.0]];
                [animation setToValue:[NSNumber numberWithFloat:0.0]];
                [animation setBeginTime:info.startTime + info.duration];
                [animation setRemovedOnCompletion:NO];
                [animation setFillMode:kCAFillModeForwards];
                [overlayLayer addAnimation:animation forKey:@"animateOpacity"];
                
                [parentLayer addSublayer:overlayLayer];
            }
        }
    }
    
    mutableVideoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
}

- (void)preCompositionVideos:(NSArray <NSURL*>*)videos success:(PreSuccessBlcok)successBlcok{
    NSCAssert(_compositionName.length > 0, @"请输入转换后的名字");
    NSString *outPutFilePath = [[self compositionPath] stringByAppendingPathComponent:_compositionName];
    
    //存在该文件
    if ([MTFileManager fileExistsAtPath:outPutFilePath]) {
        [MTFileManager clearCachesWithFilePath:outPutFilePath];
    }

    AVMutableComposition *composition = [AVMutableComposition composition];
    
    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    // 音频通道
    AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];

    videoComposition.frameDuration = CMTimeMake(1,30);
    videoComposition.renderScale = 1.0;

    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];

    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];

    float time = 0;

    for (int i = 0; i < videos.count; i++) {

        NSURL *url = videos[i];
//        AVURLAsset *currentAsset = [[AVURLAsset alloc] initWithURL:url options:nil];

        AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:url options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey]];

        NSError *error = nil;

        BOOL ok = NO;

        AVAssetTrack *sourceVideoTrack = [[sourceAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        
        AVAssetTrack *sourceAudioTrack = nil;
        if ([sourceAsset tracksWithMediaType:AVMediaTypeAudio].count > 0) {
            sourceAudioTrack = [[sourceAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        }

        CGSize temp = CGSizeApplyAffineTransform(sourceVideoTrack.naturalSize, sourceVideoTrack.preferredTransform);

        CGSize size = CGSizeMake(fabs(temp.width), fabs(temp.height));

        CGAffineTransform transform = sourceVideoTrack.preferredTransform;

        videoComposition.renderSize = CGSizeMake(960, 540);

        if (size.width > size.height && size.height < 540) {
            
            float s = 1;
            CGAffineTransform new = CGAffineTransformConcat(transform, CGAffineTransformMakeScale(s,s));
            float x = (960 - size.width*s)/2;
            float y = (540 - size.height*s)/2;
            CGAffineTransform newer = CGAffineTransformConcat(new, CGAffineTransformMakeTranslation(x, y));
            [layerInstruction setTransform:newer atTime:CMTimeMakeWithSeconds(time, 30)];
//            [layerInstruction setTransform:transform atTime:CMTimeMakeWithSeconds(time, 30)];
        }
        else {
            float s = 540.0/size.height;
            CGAffineTransform new = CGAffineTransformConcat(transform, CGAffineTransformMakeScale(s,s));

            float x = (960 - size.width*s)/2;

            float y = (540 - size.height*s)/2;

            CGAffineTransform newer = CGAffineTransformConcat(new, CGAffineTransformMakeTranslation(x, y));
            [layerInstruction setTransform:newer atTime:CMTimeMakeWithSeconds(time, 30)];
        }

        CMTime currentCompDuration = [composition duration];
        
        ok = [compositionVideoTrack insertTimeRange:sourceVideoTrack.timeRange ofTrack:sourceVideoTrack atTime:currentCompDuration error:&error];

        if (!ok) {
            NSLog(@"something went wrong");
        }

        NSLog(@"the [composition duration] is %lld",[composition duration].value/[composition duration].timescale);
        
        if (sourceAudioTrack) {
            [compositionAudioTrack insertTimeRange:sourceAudioTrack.timeRange ofTrack:[[sourceAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:currentCompDuration error:nil];
        }else{
            [compositionAudioTrack insertEmptyTimeRange:CMTimeRangeMake(currentCompDuration, sourceVideoTrack.timeRange.duration)];
        }
        
        time += CMTimeGetSeconds(sourceVideoTrack.timeRange.duration);
    }

    instruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];

    instruction.timeRange = compositionVideoTrack.timeRange;
    videoComposition.instructions = [NSArray arrayWithObject:instruction];

    dispatch_async(dispatch_get_main_queue(), ^{
        // 调用播放方法
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:composition];
        playerItem.videoComposition = videoComposition;
        successBlcok(playerItem);
    });
    
    
    
//
//    // 创建可变的音视频组合
//    AVMutableComposition *mixComposition = [AVMutableComposition composition];
//    // 视频通道
////    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
//    // 音频通道
//    AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
//
//    AVMutableVideoCompositionInstruction * mainInstruction =
//    [AVMutableVideoCompositionInstruction videoCompositionInstruction];
//
//    NSMutableArray *arrayInstruction = [[NSMutableArray alloc] init];
//
//    CMTime duration = kCMTimeZero;
//    for(int i=0;i< videos.count;i++)
//    {
//        NSURL *url = videos[i];
//        // 视频采集
//        AVURLAsset *currentAsset = [[AVURLAsset alloc] initWithURL:url options:nil];
//
//        AVMutableCompositionTrack *currentVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
//
//        if ([[currentAsset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
//            [currentVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, currentAsset.duration) ofTrack:[[currentAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:duration error:nil];
//        }else{
//            [currentVideoTrack insertEmptyTimeRange:CMTimeRangeMake(duration, currentAsset.duration)];
//        }
//
//        if ([[currentAsset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
//            [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, currentAsset.duration) ofTrack:[[currentAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:duration error:nil];
//        }else{
//            [audioTrack insertEmptyTimeRange:CMTimeRangeMake(duration, currentAsset.duration)];
//        }
//
//        AVMutableVideoCompositionLayerInstruction *currentAssetLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:currentVideoTrack];
//
//
//        AVAssetTrack *currentAssetTrack = [[currentAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
//
//        CGSize temp = CGSizeApplyAffineTransform(currentAssetTrack.naturalSize, currentAssetTrack.preferredTransform);
//
//        CGSize size = CGSizeMake(fabs(temp.width), fabs(temp.height));
//
//
//        UIImageOrientation currentAssetOrientation  = UIImageOrientationUp;
//        CGAffineTransform currentTransform = currentAssetTrack.preferredTransform;
//        if(currentTransform.a == 0 && currentTransform.b == 1.0 && currentTransform.c == -1.0 && currentTransform.d == 0)  {
//            currentAssetOrientation = UIImageOrientationRight;
//        }
//        if(currentTransform.a == 0 && currentTransform.b == -1.0 && currentTransform.c == 1.0 && currentTransform.d == 0)  {
//            currentAssetOrientation =  UIImageOrientationLeft;
//        }
//        if(currentTransform.a == 1.0 && currentTransform.b == 0 && currentTransform.c == 0 && currentTransform.d == 1.0)
//        {
//            currentAssetOrientation =  UIImageOrientationUp;
//        }
//        if(currentTransform.a == -1.0 && currentTransform.b == 0 && currentTransform.c == 0 && currentTransform.d == -1.0) {
//            currentAssetOrientation = UIImageOrientationDown;
//        }
//
//        CGAffineTransform t1;
//        CGAffineTransform t2;
//
//        if (currentAssetOrientation == UIImageOrientationRight) {
//            t1 = CGAffineTransformMakeTranslation(currentAssetTrack.naturalSize.height,0.0);
//            t2 = CGAffineTransformRotate(t1,M_PI_2);
////            currentVideoTrack.renderSize = CGSizeMake(currentAssetTrack.naturalSize.height,currentAssetTrack.naturalSize.width);
//        }else if (currentAssetOrientation == UIImageOrientationDown){
//            t1 = CGAffineTransformMakeTranslation(currentAssetTrack.naturalSize.width, currentAssetTrack.naturalSize.height);
//            t2 = CGAffineTransformRotate(t1,M_PI);
////            currentVideoTrack.renderSize = CGSizeMake(assetVideoTrack.naturalSize.width,assetVideoTrack.naturalSize.height);
//        }else if (currentAssetOrientation == UIImageOrientationLeft){
//            t1 = CGAffineTransformMakeTranslation(0.0, currentAssetTrack.naturalSize.width);
//            t2 = CGAffineTransformRotate(t1,M_PI_2*3.0);
////            mutableVideoComposition.renderSize = CGSizeMake(assetVideoTrack.naturalSize.height,assetVideoTrack.naturalSize.width);
//        }else{
//            t1 = CGAffineTransformMakeTranslation(0.0, 0);
//            t2 = CGAffineTransformRotate(t1,M_PI_2*4.0);
////            mutableVideoComposition.renderSize = CGSizeMake(assetVideoTrack.naturalSize.width,assetVideoTrack.naturalSize.height);
//        }
//
//        [currentAssetLayerInstruction setTransform:t2 atTime:duration];
//
////        CGFloat FirstAssetScaleToFitRatio = 640.0/640.0;
////        if(isCurrentAssetPortrait){
////            FirstAssetScaleToFitRatio = 640.0/640.0;
////            CGAffineTransform FirstAssetScaleFactor = CGAffineTransformMakeScale(FirstAssetScaleToFitRatio,FirstAssetScaleToFitRatio);
////            [currentAssetLayerInstruction setTransform:CGAffineTransformConcat(currentAssetTrack.preferredTransform, FirstAssetScaleFactor) atTime:duration];
////        }else{
////            CGAffineTransform FirstAssetScaleFactor = CGAffineTransformMakeScale(FirstAssetScaleToFitRatio,FirstAssetScaleToFitRatio);
////            [currentAssetLayerInstruction setTransform:CGAffineTransformConcat(CGAffineTransformConcat(currentAssetTrack.preferredTransform, FirstAssetScaleFactor),CGAffineTransformMakeTranslation(0, 0)) atTime:duration];
////        }
//
//        duration = CMTimeAdd(duration, currentAsset.duration);
//        [currentAssetLayerInstruction setOpacity:0.0 atTime:duration];
//        [arrayInstruction addObject:currentAssetLayerInstruction];
//
//    }
//
//    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, duration);
//    mainInstruction.layerInstructions = arrayInstruction;
//
//    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
//    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
////    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
////    mainCompositionInst.renderSize = CGSizeMake(1280.f, 720.f);
//
//    dispatch_async(dispatch_get_main_queue(), ^{
//        // 调用播放方法
//        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:mixComposition];
////        playerItem.videoComposition = mainCompositionInst;
//        successBlcok(playerItem);
//    });
}


- (void)paddyMergerVideoVersion :(NSMutableArray *)videoPathArray
{
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    
    videoComposition.frameDuration = CMTimeMake(1,30);
    videoComposition.renderScale = 1.0;

    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
    
    float time = 0;

    for (int i = 0; i < videoPathArray.count; i++) {
        
        AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:[videoPathArray objectAtIndex:i]] options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey]];
        
        NSError *error = nil;
        
        BOOL ok = NO;
        
        AVAssetTrack *sourceVideoTrack = [[sourceAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        
        CGSize temp = CGSizeApplyAffineTransform(sourceVideoTrack.naturalSize, sourceVideoTrack.preferredTransform);
        
        CGSize size = CGSizeMake(fabs(temp.width), fabs(temp.height));
        
        CGAffineTransform transform = sourceVideoTrack.preferredTransform;
        
        videoComposition.renderSize = CGSizeMake(320, 480);
        
        if (size.width && size.height) {
            [layerInstruction setTransform:transform atTime:CMTimeMakeWithSeconds(time, 30)];
        }
        else {
            float s = 320.0/480.0;
            CGAffineTransform new = CGAffineTransformConcat(transform, CGAffineTransformMakeScale(s,s));
            
            float x = (320 - size.width*s)/2;
            
            float y = (480 - size.height*s)/2;
            
            CGAffineTransform newer = CGAffineTransformConcat(new, CGAffineTransformMakeTranslation(x, y));
            [layerInstruction setTransform:newer atTime:CMTimeMakeWithSeconds(time, 30)];
        }
        
        ok = [compositionVideoTrack insertTimeRange:sourceVideoTrack.timeRange ofTrack:sourceVideoTrack atTime:[composition duration] error:&error];
        
        
        
        if (!ok) {
            
            // Deal with the error.
            
            NSLog(@"something went wrong");
            
        }
        
        time += CMTimeGetSeconds(sourceVideoTrack.timeRange.duration);
    }
    
    instruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];
    
    instruction.timeRange = compositionVideoTrack.timeRange;
    videoComposition.instructions = [NSArray arrayWithObject:instruction];
    
    //----------get lost--------
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *myPathDocs =[documentsDirectory stringByAppendingPathComponent:@"mergeVideo.mov"];
    
    NSURL *url = [NSURL fileURLWithPath:myPathDocs];
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    
    exporter.outputURL=url;
    
    [exporter setVideoComposition:videoComposition];
    
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    
    
    
    [exporter exportAsynchronouslyWithCompletionHandler:^
     
     {
         
         dispatch_async(dispatch_get_main_queue(), ^{
             
//             [self exportDidFinish:exporter];
             
         });
         
     }];
    
}

- (void)preCompositionVideos:(NSArray <NSURL*>*)videos successWithComposition:(PreSuccessDetailBlcok)successBlcok{
    NSCAssert(_compositionName.length > 0, @"请输入转换后的名字");
    NSString *outPutFilePath = [[self compositionPath] stringByAppendingPathComponent:_compositionName];
    
    //存在该文件
    if ([MTFileManager fileExistsAtPath:outPutFilePath]) {
        [MTFileManager clearCachesWithFilePath:outPutFilePath];
    }
    
    // 创建可变的音视频组合
    AVMutableComposition *mixComposition = [AVMutableComposition composition];
    // 视频通道
    //    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    // 音频通道
    AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    //    AVMutableVideoComposition* videoComposition = [AVMutableVideoComposition videoComposition];
    //
    //    CMTime atTime = kCMTimeZero;
    
    AVMutableVideoCompositionInstruction * mainInstruction =
    [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    
    NSMutableArray *arrayInstruction = [[NSMutableArray alloc] init];
    
    CMTime duration = kCMTimeZero;
    for(int i=0;i< videos.count;i++)
    {
        NSURL *url = videos[i];
        // 视频采集
        AVURLAsset *currentAsset = [[AVURLAsset alloc] initWithURL:url options:nil];
        
        AVMutableCompositionTrack *currentTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [currentTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, currentAsset.duration) ofTrack:[[currentAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:duration error:nil];
        
        if ([[currentAsset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
            [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, currentAsset.duration) ofTrack:[[currentAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:duration error:nil];
        }else{
            [audioTrack insertEmptyTimeRange:CMTimeRangeMake(duration, currentAsset.duration)];
        }
        
        AVMutableVideoCompositionLayerInstruction *currentAssetLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:currentTrack];
        
        AVAssetTrack *currentAssetTrack = [[currentAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        UIImageOrientation currentAssetOrientation  = UIImageOrientationUp;
        BOOL  isCurrentAssetPortrait  = NO;
        CGAffineTransform currentTransform = currentAssetTrack.preferredTransform;
        
        if(currentTransform.a == 0 && currentTransform.b == 1.0 && currentTransform.c == -1.0 && currentTransform.d == 0)  {currentAssetOrientation= UIImageOrientationRight; isCurrentAssetPortrait = YES;}
        if(currentTransform.a == 0 && currentTransform.b == -1.0 && currentTransform.c == 1.0 && currentTransform.d == 0)  {currentAssetOrientation =  UIImageOrientationLeft; isCurrentAssetPortrait = YES;}
        if(currentTransform.a == 1.0 && currentTransform.b == 0 && currentTransform.c == 0 && currentTransform.d == 1.0)   {currentAssetOrientation =  UIImageOrientationUp;}
        if(currentTransform.a == -1.0 && currentTransform.b == 0 && currentTransform.c == 0 && currentTransform.d == -1.0) {currentAssetOrientation = UIImageOrientationDown;}
        
        CGFloat FirstAssetScaleToFitRatio = 640.0/640.0;
        if(isCurrentAssetPortrait){
            FirstAssetScaleToFitRatio = 640.0/640.0;
            CGAffineTransform FirstAssetScaleFactor = CGAffineTransformMakeScale(FirstAssetScaleToFitRatio,FirstAssetScaleToFitRatio);
            [currentAssetLayerInstruction setTransform:CGAffineTransformConcat(currentAssetTrack.preferredTransform, FirstAssetScaleFactor) atTime:duration];
        }else{
            CGAffineTransform FirstAssetScaleFactor = CGAffineTransformMakeScale(FirstAssetScaleToFitRatio,FirstAssetScaleToFitRatio);
            [currentAssetLayerInstruction setTransform:CGAffineTransformConcat(CGAffineTransformConcat(currentAssetTrack.preferredTransform, FirstAssetScaleFactor),CGAffineTransformMakeTranslation(0, 0)) atTime:duration];
        }
        
        duration = CMTimeAdd(duration, currentAsset.duration);
        
        [currentAssetLayerInstruction setOpacity:0.0 atTime:duration];
        [arrayInstruction addObject:currentAssetLayerInstruction];
        
    }
    
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, duration);
    mainInstruction.layerInstructions = arrayInstruction;
    
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
    mainCompositionInst.renderSize = CGSizeMake(640.0, 640.0);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // 调用播放方法
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:mixComposition];
        playerItem.videoComposition = mainCompositionInst;
        successBlcok(playerItem,mixComposition,mainCompositionInst);
    });
}

- (void)createVideoFromManager:(VideoEditManager *)manager success:(SuccessBlcok)successBlcok{
    
    NSMutableArray *videos = [NSMutableArray new];
    if (VideoEditManager.shareVideoEidtManager.startSubtitleInfo) {
        NSURL *videoUrl = [NSURL fileURLWithPath:VideoEditManager.shareVideoEidtManager.startSubtitleInfo.subtileVideoFile];
        [videos addObject:videoUrl];
    }
    
    for (SelectAssetInfo* info in manager.selectPHAssets) {
        NSURL *videoUrl = [NSURL fileURLWithPath:info.latestVideoPath];
        [videos addObject:videoUrl];
    }
    
    if (VideoEditManager.shareVideoEidtManager.endSubtitleInfo) {
        NSURL *videoUrl = [NSURL fileURLWithPath:VideoEditManager.shareVideoEidtManager.endSubtitleInfo.subtileVideoFile];
        [videos addObject:videoUrl];
    }
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    // 音频通道
    AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    
    videoComposition.frameDuration = CMTimeMake(1,30);
    videoComposition.renderScale = 1.0;
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
    
    float time = 0;
    
    for (int i = 0; i < videos.count; i++) {
        
        NSURL *url = videos[i];
        //        AVURLAsset *currentAsset = [[AVURLAsset alloc] initWithURL:url options:nil];
        
        AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:url options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey]];
        
        NSError *error = nil;
        
        BOOL ok = NO;
        
        AVAssetTrack *sourceVideoTrack = [[sourceAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        
        AVAssetTrack *sourceAudioTrack = nil;
        if ([sourceAsset tracksWithMediaType:AVMediaTypeAudio].count > 0) {
            sourceAudioTrack = [[sourceAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        }
        
        CGSize temp = CGSizeApplyAffineTransform(sourceVideoTrack.naturalSize, sourceVideoTrack.preferredTransform);
        
        CGSize size = CGSizeMake(fabs(temp.width), fabs(temp.height));
        
        CGAffineTransform transform = sourceVideoTrack.preferredTransform;
        
        videoComposition.renderSize = CGSizeMake(960, 540);
        
        if (size.width > size.height && size.height < 540) {
            [layerInstruction setTransform:transform atTime:CMTimeMakeWithSeconds(time, 30)];
        }
        else {
            float s = 540.0/size.height;
            CGAffineTransform new = CGAffineTransformConcat(transform, CGAffineTransformMakeScale(s,s));
            
            float x = (960 - size.width*s)/2;
            
            float y = (540 - size.height*s)/2;
            
            CGAffineTransform newer = CGAffineTransformConcat(new, CGAffineTransformMakeTranslation(x, y));
            [layerInstruction setTransform:newer atTime:CMTimeMakeWithSeconds(time, 30)];
        }
        
        CMTime currentCompDuration = [composition duration];
        
        ok = [compositionVideoTrack insertTimeRange:sourceVideoTrack.timeRange ofTrack:sourceVideoTrack atTime:currentCompDuration error:&error];
        
        if (!ok) {
            NSLog(@"something went wrong");
        }
        
        NSLog(@"the [composition duration] is %lld",[composition duration].value/[composition duration].timescale);
        
        if (sourceAudioTrack) {
            [compositionAudioTrack insertTimeRange:sourceAudioTrack.timeRange ofTrack:[[sourceAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:currentCompDuration error:nil];
        }else{
            [compositionAudioTrack insertEmptyTimeRange:CMTimeRangeMake(currentCompDuration, sourceVideoTrack.timeRange.duration)];
        }
        
        time += CMTimeGetSeconds(sourceVideoTrack.timeRange.duration);
    }
    
    instruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];
    instruction.timeRange = compositionVideoTrack.timeRange;
    
    videoComposition.instructions = [NSArray arrayWithObject:instruction];
    videoComposition.renderSize = CGSizeMake(Comp_Video_Width, Comp_Video_Height);
    
    if (manager.stickerInfosArr.count > 0) {
        [self addStickerLayerWithAVMutableVideoComposition:videoComposition withStickerInfo:manager.stickerInfosArr];
    }
    
    CMTime duration = CMTimeMake(time, 1);
    
    NSMutableArray *mixArray = [NSMutableArray new];
    if (manager.audioInfosArr.count > 0) {
        for (RecordAudioInfo *audioInfo in manager.audioInfosArr) {
            
            AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:audioInfo.audioUrl] options:nil];
            
            CMTime startTime = CMTimeMake(audioInfo.startTime, 1);
            CMTimeRange timeRange = CMTimeRangeMake(startTime, audioAsset.duration);
            
            NSError *error = nil;
            
            //将超出视频长度的audio排除。 duration为组合之后，视频的长度。
            if (startTime.value/startTime.timescale < duration.value/duration.timescale) {
                CGFloat audioNatureDur = audioAsset.duration.value/audioAsset.duration.timescale;
                CGFloat startTimeValue = startTime.value/startTime.timescale;
                CGFloat videoDuration = duration.value/duration.timescale;
                
                CMTimeRange compoRange = kCMTimeRangeZero;
                if (startTimeValue + audioNatureDur < videoDuration) {
                    //去掉timeRange这段音频
                    [compositionAudioTrack removeTimeRange:timeRange];
                    //然后在timeRange这段上插入空白。
                    [compositionAudioTrack insertEmptyTimeRange:timeRange];
                    compoRange = timeRange;
                }else{
                    CGFloat realDuration = videoDuration - startTimeValue;
                    CMTime durationTime = CMTimeMake(realDuration, 1);
                    CMTimeRange realTimeRange = CMTimeRangeMake(startTime, durationTime);
                    [compositionAudioTrack removeTimeRange:realTimeRange];
                    //然后在timeRange这段上插入空白。
                    [compositionAudioTrack insertEmptyTimeRange:realTimeRange];
                    compoRange = realTimeRange;
                }
                
                AVAssetTrack *replaceAudioTrack = [audioAsset tracksWithMediaType:AVMediaTypeAudio][0];
                // Step 3
                // Add custom audio track to the composition
                AVMutableCompositionTrack *compositonReplaceAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
                
                [compositonReplaceAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, compoRange.duration) ofTrack:replaceAudioTrack atTime:compoRange.start error:&error];
                
                AVMutableAudioMixInputParameters *mixParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compositonReplaceAudioTrack];
                [mixParameters setVolumeRampFromStartVolume:1 toEndVolume:1 timeRange:compoRange];
                [mixArray addObject:mixParameters];
            }
        }
    }
    
    AVMutableAudioMix *mutableAudioMix = [AVMutableAudioMix audioMix];
    mutableAudioMix.inputParameters = mixArray;
    
    NSString *outPutFilePath = [[self compositionPath] stringByAppendingPathComponent:@"output.mp4"];
    //存在该文件
    if ([MTFileManager fileExistsAtPath:outPutFilePath]) {
        [MTFileManager clearCachesWithFilePath:outPutFilePath];
    }
    
    if (mixArray.count > 0) {
        [self composition:composition videoCompositon:videoComposition audioMix:mutableAudioMix storePath:outPutFilePath success:successBlcok];
    }else{
        [self composition:composition videoCompositon:videoComposition audioMix:nil storePath:outPutFilePath success:successBlcok];
    }
}

- (void)preCreateVideoFromManager:(VideoEditManager *)manager success:(PreSuccessBlcok)successBlcok{
    NSMutableArray *videos = [NSMutableArray new];
    for (SelectAssetInfo* info in manager.selectPHAssets) {
        NSURL *videoUrl = [NSURL fileURLWithPath:info.latestVideoPath];
        [videos addObject:videoUrl];
    }
    
    // 创建可变的音视频组合
    AVMutableComposition *mixComposition = [AVMutableComposition composition];
    
    // 音频通道
    AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVMutableVideoCompositionInstruction * mainInstruction =
    [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    
    NSMutableArray *arrayInstruction = [[NSMutableArray alloc] init];
    
    CMTime duration = kCMTimeZero;
    for(int i=0;i< videos.count;i++)
    {
        NSURL *url = videos[i];
        // 视频采集
        AVURLAsset *currentAsset = [[AVURLAsset alloc] initWithURL:url options:nil];
        
        AVMutableCompositionTrack *currentVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        if ([[currentAsset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
            [currentVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, currentAsset.duration) ofTrack:[[currentAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:duration error:nil];
        }else{
            [currentVideoTrack insertEmptyTimeRange:CMTimeRangeMake(duration, currentAsset.duration)];
        }
        
        if ([[currentAsset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
            [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, currentAsset.duration) ofTrack:[[currentAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:duration error:nil];
        }else{
            [audioTrack insertEmptyTimeRange:CMTimeRangeMake(duration, currentAsset.duration)];
        }
        
        AVMutableVideoCompositionLayerInstruction *currentAssetLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:currentVideoTrack];
        
        AVAssetTrack *currentAssetTrack = [[currentAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        UIImageOrientation currentAssetOrientation  = UIImageOrientationUp;
        CGAffineTransform currentTransform = currentAssetTrack.preferredTransform;
        if(currentTransform.a == 0 && currentTransform.b == 1.0 && currentTransform.c == -1.0 && currentTransform.d == 0)  {
            currentAssetOrientation = UIImageOrientationRight;
        }
        if(currentTransform.a == 0 && currentTransform.b == -1.0 && currentTransform.c == 1.0 && currentTransform.d == 0)  {
            currentAssetOrientation =  UIImageOrientationLeft;
        }
        if(currentTransform.a == 1.0 && currentTransform.b == 0 && currentTransform.c == 0 && currentTransform.d == 1.0)
        {
            currentAssetOrientation =  UIImageOrientationUp;
        }
        if(currentTransform.a == -1.0 && currentTransform.b == 0 && currentTransform.c == 0 && currentTransform.d == -1.0) {
            currentAssetOrientation = UIImageOrientationDown;
        }
        
        CGAffineTransform t1;
        CGAffineTransform t2;
        
        if (currentAssetOrientation == UIImageOrientationRight) {
            t1 = CGAffineTransformMakeTranslation(currentAssetTrack.naturalSize.height,0.0);
            t2 = CGAffineTransformRotate(t1,M_PI_2);
        }else if (currentAssetOrientation == UIImageOrientationDown){
            t1 = CGAffineTransformMakeTranslation(currentAssetTrack.naturalSize.width, currentAssetTrack.naturalSize.height);
            t2 = CGAffineTransformRotate(t1,M_PI);
        }else if (currentAssetOrientation == UIImageOrientationLeft){
            t1 = CGAffineTransformMakeTranslation(0.0, currentAssetTrack.naturalSize.width);
            t2 = CGAffineTransformRotate(t1,M_PI_2*3.0);
        }else{
            t1 = CGAffineTransformMakeTranslation(0.0, 0);
            t2 = CGAffineTransformRotate(t1,M_PI_2*4.0);
        }
        
        [currentAssetLayerInstruction setTransform:t2 atTime:duration];
        duration = CMTimeAdd(duration, currentAsset.duration);
        [currentAssetLayerInstruction setOpacity:0.0 atTime:duration];
        [arrayInstruction addObject:currentAssetLayerInstruction];
    }
    
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, duration);
    mainInstruction.layerInstructions = arrayInstruction;
    
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
//    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
//    mainCompositionInst.renderSize = CGSizeMake(640.0, 320);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // 调用播放方法
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:mixComposition];
        playerItem.videoComposition = mainCompositionInst;
        successBlcok(playerItem);
    });
}

@end
