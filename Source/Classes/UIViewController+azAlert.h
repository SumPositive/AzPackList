//
//  UIViewController+azAlert.h
//  PackList
//
//  Created by 松山正和 on 2017/07/02.
//
//

#import <UIKit/UIKit.h>

@interface UIViewController (azAlert)

/**
 Depricated UIAlertView を置換するためのメソッド
 */
- (void)azAleartTitle:(nullable NSString*)title
              message:(nonnull NSString*)message
                   b1:(nonnull NSString*)b1
              b1style:(UIAlertActionStyle)b1style
             b1action:(void (^_Nullable)(UIAlertAction *_Nullable))b1action
                   b2:(nonnull NSString*)b2
              b2style:(UIAlertActionStyle)b2style
             b2action:(void (^_Nullable)(UIAlertAction *_Nullable))b2action
             animated:(BOOL)animated
           completion:(void (^_Nullable)(void))completion;

@end
