//
//  HorizTableView.h
//  common
//
//  Created by xiangbiying on 12-5-25.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CxHorizTableViewDataSource;
@protocol CxHorizTableViewDelegate;

@interface CxHorizTableView : UIScrollView<UIScrollViewDelegate> {

    NSMutableArray* _visibleIndexs;  
    
    NSMutableArray* _visibleCells;
    
}

@property (weak,nonatomic) id<CxHorizTableViewDataSource> dataSource;

@property (weak,nonatomic) id<CxHorizTableViewDelegate> tableDelegate;

-(void)reloadData;

-(void)reloadCellAtIndex:(NSInteger)index;

-(UIView*)visibleCellForIndex:(NSInteger)index;

-(NSArray*)visibleCells;

-(NSArray*)indexsForVisibleCells;

-(void)updateCells;

-(void)tapToSelectTableCell:(CGPoint)location;

@end

@protocol CxHorizTableViewDataSource <NSObject>

-(NSInteger) numberOfCellsInTableView:(CxHorizTableView*)tableView;

-(CGFloat) cellWidthInTableView:(CxHorizTableView*)tableView;

-(UIView*) tableView:(CxHorizTableView*)tableView cellForIndex:(NSInteger)index reused:(UIView*)reusedCell;

@end

@protocol CxHorizTableViewDelegate <NSObject>

@optional
- (void)tableView:(CxHorizTableView *)tableView didSelectCellAtIndex:(NSInteger)index;

-(void)tableViewDidScroll:(CxHorizTableView *)tableView;
-(void)tableViewDidEndDecelerating:(CxHorizTableView *)tableView;

-(void)tableViewDidEndDragging:(CxHorizTableView *)tableView willDecelerate:(BOOL)decelerate;
- (void)tableViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset;

- (UIView *)viewForZoomingInTableView:(CxHorizTableView *)tableView;
- (void)tableViewWillBeginZooming:(CxHorizTableView *)tableView withView:(UIView *)view;
- (void)tableViewDidEndZooming:(CxHorizTableView *)tableView withView:(UIView *)view atScale:(float)scale;

@end
