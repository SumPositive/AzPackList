//
//  AZDial.m
//  AzBodyNote
//
//  Created by Sum Positive on 11/10/06.
//  Copyright (c) 2011 Azukid. All rights reserved.
//

#import "AZDial.h"

#define FrameH				44	// 高さはApple標準(44)に固定する
#define ImgW					40	// タイルの幅
#define ImgH					30

#define BLOCK				800.0		//=(ImgW * 10 * 2)	// 10=タイリング数  2=2の倍数にするため
#define PITCH					15.0			// スクロール感度　　増減するための最低変位量　＜＜ImgWの約数にするとステッパを使ったとき、ダイアルが動かないように見える。
														//【注意】 34.0だと[+]右回転に見えるが、36.0にすると左回転に見えてしまう。

@interface AZDial (PrivateMethods)
- (void)scrollReset;
@end

@implementation AZDial
{
	UIScrollView			*mScrollView;
	UIImageView		*mImgBack;
	id							mDelegate;
	
	NSInteger			mDial;
	NSInteger			mDialMin;
	NSInteger			mDialMax;
	NSInteger			mDialStep;
	
	//CGFloat				mScrollMin; = 0 固定
	CGFloat				mScrollMax;		// ScrollView左端から右端までの距離
	CGFloat				mScrollOfs;		// ScrollView左端からの距離
	
	UIImageView		*mIvLeft;
	UIImageView		*mIvCenter;
	UIImageView		*mIvRight;
	
	// Stepper button
	BOOL					mIsOS5;			//=YES: iOS5以上
	BOOL					mIsSetting;		//=YES: set中につき < dialChanged: dialDone: > を呼び出さない。ループ防止のため
	UIStepper				*mStepper;		// iOS5以上
	UIButton				*mStepBuUp;		// iOS5未満
	UIButton				*mStepBuDown;	// iOS5未満
	CGFloat				mStepperMag;	// ステッパーの刻みを mVstep * mStepperMag にする
}


