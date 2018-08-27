//
//  VideoAudioComposition.m
//  MTFoundation
//
//  Created by xiangbiying on 2018/7/24.
//

#import "VideoAudioComposition.h"
#import "MTFileManager.h"
#import "SelectAssetInfo.h"

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
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    CGFloat timeScale = asset.duration.timescale;
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    // 音频通道
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    // 视频采集
    AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    // 音频采集
    AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    
    // 这里的startTime和endTime都是秒，需要乘以timeScale来组成CMTime
    CMTime startTime = CMTimeMake(0 * timeScale, timeScale);
    CMTime duration = CMTimeMake(asset.duration.value * timeScale, timeScale);
    CMTimeRange fastRange = CMTimeRangeMake(startTime, duration);
    CMTime scaledDuration = CMTimeMake(duration.value / fastRate, timeScale);
    
    // 视频采集通道
    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    // 把采集轨道数据加入到可变轨道之中
    [videoTrack insertTimeRange:fastRange ofTrack:videoAssetTrack atTime:kCMTimeZero error:nil];
    
    // 音频采集通道
    AVAssetTrack *audioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    // 加入合成轨道之中
    [audioTrack insertTimeRange:fastRange ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];
    
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

- (void)roateVideo:(NSURL *)videoUrl withDegree:(NSInteger)degree success:(SuccessBlcok)successBlcok{
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
        t1 = CGAffineTransformMakeTranslation(assetVideoTrack.naturalSize.height,0.0);
        t2 = CGAffineTransformRotate(t1,M_PI_2);
        mutableVideoComposition.renderSize = CGSizeMake(assetVideoTrack.naturalSize.height,assetVideoTrack.naturalSize.width);
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
    
    //    t1 = CGAffineTransformMakeTranslation(assetVideoTrack.naturalSize.height, 0.0);
    //    // Rotate transformation
    //    t2 = CGAffineTransformRotate(t1, degreesToRadians(90.0));
    //    mutableVideoComposition.renderSize = CGSizeMake(assetVideoTrack.naturalSize.height,assetVideoTrack.naturalSize.width);
//    t1 = CGAffineTransformMakeTranslation(0.0, assetVideoTrack.naturalSize.width);
//    t2 = CGAffineTransformRotate(t1,M_PI_2*3.0);
//    mutableVideoComposition.renderSize = CGSizeMake(assetVideoTrack.naturalSize.height,assetVideoTrack.naturalSize.width);
    
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

- (void)addSticker:(NSArray *)stickerInfoArr toVideo:(NSURL *)videoUrl success:(PreSuccessBlcok)successBlcok{
    
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
    
    // 创建可变的音视频组合
    AVMutableComposition *composition = [AVMutableComposition composition];
    // 视频通道
    AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    // 音频通道
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    CMTime atTime = kCMTimeZero;
    
    for (int i = 0;i < videos.count;i ++) {
        NSURL *url = videos[i];
        CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, kCMTimeZero);
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
    dispatch_async(dispatch_get_main_queue(), ^{
        // 调用播放方法
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:composition];
        successBlcok(playerItem);
    });
}

@end
