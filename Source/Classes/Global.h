//
//  Global.h
//  AzPacking
//
//  Created by 松山 和正 on 09/12/03.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

//#define AzMAKE_SPLASHFACE  // 起動画面 Default.png を作るための作業オプション

#if defined(AzSTABLE) || defined(AzMAKE_SPLASHFACE)
	// 広告なし
#else // AzFREE
	#define FREE_AD	// iPadも共通
	#ifdef AzPAD
		#define AdMobID_PackPAD	@"a14dd004bc6bc0a";		//AdMobパブリッシャー ID  "モチメモ Free iPad"
	#else
		#define AdMobID_PackList	@"a14d4cec1e082c1";		//AdMobパブリッシャー ID  "モチメモ Free iPhone"　
	#endif
#endif

#define OR  ||

#ifdef AzDEBUG	//--------------------------------------------- DEBUG
#define AzLOG(...) NSLog(__VA_ARGS__)
#define AzRETAIN_CHECK(zName,pObj,iAns)  { if ([pObj retainCount] > iAns) NSLog(@"AzRETAIN_CHECK> %@ %d > %d", zName, [pObj retainCount], iAns); }

#else	//----------------------------------------------------- RELEASE
		// その他のフラグ：-DNS_BLOCK_ASSERTIONS=1　（NSAssertが除去される）
#define AzLOG(...) 
#define NSLog(...) 
#define AzRETAIN_CHECK(...) 
#endif

// iOS VERSION		http://goddess-gate.com/dc2/index.php/post/452
#define IOS_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define IOS_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define IOS_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define IOS_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define IOS_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)


#define GD_PRODUCTNAME	@"AzPacking"	// IMPORTANT PRODUCT NAME  和名「モチメモ」
/*----- GD_PRODUCTNAME を変更するときに必要となる作業の覚書 -------------------------------

 ＊ソース変更
	AppDelegete.m にて NSBundle名に GD_PRODUCTNAME が渡されている。以下適切に変更しなければ、ここでフリーズする

 *実体ファイル名変更と同時に、XCODEから各ファイルの情報を開いて、実体を再指定(リンク)する
	AzPacking					ルートフォルダ名
	AzPacking_Prefix.pch		プリコンパイルヘッダ
	AzPacking.xcmappingmodel	データマッピング
	AzPacking.xcdatamodeld		データモデル

 ＊XCODE＞プロジェクト＞アクティブターゲット"AzPacking"を編集
		＞一般＞名前を変更
		＞ビルド＞プリダクト名、GCC_PREFIX_HEADRER を変更
		＞プロパティ＞旧名があれば変更

 *iPhoneシニュレータ＞コンテンツと設定をリセット

 *XCODE＞キャッシュを空にする

 *XCODE＞ビルド＞すべてのターゲットをクリーニング

 *XCODE＞ビルドして進行

 -----------------------------------------------------------------------*/

//#define AzMAX_PLANS		 20		// 最大PLAN数
//#define AzMAX_GROUPS	100		// 最大GROUP数
//#define AzMAX_ITEMS	   1000		// 最大ITEM数 (全GROUP合計)
#define AzMAX_PLAN_WEIGHT		999999	//[0.2c] 1プランの総重量制限(g)
#define AzMAX_NAME_LENGTH		50		//[0.2c] .name 最大文字数
#define AzMAX_NOTE_LENGTH		200		//[0.2c] .note 最大文字数

#define GD_COREDATANAME	@"AzPack.sqlite"	// CoreData Saved SQLlite File name
//#define GD_CSVFILENAME			@"AzPack.csv"		// Local Save file name
#define GD_GDOCS_EXT			@".AzPack"			// Google Document Spredseet.拡張子
#define GD_CSVFILENAME4		@"AzPack.packlist"	//[1.1.0:xcdatamodel-4]以降 HOME/tmp/file name
#define GD_GDOCS_EXT4			@".packlist"				//[1.1.0:xcdatamodel-4]以降 Google Document Spredseet.拡張子

#define GD_SECTION_TIMES	100000				// .tag = .section * GD_SECTION_TIMES + .row に使用
#define GD_E2SORTLIST_COUNT		3				// E2 Sort Listの有効行数
//#define	GD_ADD_E3_NAME		@"\nAdd\n"			//(V0.4)Add行（セクション内の行移動可能）（CSV保存しない）

// standardUserDefaults Setting Plist KEY
#define GD_DefPassword						@"DefPassword"
#define GD_DefUsername						@"DefUsername"
#define GD_DefNickname						@"DefNickname"

// Option Setting Plist KEY     初期値定義は、<applicationDidFinishLaunching>内
//#define GD_OptStartupWindshield				@"OptStartupWindshield"
#define GD_OptStartupRestoreLevel			@"OptStartupRestoreLevel"
#define GD_OptShouldAutorotate				@"OptShouldAutorotate"
//#define GD_OptDisclosureButtonToEditable	@"OptDisclosureButtonToEditable"
#define GD_OptPasswordSave					@"OptPasswordSave"
#define GD_OptTotlWeightRound				@"OptTotlWeightRound"
#define GD_OptItemsQuickSort				@"OptItemsQuickSort"
#define GD_OptShowTotalWeight				@"OptShowTotalWeight"
#define GD_OptShowTotalWeightReq			@"OptShowTotalWeightReq"
#define GD_OptItemsGrayShow					@"OptItemsGrayShow"
#define GD_OptCheckingAtEditMode			@"OptCheckingAtEditMode" // 編集モードでチェックする
#define GD_OptSearchItemsNote				@"OptSearchItemsNote"	// アイテムのNote内も検索する

#define GD_KeyboardHeightPortrait	216.0f	// タテ向きのときのキーボード高さ
#define GD_KeyboardHeightLandscape	160.0f	// ヨコ向きのときのキーボード高さ

#ifdef AzPAD
#define GD_POPOVER_SIZE_INIT		CGSizeMake(480-1, 500-1)	//init初期化時に使用　＜＜＜変化ありにするため1廻り小さくする
#define GD_POPOVER_SIZE				CGSizeMake(480, 500)			//viewDidAppear時に使用

#define GD_POPOVER_E3detailTVC_SIZE		CGSizeMake(400, 610)	//590		//E3detailTVCおよびその配下に使用　＜＜下余白はテンキーエリア
#endif

// iCloud NSNotification messages
#define NFM_REFRESH_ALL_VIEWS			@"RefreshAllViews"
#define NFM_REFETCH_ALL_DATA			@"RefetchAllDatabaseData"

//
// Global.m Functions
//
void alertBox( NSString *zTitle, NSString *zMsg, NSString *zButton );
UIColor *GcolorBlue(float percent);
UIImage *GimageFromString(float Pfx, float Pfy, float PfSize, NSString* str);
NSString *GstringFromNumber( NSNumber *num );



