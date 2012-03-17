//
//  CameraVC.m
//  AzPackList5
//
//  Created by Sum Positive on 12/02/09.
//  Copyright (c) 2012 Azukid. All rights reserved.
//

#import "Global.h"
#import "AppDelegate.h"
#import "Elements.h"
#import "CameraVC.h"
#import <AVFoundation/AVFoundation.h>	//Camera
#import "GoogleService.h"



@interface CameraVC (PrivateMethods)
- (void)cameraReset;
- (void)rotateToOrientation:(UIInterfaceOrientation)orientation;
@end

@implementation CameraVC
{
	AppDelegate		*appDelegate_;

	UIBarButtonItem		*buRedo_;
	UIBarButtonItem		*buCamera_;
	UIBarButtonItem		*buTorch_;
	UIBarButtonItem		*buDone_;
	
	// CAPTURE: Front Camera
	AVCaptureDevice		*captureDevice_;
	AVCaptureSession		*captureSession_;
	AVCaptureStillImageOutput *captureOutput_;
	AVCaptureVideoPreviewLayer *previewLayer_;
	NSData						*captureData_;
	//UIPopoverController	*popRecordView;
	//AZPicasa						*picasa_;
	//float					mVolume;
}
@synthesize e3target = e3target_;
@synthesize imageView = imageView_;


#pragma mark - Camera