- (void)makeView:(BOOL)stepper
{
	if (stepper) {
		if (mIsOS5) {
			if (!mStepper) {
				CGRect rc = self.bounds;
				rc.origin.y = 7;
				// .width=94 .height=27 は固定されている
				mStepper = [[UIStepper alloc] initWithFrame:rc];
				[self addSubview:mStepper];
				[mStepper addTarget:self action:@selector(actionStepperChange:) forControlEvents:UIControlEventValueChanged];
			}
		} else {
			if (!mStepBuUp) {
				mStepBuUp = [UIButton buttonWithType:UIButtonTypeCustom];
				[self addSubview:mStepBuUp];
				[mStepBuUp addTarget:self action:@selector(actionStepBuUpTouch:) 
					forControlEvents:UIControlEventTouchDown];
				[mStepBuUp setImage:[UIImage imageNamed:@"AZDialStepperPlus"] forState:UIControlStateNormal];
				[mStepBuUp setImage:[UIImage imageNamed:@"AZDialStepperPlusDown"] forState:UIControlStateHighlighted];
				CGRect rc = self.bounds;
				rc.origin.x = 47;
				rc.origin.y = 7;
				rc.size.width = 47;
				rc.size.height = 30;
				mStepBuUp.frame = rc;		//[+]右側
			}
			if (!mStepBuDown) {
				mStepBuDown = [UIButton buttonWithType:UIButtonTypeCustom];
				[self addSubview:mStepBuDown];
				[mStepBuDown addTarget:self action:@selector(actionStepBuDownTouch:) 
					  forControlEvents:UIControlEventTouchDown];
				[mStepBuDown setImage:[UIImage imageNamed:@"AZDialStepperMinus"] forState:UIControlStateNormal];
				[mStepBuDown setImage:[UIImage imageNamed:@"AZDialStepperMinusDown"] forState:UIControlStateHighlighted];
				CGRect rc = self.bounds;
				rc.origin.x = 0;
				rc.origin.y = 7;
				rc.size.width = 47;
				rc.size.height = 30;
				mStepBuDown.frame = rc;		//[-]左側
			}
		}
		//初期値セットは、setDial: から scrollReset:　が呼び出される。
	} else {
		if (mStepper) {
			[mStepper removeFromSuperview];
			mStepper = nil;
		}
		if (mStepBuUp) {
			[mStepBuUp removeFromSuperview];
			mStepBuUp = nil;
		}
		if (mStepBuDown) {
			[mStepBuDown removeFromSuperview];
			mStepBuDown = nil;
		}
		mStepperMag = 1.0; // Default
	}
	
	// ScrollView		高さ:44　= self.bounds.size.height
	CGRect rcScroll = self.bounds;
	if (stepper) {
		rcScroll.origin.x = 94 + 2 + 10;	// self内の座標
		rcScroll.size.width -= (rcScroll.origin.x + 10);
	} else {
		rcScroll.origin.x = 10;	// self内の座標
		rcScroll.size.width -= (10 + 10);
	}
	rcScroll.origin.y = 0;  //(FrameH - ImgH)/2;
	//rcScroll.size.height = ImgH;
	if (mScrollView) {
		mScrollView.frame = rcScroll;
	} else {
		mScrollView = [[UIScrollView alloc] initWithFrame:rcScroll];
		//setDial:にて// mScrollView.contentSize = CGSizeMake( mScrollMax + rcScroll.size.width, ImgH );
		//setDial:にて// mScrollView.contentOffset = CGPointMake( mScrollMax - mScrollValue, 0);
		mScrollView.delegate = self;
		mScrollView.showsVerticalScrollIndicator = NO;
		mScrollView.showsHorizontalScrollIndicator = NO;
		mScrollView.pagingEnabled = NO;
		mScrollView.scrollsToTop = NO;
		mScrollView.bounces = NO;
		//mScrollView.backgroundColor = [UIColor whiteColor];
		[self addSubview:mScrollView];
	}

	// 背景画像
	CGRect rcBack = self.bounds;
	if (stepper) {
		rcBack.origin.x = 94 + 2;
		rcBack.origin.y = 0;
		rcBack.size.width -= rcBack.origin.x;
	} else {
		rcBack.origin.x = 0;
		rcBack.origin.y = 0;
	}
	if (mImgBack) {
		mImgBack.frame = rcBack;
	} else {
		mImgBack = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"AZDialBack"]];
		mImgBack.frame = rcBack;
		mImgBack.contentMode = UIViewContentModeScaleToFill;
		mImgBack.contentStretch = CGRectMake(0.5, 0,  0, 0);
		[self	addSubview:mImgBack];
	}
	// mScrollView 座標系をセット
	[self scrollReset];	// mScrollViewやBLOCK再配置処理
}


