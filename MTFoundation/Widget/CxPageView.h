//
//  PageView.h
//  common
//
//  Created by xiangbiying on 12-5-26.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "CxHorizTableView.h"

@protocol CxPageViewDelegate;

@interface CxPageView : CxHorizTableView<CxHorizTableViewDataSource> {

    NSTimer* _scrollTimer;

}

@property (assign,nonatomic) NSInteger pageNumber;

@property (assign,nonatomic) NSInteger pageIndex;

@property (assign,nonatomic) BOOL pageCircled;

@property (weak,nonatomic) id<CxPageViewDelegate> pageDelegate;

@property (assign,nonatomic) NSTimeInterval autoScrollInterval;

@property (readonly,nonatomic) UIView* page;

-(void) setPageIndex:(NSInteger)index animated:(BOOL)animated;

-(void) reloadPageAtIndex:(NSInteger)index;

-(UIView*) pageForIndex:(NSInteger)index reused:(UIView*)reusedPage;

-(void) pageDidChanged:(NSInteger)pageIndex;

@end

@protocol CxPageViewDelegate <NSObject>

-(UIView*) pageView:(CxPageView*)pageView pageForIndex:(NSInteger)index reused:(UIView*)reusedPage;

@optional
-(void) pageView:(CxPageView*)pageView pageDidChanged:(NSInteger)index;

@end
