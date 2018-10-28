//
//  SelectAssetInfo.m
//  ChuangKe
//
//  Created by xiangbiying on 2018/8/19.
//  Copyright © 2018年 lelemi. All rights reserved.
//

#import "SelectAssetInfo.h"

@implementation SelectAssetInfo

- (id)copyWithZone:(NSZone *)zone {
    SelectAssetInfo *model = [[[self class] allocWithZone:zone] init];
    model.asset = self.asset;
    model.type = self.type;
    model.fileName = self.fileName;
    model.filePath = self.filePath;
    model.latestVideoPath = self.latestVideoPath;
    model.imageVideoDuration = self.imageVideoDuration;
    model.rotateInfo = self.rotateInfo;
    model.speedInfo = self.speedInfo;
    model.clipInfo = self.clipInfo;
    return model;
}

@end