- (id)initWithFrame:(CGRect)frame 
		   delegate:(id)delegate 
			  dial:(NSInteger)dial			// 初期値
			   min:(NSInteger)min			// 最小値
			   max:(NSInteger)max		// 最大値
			   step:(NSInteger)step		// 増減値
			stepper:(BOOL)stepper;
{
	assert(delegate);
	assert(min < max);
	//assert(vmin <= value);
	//assert(value <= vmax);
	if (dial < min) dial = min;
	else if (max < dial) dial = max;
	//assert(1 <= vstep);
	if (step < 1) step =1;
	
	UIImage *imgTile = [UIImage imageNamed:@"AZDialTile"];	// H30 x W10の倍数
	if (imgTile==nil) return nil;
	UIColor *patternColor = [UIColor colorWithPatternImage:imgTile];
	
	self = [super initWithFrame:frame];
    if (self==nil) return nil;
	
	// Initialization
	//mIsMoved = YES;	// =YES:setDial:等の初期値セット中 ⇒ delegate呼び出ししない。
	mDelegate = delegate;
	mDialMin = min;
	mDialMax = max;
	mDialStep = step;
	mStepperMag = 1.0;
	//mValue は、mScrollView生成後、setDial:によりセットしている。
	mIsOS5 = ([[[UIDevice currentDevice] systemVersion] compare:@"5.0"] != NSOrderedAscending);  // !<  (>=) "5.0"

	[self makeView:stepper];
	
	// Left BLOCK
	CGRect rcImg = CGRectMake( (-2)*BLOCK, (FrameH - ImgH)/2, BLOCK, ImgH);	// scrollReset:にてBLOCK再配置処理されるように(-2)*している
	mIvLeft = [[UIImageView alloc] initWithFrame:rcImg];
	mIvLeft.contentMode = UIViewContentModeTopLeft;
	mIvLeft.backgroundColor = patternColor;
	[mScrollView addSubview:mIvLeft];
	// Center BLOCK
	mIvCenter = [[UIImageView alloc] initWithFrame:rcImg];
	mIvCenter.contentMode = UIViewContentModeTopLeft;
	mIvCenter.backgroundColor = patternColor;
	[mScrollView addSubview:mIvCenter];
	// Right BLOCK
	mIvRight = [[UIImageView alloc] initWithFrame:rcImg];
	mIvRight.contentMode = UIViewContentModeTopLeft;
	mIvRight.backgroundColor = patternColor;
	[mScrollView addSubview:mIvRight];
	
	// mValue, mScrollView 座標系をセット
	[self setDial:dial  animated:NO];	//---> scrollReset:にてmScrollViewやBLOCK再配置処理
	
	//mIsMoved = NO;
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{	// Drawing code
	
}


#pragma mark - Methods

- (void)scrollReset
{	// mScrollView 座標系セット
	
	//NSLog(@"-- scrollReset -- mValue=%d  mVmin=%d  mVmax=%d  :: mScrollMax=%.1f  mScrollOfs=%.1f",
	//	  mValue, mVmin, mVmax, mScrollMax, mScrollOfs);

	if (mDialStep < 1) {
		NSLog(@"LOGIC ERROR!!!  mDialStep=%ld", (long)mDialStep);
		mDialStep = 1;
	}
	CGFloat ff = (CGFloat)(mDialMax - mDialMin) / mDialStep * PITCH;
	if (mScrollView.contentSize.width != ff + mScrollView.frame.size.width) 
	{	// + mScrollView.frame.size.width は、Stepper有無でダイアル幅が変わることに対応するため。
		mScrollMax = ff;
		mScrollView.contentSize = CGSizeMake( ff + mScrollView.frame.size.width, ImgH );
		//NSLog(@"                       -- CHANGE - mScrollMax=%.1lf  mDialStep=%d  STEP=%d   .width=%f", 
		//	  mScrollMax, mDialStep, (int)PITCH,  mScrollView.frame.size.width);
	}

	ff = mScrollMax - (CGFloat)((mDial - mDialMin) / mDialStep * PITCH);	  // 右側が原点になるため
	if (mScrollOfs != ff) {
		mScrollOfs = ff;
		mScrollView.contentOffset = CGPointMake( ff, 0);
		//NSLog(@"                                          - mScrollMax=%.1lf  mScrollOfs=%.1lf  STEP=%d", mScrollMax, mScrollOfs, (int)PITCH);
	}
	
	if ( ( 0 < mIvLeft.frame.origin.x && mScrollOfs < mIvCenter.frame.origin.x - PITCH*3)
		|| ( mIvRight.frame.origin.x + BLOCK < mScrollMax && mIvRight.frame.origin.x + PITCH*3 < mScrollOfs) ) 
	{	// mIvCenterの範囲外が指定された場合、再配置する
		NSInteger iNo = floor( (mScrollOfs) / BLOCK );  // Center No.  小数以下切り捨て
		//NSLog(@"                       -- mIvCenter1 - X=%.1lf  Wid=%.1lf  iNo=%d", mIvCenter.frame.origin.x, mIvCenter.frame.origin.x + BLOCK, iNo);
		CGRect rc = mIvLeft.frame;
		//Left
		rc.origin.x =  (iNo - 1) * BLOCK;
		mIvLeft.frame = rc;
		//Center
		rc.origin.x += BLOCK;
		mIvCenter.frame = rc;
		//NSLog(@"                       -- mIvCenter2 - X=%.1lf  Wid=%.1lf", mIvCenter.frame.origin.x, mIvCenter.frame.origin.x + BLOCK);
		//Right
		rc.origin.x += BLOCK;
		mIvRight.frame = rc;
	}

	//mIsMoved = NO;	// return; で抜けることに注意
	//mScrollView.delegate = self;

	if (mIsOS5) {
		if (!mStepper) return;
		mStepper.minimumValue = mDialMin;
		mStepper.maximumValue = mDialMax;
		mStepper.stepValue = mDialStep * mStepperMag;
		mStepper.value = mDial;
	} else {
		if (!mStepBuUp || !mStepBuDown) return;
		mStepBuUp.enabled = (mDial < mDialMax);
		mStepBuDown.enabled = (mDialMin < mDial);
	}
}

- (NSInteger)getDial
{
	return mDial;
}

- (void)setFrame:(CGRect)frame	// NEW 回転のため
{
	[super setFrame:frame];
	[self makeView:(mStepper!=nil || mStepBuUp!=nil)];
}

- (void)setDial:(NSInteger)dial  animated:(BOOL)animated
{	// これで変位したときは、delegate< dialChanged: dialDone: > を呼び出さない。
	if (dial < mDialMin) dial = mDialMin;
	else if (mDialMax < dial) dial = mDialMax;
	// SET
	mDial = dial;

	mIsSetting = YES; // delegate< dialChanged: dialDone: > を呼び出さない。
	if (animated) {
		// アニメ準備
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		[UIView setAnimationDuration:0.5];
		// アニメ終了位置
		[self scrollReset];	// mScrollView 座標系セット
		// アニメ開始
		[UIView commitAnimations];
	} else {
		[self scrollReset];	// mScrollView 座標系セット
	}
	mIsSetting = NO;
}

- (void)setStep:(NSInteger)vstep
{
	if (vstep < 1) mDialStep =1;
	else mDialStep = vstep;
	mIsSetting = YES; // delegate< dialChanged: dialDone: > を呼び出さない。
	[self scrollReset];
	mIsSetting = NO;
}

- (void)setMin:(NSInteger)vmin
{
	if (mDial < vmin) mDial = vmin;
	// SET
	mDialMin = vmin;
	// mScrollView 座標系セット
	mIsSetting = YES; // delegate< dialChanged: dialDone: > を呼び出さない。
	[self scrollReset];
	mIsSetting = NO;
}

- (void)setMax:(NSInteger)vmax
{
	if (vmax < mDial) mDial = vmax;
	// SET
	mDialMax = vmax;
	// mScrollView 座標系セット
	mIsSetting = YES; // delegate< dialChanged: dialDone: > を呼び出さない。
	[self scrollReset];
	mIsSetting = NO;
}

- (void)setStepperMagnification:(CGFloat)vmagnif
{	// ステッパーは刻みを、mVstep * vmagnif にする
	mStepperMag = vmagnif;
	mIsSetting = YES; // delegate< dialChanged: dialDone: > を呼び出さない。
	[self scrollReset];
	mIsSetting = NO;
}

- (void)setStepperShow:(BOOL)bShow
{
	if (bShow) {
		if (mStepper || mStepBuUp) return; // 既に表示中
	} else {
		if (!mStepper && !mStepBuUp) return; // 既に非表示
	}
	[self makeView:bShow];
}



#pragma mark - Action

- (void)actionStepperChange:(UIStepper *)sender
{
	[self	setDial:(NSInteger)sender.value animated:YES];

	if ([mDelegate respondsToSelector:@selector(dialDone:dial:)]) {
		[mDelegate dialDone:self  dial:mDial];
	}
}

- (void)actionStepBuUpTouch:(UIButton*)sender
{
	NSInteger ii = mDial + (mDialStep * mStepperMag);
	if (mDialMax < ii) ii = mDialMax;
	[self	setDial:ii  animated:YES];
	if ([mDelegate respondsToSelector:@selector(dialDone:dial:)]) {
		[mDelegate dialDone:self  dial:mDial];
	}
}

- (void)actionStepBuDownTouch:(UIButton*)sender
{
	NSInteger ii = mDial - (mDialStep * mStepperMag);
	if (ii < mDialMin) ii = mDialMin;
	[self	setDial:ii  animated:YES];
	if ([mDelegate respondsToSelector:@selector(dialDone:dial:)]) {
		[mDelegate dialDone:self  dial:mDial];
	}
}



#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{	// スクロール中
	static CGFloat sBase = (-1);
	if (sBase < 0) {
		sBase = scrollView.contentOffset.x;
	}
	CGFloat delta = scrollView.contentOffset.x - sBase;	// 変位量
	if ( fabs(delta) < PITCH/2 ) {
		return;
	}
	sBase = scrollView.contentOffset.x;

	//NSLog(@".x=%.1f  Left.x=%.1f  Center.x=%.1f  Right.x=%.1f", scrollView.contentOffset.x, 
	//													mIvLeft.frame.origin.x, mIvCenter.frame.origin.x, mIvRight.frame.origin.x);

	// valueChange
	mDial = mDialMin + floor( (mScrollMax - scrollView.contentOffset.x) / PITCH ) * mDialStep;

	if (mDial < mDialMin) mDial = mDialMin;	// Fix:2012-01-19
	else if (mDialMax < mDial) mDial = mDialMax;
	
	if (mIsSetting==NO) {
		if ([mDelegate respondsToSelector:@selector(dialChanged:dial:)]) {
			[mDelegate dialChanged:self  dial:mDial];	// 変化、決定ではない
		}
	}

	if ( scrollView.contentOffset.x < mIvCenter.frame.origin.x - PITCH*3 ) {
		// Left
		if ( 0 < mIvLeft.frame.origin.x ) {
			UIImageView *iv = mIvRight;
			mIvRight = mIvCenter;
			mIvCenter = mIvLeft;
			//NSLog(@"                       -L- mIvCenter - X=%.1lf  Wid=%.1lf  <<< X=%.1f", 
			//	  mIvCenter.frame.origin.x, mIvCenter.frame.origin.x + BLOCK, scrollView.contentOffset.x);
			mIvLeft = iv;
			CGRect frame = mIvLeft.frame;
			frame.origin.x -= (BLOCK * 3);
			mIvLeft.frame = frame;
		}
	}
	else if ( mIvCenter.frame.origin.x + BLOCK + PITCH*3 < scrollView.contentOffset.x ) {
		// Right
		if ( mIvRight.frame.origin.x < mScrollMax ) {
			UIImageView *iv = mIvLeft;
			mIvLeft = mIvCenter;
			mIvCenter = mIvRight;
			//NSLog(@"                       -R- mIvCenter - X=%.1lf  Wid=%.1lf  <<< X=%.1f", 
			//	  mIvCenter.frame.origin.x, mIvCenter.frame.origin.x + BLOCK, scrollView.contentOffset.x);
			mIvRight = iv;
			CGRect frame = mIvRight.frame;
			frame.origin.x += (BLOCK * 3);
			mIvRight.frame = frame;
		}
	}
}

