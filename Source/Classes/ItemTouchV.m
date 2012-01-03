//
//  ItemTouchView.m
//  AzPacking
//
//  Created by 松山 和正 on 10/01/13.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Global.h"
#import "Elements.h"
#import "ItemTouchV.h"

#define TOUCHSTEP   15

@interface ItemTouchView (PrivateMethods)
//---------------------------------------------initWithFrameでnil, retain > release必要
UILabel *MlabelTableSelect;
UILabel *MlabelStock;
UILabel *MlabelRequired;
//---------------------------------------------assign
CGPoint MpointBegin;
CGPoint MpointMove;
NSInteger  MiSelect;     // [-1]NG [0]Stock [1]Required [2]Weight(x10) [3]Weight
NSInteger  MiVolume;
NSInteger  MiVolumePrev;
NSInteger  MiVolumeTenfold; // (x1) (x10) (x100) (x1000)
NSInteger  MiStock;
NSInteger  MiRequired;
NSInteger  MiWeight;
NSTimeInterval MtTouchBegan;
@end
@implementation ItemTouchView
@synthesize Pe3view;
@synthesize Pe3path;
@synthesize Pe3obj;

- (void)dealloc 
{
	AzRETAIN_CHECK(@"ItemTouchView MlabelTableSelect", MlabelTableSelect, 1)
	[MlabelTableSelect release];
	AzRETAIN_CHECK(@"ItemTouchView MlabelStock", MlabelStock, 1)
	[MlabelStock release];
	AzRETAIN_CHECK(@"ItemTouchView MlabelRequired", MlabelRequired, 1)
	[MlabelRequired release];

	// @property (retain)
	AzRETAIN_CHECK(@"ItemTouchView Pe3obj", Pe3obj, 1)
	[Pe3obj release];
	AzRETAIN_CHECK(@"ItemTouchView Pe3path", Pe3path, 1)
	[Pe3path release];
	AzRETAIN_CHECK(@"ItemTouchView Pe3view", Pe3view, 1)
	[Pe3view release];
	
    [super dealloc];
}

- (void)drawRect:(CGRect)rect {
    // Drawing code
}

- (id)initWithFrame:(CGRect)frame 
{
	MlabelTableSelect = nil;
	MlabelStock = nil;
	MlabelRequired = nil;

	if (!(self = [super initWithFrame:frame])) return self;
	
	// 透明の背景でありTOUCHイベントを受けるView
	[self setBackgroundColor:[UIColor clearColor]];
	self.userInteractionEnabled = YES; //タッチの可否
	
	// 操作パネルの中心座標
	static const NSInteger SiCenterX = 150;
	static const NSInteger SiCenterY = 250;
	
	//------------------------------------------背景画像
	UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"VolumeQty.png"]];
	iv.center = CGPointMake(SiCenterX, SiCenterY);
	[self addSubview:iv];
	[iv release];
	
	// 注意！この時点では、まだ self.e3obj はセットされていない！
	UILabel *lbl;
	
	MlabelStock = [[UILabel alloc] initWithFrame:CGRectMake(SiCenterX-75,SiCenterY-163, 60,30)];
	MlabelStock.backgroundColor = [UIColor clearColor];
	MlabelStock.font = [UIFont systemFontOfSize:20];  //フォントサイズ
	MlabelStock.textAlignment = UITextAlignmentCenter;
	[self addSubview:MlabelStock];
	
	lbl = [[UILabel alloc] initWithFrame:CGRectMake(SiCenterX-75,SiCenterY+10, 60,20)];
	lbl.backgroundColor = [UIColor clearColor];
	lbl.font = [UIFont systemFontOfSize:10];  //フォントサイズ
	lbl.textAlignment = UITextAlignmentCenter;
	lbl.text = NSLocalizedString(@"Stock", @"収納");
	[self addSubview:lbl];
	[lbl release];
	
	MlabelRequired = [[UILabel alloc] initWithFrame:CGRectMake(SiCenterX+25,SiCenterY-163, 60,30)];
	MlabelRequired.backgroundColor = [UIColor clearColor];
	MlabelRequired.font = [UIFont systemFontOfSize:20];  //フォントサイズ
	MlabelRequired.textAlignment = UITextAlignmentCenter; // Center;
	[self addSubview:MlabelRequired];
	
	lbl = [[UILabel alloc] initWithFrame:CGRectMake(SiCenterX+25,SiCenterY+10, 60,20)];
	lbl.backgroundColor = [UIColor clearColor];
	lbl.font = [UIFont systemFontOfSize:10];  //フォントサイズ
	lbl.textAlignment = UITextAlignmentCenter;
	lbl.text = NSLocalizedString(@"Required", @"必要");
	[self addSubview:lbl];
	[lbl release];
	
