//
//  E3edit.m
//  iPack
//
//  Created by 松山 和正 on 09/12/06.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
// InterfaceBuilderを使わずに作ったViewController

#import "Global.h"
#import "AppDelegate.h"
#import "Elements.h"
#import "E3viewController.h"
#import "E3edit.h"

@interface E3edit (PrivateMethods)
- (void)cancel:(id)sender;
- (void)save:(id)sender;
- (void)viewDesign;
- (void)tvNoteNarrow; // Noteフィールドをキーボードに隠れなくする
BOOL MbAnimation; // viewWillAppear時に記録し、閉じるとき同様にする
BOOL  MbKeyboardShow;
@end
@implementation E3edit   // ViewController
@synthesize Pe2array;
@synthesize Pe3array;
@synthesize Pe1selected;
@synthesize Pe2selected;
@synthesize Pe3target;
@synthesize PbAddObj;

#pragma mark Memory management

- (void)dealloc    // 生成とは逆順に解放するのが好ましい
{
	AzRETAIN_CHECK(@"E3e MbuGroup", MbuGroup, 1)
	// MbuGroupは、alloc生成でなく＋クラスインスタンスなのでrelease不要。
	AzRETAIN_CHECK(@"E3e MpvGroup", MpvGroup, 2)  // addSubviewによる+1があるため
	[MpvGroup release];
	AzRETAIN_CHECK(@"E3e MtfName", MtfName, 2)
	[MtfName release];
	AzRETAIN_CHECK(@"E3e MtfSpec", MtfSpec, 2)
	[MtfSpec release];
	AzRETAIN_CHECK(@"E3e MtfWeight", MtfWeight, 2)
	[MtfWeight release];
	AzRETAIN_CHECK(@"E3e MtfStock", MtfStock, 2)
	[MtfStock release];
	AzRETAIN_CHECK(@"E3e MtfRequired", MtfRequired, 2)
	[MtfRequired release];
	AzRETAIN_CHECK(@"E3e MtvNote", MtvNote, 2)
	[MtvNote release];
    
	// @property (retain)
	AzRETAIN_CHECK(@"E3e Pe3target", Pe3target, 5) // 4 or 5
	[Pe3target release];
	AzRETAIN_CHECK(@"E3e Pe2selected", Pe2selected, 6) // 5 or 6
	[Pe2selected release];
	AzRETAIN_CHECK(@"E3e Pe1selected", Pe1selected, 5) // 4 or 5
	[Pe1selected release];
	AzRETAIN_CHECK(@"E3e Pe3array", Pe3array, 1)
	[Pe3array release];
	AzRETAIN_CHECK(@"E3e Pe2array", Pe2array, 2)
	[Pe2array release];

	[super dealloc];
}

- (void)viewDidUnload {
	// メモリ不足時、裏側にある場合に呼び出されるので、viewDidLoadで生成したObjを解放する。
	[MpvGroup release];		MpvGroup = nil;
	[MtfName release];		MtfName = nil;
	[MtfSpec release];		MtfSpec = nil;
	[MtfWeight release];	MtfWeight = nil;
	[MtfStock release];		MtfStock = nil;
	[MtfRequired release];	MtfRequired = nil;
	[MtvNote release];		MtvNote = nil;
	// @property (retain) は解放しない。
#ifdef AzDEBUG
	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"viewDidUnload" 
													 message:@"E3edit" 
													delegate:nil 
										   cancelButtonTitle:nil 
										   otherButtonTitles:@"OK", nil] autorelease];
	[alert show];
#endif	
}


#pragma mark View lifecycle

// InterfaceBuilderを使わずにコントロール配置するとき、このinitに記述する。 initは必ず1度しか通らない。
// この後に、viewDidLoad が呼び出される。 viewDidLoadは、メモリ不足でUnloadされた後、再度呼び出される場合がある。
- (id)init   
{
	if (!(self = [super init])) return self; // 何らかの失敗

	self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];

	//-------------------------------------------------------------------------
	// E3.group
	MbuGroup = (UIButton *)[UIButton buttonWithType:UIButtonTypeRoundedRect]; // これはautoreleaseされる
