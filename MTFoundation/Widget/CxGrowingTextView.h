//
//  CxGrowingTextView.h
//  common
//
//  Created by xiangbiying on 13-8-8.
//
//

#import <UIKit/UIKit.h>

typedef enum {
  kTextGrowDown,
  kTextGrowUp,
  kTextGrowCenter
} CxTextGrowType;

@interface CxGrowingTextView : UITextView {

    
}

@property (assign,nonatomic) CxTextGrowType growType;

@property (assign,nonatomic) float maxHeight;

@property (assign,nonatomic) float minHeight;

-(float) growToFitTextSize;

@end

@protocol CxGrowingTextViewDelegate <UITextViewDelegate>

-(void) textView:(CxGrowingTextView*)textView didGrowHeight:(float)dh;

@optional
-(BOOL) checkIsSingleFirstResponser;

@end
