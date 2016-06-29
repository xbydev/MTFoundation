//
//  NTHttpManager.h
//  MTFoundationDemo
//
//  Created by xiangbiying on 16/6/29.
//  Copyright © 2016年 xiangby. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTHttpRequest.h"

@interface NTHttpManager : NSObject{
    
    NSMutableArray* _requestQueue;
}
@property (assign,nonatomic) NSTimeInterval callbackDelay;

+(id) sharedManager;

-(void) sendHttpRequest:(NSURLRequest*)req withHandler:
(void (^)(NSHTTPURLResponse* response, NSData* data, NSError* error))handler;

-(void) sendHttpRequest:(NSURLRequest*)req forJsonDataReceived:
(void (^)(NSHTTPURLResponse* response, id jsonData, NSError* error))handler;

-(void) cancelHttpRequest:(NSURLRequest*)req;

@end