- (void)scrollDone:(UIScrollView *)scrollView
{	// Original
	//NG//ここで、改めて位置から求めると、指を離した瞬間に動いて変化する場合がある。
	//OK//そのため、scrollViewDidScroll:にて表示されている mValue に決定することにした。
	if (mIsSetting==NO) {
		if ([mDelegate respondsToSelector:@selector(dialDone:dial:)]) {
			[mDelegate dialDone:self  dial:mDial];	// 決定
		}
	}
	
	NSInteger iStep = mDialStep * mStepperMag;
	[self setDial:((mDial / iStep) * iStep)  animated:NO];	// ステッパーのステップに補正する
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{	// ドラッグ終了 ＜＜＜スクロールを止めてから、指を離したときに呼ばれる　　		decelerate=YES:まだ慣性動作中
	if (decelerate) {
		// まだ慣性動作中 ⇒ この後、scrollViewDidEndDecelerating：が呼び出される
	} else {
		// ピタッと止まった ＜＜指を離した瞬間に僅かに動くのは無視してピタット扱いになるようだ。
		[self scrollDone:scrollView];
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{	// スクロール・ビューの動きが減速終了 ＜＜＜スクロール中に指を離して、自然に止まったときに呼ばれる
	[self scrollDone:scrollView];
}

@end