//	[MbuGroup setFrame:CGRectMake(0, 0, 260, 20)];
//	[MbuGroup setCenter:CGPointMake(160, LfOriginY)];
	
	MbuGroup.titleLabel.font = [UIFont systemFontOfSize:12];
	[MbuGroup setTitle:NSLocalizedString(@"Group", @"グループ") forState:UIControlStateNormal];
	[MbuGroup addTarget:self action:@selector(selectGroup:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:MbuGroup];
	// MbuGroupは、alloc生成でなく＋クラスインスタンスなのでrelease不要。
	
	//-------------------------------------------------------------------------
	// E3.name
//	MtfName = [[UITextField alloc] initWithFrame:CGRectMake(10,LfOriginY, 300,26)];
	MtfName = [[UITextField alloc] init];
	MtfName.borderStyle = UITextBorderStyleRoundedRect;
	MtfName.font = [UIFont systemFontOfSize:18];  //フォントサイズ
	MtfName.placeholder = NSLocalizedString(@"Item name", @"アイテム名称");
	MtfName.keyboardType = UIKeyboardTypeDefault;
	MtfName.delegate = self;
	[self.view addSubview:MtfName];
	AzRETAIN_CHECK(@"E3e -A- MtfName", MtfName, 2)  // addSubviewにより+1で2になる
		
	//-------------------------------------------------------------------------
	// E3.stock / need / weight
	MtfStock = [[UITextField alloc] init];
	MtfStock.borderStyle = UITextBorderStyleRoundedRect;
	MtfStock.font = [UIFont systemFontOfSize:16];  //フォントサイズ
	MtfStock.placeholder = NSLocalizedString(@"Stock", @"収納");
	MtfStock.textAlignment = UITextAlignmentRight;  //右字寄せ
	MtfStock.keyboardType = UIKeyboardTypeNumberPad; // テンキーパッド
	MtfStock.delegate = self;
	[self.view addSubview:MtfStock];
	
	// E3.need
	MtfRequired = [[UITextField alloc] init];
	MtfRequired.borderStyle = UITextBorderStyleRoundedRect;
	MtfRequired.font = [UIFont systemFontOfSize:16];  //フォントサイズ
	MtfRequired.placeholder = NSLocalizedString(@"Need", @"必要");
	MtfRequired.textAlignment = UITextAlignmentRight;  //右字寄せ
	MtfRequired.keyboardType = UIKeyboardTypeNumberPad; // テンキーパッド
	MtfRequired.delegate = self;
	[self.view addSubview:MtfRequired];
	
	// E3.weight
	MtfWeight = [[UITextField alloc] init];
	MtfWeight.borderStyle = UITextBorderStyleRoundedRect;
	MtfWeight.font = [UIFont systemFontOfSize:16];  //フォントサイズ
	MtfWeight.placeholder = NSLocalizedString(@"One weight", @"単重量");
	MtfWeight.textAlignment = UITextAlignmentRight;  //右字寄せ
	MtfWeight.keyboardType = UIKeyboardTypeNumberPad; // テンキーパッド
	MtfWeight.delegate = self;
	[self.view addSubview:MtfWeight];
	
	//-------------------------------------------------------------------------
	// E3.note
	MtvNote = [[UITextView alloc] init];
	MtvNote.font = [UIFont systemFontOfSize:12];
	MtvNote.keyboardType = UIKeyboardTypeDefault;
	MtvNote.delegate = self;  // textViewDidBeginEditingなどが呼び出されるように
	[self.view addSubview:MtvNote];
	
	// UIPickerView   ＜＜MtvNoteの上になるように、MtvNoteの後にaddしている＞＞
	MpvGroup = [[UIPickerView alloc] init];
	MpvGroup.delegate = self;
	MpvGroup.showsSelectionIndicator = YES;
	//MpvGroup.backgroundColor = [UIColor whiteColor];
	MpvGroup.hidden = YES;
	[self.view addSubview:MpvGroup];
	// 以後、参照したいので、ここではreleaseせず、deallocまで保持させる。
	AzRETAIN_CHECK(@"E3e -A- MpvGroup", MpvGroup, 2)  // addSubviewにより+1で2になる
	
	
	// CANCELボタンを左側に追加する  Navi標準の戻るボタンでは cancel:処理ができないため
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc]
											  initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
											  target:self action:@selector(cancel:)] autorelease];
	// SAVEボタンを右側に追加する
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
											   initWithBarButtonSystemItem:UIBarButtonSystemItemSave
											   target:self action:@selector(save:)] autorelease];
	MbKeyboardShow = NO; // キーなし
	return self;
}

