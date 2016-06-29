//
//  XLGridView.m
//  common
//
//  Created by xiangbiying on 12-4-18.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "CxGridView.h"
#import "UIView+mt.h"

@interface CxGridView()

-(void)_grid_view_init;
-(void) handleCellTapEvent:(UITapGestureRecognizer*)sender;

@end

@implementation CxGridView

@synthesize gridDataSource = _gridDataSource;
@synthesize gridDelegate = _gridDelegate;

-(void)_grid_view_init {
    self.dataSource = self;
    self.delegate = self;
    self.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.clipsToBounds = YES;
    
    [self addTapGestureRecognizer:self forAction:@selector(handleCellTapEvent:)];
}

-(id)init {
    if (self = [super init]) {
        [self _grid_view_init];
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self _grid_view_init];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self _grid_view_init];
    }
    return self;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger total_count = [self.gridDataSource numberCellsInGridView:self];
    NSInteger cols = [self.gridDataSource numberColumnsOfRowInGridView:self];
    return ceil(total_count * 1.0 / cols);
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* identifier = @"grid_cell";
    UITableViewCell* row_view = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    NSInteger cols = [self.gridDataSource numberColumnsOfRowInGridView:self];
    NSInteger row = [indexPath row];
    NSInteger total_count = [self.gridDataSource numberCellsInGridView:self];
    
    //float row_gap = [self.gridDataSource gapBetweenRowsInGridView:self] / 2;
    CGSize cell_size = [self.gridDataSource cellSizeInGridView:self];
    
    float col_gap;
    if (self.ignoreColumnSideGap) {
        if (cols > 1) {
            col_gap = (self.frame.size.width - cell_size.width * cols) / (cols - 1);
        } else {
            col_gap = 0;
        }
    } else {
        col_gap = (self.frame.size.width - cell_size.width * cols) / (cols + 1);
    }
    
    if (!row_view) {
        row_view = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        row_view.selectionStyle = UITableViewCellSelectionStyleNone;
        
        row_view.backgroundColor = [UIColor clearColor];
        
        UIView* content_view = row_view.contentView;
        
        if (self.rowBackgroundColor) {
            content_view.backgroundColor = self.rowBackgroundColor;
        }
        
        float offx = self.ignoreColumnSideGap ? 0 : col_gap;
        
        for (int i = 0; i < cols; i++) {
            if (i + row * cols < total_count) {
                UIView* cell = [self.gridDataSource gridView:self cellForRow:[indexPath row] columns:i reused:nil];
                cell.frame = CGRectMake((cell_size.width + col_gap) * i + offx, 0,
                                        cell_size.width, cell_size.height);
                [content_view addSubview:cell];
            }
        }
        
    } else {
        
        UIView* content_view = row_view.contentView;
        
        NSMutableArray* reused_cells = [NSMutableArray arrayWithArray:content_view.subviews];
        
        float offx = self.ignoreColumnSideGap ? 0 : col_gap;
        
        for (int i = 0; i < cols; i++) {
            if (i + row * cols < total_count) {
                UIView* reused_cell = nil;
                if (reused_cells.count > 0) {
                    reused_cell = [reused_cells objectAtIndex:0];
                    [reused_cells removeObjectAtIndex:0];
                }
                UIView* cell = [_gridDataSource gridView:self cellForRow:row columns:i reused:reused_cell];
                if (cell != reused_cell) {
                    [reused_cell removeFromSuperview];
                }
                cell.frame = CGRectMake((cell_size.width + col_gap) * i + offx, 0,
                                        cell_size.width, cell_size.height);
                [content_view addSubview:cell];
            }
        }
        
        for (UIView* remain_cell in reused_cells) {
            [remain_cell removeFromSuperview];
        }
        
    }
    
    return row_view;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    float gap = [self.gridDataSource gapBetweenRowsInGridView:self];
    CGSize cell_size = [self.gridDataSource cellSizeInGridView:self];
    return gap + cell_size.height;
}

-(UIView*) cellForRow:(NSInteger)row columns:(NSInteger)col {
    UITableViewCell* row_view = [self cellForRowAtIndexPath:
                                 [NSIndexPath indexPathForRow:row inSection:0]];
    if (row_view) {
        NSArray* cells = row_view.contentView.subviews;
        
        NSInteger cols = [self.gridDataSource numberColumnsOfRowInGridView:self];
        CGSize cell_size = [self.gridDataSource cellSizeInGridView:self];
        float col_gap = (self.frame.size.width - cell_size.width * cols) / (cols + 1);
        
        for (UIView* cell in cells) {
            if (fabs([cell left] - ((cell_size.width + col_gap) * col + col_gap)) < 1) {
                return cell;
            }
        }
    }
    
    return nil;
}

