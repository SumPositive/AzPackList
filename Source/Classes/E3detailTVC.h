//
//  E3detailTVC.h
//  AzPacking
//
//  Created by 松山 和正 on 10/01/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AZDial.h"

#define WEIGHT_DIAL	1

@class E3;
@class CalcView;

@interface E3detailTVC : UITableViewController <UITextFieldDelegate, UITextViewDelegate
#ifdef AzPAD
//	,UIPopoverControllerDelegate
#endif
>
{
@private
	NSMutableArray	*RaE2array;
	NSMutableArray	*RaE3array;
	E3						*Re3target;
	NSInteger			PiAddGroup;		// =(-1)Edit  >=(E2.row)Add Mode
	NSInteger			PiAddRow;		//(V0.4)Add行の.row ここに追加する
	BOOL					PbSharePlanList;  // PbSpMode;	// SharePlan プレビューモード
#ifdef AzPAD
	id									delegate;
	UIPopoverController*	selfPopover;  // 自身を包むPopover  閉じる為に必要
#endif
	//----------------------------------------------viewDidLoadでnil, dealloc時にrelese
	//NSAutoreleasePool	*MautoreleasePool;	autoreleaseオブジェクトを「戻り値」にしているため、ここでの破棄禁止
	//----------------------------------------------Owner移管につきdealloc時のrelese不要
	UILabel		*MlbGroup;	// .tag = E2.row　　　以下全てcellがOwnerになる
	UITextField	*MtfName;
	UITextField	*MtfKeyword;	//[1.1]Shopping keyword
	UITextView	*MtvNote;
	//UILabel		*MlbNote;
	UILabel		*MlbStock;
	UILabel		*MlbNeed;
	UILabel		*MlbWeight;
	//UILabel		*MlbStockMax;
	//UILabel		*MlbNeedMax;
	//UISlider			*MsliderStock;
	//UISlider			*MsliderNeed;
	AZDial			*mDialStock;
	AZDial			*mDialNeed;
#ifdef WEIGHT_DIAL
	AZDial			*mDialWeight;
#else
	UISlider			*MsliderWeight;
	UILabel		*MlbWeightMax;
	UILabel		*MlbWeightMin;
#endif

	CalcView		*McalcView;
#ifdef AzPAD
	//UIPopoverController*	MpopoverView;	// 回転時に強制的に閉じるため
#endif
	//----------------------------------------------assign
	AppDelegate		*appDelegate;
	float						MfTableViewContentY;
}

@property (nonatomic, retain) NSMutableArray *RaE2array;
@property (nonatomic, retain) NSMutableArray *RaE3array;
@property (nonatomic, retain) E3 *Re3target;
@property (nonatomic, assign) NSInteger PiAddGroup;
@property (nonatomic, assign) NSInteger PiAddRow;
@property (nonatomic, assign) BOOL	PbSharePlanList;
#ifdef AzPAD
@property (nonatomic, assign) id									delegate;
@property (nonatomic, retain) UIPopoverController*	selfPopover;
#endif

// 公開メソッド
- (void)cancelClose:(id)sender ;
#ifdef AzPAD
//- (void)closePopover;
#endif

@end
