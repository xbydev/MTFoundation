//
//  PageView.m
//  common
//
//  Created by xiangbiying on 12-5-26.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "CxPageView.h"
#import "UIView+mt.h"

@interface CxPageView()

-(void)_page_view_init;

-(void)autoScroll;

@end

@implementation CxPageView

@synthesize pageNumber = _pageNumber;
@synthesize pageIndex = _pageIndex;
@synthesize pageCircled = _pageCircled;
@synthesize pageDelegate = _pageDelegate;
@synthesize autoScrollInterval = _autoScrollInterval;
@synthesize page = _page;

-(void)_page_view_init {
    self.dataSource = self;
    self.pagingEnabled = YES;
    self.exclusiveTouch = YES;
}

-(id)init {
    if (self = [super init]) {
        [self _page_view_init];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self _page_view_init];
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self _page_view_init];
    }
    return self;
}

-(CGFloat)cellWidthInTableView:(CxHorizTableView *)tableView {
    return [self width];
}

-(NSInteger)numberOfCellsInTableView:(CxHorizTableView *)tableView {
    return (_pageCircled && _pageNumber > 0) ?  _pageNumber + 2 : _pageNumber;
}

-(void)setPageIndex:(NSInteger)index {
    [self setPageIndex:index animated:NO];
}

-(void)setPageIndex:(NSInteger)index animated:(BOOL)animated {
    float width = [self cellWidthInTableView:self];
    [self setContentOffset:CGPointMake(width * index, 0) animated:animated];
    
    if (self.contentSize.width <= 0) {
        _pageIndex = index;
    }
}

-(void)setAutoScrollInterval:(NSTimeInterval)interval {
    _autoScrollInterval = interval;
    
    [_scrollTimer invalidate];
    _scrollTimer = nil;
    
    if (interval > 0) {
        _scrollTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(autoScroll) userInfo:nil repeats:YES];
    }
    
}

-(void)autoScroll {
    float offx = self.contentOffset.x;
    float width = [self.dataSource cellWidthInTableView:self];
    float f_index = offx / width;
    if (f_index == fabsf(f_index)) {
        [self setContentOffset:CGPointMake(offx + width, 0) animated:YES];
    }
}

-(UIView *)page {
    NSInteger index = _pageIndex;
    
    if (_pageCircled) {
        index += 1;
    }
    
    return [self visibleCellForIndex:index];
}

-(void)reloadData {
    if (_pageCircled && self.contentOffset.x <= 0) {
        float width = [self.dataSource cellWidthInTableView:self];
        self.contentOffset = CGPointMake(width, 0);
    } else {
        self.pageIndex = _pageIndex;
    }
    [super reloadData];
}

-(void)reloadPageAtIndex:(NSInteger)index {
    if (_pageCircled) {
        if (index == 0) {
            [self reloadCellAtIndex:1];
            [self reloadCellAtIndex:_pageNumber+1];
        } else if(index == _pageNumber - 1) {
            [self reloadCellAtIndex:_pageNumber];
            [self reloadCellAtIndex:0];
        } else {
            [self reloadCellAtIndex:index+1];
        }
    } else {
        [self reloadCellAtIndex:index];
    }
    
}

-(UIView *)tableView:(CxHorizTableView *)tableView cellForIndex:(NSInteger)index reused:(UIView *)reusedCell {
    if (_pageCircled) {
        if (index == 0) {
            index = _pageNumber - 1;
        } else if(index == _pageNumber + 1) {
            index = 0;
        } else {
            index -= 1;
        }
    }
    
    return [self pageForIndex:index reused:reusedCell];
}

-(UIView*) pageForIndex:(NSInteger)index reused:(UIView*)reusedPage {
    if (_pageDelegate) {
        return [_pageDelegate pageView:self pageForIndex:index reused:reusedPage];
    } else {
        return reusedPage ? reusedPage : [[UIView alloc] init];
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if (self.contentSize.width > 0) {
        
        float offx = self.contentOffset.x;
        if (_pageCircled) {
            float width = [self.dataSource cellWidthInTableView:self];
            
            if (offx <= 0) {

                self.contentOffset = CGPointMake(width * _pageNumber, 0);  
                return;
                
            } else if(offx >= width * (_pageNumber + 1)) { 

                //self.contentSize.width - [self width]
                //self.contentOffset = CGPointMake(2 * width - [self width], 0);
                
                self.contentOffset = CGPointMake(width, 0);
                return;
            } 
        } 
        
        [super scrollViewDidScroll:scrollView];

        float width = [self cellWidthInTableView:self];
        float f_page_index = self.contentOffset.x / width;
        int page_index = (int)f_page_index;
        if (page_index == f_page_index) {
            if(_pageCircled) page_index -= 1;
            if(page_index >= 0 && page_index != _pageIndex) {
                _pageIndex = page_index;
                [self pageDidChanged:page_index];
            }
        }
    }
}

-(void)pageDidChanged:(NSInteger)pageIndex {
    if ([_pageDelegate respondsToSelector:@selector(pageView:pageDidChanged:)]) {
        [_pageDelegate pageView:self pageDidChanged:pageIndex];
    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [_scrollTimer invalidate];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    self.autoScrollInterval = _autoScrollInterval;
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    self.autoScrollInterval = _autoScrollInterval;
}

-(void)dealloc {
    [_scrollTimer invalidate];
}

//以下三个scrollview drag相关的函数，add by xiangby,滑动结束后，再启动timer。
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    
    [_scrollTimer invalidate];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    
    if (!decelerate) {
        
        self.autoScrollInterval = _autoScrollInterval;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    
    self.autoScrollInterval = _autoScrollInterval;
}

@end




