//
//  PLObjectModel.h
//  MTFoundationDemo
//
//  Created by xiangbiying on 16/6/21.
//  Copyright © 2016年 xiangby. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PLObjectModel : NSObject

+(NSDictionary*) definedPropertyTypes;

+(id) objectWithProps:(NSDictionary*)props;

-(id) initWithProperties:(NSDictionary*)props;

@end