// viewWillAppear はView表示直前に呼ばれる。よって、Viewの変化要素はここに記述する。　 　// viewDidAppear はView表示直後に呼ばれる
- (void)viewWillAppear:(BOOL)animated 
{
	[super viewWillAppear:animated];
	MbAnimation = animated; // 閉じるときも同様にするため

	[self viewDesign];

	[MbuGroup setTitle:Pe2selected.name forState:UIControlStateNormal];
	
	// PICKER
//	MpvGroup.hidden = YES; // 非表示
	// PICKER 指定されたコンポーネンツ(0)の行を選択する。
	[MpvGroup selectRow:[Pe2selected.row intValue] inComponent:0 animated:NO];	
	
	MtfName.text = [Pe3target valueForKey:@"name"];
	MtvNote.text = [Pe3target valueForKey:@"note"];
	
	if ([[Pe3target valueForKey:@"weight"] intValue] == 0) {
		MtfWeight.text = nil;
	} else {
		MtfWeight.text = [NSString stringWithFormat:@"%d", [[Pe3target valueForKey:@"weight"] intValue]];
	}
	
	if ([[Pe3target valueForKey:@"stock"] intValue] == 0) {
		MtfStock.text = nil;
	} else {
		MtfStock.text = [NSString stringWithFormat:@"%d", [[Pe3target valueForKey:@"stock"] intValue]];
	}
	
	if ([[Pe3target valueForKey:@"need"] intValue] == 0) {
		MtfRequired.text = nil;
	} else {
		MtfRequired.text = [NSString stringWithFormat:@"%d", [[Pe3target valueForKey:@"need"] intValue]];
	}
}

// ビューが非表示にされる前や解放される前ににこの処理が呼ばれる
- (void)viewWillDisappear:(BOOL)animated 
{
	// 戻る前にキーボードを消さないと、次に最初から現れた状態になってしまう。
	// キーボードを消すために全てのコントロールへresignFirstResponderを送る ＜表示中にしか効かない＞
	[MtfName resignFirstResponder];
	[MtfWeight resignFirstResponder];
	[MtfStock resignFirstResponder];
	[MtfRequired resignFirstResponder];
	[MtvNote resignFirstResponder];
	MbKeyboardShow = NO; // キーなし
	// PICKER
	MpvGroup.hidden = YES; // 非表示
}

// 回転サポート
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

// ユーザインタフェースの回転の最後の半分が始まる前にこの処理が呼ばれる　＜＜このタイミングで配置転換すると見栄え良い＞＞
- (void)willAnimateSecondHalfOfRotationFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation 
													   duration:(NSTimeInterval)duration
{
	//[self viewWillAppear:NO];没：これを呼ぶと、回転の都度、編集がキャンセルされてしまう。
	[self viewDesign]; // これで回転しても編集が継続されるようになった。
}

