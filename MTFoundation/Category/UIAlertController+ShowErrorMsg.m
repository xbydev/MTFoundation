//
//  UIAlertController+ShowErrorMsg.m
//  MTFoundation
//
//  Created by xiangbiying on 2018/9/3.
//

#import "UIAlertController+ShowErrorMsg.h"

@implementation UIAlertController (ShowErrorMsg)

- (void)showAlertTitle:(NSString *)title error:(NSString *)errorMsg{
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:title message:errorMsg preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    [alertVC addAction:okAction];
    [self presentViewController:alertVC animated:YES completion:nil];
}

@end
