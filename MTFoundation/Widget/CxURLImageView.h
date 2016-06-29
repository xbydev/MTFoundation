//
//  CxURLImageView.h
//  Whisper
//
//  Created by xiangbiying on 14-5-11.
//  Copyright (c) 2014年 JoyoDream. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CxURLImageViewDelegate;

@interface CxURLImageView : UIImageView<NSURLConnectionDataDelegate> {

    NSURLConnection* _conn;
    
    NSMutableData* _imgData;
        
}

@property (weak,nonatomic) id<CxURLImageViewDelegate> delegate;

@property (strong,nonatomic) NSCache* cache;

@property (copy,nonatomic) NSString* cacheDir;

@property (assign,nonatomic) BOOL transitionOnLoad;

@property (assign,nonatomic) NSInteger errorCode;

@property (assign,nonatomic) CGSize constraintSize;

@property (assign,nonatomic) BOOL asyncRenderDecode;

@property (copy,nonatomic) NSString* imageUrl;

-(UIImage*) loadImageFromURL:(NSString*)url;

-(void) cancelLoading;

@end

@protocol CxURLImageViewDelegate <NSObject>

-(void) imageDidLoadFromURL:(CxURLImageView*)view success:(BOOL)success;

@end