- (void)viewDesign
{
	CGRect rect;
	BOOL	bPortrait;
//	UILabel *label;
	
	float fKeyHeight;
	if (self.interfaceOrientation == UIInterfaceOrientationPortrait OR self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
		fKeyHeight = GD_KeyboardHeightPortrait;	 // タテ
		bPortrait = YES;
	} else {
		fKeyHeight = GD_KeyboardHeightLandscape; // ヨコ
		bPortrait = NO;
	}

	const float fPickerHeight = 216.0f; //　固定値である
	const float fWeightWidth = 120; // ヨコ：重量列の幅
	//-------------------------------------------------------------------------
	rect.origin.x = 10;
	if (bPortrait) {
		rect.size.width = self.view.frame.size.width - rect.origin.x * 2;
	} else {
		rect.size.width = self.view.frame.size.width - rect.origin.x * 2 - fWeightWidth;
	}

	// E3.group
	rect.origin.y = 5;
	rect.size.height = 18;
	MbuGroup.frame = rect;
	
	// UIPickerView
	rect.origin.y = self.view.frame.size.height - fPickerHeight;
	rect.size.height = fPickerHeight;
	MpvGroup.frame = rect;
	
	// E3.name
	rect.origin.y = 25;
	rect.size.height = 24;
	MtfName.frame = rect;
	
	//-------------------------------------------------------------------------
	// E3.note
	rect.origin.x = 15;
	if (bPortrait) {
		rect.origin.y = 80;
		rect.size.width = self.view.frame.size.width - rect.origin.x * 2;
	} else {
		rect.origin.y = 55;
		rect.size.width = self.view.frame.size.width - rect.origin.x * 2 - fWeightWidth;
	}
	if (MbKeyboardShow) {
		MtvNote.frame = rect; // 幅変更のみ
		[self tvNoteNarrow];  // 高さ変更：Noteフィールドを狭くして、キーボードに隠れなくする
	} else {
		// キーボードがないとき、最大表示する
		rect.size.height = self.view.frame.size.height - rect.origin.y - 5;
		MtvNote.frame = rect;
	}
	
	//-------------------------------------------------------------------------
	// E3.stock
	if (bPortrait) { // タテ
		rect.origin.x = 10;
		rect.origin.y = 52;
	} else {  // ヨコ
		rect.origin.x = self.view.frame.size.width - fWeightWidth + 10;
		rect.origin.y = 10;
	}
	rect.size.width = fWeightWidth - 40;
	rect.size.height = 24;
	MtfStock.frame = rect;

/*	if (bPortrait) { // タテ
		rect.origin.x += (rect.size.width + 2);
		rect.origin.y += 2;
		rect.size.width = 30;
		rect.size.height = 24;

		label = [[UILabel alloc] initWithFrame:rect];
		label.backgroundColor = [UIColor clearColor];  //背景のアルファ値を0.0にする
		label.font = [UIFont systemFontOfSize:18];
		label.text = @"／";
		[self.view addSubview:label]; // 現在の画面にUILabelを追加
		[label release];
	}*/

	//-------------------------------------------------------------------------
	// E3.need
	if (bPortrait) { // タテ
		rect.origin.x = 111;
		rect.origin.y = 52;
	} else {  // ヨコ
		rect.origin.x = self.view.frame.size.width - fWeightWidth + 10;
		rect.origin.y = 40;
	}
	rect.size.width = fWeightWidth - 40;
	rect.size.height = 24;
	MtfRequired.frame = rect;
	
/*	rect.origin.x += (rect.size.width + 2);
	rect.origin.y += 6;
	rect.size.width = 30;
	rect.size.height = 15;
	{
		label = [[UILabel alloc] initWithFrame:rect];
		label.backgroundColor = [UIColor clearColor];  //背景のアルファ値を0.0にする
		label.font = [UIFont systemFontOfSize:12];  //フォントサイズ
		label.text = NSLocalizedString(@"Qty", @"個");
		[self.view addSubview:label]; // 現在の画面にUILabelを追加
		[label release];
	}*/		
	
	//-------------------------------------------------------------------------
	// E3.weight
	if (bPortrait) { // タテ
		rect.origin.x = 210;
		rect.origin.y = 52;
	} else {  // ヨコ
		rect.origin.x = self.view.frame.size.width - fWeightWidth + 10;
		rect.origin.y = 70;
	}
	rect.size.width = fWeightWidth - 40;
	rect.size.height = 24;
	MtfWeight.frame = rect;

/*	rect.origin.x += (rect.size.width + 2);
	rect.origin.y += 6;
	rect.size.width = 20;
	rect.size.height = 15;
	{
		label = [[UILabel alloc] initWithFrame:rect];
		label.text = @"g";
		label.backgroundColor = [UIColor clearColor];  //背景のアルファ値を0.0にする
		label.font = [UIFont systemFontOfSize:12];  //フォントサイズ
		[self.view addSubview:label]; // 現在の画面にUILabelを追加
		[label release];
	}*/
}

