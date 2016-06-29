//
//  XLGridView.h
//  common
//
//  Created by xiangbiying on 12-4-18.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CxGridViewDataSource;
@protocol CxGridViewDelegate;

@interface CxGridView : UITableView <UITableViewDataSource,UITableViewDelegate>

@property (weak,nonatomic) id<CxGridViewDataSource> gridDataSource;

@property (weak,nonatomic) id<CxGridViewDelegate> gridDelegate;

//2014.8.6
@property (assign,nonatomic) BOOL ignoreColumnSideGap;

@property (strong,nonatomic) UIColor* rowBackgroundColor;

-(void) reloadCellForRow:(NSInteger)row columns:(NSInteger)col;

-(UIView*) cellForRow:(NSInteger)row columns:(NSInteger)col;

-(void) scrollToRow:(int)row atScrollPosition:(UITableViewScrollPosition)scrollPosition 
           animated:(BOOL)animated;

//20130306
-(BOOL) positionForCell:(UIView*)cell row:(int*)row column:(int*)col;

@end

@protocol CxGridViewDataSource <NSObject>

-(UIView*) gridView:(CxGridView*)gridView cellForRow:(NSInteger)row columns:(NSInteger)col 
             reused:(UIView*)reusedCell;

-(NSInteger) numberColumnsOfRowInGridView:(CxGridView*)gridView;

-(CGFloat) gapBetweenRowsInGridView:(CxGridView*)gridView;

-(CGSize) cellSizeInGridView:(CxGridView*)gridView;

-(NSInteger) numberCellsInGridView:(CxGridView*)gridView;

@end

@protocol CxGridViewDelegate <NSObject>

@optional
-(void)gridView:(CxGridView*)gridView didSelectCellAtRow:(NSInteger)row column:(NSInteger)col;

-(void)gridViewDidScroll:(CxGridView *)gridView;

-(void)gridViewDidEndDecelerating:(CxGridView *)gridView;

-(void)gridViewDidEndDragging:(CxGridView *)gridView willDecelerate:(BOOL)decelerate;

-(void)gridViewWillBeginDragging:(CxGridView *)gridView;

-(BOOL)isShouldBounces;

@end
