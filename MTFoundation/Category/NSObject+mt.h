//
//  NSObject+mt.h
//  MTFoundationDemo
//
//  Created by xiangbiying on 16/6/21.
//  Copyright © 2016年 xiangby. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (mt)

+(id) object;

+(BOOL)switchMethod:(SEL)origSel withMethod:(SEL)altSel;

-(void) asyncTask:(dispatch_block_t)block;

-(void) syncTaskOnMain:(dispatch_block_t)block;

-(void) asyncTask:(dispatch_block_t)block after:(NSTimeInterval)delay;

-(void) syncTaskOnMain:(dispatch_block_t)block after:(NSTimeInterval)delay;

-(void) asyncTask:(dispatch_block_t)block returnOnMain:(dispatch_block_t)block2;

-(BOOL) execOnceOnKey:(NSString*)key block:(dispatch_block_t)block;

@end
