//
//  SelectAssetInfo.h
//  ChuangKe
//
//  Created by xiangbiying on 2018/8/19.
//  Copyright © 2018年 lelemi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import "RotateInfo.h"
#import "SpeedInfo.h"
#import "ClipInfo.h"
#import "AddAudioInfo.h"
#import "EditStickerInfo.h"
#import "EditSubtitleInfo.h"

@interface SelectAssetInfo : NSObject

@property(nonatomic, strong)PHAsset *asset;
@property(nonatomic, strong)NSString *fileName;
@property(nonatomic, strong)NSString *filePath;
@property(nonatomic, assign)CGFloat imageVideoDuration; //是图片时设置，默认为3s
@property(nonatomic, strong)RotateInfo *rotateInfo;
@property(nonatomic, strong)SpeedInfo *speedInfo;
@property(nonatomic, strong)ClipInfo *clipInfo;
@property(nonatomic, strong)AddAudioInfo *addAudioInfo;
@property(nonatomic, strong)EditStickerInfo *eidtStickerInfo;
@property(nonatomic, strong)EditSubtitleInfo *editSubtitleInfo;

@end
