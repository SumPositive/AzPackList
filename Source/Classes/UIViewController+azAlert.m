//
//  UIViewController+azAlert.m
//  PackList
//
//  Created by 松山正和 on 2017/07/02.
//
//

#import "UIViewController+azAlert.h"

@implementation UIViewController (azAlert)

- (void)azAleartTitle:(nullable NSString*)title
              message:(nonnull NSString*)message
                   b1:(nonnull NSString*)b1
              b1style:(UIAlertActionStyle)b1style
             b1action:(void (^_Nullable)(UIAlertAction *_Nullable))b1action
                   b2:(nonnull NSString*)b2
              b2style:(UIAlertActionStyle)b2style
             b2action:(void (^_Nullable)(UIAlertAction *_Nullable))b2action
             animated:(BOOL)animated
           completion:(void (^_Nullable)(void))completion
{
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle: title
                                                                             message: message
                                                                      preferredStyle: UIAlertControllerStyleAlert];
    if (0 < b1.length) {
        UIAlertAction *acttion = [UIAlertAction actionWithTitle: b1
                                                          style: b1style
                                                        handler: b1action];
        [alertController addAction:acttion];
    }

    if (0 < b2.length) {
        UIAlertAction *acttion = [UIAlertAction actionWithTitle: b2
                                                          style: b2style
                                                        handler: b2action];
        [alertController addAction:acttion];
    }
    
    [self presentViewController: alertController
                       animated: animated
                     completion: completion];
}

@end
