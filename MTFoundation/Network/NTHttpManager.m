//
//  NTHttpManager.m
//  MTFoundationDemo
//
//  Created by xiangbiying on 16/6/29.
//  Copyright © 2016年 xiangby. All rights reserved.
//

#import "NTHttpManager.h"
#import "NSData+SBJson.h"

@implementation NTHttpManager

+(id) sharedManager {
    static id instance = nil;
    if (!instance) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{

            instance = [[self alloc] init];
        });
    }
    return instance;
}

-(id)init {
    if (self = [super init]) {
        _requestQueue = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void) sendHttpRequest:(NSURLRequest*)req withHandler:
(void (^)(NSHTTPURLResponse* response, NSData* data, NSError* error))handler {
    
    [_requestQueue addObject:req];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSHTTPURLResponse* response = nil;
        NSError* error = nil;
        NSData* data = [NSURLConnection sendSynchronousRequest:req
                                             returningResponse:&response error:&error];
        
        dispatch_block_t block = ^{
            
            //fixed on 2015.5.12
            //if ([_requestQueue containsObject:req]) {
            //    handler(response, data, error);
            //    [_requestQueue removeObject:req];
            //}
            
            NSUInteger index = [_requestQueue indexOfObjectIdenticalTo:req];
            
            if (index != NSNotFound) {
                handler(response, data, error);
                [_requestQueue removeObjectAtIndex:index];
            }
            
        };
        
        NSTimeInterval dalay = self.callbackDelay;
        
        if (dalay <= 0) {
            dispatch_async(dispatch_get_main_queue(), block);
        } else {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, dalay * NSEC_PER_SEC),
                           dispatch_get_main_queue(), block);
        }
        
    });
    
}

-(void) sendHttpRequest:(NSURLRequest*)req forJsonDataReceived:
(void (^)(NSHTTPURLResponse* response, id jsonData, NSError* error))handler {
    
    [self sendHttpRequest:req withHandler:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        
        id jsonData = [data jsonFormat];
        
#ifdef DEBUG
        if (error) {
            NSLog(@"http error: %@  %@", req.URL.path, error);
        } else if (!jsonData) {
            NSLog(@"http error: %@  %ld  %@", req.URL.path, (long)response.statusCode
                  ,[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        }
#endif
        handler(response, jsonData, error);
    }];
    
}

-(void)cancelHttpRequest:(NSURLRequest *)req {
    [_requestQueue removeObjectIdenticalTo:req];
}

@end
