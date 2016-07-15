//
//  AsynURLImageView.m
//  MTFoundationDemo
//
//  Created by xiangbiying on 16/7/15.
//  Copyright © 2016年 xiangby. All rights reserved.
//

#import "AsynURLImageView.h"
#import "NSFileManager+mt.h"

static NSString* g_defaultCachePath;
static NSString* g_defaultCachePath2;

static NSCache* g_imageCache;

@implementation AsynURLImageView

+(NSString*) imageCachesPath {
    return g_defaultCachePath;
}

+(void) cleanCaches {
    
    NSFileManager* fm = [NSFileManager defaultManager];
    
    [fm removeItemAtPath:g_defaultCachePath error:NULL];
    
    [fm createDirectoryAtPath:g_defaultCachePath withIntermediateDirectories:YES
                   attributes:nil error:nil];
    
    [fm removeItemAtPath:g_defaultCachePath2 error:NULL];
    
    [fm createDirectoryAtPath:g_defaultCachePath2 withIntermediateDirectories:YES
                   attributes:nil error:nil];
    
}

+(void) cleanCachesIfExceedLimits {
    NSFileManager* fm = [NSFileManager defaultManager];
    NSArray* subpaths = [fm subpathsAtPath:g_defaultCachePath];
    if (subpaths.count > 200) {
        [fm removeItemAtPath:g_defaultCachePath error:NULL];
        [fm createDirectoryAtPath:g_defaultCachePath withIntermediateDirectories:YES
                       attributes:nil error:nil];
    }
}

+(void)initialize {
    g_imageCache = [[NSCache alloc] init];
    g_imageCache.countLimit = 10;
    
    NSFileManager* fm = [NSFileManager defaultManager];
    
    g_defaultCachePath = [NSFileManager pathInLibraryCaches:@"Images"];
    [fm createDirectoryAtPath:g_defaultCachePath withIntermediateDirectories:YES attributes:nil error:nil];
    
    g_defaultCachePath2 = [NSFileManager pathInLibraryCaches:@"Images2"];
    [fm createDirectoryAtPath:g_defaultCachePath2 withIntermediateDirectories:YES attributes:nil error:nil];
}

-(void)_init {
    self.cache = g_imageCache;
    self.cacheDir = g_defaultCachePath;
    self.transitionOnLoad = YES;
}

-(id)init {
    if (self = [super init]) {
        [self _init];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self _init];
    }
    return self;
}

-(id)initWithImage:(UIImage *)image {
    if (self = [super initWithImage:image]) {
        [self _init];
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self _init];
    }
    return self;
}

-(UIImage*)loadImageFromURL:(NSString *)url {
    
    if (url.length == 0) {
        return nil;
    }
    //    NSLog(@"loadIamgeFromeURL = %@",url);
    
    if (![url hasPrefix:@"http://"] && ![url hasPrefix:@"https://"]) {
        
        UIImage* image;
        
        if ([url hasPrefix:@"/"]) {
            image = [UIImage imageWithContentsOfFile:url];
        } else {
            image = [UIImage imageNamed:url];
        }
        
        self.image = image;
        
        [self.delegate imageDidLoadFromURL:self success:YES];
        
        return image;
    }
    
    return [super loadImageFromURL:url];
}

-(void)setCachesLongTime:(BOOL)cachesLongTime {
    _cachesLongTime = cachesLongTime;
    self.cacheDir = _cachesLongTime ? g_defaultCachePath2 : g_defaultCachePath;
}

@end
