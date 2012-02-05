//
//  Global.h
//  AzPackList
//
//  Created by 松山 和正 on 09/12/03.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

//#define AzMAKE_SPLASHFACE  // 起動画面 Default.png を作るための作業オプション

#define COPYRIGHT		@"©1995-2012 Azukid"

#define GD_PRODUCTNAME	@"AzPackList"	// IMPORTANT PRODUCT NAME  和名「モチメモ」

#define AdMobID_PackPAD	@"a14dd004bc6bc0a";		//AdMobパブリッシャー ID  "モチメモ Free iPad"
#define AdMobID_PackList	@"a14d4cec1e082c1";		//AdMobパブリッシャー ID  "モチメモ Free iPhone"　


//#define AzMAX_PLANS		 20		// 最大PLAN数
//#define AzMAX_GROUPS	100		// 最大GROUP数
//#define AzMAX_ITEMS	   1000		// 最大ITEM数 (全GROUP合計)
#define AzMAX_PLAN_WEIGHT		999999	//[0.2c] 1プランの総重量制限(g)
#define AzMAX_NAME_LENGTH		50		//[0.2c] .name 最大文字数
#define AzMAX_NOTE_LENGTH		200		//[0.2c] .note 最大文字数

#define GD_CSV_HEADER_ID	@"AzPacking"		// CSV Version.1
//#define GD_COREDATANAME	@"AzPack.sqlite"	// CoreData Saved SQLlite File name
//#define GD_CSVFILENAME			@"AzPack.csv"		// Local Save file name
#define GD_GDOCS_EXT			@".AzPack"			// Google Document Spredseet.拡張子
#define GD_CSVFILENAME4		@"AzPack.packlist"	//[1.1.0:xcdatamodel-4]以降 HOME/tmp/file name
#define GD_GDOCS_EXT4			@".packlist"			//[1.1.0:xcdatamodel-4]以降 Google Document Spredseet.拡張子
#define GD_EXTENSION				@"azp"					//[2.0]
#define CRYPT_HEADER				@"AzPackListCrypt"	//変更禁止//固定長

#define GD_SECTION_TIMES	100000				// .tag = .section * GD_SECTION_TIMES + .row に使用
#define GD_E2SORTLIST_COUNT		3				// E2 Sort Listの有効行数
//#define	GD_ADD_E3_NAME		@"\nAdd\n"			//(V0.4)Add行（セクション内の行移動可能）（CSV保存しない）

// UserDefaults: UD_KEY   機種個別設定   初期値定義は、<applicationDidFinishLaunching>内
#define UD_OptShouldAutorotate				@"UD_OptShouldAutorotate"
#define UD_OptPasswordSave					@"UD_OptPasswordSave"
#define UD_OptCrypt									@"UD_OptCrypt"	// YES=PackList暗号化 ＜＜秘密Keyはデバイス別に保存

#define UD_CurrentVersion						@"UD_CurrentVersion"
//#define UD_DeviceID									@"UD_DeviceID"		//2.0// Original UDID
#define GD_DefPassword							@"DefPassword"
#define GD_DefUsername							@"DefUsername"
#define GD_DefNickname							@"DefNickname"

// iCloud-KVS: KV_KEY  全機種共有設定
#define KV_OptWeightRound					@"KV_OptWeightRound"
#define KV_OptShowTotalWeight				@"KV_OptShowTotalWeight"
#define KV_OptShowTotalWeightReq		@"KV_OptShowTotalWeightReq"
#define KV_OptItemsGrayShow					@"KV_OptItemsGrayShow"
#define KV_OptCheckingAtEditMode		@"KV_OptCheckingAtEditMode" // 編集モードでチェックする
#define KV_OptSearchItemsNote				@"KV_OptSearchItemsNote"	// アイテムのNote内も検索する
#define KV_OptAdvertising						@"KV_OptAdvertising"			// YES=広告あり／NO=なし


#define GD_KeyboardHeightPortrait	216.0f	// タテ向きのときのキーボード高さ
#define GD_KeyboardHeightLandscape	160.0f	// ヨコ向きのときのキーボード高さ

#define GD_POPOVER_SIZE_INIT		CGSizeMake(480-1, 500-1)	//init初期化時に使用　＜＜＜変化ありにするため1廻り小さくする
#define GD_POPOVER_SIZE				CGSizeMake(480, 500)			//viewDidAppear時に使用

#define GD_POPOVER_E3detailTVC_SIZE		CGSizeMake(400, 610)	//590		//E3detailTVCおよびその配下に使用　＜＜下余白はテンキーエリア

// iCloud NSNotification messages
#define NFM_REFRESH_ALL_VIEWS			@"RefreshAllViews"					// 再描画（MOC変更）
//#define NFM_REFETCH_ALL_DATA			@"RefetchAllDatabaseData"		<<< NFM_REFRESH_ALL_VIEWS に一元化

//
// Global.m Functions
//
void alertBox( NSString *zTitle, NSString *zMsg, NSString *zButton );
UIColor *GcolorBlue(float percent);
UIImage *GimageFromString(float Pfx, float Pfy, float PfSize, NSString* str);
NSString *GstringFromNumber( NSNumber *num );
NSString *getMacAddress();
NSDate *dateFromUTC( NSString *zUTC );
NSString *utcFromDate( NSDate *dTZ );



//-------------------------------------------------------------------以下、定型定義

#define OR  ||

#ifdef DEBUG	//--------------------------------------------- DEBUG
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