-(void) reloadCellForRow:(NSInteger)row columns:(NSInteger)col {
    
    UITableViewCell* row_view = [self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    
    if (row_view) {
        UIView* content_view = row_view.contentView;
        NSArray* cells = content_view.subviews;
        
        NSInteger cols = [self.gridDataSource numberColumnsOfRowInGridView:self];
        CGSize cell_size = [self.gridDataSource cellSizeInGridView:self];
        float col_gap = (self.frame.size.width - cell_size.width * cols) / (cols + 1);
        //float row_gap = [self.gridDataSource gapBetweenRowsInGridView:self] / 2;
        
        float offx = self.ignoreColumnSideGap ? 0 : col_gap;
        
        for (UIView* cell in cells) {
            if (fabs([cell left] - ((cell_size.width + col_gap) * col + col_gap)) < 1) {
                UIView* cell2 = [_gridDataSource gridView:self cellForRow:row columns:col reused:cell];
                if (cell2 != cell) {
                    [cell removeFromSuperview];
                    cell.frame = CGRectMake((cell_size.width + col_gap) * col + offx, 0,
                                            cell_size.width, cell_size.height);
                    [content_view addSubview:cell];
                }
            }
        }
    }
    
}

-(void) handleCellTapEvent:(UITapGestureRecognizer*)sender {
    
    if (_gridDelegate) {
        
        CGPoint location = [sender locationInView:self];
        
        NSArray* visibleRows = [self visibleCells];
        
        int cols = [self.gridDataSource numberColumnsOfRowInGridView:self];
        CGSize cell_size = [self.gridDataSource cellSizeInGridView:self];
        float col_gap = (self.frame.size.width - cell_size.width * cols) / (cols + 1);
        
        for (int i = 0; i < visibleRows.count; i++) {
            UITableViewCell* row_view = [visibleRows objectAtIndex:i];  
            if (CGRectContainsPoint(row_view.frame, location)) {
                
                CGPoint position = row_view.frame.origin;
                CGPoint location2 = CGPointMake(location.x - position.x, location.y - position.y);
                
                NSArray* cells = row_view.contentView.subviews;
                
                BOOL done = NO;
                
                float offx = self.ignoreColumnSideGap ? 0 : col_gap;
                
                for (UIView* cell in cells) {
                    if (CGRectContainsPoint(cell.frame, location2)) {
                        int row = [[self indexPathForCell:row_view] row];
                        int col = round(([cell left] - offx) / (cell_size.width + col_gap));
                        if ([_gridDelegate respondsToSelector:
                                    @selector(gridView:didSelectCellAtRow:column:)]) {
                            [_gridDelegate gridView:self didSelectCellAtRow:row column:col];
                        }
        
                        done = YES;
                        break;
                    }
                }
                
                if (done) {
                    break;
                }
                
            }
        }
        
    }
    
}

//-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
//    [super touchesEnded:touches withEvent:event];
//    CGPoint location = [[touches anyObject] locationInView:self];
//    [self handleCellTapEvent:location];
//}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([_gridDelegate respondsToSelector:@selector(gridViewDidScroll:)]) {
        [_gridDelegate gridViewDidScroll:self];
    }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if ([_gridDelegate respondsToSelector:@selector(gridViewDidEndDecelerating:)]) {
        [_gridDelegate gridViewDidEndDecelerating:self];
    }
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if ([_gridDelegate respondsToSelector:@selector(gridViewDidEndDragging:willDecelerate:)]) {
        [_gridDelegate gridViewDidEndDragging:self willDecelerate:decelerate];
    }
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if ([_gridDelegate respondsToSelector:@selector(gridViewWillBeginDragging:)]) {
        [_gridDelegate gridViewWillBeginDragging:self];
    }
}

-(void) scrollToRow:(int)row atScrollPosition:(UITableViewScrollPosition)scrollPosition 
           animated:(BOOL)animated {
    [self scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0] atScrollPosition:scrollPosition animated:animated];
}

-(BOOL) positionForCell:(UIView*)cell row:(int*)row column:(int*)col {
    UITableViewCell* table_cell = [cell findSuperViewWithClass:[UITableViewCell class]]; //(UITableViewCell*)cell.superview.superview;
    if (table_cell) {
        NSIndexPath* index_path = [self indexPathForCell:table_cell];
        *row = [index_path row];
        
        int cols = [self.gridDataSource numberColumnsOfRowInGridView:self];
        CGSize cell_size = [self.gridDataSource cellSizeInGridView:self];
        float col_gap = (self.frame.size.width - cell_size.width * cols) / (cols + 1);
        
        *col = round(([cell left] - col_gap) / (cell_size.width + col_gap));
        
        return YES;
    }
    return NO;
}

@end

