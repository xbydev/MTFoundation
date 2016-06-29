//
//  CxToast.h
//  common
//
//  Created by xiangbiying on 13-5-20.
//
//

#import <UIKit/UIKit.h>

@interface CxToast : UIView {

    UIView* _bgView;
    
    UILabel* _label;
}

@property (strong,nonatomic) NSString* text;

-(void) showInView:(UIView*)view duration:(NSTimeInterval)duration;

-(void) dismiss;

@end
