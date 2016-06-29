//
//  HorizTableView.m
//  common
//
//  Created by xiangbiying on 12-5-25.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "CxHorizTableView.h"
#import "UIView+mt.h"

@interface NSArray (Integer)

-(NSInteger) intAtIndex:(NSInteger)index;

-(BOOL) containsInt:(NSInteger)num;

-(NSInteger) indexOfInt:(NSInteger)num;

@end

@interface NSMutableArray (Integer)

-(void) addInt:(NSInteger)num;

-(void) removeInt:(NSInteger)num;

-(void) replaceInt:(NSInteger)num atIndex:(NSInteger)index;

@end

@interface CxHorizTableView()

-(void)_horiz_table_init;

-(NSArray*)visibleIndexsForOffset:(CGFloat)offset;

-(NSArray*)insectionIndexsBetween:(NSArray*)indexs with:(NSArray*)indexs2;

-(NSMutableArray*)diffIndexsBetween:(NSArray*)indexs with:(NSArray*)indexs2;

-(void) tapToSelectTableCell:(CGPoint)location;

@end

@implementation CxHorizTableView

@synthesize dataSource = _dataSource;
@synthesize tableDelegate = _tableDelegate;

-(void)_horiz_table_init {
    self.delegate = self;
    self.clipsToBounds = YES;
    _visibleIndexs = [[NSMutableArray alloc] init];
    _visibleCells = [[NSMutableArray alloc] init];
    
}

