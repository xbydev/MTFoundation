//
//  FMObjectProtocol.h
//  MTFoundationDemo
//
//  Created by xiangbiying on 16-6-21.
//  Copyright (c) 2016年 xiangby. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FMObjectProtocol <NSObject>

+(NSDictionary*) SQLFormat;

@property (assign,nonatomic) long primaryId;

@end
