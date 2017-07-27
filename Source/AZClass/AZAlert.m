//
//  AZAlert.m
//  UIAlertController+Wrapper アラート&アクションシート
//
//  Copyright 2017 Azukid
//  Created by 松山正和 on 2017/07/19.
//
//

#import "AZAlert.h"

#define IS_PAD      ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

@implementation AZAlert


#pragma mark - Private methods

+ (UIViewController*)getTopViewController
{
    UIViewController* vc = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    while (vc.presentedViewController) {
        vc = vc.presentedViewController;
    }
    return vc;
}

/*
 5ボタン
 */
+ (void)target:(UIViewController*_Nullable)target
         style:(UIAlertControllerStyle)style
          rect:(CGRect)rect
         title:(NSString*_Nullable)title
       message:(NSString*_Nullable)message
       b1title:(NSString*_Nonnull)b1title
       b1style:(UIAlertActionStyle)b1style
      b1action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b1action
       b2title:(NSString*_Nullable)b2title
       b2style:(UIAlertActionStyle)b2style
      b2action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b2action
       b3title:(NSString*_Nullable)b3title
       b3style:(UIAlertActionStyle)b3style
      b3action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b3action
       b4title:(NSString*_Nullable)b4title
       b4style:(UIAlertActionStyle)b4style
      b4action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b4action
       b5title:(NSString*_Nullable)b5title
       b5style:(UIAlertActionStyle)b5style
      b5action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b5action
{
    UIAlertController *alertController
    = [UIAlertController alertControllerWithTitle: title
                                          message: message
                                   preferredStyle: style];
    
    [alertController addAction:[UIAlertAction actionWithTitle: b1title
                                                        style: b1style
                                                      handler: b1action ]];

    if (b2title) {
        [alertController addAction:[UIAlertAction actionWithTitle: b2title
                                                            style: b2style
                                                          handler: b2action ]];
    }

    if (b3title) {
        [alertController addAction:[UIAlertAction actionWithTitle: b3title
                                                            style: b3style
                                                          handler: b3action ]];
    }
    
    if (b4title) {
        [alertController addAction:[UIAlertAction actionWithTitle: b4title
                                                            style: b4style
                                                          handler: b4action ]];
    }
    
    if (b5title) {
        [alertController addAction:[UIAlertAction actionWithTitle: b5title
                                                            style: b5style
                                                          handler: b5action ]];
    }
    
    if (target == nil) {
        target = [AZAlert getTopViewController];
    }

    if (style==UIAlertControllerStyleActionSheet && IS_PAD) {
        // rect 必須
        if (rect.size.width < 1.0 || rect.size.height < 1.0) {
            @throw @"iPad: rect is required.";
            return;
        }
        alertController.popoverPresentationController.sourceView = target.view;
        alertController.popoverPresentationController.sourceRect = rect;
    }
    
    [target presentViewController:alertController animated:YES completion:nil];
}


#pragma mark - Public methods

/*
 3ボタン・アラート
 */
+ (void)target:(UIViewController*_Nullable)target
         title:(NSString*_Nullable)title
       message:(NSString*_Nullable)message
       b1title:(NSString*_Nonnull)b1title
       b1style:(UIAlertActionStyle)b1style
      b1action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b1action
       b2title:(NSString*_Nullable)b2title
       b2style:(UIAlertActionStyle)b2style
      b2action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b2action
       b3title:(NSString*_Nullable)b3title
       b3style:(UIAlertActionStyle)b3style
      b3action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b3action
{
    [AZAlert target:target
              style:UIAlertControllerStyleAlert
               rect:CGRectZero
              title:title
            message:message
            b1title:b1title  b1style:b1style  b1action:b1action
            b2title:b2title  b2style:b2style  b2action:b2action
            b3title:b3title  b3style:b3style  b3action:b3action
            b4title:nil      b4style:0        b4action:nil
            b5title:nil      b5style:0        b5action:nil
     ];
}

/*
 2ボタン・アラート
 */
+ (void)target:(UIViewController*_Nullable)target
         title:(NSString*_Nullable)title
       message:(NSString*_Nullable)message
       b1title:(NSString*_Nonnull)b1title
       b1style:(UIAlertActionStyle)b1style
      b1action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b1action
       b2title:(NSString*_Nullable)b2title
       b2style:(UIAlertActionStyle)b2style
      b2action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b2action
{
    [AZAlert target:target
              style:UIAlertControllerStyleAlert
               rect:CGRectZero
              title:title
            message:message
            b1title:b1title  b1style:b1style  b1action:b1action
            b2title:b2title  b2style:b2style  b2action:b2action
            b3title:nil      b3style:0        b3action:nil
            b4title:nil      b4style:0        b4action:nil
            b5title:nil      b5style:0        b5action:nil
     ];
}

/*
 1ボタン・アラート
 */
+ (void)target:(UIViewController*_Nullable)target
         title:(NSString*_Nullable)title
       message:(NSString*_Nullable)message
       b1title:(NSString*_Nonnull)b1title
       b1style:(UIAlertActionStyle)b1style
      b1action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b1action
{
    [AZAlert target:target
              style:UIAlertControllerStyleAlert
               rect:CGRectZero
              title:title
            message:message
            b1title:b1title  b1style:b1style  b1action:b1action
            b2title:nil      b2style:0        b2action:nil
            b3title:nil      b3style:0        b3action:nil
            b4title:nil      b4style:0        b4action:nil
            b5title:nil      b5style:0        b5action:nil
     ];
}

