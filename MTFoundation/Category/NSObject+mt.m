//
//  NSObject+mt.m
//  MTFoundationDemo
//
//  Created by xiangbiying on 16/6/21.
//  Copyright © 2016年 xiangby. All rights reserved.
//

#import "NSObject+mt.h"
#import <objc/runtime.h>

@implementation NSObject (mt)
+(id) object {
    return [[self alloc] init];
}

+(BOOL)switchMethod:(SEL)origSel withMethod:(SEL)altSel{
    Method originMethod = class_getInstanceMethod(self, origSel);
    Method newMethod = class_getInstanceMethod(self, altSel);
    
    if (originMethod && newMethod) {
        if (class_addMethod(self, origSel, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
            class_replaceMethod(self, altSel, method_getImplementation(originMethod), method_getTypeEncoding(originMethod));
        } else {
            method_exchangeImplementations(originMethod, newMethod);
        }
        return YES;
    }
    return NO;
}

-(void)asyncTask:(dispatch_block_t)block {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

-(void)syncTaskOnMain:(dispatch_block_t)block {
    dispatch_async(dispatch_get_main_queue(), block);
}

-(void) asyncTask:(dispatch_block_t)block after:(NSTimeInterval)delay {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC),
                   dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

-(void) syncTaskOnMain:(dispatch_block_t)block after:(NSTimeInterval)delay {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC),
                   dispatch_get_main_queue(), block);
}

-(void)asyncTask:(dispatch_block_t)block returnOnMain:(dispatch_block_t)block2 {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        block();
        dispatch_async(dispatch_get_main_queue(), block2);
    });
    
}

-(BOOL) execOnceOnKey:(NSString*)key block:(dispatch_block_t)block {
    NSUserDefaults* udef = [NSUserDefaults standardUserDefaults];
    BOOL processed = [udef boolForKey:key];
    if (!processed) {
        block();
        [udef setBool:YES forKey:key];
        [udef synchronize];
        return YES;
    }
    return NO;
}
@end
