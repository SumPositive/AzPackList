//
//  AZAlert.h
//  UIAlertController+Wrapper アラート&アクションシート
//
//  Copyright 2017 Azukid
//  Created by 松山正和 on 2017/07/19.
//
//

#import <UIKit/UIKit.h>


@interface AZAlert : NSObject

/**
 3ボタン・アラート

 @param  target: 表示するViewController, nilならば最上のViewControllerに表示
 @param  title: タイトル
 @param  message: 本文メッセージ
 @param  b1title: 左側のボタン・タイトル
 @param  b1style: UIAlertActionStyle
 @param  b1action: ボタンタップ時に実行するブロック
 @param  b2title: 中央のボタン・タイトル
 @param  b2style: UIAlertActionStyle
 @param  b2action: ボタンタップ時に実行するブロック
 @param  b3title: 右側のボタン・タイトル
 @param  b3style: UIAlertActionStyle
 @param  b3action: ボタンタップ時に実行するブロック
 @return void
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
      b3action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b3action;

/**
 2ボタン・アラート
 
 @param  target: 表示するViewController, nilならば最上のViewControllerに表示
 @param  title: タイトル
 @param  message: 本文メッセージ
 @param  b1title: 左側のボタン・タイトル
 @param  b1style: UIAlertActionStyle
 @param  b1action: ボタンタップ時に実行するブロック
 @param  b2title: 右側のボタン・タイトル
 @param  b2style: UIAlertActionStyle
 @param  b2action: ボタンタップ時に実行するブロック
 @return void
 */
+ (void)target:(UIViewController*_Nullable)target
         title:(NSString*_Nullable)title
       message:(NSString*_Nullable)message
       b1title:(NSString*_Nonnull)b1title
       b1style:(UIAlertActionStyle)b1style
      b1action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b1action
       b2title:(NSString*_Nullable)b2title
       b2style:(UIAlertActionStyle)b2style
      b2action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b2action;

/**
 1ボタン・アラート
 
 @param  target: 表示するViewController, nilならば最上のViewControllerに表示
 @param  title: タイトル
 @param  message: 本文メッセージ
 @param  b1title: ボタン・タイトル
 @param  b1style: UIAlertActionStyle
 @param  b1action: ボタンタップ時に実行するブロック
 @return void
 */
+ (void)target:(UIViewController*_Nullable)target
         title:(NSString*_Nullable)title
       message:(NSString*_Nullable)message
       b1title:(NSString*_Nonnull)b1title
       b1style:(UIAlertActionStyle)b1style
      b1action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b1action;

/**
 5ボタン・アクションシート
 
 @param  target: 表示するViewController, nilならば最上のViewControllerに表示
 @param  actionRect:（iPhoneだけならCGRectZero）iPad必須、Popupの吹き出し根元位置を矩形範囲で指定。大抵は、UIButton.frameが適する
                        このパラメータの有無でアラートとアクションシートを変えることができる
 @param  title: タイトル
 @param  message: 本文メッセージ
 @param  b1title: 1つ目のボタン・タイトル
 @param  b1style: UIAlertActionStyle
 @param  b1action: ボタンタップ時に実行するブロック
 @param  b2title: 2つ目のボタン・タイトル
 ・・・以下同様に5つ目まで可能。上から順に並ぶ
 ・・・ただし、UIAlertActionStyleCancelを指定したボタンは最下段(iPhone)もしくは非表示(iPadで範囲外タップ相当)になる
 @return void
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
      b5action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b5action;

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
      b4action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b4action;

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
      b3action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b3action;

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
      b2action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b2action;

/*
 1ボタン・アクションシート
 */
+ (void)target:(UIViewController*_Nullable)target
    actionRect:(CGRect)rect
         title:(NSString*_Nullable)title
       message:(NSString*_Nullable)message
       b1title:(NSString*_Nonnull)b1title
       b1style:(UIAlertActionStyle)b1style
      b1action:(void (^ _Nullable)(UIAlertAction*_Nullable action))b1action;

@end
