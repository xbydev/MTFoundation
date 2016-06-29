//
//  NTHttpConnection.h
//  MTFoundationDemo
//
//  Created by xiangbiying on 16/6/29.
//  Copyright © 2016年 xiangby. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NTHttpConnection : NSURLConnection<NSURLConnectionDataDelegate> {
    
    NSMutableData* _totalData;
}

-(id)initWithRequest:(NSURLRequest *)request;

-(id)initWithRequest:(NSURLRequest *)request startImmediately:(BOOL)startImmediately;

@end
