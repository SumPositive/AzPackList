//
//  AZPicasa.h
//  AzPackList5
//
//  Created by Sum Positive on 12/02/11.
//  Copyright (c) 2012 Azukid. All rights reserved.
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

#import <Foundation/Foundation.h>
#import "GData.h"
#import "GDataPhotos.h"

@interface AZPicasa : NSObject

- (id)init;
- (void)uploadData:(NSData*)photoData  photoTitle:(NSString*)photoTitle;

@end
