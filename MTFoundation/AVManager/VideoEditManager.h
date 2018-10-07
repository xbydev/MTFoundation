//
//  VideoEditManager.h
//  ChuangKe
//
//  Created by xiangbiying on 2018/8/14.
//  Copyright © 2018年 lelemi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "StickerInfo.h"
@class SelectAssetInfo;
@class EditSubtitleInfo;
@class AddAudioInfo;
@class EditStickerInfo;

@interface VideoEditManager : NSObject

+ (instancetype)shareVideoEidtManager;

@property(nonatomic, strong) NSString *compressedVideoDir;
//@property(nonatomic, strong) NSMutableArray *selectedVideoEidtInfoArr;
@property(nonatomic, strong) NSMutableArray *selectPHAssets;//PHAssets

//字幕、配音、贴图为全局属性。
@property(nonatomic, strong) EditSubtitleInfo *startSubtitleInfo;
@property(nonatomic, strong) EditSubtitleInfo *endSubtitleInfo;
//@property(nonatomic, strong) AddAudioInfo *addAudioInfo;
//@property(nonatomic, strong) EditStickerInfo *eidtStickerInfo;
@property(nonatomic, strong) NSMutableArray *stickerInfosArr;
@property(nonatomic, strong) NSMutableArray *audioInfosArr;
@property(nonatomic, strong, readonly) AVPlayerItem *currentPlayerItem;
//尝试直接处理预处理过的视频。

@property(nonatomic, strong, readonly) AVMutableComposition *compositon;
@property(nonatomic, strong, readonly) AVMutableVideoComposition *videoCompositon;

@property(nonatomic, assign) BOOL isSingleVideoChanged;

- (void)addSelectAssetInfo:(SelectAssetInfo *)info;

- (void)updateCurrentPlayerItem:(AVPlayerItem *)playerItem;



- (void)updateComposition:(AVMutableComposition *)compositon videoCompositon:(AVMutableVideoComposition *)videoCompositon;

- (CALayer *)builidStickerLayerWithInfo:(StickerInfo *)info;

- (void)clearSelectedAsset;
@end
