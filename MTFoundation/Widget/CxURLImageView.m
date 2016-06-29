//
//  CxURLImageView.m
//  Whisper
//
//  Created by xiangbiying on 14-5-11.
//  Copyright (c) 2014年 JoyoDream. All rights reserved.
//

#import "CxURLImageView.h"
#import "NSString+mt.h"
#import "UIImage+mt.h"
#import "NSObject+mt.h"

@implementation CxURLImageView

//-(void) loadImageFromURL:(NSString*)url {
//    [self loadImageFromURL:url cacheDir:nil];
//}

-(UIImage*) loadImageFromURL:(NSString*)url {
    
    self.imageUrl = url;
    
    [self cancelLoading];
    
    NSString* uuid = [url MD5];
    
    if (_cache) {
        UIImage* image = [_cache objectForKey:uuid];
        if (image) {
            
            if (_constraintSize.width > 0 && _constraintSize.height > 0) {
                
                image = [image resizableImageWithConstrainedSize:_constraintSize];
            }
            self.image = image;
            [self.delegate imageDidLoadFromURL:self success:YES];
            
            return image;
        }
    }
    
    if (_cacheDir) {
        
        if (self.asyncRenderDecode) {
            
            __block UIImage* dstImage = nil;
            
            [self asyncTask:^{
                
                UIImage* image = [self loadImageFromCacheDir:uuid];
                
                if (image) {
                    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
                    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
                    
                    dstImage = UIGraphicsGetImageFromCurrentImageContext();
                    
                    UIGraphicsEndImageContext();
                }
                
                
            } returnOnMain:^{
                
                if (dstImage) {
                    
                    self.image = dstImage;
                    
                    [_cache setObject:dstImage forKey:uuid];
                    
                    [self.delegate imageDidLoadFromURL:self success:YES];
                    
                } else {
                    
                     [self loadImageFromNetwork:url];
                    
                }
                
            }];
            
        } else {
            
            
            UIImage* image = [self loadImageFromCacheDir:uuid];
            
            if (image) {
                
                self.image = image;
                
                [_cache setObject:image forKey:uuid];
                
                [self.delegate imageDidLoadFromURL:self success:YES];
                
                return image;
                
            } else {
                
                [self loadImageFromNetwork:url];
                
            }
            
        }
        
        
        
        
    }
    
    return nil;
}

-(UIImage*) loadImageFromCacheDir:(NSString*)uuid {
    NSString* filepath = [_cacheDir stringByAppendingPathComponent:uuid];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filepath]) {
        
        NSData* data = [NSData dataWithContentsOfFile:filepath];
        UIImage* image = [UIImage imageWithData:data];
        
        if (image) {
            
            if (_constraintSize.width > 0 && _constraintSize.height > 0) {
                image = [image resizableImageWithConstrainedSize:_constraintSize];
            }
            
            return image;
            
        }
    }
    return nil;
}

-(void) loadImageFromNetwork:(NSString*)url {
    NSURL* nsurl = [NSURL URLWithString:url];
    NSURLRequest* req = [NSURLRequest requestWithURL:nsurl];
    _conn = [NSURLConnection connectionWithRequest:req delegate:self];
}

-(void)setImage:(UIImage *)image {
    [super setImage:image];
    [self cancelLoading];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"image loading did fail with error: %@", error);
    _imgData = nil;
    self.errorCode = -1;
    [self.delegate imageDidLoadFromURL:self success:NO];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSHTTPURLResponse* resp = (NSHTTPURLResponse*)response;
    //NSLog(@"receive response: %d", resp.statusCode);
    
    if (resp.statusCode == 200) {
        self.errorCode = 0;
        _imgData = [NSMutableData data];
    } else {
        _imgData = nil;
        self.errorCode = resp.statusCode;
        [self.delegate imageDidLoadFromURL:self success:NO];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    //NSLog(@"did receive data: %d", data.length);
    [_imgData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {

    if (_imgData.length > 0) {
        
        NSString* url = [[connection.originalRequest URL] absoluteString];
        NSString* uuid = [url MD5];
        
        NSData* data = _imgData;
        
        if (self.asyncRenderDecode) {
            
            __block UIImage* dstImage = nil;
            
            [self asyncTask:^{
               
                UIImage* image = [UIImage imageWithData:data];
                
                if (image) {
                    
                    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
                    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
                    
                    dstImage = UIGraphicsGetImageFromCurrentImageContext();
                    
                    UIGraphicsEndImageContext();
                    
                    
                    if (_cacheDir) {
                        
                        NSString* filepath = [_cacheDir stringByAppendingPathComponent:uuid];
                        [data writeToFile:filepath atomically:YES];
                        
                    }
                    
                }
                
            } returnOnMain:^{
                
                if (dstImage) {
                    
                    [_cache setObject:dstImage forKey:uuid];
                    
                    if (self.transitionOnLoad) {
                        [self.layer addAnimation:[CATransition animation] forKey:kCATransition];
                    }
                    
                    self.image = dstImage;
                    
                    [self.delegate imageDidLoadFromURL:self success:YES];

                    
                }
                
            }];
            
            
        } else {
            
            UIImage* image = [UIImage imageWithData:data];
            
            if (image) {
                
                NSString* url = [[connection.originalRequest URL] absoluteString];
                NSString* uuid = [url MD5];
                
                [_cache setObject:image forKey:uuid];
                
                if (self.transitionOnLoad) {
                    [self.layer addAnimation:[CATransition animation] forKey:kCATransition];
                }
                
                self.image = image;
                
                [self.delegate imageDidLoadFromURL:self success:YES];
                
                if (_cacheDir) {
                    
                    [self asyncTask:^{
                        
                        NSString* filepath = [_cacheDir stringByAppendingPathComponent:uuid];
                        [data writeToFile:filepath atomically:YES];
                        
                    }];
                    
                }
                
            }
            
        }
        
        
        
    } else {
        
        [self.delegate imageDidLoadFromURL:self success:NO];
        
    }
}

- (void)cancelLoading {
    if (_conn) {
        [_conn cancel];
        _conn = nil;
        _imgData = nil;
    }
}

-(void) asynImageRenderDecode:(UIImage*)image {
    
    __block UIImage* dstImage = nil;
    
    [self asyncTask:^{
        
        UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
        [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
        dstImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
    } returnOnMain:^{
        
        self.image = dstImage;
        
    }];
    
    
}

@end