/*
 5ボタン・アクションシート
 */
+ (void)target:(UIViewController*_Nullable)target
    actionRect:(CGRect)rect
         title:(NSString*_Nullable)title
       message:(NSString*_Nullable)message
       b1title:(NSString*_Nonnull)b1title
       b1style:(UIAlertActionStyle)b1style
      b1action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b1action
       b2title:(NSString*_Nullable)b2title
       b2style:(UIAlertActionStyle)b2style
      b2action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b2action
       b3title:(NSString*_Nullable)b3title
       b3style:(UIAlertActionStyle)b3style
      b3action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b3action
       b4title:(NSString*_Nullable)b4title
       b4style:(UIAlertActionStyle)b4style
      b4action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b4action
       b5title:(NSString*_Nullable)b5title
       b5style:(UIAlertActionStyle)b5style
      b5action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b5action
{
    [AZAlert target:target
              style:UIAlertControllerStyleActionSheet
               rect:rect
              title:title
            message:message
            b1title:b1title  b1style:b1style  b1action:b1action
            b2title:b2title  b2style:b2style  b2action:b2action
            b3title:b3title  b3style:b3style  b3action:b3action
            b4title:b4title  b4style:b4style  b4action:b4action
            b5title:b5title  b5style:b5style  b5action:b5action
     ];
}

/*
 4ボタン・アクションシート
 */
+ (void)target:(UIViewController*_Nullable)target
    actionRect:(CGRect)rect
         title:(NSString*_Nullable)title
       message:(NSString*_Nullable)message
       b1title:(NSString*_Nonnull)b1title
       b1style:(UIAlertActionStyle)b1style
      b1action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b1action
       b2title:(NSString*_Nullable)b2title
       b2style:(UIAlertActionStyle)b2style
      b2action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b2action
       b3title:(NSString*_Nullable)b3title
       b3style:(UIAlertActionStyle)b3style
      b3action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b3action
       b4title:(NSString*_Nullable)b4title
       b4style:(UIAlertActionStyle)b4style
      b4action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b4action
{
    [AZAlert target:target
              style:UIAlertControllerStyleActionSheet
               rect:rect
              title:title
            message:message
            b1title:b1title  b1style:b1style  b1action:b1action
            b2title:b2title  b2style:b2style  b2action:b2action
            b3title:b3title  b3style:b3style  b3action:b3action
            b4title:b4title  b4style:b4style  b4action:b4action
            b5title:nil      b5style:0        b5action:nil
     ];
}

/*
 3ボタン・アクションシート
 */
+ (void)target:(UIViewController*_Nullable)target
    actionRect:(CGRect)rect
         title:(NSString*_Nullable)title
       message:(NSString*_Nullable)message
       b1title:(NSString*_Nonnull)b1title
       b1style:(UIAlertActionStyle)b1style
      b1action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b1action
       b2title:(NSString*_Nullable)b2title
       b2style:(UIAlertActionStyle)b2style
      b2action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b2action
       b3title:(NSString*_Nullable)b3title
       b3style:(UIAlertActionStyle)b3style
      b3action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b3action
{
    [AZAlert target:target
              style:UIAlertControllerStyleActionSheet
               rect:rect
              title:title
            message:message
            b1title:b1title  b1style:b1style  b1action:b1action
            b2title:b2title  b2style:b2style  b2action:b2action
            b3title:b3title  b3style:b3style  b3action:b3action
            b4title:nil      b4style:0        b4action:nil
            b5title:nil      b5style:0        b5action:nil
     ];
}

/*
 2ボタン・アクションシート
 */
+ (void)target:(UIViewController*_Nullable)target
    actionRect:(CGRect)rect
         title:(NSString*_Nullable)title
       message:(NSString*_Nullable)message
       b1title:(NSString*_Nonnull)b1title
       b1style:(UIAlertActionStyle)b1style
      b1action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b1action
       b2title:(NSString*_Nullable)b2title
       b2style:(UIAlertActionStyle)b2style
      b2action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b2action
{
    [AZAlert target:target
              style:UIAlertControllerStyleActionSheet
               rect:rect
              title:title
            message:message
            b1title:b1title  b1style:b1style  b1action:b1action
            b2title:b2title  b2style:b2style  b2action:b2action
            b3title:nil      b3style:0        b3action:nil
            b4title:nil      b4style:0        b4action:nil
            b5title:nil      b5style:0        b5action:nil
     ];
}

/*
 1ボタン・アクションシート
 */
+ (void)target:(UIViewController*_Nullable)target
    actionRect:(CGRect)rect
         title:(NSString*_Nullable)title
       message:(NSString*_Nullable)message
       b1title:(NSString*_Nonnull)b1title
       b1style:(UIAlertActionStyle)b1style
      b1action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b1action
{
    [AZAlert target:target
              style:UIAlertControllerStyleActionSheet
               rect:rect
              title:title
            message:message
            b1title:b1title  b1style:b1style  b1action:b1action
            b2title:nil      b2style:0        b2action:nil
            b3title:nil      b3style:0        b3action:nil
            b4title:nil      b4style:0        b4action:nil
            b5title:nil      b5style:0        b5action:nil
     ];
}


@end
