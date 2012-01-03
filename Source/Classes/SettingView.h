//
//  SettingView.h
//  iPack
//
//  Created by 松山 和正 on 10/01/03.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingView : UIView  //UIViewController 
{
	UITableViewController *PparentViewCon;  // 親View 設定変更時に viewWillAppear を送るため
}

@property (nonatomic, retain) UITableViewController *PparentViewCon;

// 公開メソッド
- (void)show;
- (void)hide;

@end
