//
//  UIImage+mt.m
//  MTFoundationDemo
//
//  Created by xiangbiying on 16/6/21.
//  Copyright © 2016年 xiangby. All rights reserved.
//

#import "UIImage+mt.h"
#import "NSFileManager+mt.h"

@implementation UIImage (mt)

+(UIImage*) imageWithURL:(NSURL*)url {
    NSURLRequest* req = [NSURLRequest requestWithURL:url];
    NSHTTPURLResponse* response;
    NSData* data = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:NULL];
    if ([response statusCode] == 200) {
        return [UIImage imageWithData:data];
    }
    return nil;
}

+(UIImage *)imageWithFileInDomain:(NSString *)filepath {
    NSString* file = [NSFileManager pathInDocuments:filepath];
    return [UIImage imageWithContentsOfFile:file];
}

+(UIImage *)imageNamed:(NSString *)name scale:(float)scale {
    UIImage* image = [UIImage imageNamed:name];
    return [UIImage imageWithCGImage:image.CGImage scale:scale orientation:UIImageOrientationUp];
}

+(UIImage*) imageNamed:(NSString *)name rect:(CGRect)rect {
    UIImage* image = [UIImage imageNamed:name];
    CGImageRef c_image = CGImageCreateWithImageInRect(image.CGImage, rect);
    return [[UIImage alloc] initWithCGImage:c_image];
}

+(UIImage*) imageWithContentsOfFile:(NSString *)path rect:(CGRect)rect {
    UIImage* image = [UIImage imageWithContentsOfFile:path];
    CGImageRef c_image = CGImageCreateWithImageInRect(image.CGImage, rect);
    return [[UIImage alloc] initWithCGImage:c_image];
}

+(UIImage *)resizeableImageNamed:(NSString *)name capLeft:(CGFloat)left capTop:(CGFloat)top {
    UIImage *resizeImage = [UIImage imageNamed:name];
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 5.0) {
        UIEdgeInsets edgeInsets = UIEdgeInsetsMake(top, left, top, left);
        resizeImage = [resizeImage resizableImageWithCapInsets:edgeInsets];
    } else {
        resizeImage = [resizeImage stretchableImageWithLeftCapWidth:left topCapHeight:top];
    }
    return resizeImage;
}

-(void) drawInRect:(CGRect)rect color:(UIColor*)color {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    
    
    CGContextSaveGState(ctx);
    
    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, 0, -rect.size.height);
    
    CGColorSpaceCreateDeviceGray();
    
    CGContextDrawImage(ctx, rect, self.CGImage);
    CGContextClipToMask(ctx, rect, self.CGImage);
    CGContextSetBlendMode(ctx, kCGBlendModeMultiply);  //kCGBlendModeSourceIn
    CGContextSetFillColorWithColor(ctx, color.CGColor);
    CGContextFillRect(ctx, rect);
    
    CGContextRestoreGState(ctx);
}

-(BOOL)writeToFileInDomain:(NSString *)filepath {
    return [self writeToFilePath:[NSFileManager pathInDocuments:filepath]];
}

-(BOOL) writeToFilePath:(NSString*)filepath {
    NSData* data = UIImagePNGRepresentation(self);
    if (data) {
        return [data writeToFile:filepath atomically:YES];
    }
    return NO;
}

-(UIImage*) resizableImageWithConstrainedSize:(CGSize)maxSize {
    CGSize size = self.size;
    
    //ios系统在绘制正方形图片的时，偶尔会出现宽高不一致的情况，但差值不会超过一个像素。因此，原始图片宽高之差在一个像素之内时，我们认为这张图片是正方形的。 add by xiangby
    if(fabs(size.width - size.height) <= 1){
        size.width = MIN(size.width, size.height);
        size.height = MIN(size.width, size.height);
    }
    
    float width, height;
    
    if (size.width / size.height >= maxSize.width / maxSize.height) {
        
        width = MIN(size.width, maxSize.width);
        height = size.height * (width / size.width);
        
    } else {
        
        height = MIN(size.height, maxSize.height);
        width = size.width * (height / size.height);
        
    }
    
    if (width < size.width || height < size.height) {
        UIGraphicsBeginImageContext(CGSizeMake(width, height));
        [self drawInRect:CGRectMake(0, 0, width, height)];
        UIImage* img = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return img;
    }
    
    return self;
}

-(UIImage*) imageInRect:(CGRect)rect {
    CGImageRef imgref = CGImageCreateWithImageInRect(self.CGImage, rect);
    return [UIImage imageWithCGImage:imgref];
}

- (UIImage *)bluredImage
{
    CIImage *image = [CIImage imageWithCGImage:self.CGImage];
    CIFilter *filter = [CIFilter filterWithName: @"CIGaussianBlur"];
    [filter setValue:image forKey: @"inputImage"];
    [filter setValue:[NSNumber numberWithFloat:6] forKey: @"inputRadius"];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *outputImage = filter.outputImage;
    CGRect rect = [outputImage extent];
    rect.origin.x = 8;
    rect.size.width -= 54; //去除两边的空白。
    CGImageRef cgimg = [context createCGImage:outputImage fromRect:rect];
    UIImage *newImg = [UIImage imageWithCGImage:cgimg];
    CGImageRelease(cgimg);
    return newImg;
}

- (UIImage *)bluredImage2{
    CIImage *image = [CIImage imageWithCGImage:self.CGImage];
    CIFilter *filter = [CIFilter filterWithName: @"CIGaussianBlur"];
    [filter setValue:image forKey: @"inputImage"];
    [filter setValue:[NSNumber numberWithFloat:6] forKey: @"inputRadius"];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *outputImage = filter.outputImage;
    CGRect rect = [outputImage extent];
    rect.origin.x = 4;
    rect.size.width -= 88; //去除两边的空白。
    rect.origin.y = 4;
    rect.size.height -= 88; //去除上下空白。
    CGImageRef cgimg = [context createCGImage:outputImage fromRect:rect];
    UIImage *newImg = [UIImage imageWithCGImage:cgimg];
    CGImageRelease(cgimg);
    return newImg;
}

- (UIImage *)fixOrientation
{
    if (self.imageOrientation == UIImageOrientationUp)
        return self;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (self.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, self.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, self.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (self.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, self.size.width, self.size.height,
                                             CGImageGetBitsPerComponent(self.CGImage), 0,
                                             CGImageGetColorSpace(self.CGImage),
                                             CGImageGetBitmapInfo(self.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (self.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.height,self.size.width), self.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.width,self.size.height), self.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

+(UIImage*) imageWithColor:(UIColor*)color size:(CGSize)size {
    return [self imageWithColor:color size:size cornerRadius:0];
}

+(UIImage*) imageWithColor:(UIColor*)color size:(CGSize)size cornerRadius:(CGFloat)radius {
    CALayer* layer = [[CALayer alloc] init];
    layer.frame = CGRectMake(0, 0, size.width, size.height);
    layer.cornerRadius = radius;
    layer.backgroundColor = color.CGColor;
    
    //UIGraphicsBeginImageContext(size);
    float scale = [UIScreen mainScreen].scale;
    UIGraphicsBeginImageContextWithOptions(size, NO, scale);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [layer renderInContext:ctx];
    
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

-(NSData*) imageJPEGRepresentationWithLimitLength:(NSUInteger)length {
    
    NSData *data = UIImageJPEGRepresentation(self, 1);
    
    for (CGFloat i = 0.7; data.length > length; i -= 0.2) {//每次减0.2
        
        data = UIImageJPEGRepresentation(self, i);
        
        if (i < 0.15) {
            
            break;
        }
    }
    
    return data;
}

@end