-(id) init {
    if (self = [super init]) {  
        [self _horiz_table_init];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {  
        [self _horiz_table_init];
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {  
        [self _horiz_table_init];
    }
    return self;
}

-(void)reloadData {
    NSAssert(_dataSource != nil, @"The data source can't be nil !");
    
    [_visibleIndexs removeAllObjects];
    
    for (UIView* cell in _visibleCells) {
        [cell removeFromSuperview];
    }
    [_visibleCells removeAllObjects];
    
    CGFloat cell_width = [_dataSource cellWidthInTableView:self];
    NSInteger count = [_dataSource numberOfCellsInTableView:self];
    
    self.contentSize = CGSizeMake(cell_width * count, [self height]);
    
    [self updateCells];
}

-(void)reloadCellAtIndex:(NSInteger)index {
    UIView* cell = [self visibleCellForIndex:index];
    if (cell) {
        UIView* cell2 = [_dataSource tableView:self cellForIndex:index reused:cell];
        if (cell2 != cell) {
            cell2.frame = cell.frame;
            [cell removeFromSuperview];
            assert(cell2);
            [self insertSubview:cell2 atIndex:0];
            
            NSInteger _index = [_visibleCells indexOfObject:cell];
            [_visibleCells replaceObjectAtIndex:_index withObject:cell2];
        }

    }
}

-(void)updateCells {  
    CGFloat offx = floorf(self.contentOffset.x);
    NSArray* v_indexs = [self visibleIndexsForOffset:offx];
    NSArray* insec_indexs = [self insectionIndexsBetween:v_indexs with:_visibleIndexs];
    NSMutableArray* v_upt_indexs = [self diffIndexsBetween:v_indexs with:insec_indexs];
    NSMutableArray* reused_indexs = [self diffIndexsBetween:_visibleIndexs with:insec_indexs];
    
    CGFloat cell_width = [_dataSource cellWidthInTableView:self];
    
    for (int i = 0; i < v_upt_indexs.count; i++) {
        NSInteger upt_index = [v_upt_indexs intAtIndex:i];
        UIView* reused_cell = nil;
        NSInteger r_index = 0;
        if (reused_indexs.count > 0) {
            r_index = [reused_indexs intAtIndex:0];
            [reused_indexs removeObjectAtIndex:0];
            reused_cell = [self visibleCellForIndex:r_index];
        }
        
        assert(_dataSource);
        
        UIView* cell = [_dataSource tableView:self cellForIndex:upt_index reused:reused_cell];
        cell.frame = CGRectMake(cell_width * upt_index, 0, cell_width, [self height]);
        
        assert(cell);
        [self insertSubview:cell atIndex:0]; //don't hide the scollbar
        
        if (reused_cell != cell) {
            if (reused_cell) {
                [reused_cell removeFromSuperview];  //20120723
                [_visibleIndexs removeInt:r_index];   //20120718
                [_visibleCells removeObject:reused_cell];
            }
            [_visibleCells addObject:cell];
            [_visibleIndexs addInt:upt_index];
        } else {
            NSInteger k = [_visibleIndexs indexOfInt:r_index];
            [_visibleIndexs replaceInt:upt_index atIndex:k];
        }
    }
    
}

-(NSArray*)visibleIndexsForOffset:(CGFloat)offset {
    
    CGFloat cell_width = [_dataSource cellWidthInTableView:self];
    NSInteger count = [_dataSource numberOfCellsInTableView:self];
    
    NSInteger s_index = MAX(0, floor(offset / cell_width));  //2015.07.22
    NSInteger e_index = MAX(0, ceil((offset + [self width]) / cell_width));  //2015.07.22
    NSMutableArray* indexs = [NSMutableArray array];
    
    for (NSInteger i = s_index; i < e_index; i++) {
        if (i < count) {
            [indexs addInt:i];
        }
    }
    return indexs;
}
                             
-(NSArray*)insectionIndexsBetween:(NSArray*)indexs with:(NSArray*)indexs2 {
    NSMutableArray* insection = [NSMutableArray array];
    for (int i = 0; i < indexs.count; i++) {
        NSInteger n = [indexs intAtIndex:i];
        if ([indexs2 containsInt:n]) {
            [insection addInt:n];
        }
    }
    return insection;
}

-(NSMutableArray*)diffIndexsBetween:(NSArray*)indexs with:(NSArray*)indexs2 {
    NSMutableArray* diffs = [NSMutableArray array];
    for (int i = 0; i < indexs.count; i++) {
        NSInteger n = [indexs intAtIndex:i];
        if (![indexs2 containsInt:n]) {
            [diffs addInt:n];
        }
    }
    return diffs;
}

-(UIView*) visibleCellForIndex:(NSInteger)index {
    NSInteger _index = [_visibleIndexs indexOfInt:index];
    if (_index != NSNotFound) { 
        return (UIView*)[_visibleCells objectAtIndex:_index];
    }
    return nil;
}

-(NSArray *)visibleCells {
    return _visibleCells;
}

-(NSArray*)indexsForVisibleCells {
    return _visibleIndexs;
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offx = self.contentOffset.x;
    
    if (offx >= 0 && offx <= self.contentSize.width - [self width]) {
        [self updateCells];
    }
    if ([_tableDelegate respondsToSelector:@selector(tableViewDidScroll:)]) {
        [_tableDelegate tableViewDidScroll:self];
    }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if ([_tableDelegate respondsToSelector:@selector(tableViewDidEndDecelerating:)]) {
        [_tableDelegate tableViewDidEndDecelerating:self];
    }
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if ([_tableDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
        [_tableDelegate tableViewDidEndDragging:self willDecelerate:decelerate];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if ([_tableDelegate respondsToSelector:@selector(tableViewWillEndDragging:withVelocity:targetContentOffset:)]) {
        [_tableDelegate tableViewWillEndDragging:self withVelocity:velocity targetContentOffset:targetContentOffset];
    }
}

-(void)tapToSelectTableCell:(CGPoint)location {
    if ([_tableDelegate respondsToSelector:@selector(tableView:didSelectCellAtIndex:)]) {
        CGFloat offx = location.x;
        CGFloat cell_width = [_dataSource cellWidthInTableView:self];
        CGFloat count = [_dataSource numberOfCellsInTableView:self];
        NSInteger selected_index = offx / cell_width;
        if (selected_index >= 0 && selected_index < count) {
            [_tableDelegate tableView:self didSelectCellAtIndex:selected_index];
        }
    }        
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    CGPoint location = [[touches anyObject] locationInView:self];
    [self tapToSelectTableCell:location];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if ([_tableDelegate respondsToSelector:@selector(viewForZoomingInTableView:)]) {
        return [_tableDelegate viewForZoomingInTableView:self];
    }
    return nil;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    if ([_tableDelegate respondsToSelector:@selector(tableViewWillBeginZooming:withView:)]) {
        [_tableDelegate tableViewWillBeginZooming:self withView:view];
    }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    if ([_tableDelegate respondsToSelector:@selector(tableViewDidEndZooming:withView:atScale:)]) {
        [_tableDelegate tableViewDidEndZooming:self withView:view atScale:scale];
    }
}



@end

@implementation NSArray (Integer) 

-(NSInteger) intAtIndex:(NSInteger)index {
    return [[self objectAtIndex:index] intValue];
}

-(BOOL) containsInt:(NSInteger)num {
    return [self containsObject:[NSNumber numberWithInteger:num]];
}

-(NSInteger) indexOfInt:(NSInteger)num {
    return [self indexOfObject:[NSNumber numberWithInteger:num]];
}

@end

@implementation NSMutableArray (Integer) 

-(void) addInt:(NSInteger)num {
    [self addObject:[NSNumber numberWithInteger:num]];
}

-(void) removeInt:(NSInteger)num {
    [self removeObject:[NSNumber numberWithInteger:num]];
}

-(void) replaceInt:(NSInteger)num atIndex:(NSInteger)index {
    [self replaceObjectAtIndex:index withObject:[NSNumber numberWithInteger:num]];
}

@end










