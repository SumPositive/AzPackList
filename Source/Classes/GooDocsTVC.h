//
//  GooDocsView.h
//  iPack
//
//  Created by 松山 和正 on 09/12/25.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
/* -----------------------------------------------------------------------------------------------
 * GData API ライブラリの組み込み手順
 *
 * 1)ダウンロードした gdata-objectivec-client-1 の Source／GData.xcodeproj から Xcode起動
 *
 * 2)グループとファイルに表示される「GData Source」フォルダを丸ごとドラッグして自己のグループとファイルへ「リンク」する
 *																			　（コピーでなく「リンク」にすること）
 *
 * 3)Xcodeメニュー、プロジェクト設定を編集から「検索パス」をセットする
 *		ヘッダ検索パス		/usr/include/libxml2
 *		他のリンカフラグ	-lxml2		（既に他の定義があれば付け足すことになる）
 *
 * 以上でコンパイル可能になる。
 * -----------------------------------------------------------------------------------------------
 */


#import <UIKit/UIKit.h>
#import "GData.h"
#import "GDataFeedDocList.h"


@interface GooDocsView : UITableViewController <UITextFieldDelegate, UIActionSheetDelegate> 

@property (nonatomic, retain) NSManagedObjectContext *Rmoc;
@property (nonatomic, retain) E1 *Re1selected;
@property NSInteger PiSelectedRow;
@property BOOL	 PbUpload; 
@property (nonatomic, assign) id									delegate;
@property (nonatomic, retain) UIPopoverController*	selfPopover;

@end