//----------------------------------------------------------UITextView DELEGATE
- (void)tvNoteNarrow // Noteフィールドをキーボードに隠れなくする
{
	MbKeyboardShow = YES; // キー出現
	// 編集状態になりキーボードが現れたら最小化する
	float fKeyHeight;
	if (self.interfaceOrientation == UIInterfaceOrientationPortrait 
		OR self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
		fKeyHeight = GD_KeyboardHeightPortrait;	 // タテ
	} else {
		fKeyHeight = GD_KeyboardHeightLandscape; // ヨコ
	}
	CGRect rect = MtvNote.frame;
	rect.size.height = self.view.frame.size.height - rect.origin.y - 5 - fKeyHeight;
	MtvNote.frame = rect;
}

- (void)textViewDidBeginEditing : (UITextView *)textView
{
	[self tvNoteNarrow]; // Noteフィールドをキーボードに隠れなくする
}

//----------------------------------------------------------UITextField DELEGATE
//テキストフィールドの編集開始のイベント処理
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField 
{
	[self tvNoteNarrow]; // Noteフィールドをキーボードに隠れなくする
	return YES;
}

//テキストフィールドの文字変更のイベント処理
// UITextFieldオブジェクトから1文字入力の都度呼び出されることにより入力文字数制限を行っている。
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSMutableString *text = [[textField.text mutableCopy] autorelease];
    [text replaceCharactersInRange:range withString:string];
	
	if( textField == MtfWeight ) return [text length] <= 5; // 最大文字数
	else
		if( textField == MtfStock  ) return [text length] <= 3; // 最大文字数
		else
			if( textField == MtfRequired ) return [text length] <= 3; // 最大文字数
			else
				return YES;  //[text length] <= 30; // 最大文字数
}

//テキストフィールドのクリア時のイベント処理
//- (BOOL)textFieldShouldClear:(UITextField *)textField {

//テキストフィールドリターン時のイベント処理
- (BOOL)textFieldShouldReturn:(UITextField *)sender {
    // if (sender.tag==1) [sender resignFirstResponder];        //キーボードを閉じる
	// if( [sender canResignFirstResponder] ) [sender resignFirstResponder];    //キーボードを閉じる

	if( sender == MtfName ) [MtfSpec becomeFirstResponder];
	else 
		if( sender == MtfSpec ) [MtfStock becomeFirstResponder];
		else 
			if( sender == MtfStock ) [MtfRequired becomeFirstResponder];
			else 
				if( sender == MtfRequired ) [MtfWeight becomeFirstResponder];
				else 
					if( sender == MtfWeight ) [MtvNote becomeFirstResponder];
						// tvNoteは、改行が必要なので、次送りしない。
    return YES;
}


#pragma mark pickerView

//----------------------------------------------------------------------------------------------UIPickerView DELEGATE
// PICKER ホイールの列数
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// PICKER ホイールの行数
- (NSInteger)pickerView: (UIPickerView *)pView numberOfRowsInComponent:(NSInteger)component
{
	return [Pe2array count]; // E2ノード数
}

// PICKER 
- (NSString *)pickerView: (UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	// E2 Node Object
	E2 *e2obj = [Pe2array objectAtIndex:row];
	return e2obj.name;
}

// PICKER ユーザ選択への応答
- (void)pickerView: (UIPickerView *)aPickerView didSelectRow:(NSInteger)selectRow inComponent:(NSInteger)component
{
	// ここではbuGroupの表示更新のみし、e3obj更新はsaveにて実行
	E2 *e2obj = [Pe2array objectAtIndex:selectRow];
	[MbuGroup setTitle:e2obj.name forState:UIControlStateNormal];

	// フォーカスをNameに移して、PICKERをキーボードの下に隠す
	// [tfName becomeFirstResponder]; すぐに隠さないようにした。 
}

//----------------------------------------------------------------------------------------------UIButton DELEGATE
- (void)selectGroup:(UIButton *)button
{
	[self tvNoteNarrow]; // Noteフィールドをキーボードに隠れなくする
	// GROUP PICKER を表示する
	MpvGroup.hidden = NO;
	// 上にあるキーボードを消すために全てのコントロールへresignFirstResponderを送る
	[MtfName resignFirstResponder];
	[MtfWeight resignFirstResponder];
	[MtfStock resignFirstResponder];
	[MtfRequired resignFirstResponder];
	[MtvNote resignFirstResponder];
}