/*	lbl = [[UILabel alloc] initWithFrame:CGRectMake(185,255,90,20)];
	lbl.backgroundColor = [UIColor clearColor];
	lbl.font = [UIFont systemFontOfSize:10];  //フォントサイズ
	lbl.textAlignment = UITextAlignmentCenter;
	lbl.text = NSLocalizedString(@"Weight", nil);
	[self addSubview:lbl];
	[lbl release];
	labelWeight = [[UILabel alloc] initWithFrame:CGRectMake(185,100,90,30)];
	labelWeight.backgroundColor = [UIColor clearColor];
	labelWeight.font = [UIFont systemFontOfSize:20];  //フォントサイズ
	labelWeight.textAlignment = UITextAlignmentCenter;
	[self addSubview:labelWeight];
	lbl = [[UILabel alloc] initWithFrame:CGRectMake(245,125,20,20)];
	lbl.backgroundColor = [UIColor clearColor];
	lbl.font = [UIFont systemFontOfSize:12];  //フォントサイズ
	lbl.textAlignment = UITextAlignmentLeft; // Center;
	lbl.text = @"g";
	[self addSubview:lbl];
	[lbl release];
*/	
	
    return self;
}

- (void)show
{
	// この時点では、self.e3obj がセットされている。
	MiStock = [self.Pe3obj.stock intValue];
	MlabelStock.tag = MiStock; // 元の値を保持：最後に変化あればSAVEするため
	MlabelStock.text = [NSString stringWithFormat:@"%ld", (long)MiStock];
	
	MiRequired = [self.Pe3obj.need intValue];
	MlabelRequired.tag = MiRequired;
	MlabelRequired.text = [NSString stringWithFormat:@"%ld", (long)MiRequired];

/*	lWeight = [self.e3obj.weight intValue];
	labelWeight.tag = lWeight;
	labelWeight.text = [NSString stringWithFormat:@"%ld", (long)lWeight];
*/	
	// 選択されたセル業をハイライト表示する
	MlabelTableSelect = [[UILabel alloc] initWithFrame:[self.Pe3view rectForRowAtIndexPath:self.Pe3path]];
	MlabelTableSelect.backgroundColor = [UIColor yellowColor];
	MlabelTableSelect.alpha = 0.2f;
	[self.Pe3view addSubview:MlabelTableSelect];  // hide:にて removeFromSuperview している
	
	// Scroll in the overlay
	CGContextRef context = UIGraphicsGetCurrentContext();
	[UIView beginAnimations:nil context:context];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.2];
	[self setAlpha:1.0f];
	[UIView commitAnimations];

	self.multipleTouchEnabled = YES;
	MiSelect = -1; // touchesBegan Reset
}

- (void)hide
{
	self.multipleTouchEnabled = NO;
	
	
	// Scroll in the overlay
	CGContextRef context = UIGraphicsGetCurrentContext();
	[UIView beginAnimations:nil context:context];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.1];
	[self setAlpha:0.0f];
	[UIView commitAnimations];
	
	if (MlabelTableSelect) [MlabelTableSelect removeFromSuperview]; // addSubviewした親から消す
	// e3view のセクションを更新する　＜＜合計値のため＞＞
	[self.Pe3view reloadData];
}


