//
//  CxGrowingTextView.m
//  common
//
//  Created by xiangbiying on 13-8-8.
//
//

#import "CxGrowingTextView.h"
#import "iMacro.h"
#import "UIScrollView+mt.h"

@implementation CxGrowingTextView

-(void) __init {
    //self.scrollEnabled = NO;
    
    self.growType = kTextGrowDown;
    
    [self growToFitTextSize];
    
    REG_NOTIFY(@selector(textViewDidChange:), UITextViewTextDidChangeNotification);
    
    [self addObserver:self forKeyPath:@"text" options:0 context:NULL];
    
}

-(id)init {
    if (self = [super init]) {
        [self __init];
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self __init];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self __init];
    }
    return self;
}

-(float) growToFitTextSize {
    CGRect frame = self.frame;
    
    CGSize text_size = [self sizeThatFits:CGSizeMake(frame.size.width, MAXFLOAT)];
    float height = MAX(text_size.height, _minHeight);
    
    int dh = 0;
    
    if (_maxHeight <= 0 || _maxHeight >= height) {
        
        dh = height - frame.size.height;
        
    } else {
        
        dh = _maxHeight - frame.size.height;
        
    }
    
    if (dh != 0) {
        frame.size.height += dh;
        
        switch (_growType) {
            case kTextGrowUp:
                frame.origin.y -= dh;
                break;
            case kTextGrowCenter:
                frame.origin.y -= dh / 2;
            case kTextGrowDown:
            default:
                break;
        }
        
        self.frame = frame;
        
        [self scrollToBottom:YES];
  
    }
    
    //   if (!self.scrollEnabled) {
    //        self.scrollEnabled = YES;
    //   }
    
    if (dh != 0) {
        if ([self.delegate conformsToProtocol:@protocol(CxGrowingTextViewDelegate)]) {
            id<CxGrowingTextViewDelegate> delegate = (id<CxGrowingTextViewDelegate>)self.delegate;
            [delegate textView:self didGrowHeight:dh];
        }
    }
    
    return dh;
}

- (void)textViewDidChange:(NSNotification*)notification {
    
    if (notification.object == self) {
        
        [self growToFitTextSize];
        
    }
    
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqual:@"text"]) {
         [self growToFitTextSize];
    }
}

-(void)setContentOffset:(CGPoint)contentOffset {
    //NSLog(@"set content offset: %@ %d %d", NSStringFromCGPoint(contentOffset),
      //                    self.tracking, self.decelerating);
    
    if (!self.tracking && !self.decelerating) {
        UIEdgeInsets insets = self.contentInset;
        float dist = self.contentSize.height + insets.top + insets.bottom - _maxHeight;
        if (dist > 0 && _maxHeight > 0) {
            //NSLog(@"text view dist: %f", dist);
            [super setContentOffset:CGPointMake(contentOffset.x, dist)];
        } else {
            [super setContentOffset:CGPointMake(contentOffset.x, 0)];
        }
        return;
    }
    
    [super setContentOffset:contentOffset];
    
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender{
    
    if ([self.delegate conformsToProtocol:@protocol(CxGrowingTextViewDelegate)]) {
        
        id<CxGrowingTextViewDelegate> delegate = (id<CxGrowingTextViewDelegate>)self.delegate;
        BOOL isSingleFirstResponser = [delegate checkIsSingleFirstResponser];
        
        if (!isSingleFirstResponser) {
            if (action == @selector(paste:)) {
                return NO;
            }
            
            if (action == @selector(select:)) {
                return NO;
            }
            
            if (action == @selector(selectAll:)) {
                return NO;
            }
            return [super canPerformAction:action withSender:sender];
        }
    }
    
    return [super canPerformAction:action withSender:sender];
}

//-(void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated {
//     NSLog(@"set content offset with animated: %@", NSStringFromCGPoint(contentOffset));
//    [super setContentOffset:contentOffset animated:animated];
//}


-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeObserver:self forKeyPath:@"text"];
}

@end
