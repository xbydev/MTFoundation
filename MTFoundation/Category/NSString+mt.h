//
//  NSString+mt.h
//  MTFoundationDemo
//
//  Created by xiangbiying on 16/6/21.
//  Copyright © 2016年 xiangby. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSString (mt)

+(NSString*) macAddress;

+(NSString*) peerId;

+(NSString*) URLEncodedWtihDictionary:(NSDictionary*)dictionary;

+(NSString*) stringRandom:(int)count;

+(NSString*) formateIntegerValue:(NSInteger)aIntValue;

-(NSString *) MD5;

-(NSString*) URLEncodedString2;

-(NSString*) URLDecodedString2;

-(int) hexIntValue;

-(NSString *) capitalizedFirstLetter;

-(BOOL) matchesWithPattern:(NSString*)pattern;

-(int) charValue;

-(CGSize) sizeWithFont:(UIFont*)font maxSize:(CGSize)maxSize;

-(NSString*) trim;

@end

@interface NSString (JavaLikeStringHandle)

- (NSString *)substringWithBeginIndex:(NSInteger)beginIndex endIndex:(NSInteger)endIndex;
- (NSInteger)find:(NSString *)str fromIndex:(NSInteger)fromInex reverse:(BOOL)reverse caseSensitive:(BOOL)caseSensitive;
- (NSInteger)find:(NSString *)str fromIndex:(NSInteger)fromInex reverse:(BOOL)reverse;
- (NSInteger)find:(NSString *)str fromIndex:(NSInteger)fromInex;
- (NSInteger)find:(NSString *)str;
- (NSString *)substringWithOutRange:(NSRange)range;

@end