// タッチイベント開始
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{
//	if ([touches count] != 1) return;
	if (MiSelect != -1) return;

	
	MpointBegin = [[touches anyObject] locationInView:self];
	MtTouchBegan = event.timestamp;
	
	//AzLOG(@"tpBegin=(%f,%f)", MpointBegin.x, MpointBegin.y);

	MiVolume = 0;
	MiVolumeTenfold = 1;
	MiVolumePrev = 0;
	
	if (MpointBegin.y < 90 OR 440 < MpointBegin.y) {
		MiSelect = -1; // touchesBegan Reset
		return;
	}
	
	if (MlabelStock.frame.origin.x-30 < MpointBegin.x 
						&& MpointBegin.x < MlabelStock.frame.origin.x+MlabelStock.frame.size.width+30) {
		MiSelect = 0;
	}
	else if (MlabelRequired.frame.origin.x-30 < MpointBegin.x 
						&& MpointBegin.x < MlabelRequired.frame.origin.x+MlabelRequired.frame.size.width+30) {
		MiSelect = 1;
	}
/*	else if (MlabelWeight.frame.origin.x < MpointBegin.x 
						&& MpointBegin.x < MlabelWeight.frame.origin.x+MlabelWeight.frame.size.width/2) {
		MiSelect = 2;
	}
	else if (labelWeight.frame.origin.x+labelWeight.frame.size.width/2 < tpBegin.x 
			 && tpBegin.x < labelWeight.frame.origin.x+labelWeight.frame.size.width) {
		iSelect = 3;
		if (2 <= [touches count]) iSelect = 2;
	}*/
	else {
		MiSelect = -1; // touchesBegan Reset
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event 
{
	MpointMove = [[touches anyObject] locationInView:self];

	MiVolume = (NSInteger)(MpointBegin.y - MpointMove.y) / TOUCHSTEP;  // Y軸下向きに注意

/*	// 倍率が上がれば、そのまま保持する
	long lNewTenfold = 1;
	if (2 <= iSelect) lNewTenfold = 10; // Weight(x10)
	switch ([touches count]) {  // マルチタッチ本数
		case 2: // 2本 10倍
			lNewTenfold *= 10;
			break;
		case 3: // 3本 100倍
			lNewTenfold *= 100;
			break;
	}
	if (lVolumeTenfold < lNewTenfold) lVolumeTenfold = lNewTenfold; // 増加のみ
	
	lVolume *= lVolumeTenfold;
*/	
	
	if (MiVolume == MiVolumePrev) return;
	MiVolumePrev = MiVolume;
	
	switch (MiSelect) {
		case 0:
			if (MiStock + MiVolume < 0) MiVolume = 0 - MiStock;
			else if (999 < MiStock + MiVolume) MiVolume = MiStock - 999;
			MlabelStock.text = [NSString stringWithFormat:@"%ld", (long)(MiStock + MiVolume)];
			break;
		case 1:
			if (MiRequired + MiVolume < 0) MiVolume = 0 - MiRequired;
			else if (999 < MiRequired + MiVolume) MiVolume = MiRequired - 999;
			MlabelRequired.text = [NSString stringWithFormat:@"%ld", (long)(MiRequired + MiVolume)];
			break;
/*		case 2: // Weight(x10)(x100)
		case 3:
			if (MiWeight + MiVolume < 0) MiVolume = 0 - MiWeight;
			else if (99999 < MiWeight + MiVolume) MiVolume = MiWeight - 99999;
			MlabelWeight.text = [NSString stringWithFormat:@"%ld", (long)(MiWeight + MiVolume)];
			break;*/
	}
}

// タッチイベント終了：指を離せば保存して閉じる
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{
	static const NSTimeInterval tFlickInterval = 0.3;
//	static const NSTimeInterval tClickInterval = 0.5;
	static const NSInteger iFlickDistance = 10;
	BOOL bSave = NO;
	
//	if (1 < [touches count]) return;  // まだ1本が離れていない

	switch (MiSelect) {
		case 0:
			if (MiStock + MiVolume < 0) MiVolume = 0 - MiStock;
			else if (999 < MiStock + MiVolume) MiVolume = MiStock - 999;
			MiStock += MiVolume;
			break;
		case 1:
			if (MiRequired + MiVolume < 0) MiVolume = 0 - MiRequired;
			else if (999 < MiRequired + MiVolume) MiVolume = MiRequired - 999;
			MiRequired += MiVolume;
			break;
		case 2: // Weight(x10)(x100)
		case 3:
			if (MiWeight + MiVolume < 0) MiVolume = 0 - MiWeight;
			else if (99999 < MiWeight + MiVolume) MiVolume = MiWeight - 99999;
			MiWeight += MiVolume;
			break;
	}

	// Stock フリック検出
	MpointMove = [[touches anyObject] locationInView:self];
	NSInteger iX = abs(MpointBegin.x - MpointMove.x);
//	NSInteger iY = abs(tpBegin.y - tpMove.y);
	if (iFlickDistance < iX) {
		if (event.timestamp - MtTouchBegan < tFlickInterval) {
			// フリック決定
			if (MiSelect == 0) {
				if (MpointBegin.x < MpointMove.x) {
					// 右フリック：Compleat
					MiStock = MiRequired;
				} else {
					// 左フリック：ZERO
					MiStock = 0;
				}
				MlabelStock.text = [NSString stringWithFormat:@"%d", (long)MiStock];
			}
			else if (MiSelect == 1) {
				if (MpointBegin.x < MpointMove.x) {
					// 右フリック：Compleat
				} else {
					// 左フリック：ZERO
					MiRequired = 0;
					MlabelRequired.text = [NSString stringWithFormat:@"%d", (long)MiRequired];
					// 必要数が0になれば在庫数も0にする
					MiStock = 0;
					MlabelStock.text = [NSString stringWithFormat:@"%d", (long)MiStock];
				}
			}
		}
//		iSelect = -1; // touchesBegan Reset
//		lVolumeTenfold = 1; // Reset
//		return;
	}
//	else if (iX < TOUCHSTEP && iY < TOUCHSTEP && event.timestamp - tTouchBegan < tClickInterval)
//	{
//指が離れたら、クローズする。　Opt設定で選択できるようにするかも
		
		// 終了クリック検出

		// Check Mark Zone
		//CGRect rect = [self.e3view rectForRowAtIndexPath:self.e3path];
		//＜＜この rect.origin.y は、UIScreenView座標であり、Table末尾まで連続するY座標になっている＞＞
		if (MpointBegin.x < 40 && 90 < MpointBegin.y && MpointBegin.y < 440 ) {
			// Check Mark Zone をクリックした　＜＜ダブルクリックしてチェックが変化する感じ＞＞
			if (MiStock == MiRequired) MiStock = 0; // Check No
			else MiStock = MiRequired;			 // Check Ok
		}
		
		// ＜＜チューンにより、最後にだけ書き込み更新している＞＞
		if (MlabelStock.tag != MiStock) {
			[self.Pe3obj setValue:[NSNumber numberWithInteger:MiStock] forKey:@"stock"];
			bSave = YES;
		}
		
		if (MlabelRequired.tag != MiRequired) {
			[self.Pe3obj setValue:[NSNumber numberWithInteger:MiRequired] forKey:@"need"];
			bSave = YES;
		}
		
/*		if (MlabelWeight.tag != MiWeight) {
			[self.Pe3obj setValue:[NSNumber numberWithInteger:MiWeight] forKey:@"weight"];
			bSave = YES;
		}*/
		
		if (bSave) {
			// SAVE
			[self.Pe3obj setValue:[NSNumber numberWithInteger:(MiWeight*MiStock)] forKey:@"weightStk"];
			[self.Pe3obj setValue:[NSNumber numberWithInteger:(MiWeight*MiRequired)] forKey:@"weightNed"];
			[self.Pe3obj setValue:[NSNumber numberWithInteger:(MiRequired-MiStock)] forKey:@"lack"]; // 不足数
			[self.Pe3obj setValue:[NSNumber numberWithInteger:(MiWeight*(MiRequired-MiStock))] forKey:@"weightLack"]; // 不足重量

			NSInteger iNoGray = 0;
			if (0 < MiRequired) iNoGray = 1;
			[self.Pe3obj setValue:[NSNumber numberWithInteger:iNoGray] forKey:@"noGray"]; // 有効(0<必要)アイテム

			NSInteger iNoCheck = 0;
			if (0 < MiRequired && MiStock < MiRequired) iNoCheck = 1;
			[self.Pe3obj setValue:[NSNumber numberWithInteger:iNoCheck] forKey:@"noCheck"]; // 不足アイテム
			
			// E2 sum属性　＜高速化＞ 親sum保持させる
			E2 *e2obj = self.Pe3obj.parent;
			[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.noGray"] forKey:@"sumNoGray"];
			[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.noCheck"] forKey:@"sumNoCheck"];
			[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.weightStk"] forKey:@"sumWeightStk"];
			[e2obj setValue:[e2obj valueForKeyPath:@"childs.@sum.weightNed"] forKey:@"sumWeightNed"];
			
			// E1 sum属性　＜高速化＞ 親sum保持させる
			E1 *e1obj = e2obj.parent;
			[e1obj setValue:[e1obj valueForKeyPath:@"childs.@sum.sumNoGray"] forKey:@"sumNoGray"];
			[e1obj setValue:[e1obj valueForKeyPath:@"childs.@sum.sumNoCheck"] forKey:@"sumNoCheck"];
			[e1obj setValue:[e1obj valueForKeyPath:@"childs.@sum.sumWeightStk"] forKey:@"sumWeightStk"];
			[e1obj setValue:[e1obj valueForKeyPath:@"childs.@sum.sumWeightNed"] forKey:@"sumWeightNed"];
			
			// SAVE : e3edit,e2list は ManagedObject だから更新すれば ManagedObjectContext に反映されている
			NSError *err = nil;
			if (![self.Pe3obj.managedObjectContext save:&err]) {
				NSLog(@"Unresolved error %@, %@", err, [err userInfo]);
				abort();
			}
		}
		[self hide];
		return;
//	}
	
/*
	// 一旦、指が離れた。ここまでのVolumeを蓄積する。
	switch (iSelect) {
		case 0:
			if (lStock + lVolume < 0) lVolume = 0 - lStock;
			else if (999 < lStock + lVolume) lVolume = lStock - 999;
			lStock += lVolume;
			break;
		case 1:
			if (lRequired + lVolume < 0) lVolume = 0 - lRequired;
			else if (999 < lRequired + lVolume) lVolume = lRequired - 999;
			lRequired += lVolume;
			break;
		case 2: // Weight(x10)(x100)
		case 3:
			if (lWeight + lVolume < 0) lVolume = 0 - lWeight;
			else if (99999 < lWeight + lVolume) lVolume = lWeight - 99999;
			lWeight += lVolume;
			break;
	}
	iSelect = -1; // touchesBegan Reset
	lVolumeTenfold = 1; // Reset
	return;
*/
}

@end