- (void)cameraPreview
{
	if (!captureDevice_) {
		return; // カメラなし
	}

	captureSession_ = [[AVCaptureSession alloc] init];
	if (!captureSession_) {
		NSLog(@"ERROR: !captureSession -- No Camera");
		return;
	}
	
	NSError *error = nil;
	// INPUT
	AVCaptureDeviceInput *camInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice_ error:&error];
	if (!camInput) {
		NSLog(@"ERROR: !camInput -- No Camera");
		return;
	}
	[captureSession_ addInput: camInput]; //[camInput release];
	
	// OUTPUT
	captureOutput_ = [[AVCaptureStillImageOutput alloc] init];
	[captureSession_ addOutput: captureOutput_]; 	//[camOutput release];
	
	// セッション初期化
	[captureSession_ beginConfiguration];
	captureSession_.sessionPreset = AVCaptureSessionPreset640x480;
	[captureSession_ commitConfiguration];
	
	// カメラ設定
	if ([captureDevice_ lockForConfiguration:&error]) {
		// オートフォーカス
		if ([captureDevice_ isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
			captureDevice_.focusMode = AVCaptureFocusModeContinuousAutoFocus;
		}	
		else if ([captureDevice_ isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
			captureDevice_.focusMode = AVCaptureFocusModeAutoFocus;
		}
		// 露出制御自動
		if ([captureDevice_ isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
			captureDevice_.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
		}	
		// ホワイトバランス自動
		if ([captureDevice_ isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
			captureDevice_.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
		}	
		// フラッシュ自動
		if ([captureDevice_ isFlashModeSupported:AVCaptureFlashModeAuto]) {
			captureDevice_.flashMode = AVCaptureFlashModeAuto;
		}	
		// トーチＯＦＦ
		if ([captureDevice_ isTorchModeSupported:AVCaptureTorchModeOff]) {
			captureDevice_.torchMode = AVCaptureTorchModeOff;
		}	
		// 完了 ロック解除
		[captureDevice_ unlockForConfiguration];
	}

	// プレビュー
	previewLayer_ = [AVCaptureVideoPreviewLayer layerWithSession: captureSession_];
	previewLayer_.frame = ibImageView.frame;
	previewLayer_.videoGravity = AVLayerVideoGravityResizeAspectFill;
	previewLayer_.automaticallyAdjustsMirroring = NO;
	//[self.view.layer insertSublayer: previewLayer_ atIndex: 0];
	[self.view.layer  addSublayer: previewLayer_];
	
	[self cameraReset];
}

- (void)cameraReset
{
	// OFF
	ibImageView.hidden = YES;
	buRedo_.enabled = NO;
	buDone_.enabled = NO;

	// 回転対応
	UIInterfaceOrientation interOri;
	if (appDelegate_.app_is_iPad) {
		interOri = appDelegate_.mainSVC.interfaceOrientation;    //parentViewController.interfaceOrientation;
	} else {
		//interOri = appDelegate_.mainNC.visibleViewController.interfaceOrientation;
		interOri = self.interfaceOrientation;
	}
	[self rotateToOrientation:interOri];

	// ON
	previewLayer_.hidden = NO;
	buCamera_.enabled = YES;
	[buTorch_ setEnabled:YES]; //buTorch_=nil の場合があるため
	[captureSession_ startRunning];

	ibLbCamera.text = NSLocalizedString(@"Camera msg1",nil);
}

- (void)cameraTake
{
	if (!captureDevice_) {
		return; // カメラなし
	}
	if (!captureOutput_ OR !captureSession_) return;
	
	// 撮影開始
	AVCaptureConnection *connection = [captureOutput_.connections lastObject];
	[captureOutput_ captureStillImageAsynchronouslyFromConnection: connection
												completionHandler: ^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {

												   captureData_ = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation: imageDataSampleBuffer];
												   
													//  アルバム「カメラロール」へ保存しない
												   
													// 静止画表示する
													[captureSession_ stopRunning];
													ibImageView.image = [UIImage imageWithData: captureData_];
													[self rotateToOrientation:self.interfaceOrientation]; //回転位置
													// OFF
													previewLayer_.hidden = YES;
													buCamera_.enabled = NO;
													[buTorch_ setEnabled:NO]; //buTorch_=nil の場合があるため
													[captureSession_ startRunning];
													// ON
													ibImageView.hidden = NO;
													buRedo_.enabled = YES;
													buDone_.enabled = YES;
													ibLbCamera.text = NSLocalizedString(@"Camera msg2",nil);
													
													if (appDelegate_.app_is_iPad) {	//Popover外タッチで閉じないようにするため。
														appDelegate_.app_UpdateSave = YES; // 変更あり
													}
											   } 
	 ];
}


#pragma mark - Action

- (void)actionCamera:(UIButton *)button
{
	/*// 音量を保持して0にする
	AVAudioPlayer *audio = [[AVAudioPlayer alloc] initWithContentsOfURL:nil error:nil];
	[audio setVolume:0.1];*/
	
	if (buCamera_.enabled) {
		buCamera_.enabled = NO;
		[buTorch_ setEnabled:NO]; //buTorch_=nil の場合があるため
		[self cameraTake];	// カメラ撮影  ＜＜この中で saveClose を呼び出している
	}
}

- (void)actionRedo:(UIButton *)button
{
	[self cameraReset];
}

- (void)actionTorch:(UIButton *)button
{
	NSError *error = nil;
	// カメラ設定
	if ([captureDevice_ lockForConfiguration:&error]) {
		// トーチ
		if (buTorch_.tag != 0) {	// ON-->OFF
			buTorch_.tag = 0; //OFF
			if ([captureDevice_ isTorchModeSupported:AVCaptureTorchModeOff]) {
				captureDevice_.torchMode = AVCaptureTorchModeOff;
			}	
		} else {		// OFF-->ON
			buTorch_.tag = 1; //ON
			if ([captureDevice_ isTorchModeSupported:AVCaptureTorchModeOn]) {
				captureDevice_.torchMode = AVCaptureTorchModeOn;
			}	
		}
		// 完了 ロック解除
		[captureDevice_ unlockForConfiguration];
	}
}

//- (void)doneClose:(UIButton*)button
- (void)actionDone:(UIButton*)button
{
	// E3detailTVCへ表示する
	if (imageView_) {
		imageView_.image = ibImageView.image;
	}

	// PicasaID をセットする
	if (e3target_) {
		appDelegate_.app_UpdateSave = YES; // 変更あり
		// Mocへキャッシュ保存
		E4photo *e4 = e3target_.e4photo;
		if (!e4) {
			e4 = (E4photo *)[NSEntityDescription insertNewObjectForEntityForName:@"E4photo"
														  inManagedObjectContext:e3target_.managedObjectContext];
			e3target_.e4photo = e4; //LINK
		}
		e4.photoData = [NSData dataWithData:captureData_];
		e3target_.photoUrl = [NSString stringWithFormat:GS_PHOTO_UUID_PREFIX @"%@", uuidString()];
		//Moc[保存]時にする// [picasa_ uploadData:e3target_.photoData photoTitle:e3target_.name];
		//E3detailTVC:にてアップ状況をアイコン表示。 未アップならば自動的にアップリトライする ＜＜失敗やオフラインに対応するため
	}
	
	[self.navigationController popViewControllerAnimated:YES];	// < 前のViewへ戻る
}


#pragma mark - View lifecicle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		appDelegate_ = (AppDelegate *)[[UIApplication sharedApplication] delegate];

		if (appDelegate_.app_is_iPad) {
			/*if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
				self.contentSizeForViewInPopover = CGSizeMake(480, 640);  //GD_POPOVER_SIZE;
			} else {
				self.contentSizeForViewInPopover = CGSizeMake(640, 480);
			}*/
			self.contentSizeForViewInPopover = GD_POPOVER_SIZE_Camera;
		}
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

	// Picasaへアップロード
	//if (picasa_==nil) {
	//	picasa_ = [[AZPicasa alloc] init];
	//}

	// フロントカメラを取得する	=nil:カメラなし
	NSArray	*camArry = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	for (AVCaptureDevice *cam in camArry) {
		if (cam.position == AVCaptureDevicePositionBack) { // 背面カメラ
			captureDevice_ = cam;
		}
	}
	if (captureDevice_==nil) {
		alertBox(NSLocalizedString(@"Camera Non",nil), nil, @"OK");
		[self.navigationController popViewControllerAnimated:YES];	// < 前のViewへ戻る
	}
	
    buDone_ = [[UIBarButtonItem alloc]
			   initWithBarButtonSystemItem:UIBarButtonSystemItemDone
			   target:self
			   action:@selector(actionDone:)];
	
    buCamera_ = [[UIBarButtonItem alloc]
							  initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
							  target:self
							  action:@selector(actionCamera:)];

	buRedo_ = [[UIBarButtonItem alloc]
			   initWithBarButtonSystemItem:UIBarButtonSystemItemRedo
			   target:self
			   action:@selector(actionRedo:)];

	if ([captureDevice_ hasTorch]) {	// Torch装備あり
		buTorch_ = [[UIBarButtonItem alloc]
					initWithTitle:NSLocalizedString(@"Camera Torch",nil)
					style:UIBarButtonItemStyleBordered
					target:self action:@selector(actionTorch:)];
		buTorch_.tag = 0; //消灯
	} else {
		buTorch_ = nil;
	}
	self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects: buDone_, buCamera_, buRedo_, buTorch_, nil];	
	
	ibImageView.contentMode = UIViewContentModeScaleAspectFit;

	// 1指タップ
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionCamera:)];
	tap.numberOfTouchesRequired =1; // 指数
	tap.numberOfTapsRequired = 1; // タップ数
	[self.view addGestureRecognizer:tap];
	
	// 音量を保持して0にする
	/*AVAudioPlayer *audio = [[AVAudioPlayer alloc] initWithContentsOfURL:nil error:nil];
	mVolume = audio.volume;
	[audio setVolume:0.1];*/
	
