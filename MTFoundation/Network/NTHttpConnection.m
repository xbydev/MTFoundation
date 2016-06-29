//
//  NTHttpConnection.m
//  MTFoundationDemo
//
//  Created by xiangbiying on 16/6/29.
//  Copyright © 2016年 xiangby. All rights reserved.
//

#import "NTHttpConnection.h"

@implementation NTHttpConnection

-(id)initWithRequest:(NSURLRequest *)request {
    return [self initWithRequest:request startImmediately:YES];
}

-(id)initWithRequest:(NSURLRequest *)request startImmediately:(BOOL)startImmediately {
    if (self = [super initWithRequest:request delegate:self startImmediately:startImmediately]) {
        _totalData = [[NSMutableData alloc] init];
    }
    return self;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_totalData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
}

@end
