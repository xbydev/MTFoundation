//
//  UIImage+mt.h
//  MTFoundationDemo
//
//  Created by xiangbiying on 16/6/21.
//  Copyright © 2016年 xiangby. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (mt)

+(UIImage*) imageWithURL:(NSURL*)url;

+(UIImage*) imageWithFileInDomain:(NSString *)filepath;

+(UIImage*) imageNamed:(NSString *)name scale:(float)scale;

+(UIImage*) imageNamed:(NSString *)name rect:(CGRect)rect;

+(UIImage*) imageWithContentsOfFile:(NSString *)path rect:(CGRect)rect;

+(UIImage*) resizeableImageNamed:(NSString *)name capLeft:(CGFloat)left capTop:(CGFloat)top;

+(UIImage*) imageWithColor:(UIColor*)color size:(CGSize)size;

+(UIImage*) imageWithColor:(UIColor*)color size:(CGSize)size cornerRadius:(CGFloat)radius;

-(void) drawInRect:(CGRect)rect color:(UIColor*)color;

-(BOOL) writeToFileInDomain:(NSString*)filepath;

-(BOOL) writeToFilePath:(NSString*)filepath;

-(UIImage*) resizableImageWithConstrainedSize:(CGSize)maxSize;

-(UIImage*) imageInRect:(CGRect)rect;

-(UIImage*) bluredImage;

-(UIImage*) fixOrientation;

-(UIImage*) bluredImage2;

//如果图片太大可能压缩不到limit值以下
-(NSData*) imageJPEGRepresentationWithLimitLength:(NSUInteger)length;//data length

@end
