//
//  E3viewController.h
//  iPack
//
//  Created by 松山 和正 on 09/12/06.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@class E1;
@class E2;
@class E3edit;
@class ItemTouchView;
#ifdef AzPAD
@class E2viewController;
#endif

@interface E3viewController : UITableViewController <UIActionSheetDelegate, UISearchBarDelegate
#ifdef AzPAD
	,UIPopoverControllerDelegate
#endif
>
{

@private
	E1				*Re1selected;  // grandParent: 常にセットされる
	//E2				*Re2selected;  // Parent: = nil; Sort listの場合！注意   //NG//E3で移動すると親が変わるから廃止
	NSInteger		PiFirstSection;  // E2から呼び出されたとき頭出しするセクション viewWillAppear内でジャンプ後、(-1)にする。
	NSInteger		PiSortType;		// (-1)Group  (0〜)Sort list.
	BOOL			PbSharePlanList;	// SharePlan プレビューモード

	//----------------------------------------------viewDidLoadでnil, dealloc時にrelese
	//NSAutoreleasePool	*RautoPool;		// [0.3]autorelease独自解放のため
	NSMutableArray		*RaE2array;			//[1.0.2]E2から受け取るのではなく、ここで生成するようにした。
	NSMutableArray		*RaE3array;
	//----------------------------------------------Owner移管につきdealloc時のrelese不要
#ifdef AzPAD
	UIPopoverController*	Mpopover;
	NSIndexPath*				MindexPathEdit;	//[1.1]ポインタ代入注意！copyするように改善した。
	UIToolbar*					Me2toolbar;
#endif
	//----------------------------------------------assign
	AppDelegate *appDelegate;
	NSIndexPath		*MpathClip;					//[1.1]ポインタ代入注意！copyするように改善した。
	NSIndexPath	  *MindexPathActionDelete;	//[1.1]ポインタ代入注意！copyするように改善した。
	//BOOL MbFirstOne;
	//BOOL MbOptShouldAutorotate;
	BOOL MbAzOptTotlWeightRound;
	BOOL MbAzOptShowTotalWeight;
	BOOL MbAzOptShowTotalWeightReq;
	BOOL MbAzOptItemsGrayShow;
	BOOL MbAzOptItemsQuickSort;
	BOOL MbAzOptCheckingAtEditMode;
	BOOL MbAzOptSearchItemsNote;
	BOOL MbClipPaste;
	CGPoint		McontentOffsetDidSelect; // didSelect時のScrollView位置を記録
}

//@property (nonatomic, retain) NSMutableArray *RaE2array; // assignにするとスクーロール中に「戻る」とフリーズする。
														// assignだとE3側の処理が完了する前に解放されてしまうようだ。
@property (nonatomic, retain) E1		*Re1selected;	//grandParent;
//@property (nonatomic, retain) E2		*Re2selected;	//parent;
@property (nonatomic, assign) NSInteger	PiFirstSection;
@property (nonatomic, assign) NSInteger	PiSortType;
@property (nonatomic, assign) BOOL		PbSharePlanList;

//- (void)viewComeback:(NSArray *)selectionArray;  // Comeback 再現復帰処理用
#ifdef AzPAD
- (void)refreshE3view;
#endif

@end
