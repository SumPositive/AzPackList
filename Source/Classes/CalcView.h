//
//  CalcView.h
//
//  Created by 松山 和正 on 10/01/04.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define GOLDENPER				1.618	// 黄金比
#define MINUS_SIGN				@"−"	// Unicode[2212] 表示用文字　[002D]より大きくするため
#define ANSWER_MAX				99999999.991	// double近似値で比較するため+0.001してある


@interface NSObject (CalcViewDelegate)	// 非形式プロトコル（カテゴリ）方式によるデリゲート
- (void)calcViewWillAppear;
- (void)calcViewWillDisappear;
@end

@interface CalcView : UIView <UITextFieldDelegate>

@property (assign) id						delegate;
@property (nonatomic, retain) UILabel		*Rlabel;
@property (nonatomic, retain) id			Rentity;
@property (nonatomic, retain) NSString		*RzKey;	
@property (nonatomic, assign) NSInteger		maxValue;

// 公開メソッド
- (id)initWithFrame:(CGRect)rect;
- (void)show;
- (void)save;
- (void)cancel;
- (void)hide;
- (void)viewDesign:(CGRect)rect;	// 回転時に呼び出す
- (BOOL)isShow;

@end