- (void)cancel:(id)sender {
	if (PbAddObj) {
		// 新オブジェクトのキャンセルなので、呼び出し元で挿入したオブジェクトを削除する
		[Pe3target.managedObjectContext deleteObject:Pe3target];
		// SAVE
		NSError *err = nil;
		if (![Pe3target.managedObjectContext save:&err]) {
			NSLog(@"Unresolved error %@, %@", err, [err userInfo]);
			abort();
		}
	}
//	[self.navigationController dismissModalViewControllerAnimated:MbAnimation];
	[self.navigationController popViewControllerAnimated:YES];	// < 前のViewへ戻る
}

// 編集フィールドの値を e3obj にセットする
- (void)save:(id)sender {
	// e3edit,e2list は ManagedObject だから更新すれば ManagedObjectContext に反映される
	// PICKER 指定したコンポーネントで選択された行のインデックスを返す。
	NSInteger oldSection = [Pe2selected.row intValue];
	NSInteger newSection = [MpvGroup selectedRowInComponent:0];

	if (0 <= newSection && oldSection != newSection) { 
		// E2セクション(Group)の変更あり  self.e3section ==>> newSection
		NSInteger oldRow = [Pe3target.row intValue];	// 元ノードのrow　最後のrow更新処理で、ie3nodeRow以降を更新する。
		NSInteger newRow = [[Pe3array objectAtIndex:newSection] count];  // セクション末尾

		//--------------------------------------------------(1)MutableArrayの移動
		[[Pe3array objectAtIndex:oldSection] removeObjectAtIndex:oldRow];
		[[Pe3array objectAtIndex:newSection] insertObject:Pe3target atIndex:newRow];
		
		// 異セクション間の移動　＜＜親(.e2selected)の変更が必要＞＞
		// 移動元セクション（親）から子を削除する
		[[Pe2array objectAtIndex:oldSection] removeChildsObject:Pe3target];	// 元の親ノードにある子登録を抹消する
		// 異動先セクション（親）へ子を追加する
		[[Pe2array objectAtIndex:newSection] addChildsObject:Pe3target];	// 新しい親ノードに子登録する
		// 異セクション間での移動： 双方のセクションで変化あったrow以降、全て更新するしかないだろう
		// 元のrow付け替え処理
		NSInteger i;
		E3 *e3obj;
		for (i = oldRow ; i < [[Pe3array objectAtIndex:oldSection] count] ; i++) {
			e3obj = [[Pe3array objectAtIndex:oldSection] objectAtIndex:i];
			e3obj.row = [NSNumber numberWithInteger:i];
		}
		// 先のrow付け替え処理
		Pe3target.row = [NSNumber numberWithInteger:newRow];  // 最終行の次に追加
	}
	
	if( 30 < [MtfName.text length] ){
		// 長さが30超ならば、0文字目から30文字を切り出して保存　＜以下で切り出すとフリーズする＞
		[Pe3target setValue:[MtfName.text substringWithRange:NSMakeRange(0, 30)] forKey:@"name"];
	} else {
		[Pe3target setValue:MtfName.text forKey:@"name"];
	}

	if( 30 < [MtfSpec.text length] ){
		// 長さが30超ならば、0文字目から30文字を切り出して保存　＜以下で切り出すとフリーズする＞
		[Pe3target setValue:[MtfSpec.text substringWithRange:NSMakeRange(0, 30)] forKey:@"spec"];
	} else {
		[Pe3target setValue:MtfSpec.text forKey:@"spec"];
	}

	if( 200 < [MtvNote.text length] ){
		// 長さが200超ならば、0文字目から200文字を切り出して保存　＜以下で切り出すとフリーズする＞
		[Pe3target setValue:[MtvNote.text substringWithRange:NSMakeRange(0, 200)] forKey:@"note"];
	} else {
		[Pe3target setValue:MtvNote.text forKey:@"note"];
	}
	
	long lWeight = [MtfWeight.text intValue];
	long lStock = [MtfStock.text intValue];
	long lRequired = [MtfRequired.text intValue];
	[Pe3target setValue:[NSNumber numberWithLong:lWeight] forKey:@"weight"];  // 最小値が0でないとエラー発生
	[Pe3target setValue:[NSNumber numberWithLong:lStock] forKey:@"stock"];
	[Pe3target setValue:[NSNumber numberWithLong:lRequired] forKey:@"need"];
	[Pe3target setValue:[NSNumber numberWithLong:(lWeight*lStock)] forKey:@"weightStk"];
	[Pe3target setValue:[NSNumber numberWithLong:(lWeight*lRequired)] forKey:@"weightReq"];
	[Pe3target setValue:[NSNumber numberWithLong:(lRequired-lStock)] forKey:@"lack"]; // 不足数
	[Pe3target setValue:[NSNumber numberWithLong:((lRequired-lStock)*lWeight)] forKey:@"weightLack"]; // 不足重量
	
	NSInteger iNoGray = 0;
	if (0 < lRequired) iNoGray = 1;
	[Pe3target setValue:[NSNumber numberWithInteger:iNoGray] forKey:@"noGray"]; // NoGray:有効(0<必要数)アイテム

	NSInteger iNoCheck = 0;
	if (0 < lRequired && lStock < lRequired) iNoCheck = 1;
	[Pe3target setValue:[NSNumber numberWithInteger:iNoCheck] forKey:@"noCheck"]; // NoCheck:不足アイテム
	
	if (PbAddObj) {
		// 新規のとき、末尾になるように行番号を付与する
		NSInteger rows = [[Pe3array objectAtIndex:newSection] count]; // 追加するセクションの現在行数
		[Pe3target setValue:[NSNumber numberWithInteger:rows] forKey:@"row"];
		// 親(E2)のchilesにe3editを追加する
		[[Pe2array objectAtIndex:newSection] addChildsObject:Pe3target];
	}

	// E2 sum属性　＜高速化＞ 親sum保持させる
	[Pe2selected setValue:[Pe2selected valueForKeyPath:@"childs.@sum.noGray"] forKey:@"sumNoGray"];
	[Pe2selected setValue:[Pe2selected valueForKeyPath:@"childs.@sum.noCheck"] forKey:@"sumNoCheck"];
	[Pe2selected setValue:[Pe2selected valueForKeyPath:@"childs.@sum.weightStk"] forKey:@"sumWeightStk"];
	[Pe2selected setValue:[Pe2selected valueForKeyPath:@"childs.@sum.weightReq"] forKey:@"sumWeightNed"];

	// E1 sum属性　＜高速化＞ 親sum保持させる
	[Pe1selected setValue:[Pe1selected valueForKeyPath:@"childs.@sum.sumNoGray"] forKey:@"sumNoGray"];
	[Pe1selected setValue:[Pe1selected valueForKeyPath:@"childs.@sum.sumNoCheck"] forKey:@"sumNoCheck"];
	[Pe1selected setValue:[Pe1selected valueForKeyPath:@"childs.@sum.sumWeightStk"] forKey:@"sumWeightStk"];
	[Pe1selected setValue:[Pe1selected valueForKeyPath:@"childs.@sum.sumWeightNed"] forKey:@"sumWeightNed"];
	
	// SAVE : e3edit,e2list は ManagedObject だから更新すれば ManagedObjectContext に反映されている
	NSError *err = nil;
	if (![Pe3target.managedObjectContext save:&err]) {
		NSLog(@"Unresolved error %@, %@", err, [err userInfo]);
		abort();
	}

//	[self.navigationController dismissModalViewControllerAnimated:MbAnimation];
	[self.navigationController popViewControllerAnimated:YES];	// < 前のViewへ戻る
}

- (void)didReceiveMemoryWarning {
#ifdef AzDEBUG
	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"didReceiveMemoryWarning" 
													 message:@"E3edit" 
													delegate:nil 
										   cancelButtonTitle:nil 
										   otherButtonTitles:@"OK", nil] autorelease];
	[alert show];
#endif
    [super didReceiveMemoryWarning];
}

@end