/*	// these 4 lines of code tell the system that "this app needs to play sound/music"
	AVAudioPlayer* p = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"photo-shutter.wav"]] error:NULL];
	[p prepareToPlay];
	[p stop];
	
	// 音量ボタンでシャッターを切る
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(actionCamera:)
												 name: @"AVSystemController_SystemVolumeDidChangeNotification" object:nil]; 
 */
	if (appDelegate_.app_is_iPad) {
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(notification_ToInterfaceOrientation:)
													 name: NFM_ToInterfaceOrientation object:nil]; 
	}
}

- (void)notification_ToInterfaceOrientation:(NSNotification*)note 
{
	NSDictionary *info = [note userInfo];
	UIInterfaceOrientation ori = [[info valueForKey:NFM_ToInterfaceOrientation] integerValue];
	[self rotateToOrientation:ori];
}

//Viewが表示された直後に実行される
- (void)viewDidAppear:(BOOL)animated 
{
	[super viewDidAppear:animated];

	[self cameraPreview];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{	// Return YES for supported orientations
	if (appDelegate_.app_is_iPad) {
		return YES;	// Popover窓内対応
	} else {
		// 回転禁止の場合、万一ヨコからはじまった場合、タテにはなるようにしてある。
		return appDelegate_.app_opt_Autorotate OR (interfaceOrientation == UIInterfaceOrientationPortrait);
	}
}

- (void)rotateToOrientation:(UIInterfaceOrientation)orientation
{
	for (AVCaptureConnection *connection in captureOutput_.connections) {
		if (connection.supportsVideoOrientation) {
			switch (orientation) {
				case UIInterfaceOrientationPortrait:
					connection.videoOrientation = AVCaptureVideoOrientationPortrait;
					break;
				case UIInterfaceOrientationPortraitUpsideDown:
					connection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
					break;
				case UIInterfaceOrientationLandscapeLeft:
					connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
					break;
				case UIInterfaceOrientationLandscapeRight:
					connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
					break;
			}
		}
	}

	// VGA: 640x480
	CGFloat fL = 640 / 2;		// Land 長辺
	CGFloat fS = 480 / 2;		// Short 短辺
	CGRect rect;
	if (appDelegate_.app_is_iPad) {
		fL = self.view.bounds.size.width - 10;
		fS = fL * 480/640;
	}
	// ファインダーをカメラの縦横に合わせる
	ibLbCamera.hidden = NO;
	switch (orientation) {
		case UIInterfaceOrientationPortrait:
			previewLayer_.orientation = AVCaptureVideoOrientationPortrait;
			rect = CGRectMake((self.view.bounds.size.width-fS)/2, (self.view.bounds.size.height-fL)/2, fS, fL);	// Portrait
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			previewLayer_.orientation = AVCaptureVideoOrientationPortraitUpsideDown;
			rect = CGRectMake((self.view.bounds.size.width-fS)/2, (self.view.bounds.size.height-fL)/2, fS, fL);	// Portrait
			break;
		case UIInterfaceOrientationLandscapeLeft:
			previewLayer_.orientation = AVCaptureVideoOrientationLandscapeLeft;
			rect = CGRectMake((self.view.bounds.size.width-fL)/2, (self.view.bounds.size.height-fS)/2, fL, fS);	// Landscape
			if (appDelegate_.app_is_iPad==NO) {
				ibLbCamera.hidden = YES;
			}
			break;
		case UIInterfaceOrientationLandscapeRight:
			previewLayer_.orientation = AVCaptureVideoOrientationLandscapeRight;
			rect = CGRectMake((self.view.bounds.size.width-fL)/2, (self.view.bounds.size.height-fS)/2, fL, fS);	// Landscape
			if (appDelegate_.app_is_iPad==NO) {
				ibLbCamera.hidden = YES;
			}
			break;
		default:
			return;
	}
	DEBUG_LOG_RECT(rect, @"previewLayer_.frame");
	previewLayer_.frame = rect;

	// 撮影イメージを写真の縦横に合わせる
	if (UIInterfaceOrientationIsPortrait(orientation)) {	// デバイス縦
		if (ibImageView.image.size.width < 600) {	// 写真タテ
			rect = CGRectMake((self.view.bounds.size.width-fS)/2, (self.view.bounds.size.height-fL)/2, fS, fL);	// Portrait
		} else {		// 写真ヨコ
			if (self.view.bounds.size.width <= fL) {
				fL = self.view.bounds.size.width - 10;
				fS = fL * 480/640;
			}
			rect = CGRectMake((self.view.bounds.size.width-fL)/2, (self.view.bounds.size.height-fS)/2, fL, fS);	// Landscape
		}
	}
	else {		// デバイス横
		if (ibImageView.image.size.width < 600) {	// 写真タテ
			if (self.view.bounds.size.height <= fL) {
				fL = self.view.bounds.size.height - 4;
				fS = fL * 480/640;
			}
			rect = CGRectMake((self.view.bounds.size.width-fS)/2, (self.view.bounds.size.height-fL)/2, fS, fL);	// Portrait
		} else {		// 写真ヨコ
			rect = CGRectMake((self.view.bounds.size.width-fL)/2, (self.view.bounds.size.height-fS)/2, fL, fS);	// Landscape
		}
	}
	DEBUG_LOG_RECT(rect, @"ibImageView.frame");
	ibImageView.frame = rect;		//UIViewContentModeScaleAspectFit である。
	//ibImageView.backgroundColor = [UIColor grayColor];
	DEBUG_LOG_RECT(rect, @"ibImageView.frame");
	DEBUG_LOG_RECT(self.view.bounds, @"self.view.bounds");
}

/*
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{	// 回転を始める前にこの処理が呼ばれる。 ＜＜OS 3.0以降の推奨メソッド＞＞
	// この時点で self.view.frame はまだ回転していない。
	//NG//[self rotateToOrientation:toInterfaceOrientation];
}*/

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration 
{	// 回転を始める前にこの処理が呼ばれる。 ＜＜OS 3.0以降の推奨メソッド＞＞
	[self rotateToOrientation:toInterfaceOrientation];
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
	
/*	// 音量を復元する
	AVAudioPlayer *audio = [[AVAudioPlayer alloc] initWithContentsOfURL:nil error:nil];
	[audio setVolume:mVolume];*/

	[captureSession_ stopRunning];
	captureSession_ = nil;
	captureOutput_ = nil;
}


@end
