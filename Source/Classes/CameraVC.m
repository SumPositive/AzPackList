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
	captureSession_.sessionPreset = AVCaptureSessionPresetLow; //Low: (4)640x480  (3G)400x304
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
	
	// 回転対応
	UIInterfaceOrientation interOri;
	if (appDelegate_.app_is_iPad) {
		interOri = appDelegate_.mainSVC.parentViewController.interfaceOrientation;
	} else {
		//interOri = appDelegate_.mainNC.visibleViewController.interfaceOrientation;
		interOri = self.interfaceOrientation;
	}
	[self rotateToOrientation:interOri];

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
											   } 
	 ];
}


#pragma mark - Action

- (void)actionCamera:(UIButton *)button
{
	// 音量を保持して0にする
	AVAudioPlayer *audio = [[AVAudioPlayer alloc] initWithContentsOfURL:nil error:nil];
	[audio setVolume:0.1];
	
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
		e3target_.photoData = [NSData dataWithData:captureData_];
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
			self.contentSizeForViewInPopover = GD_POPOVER_SIZE;
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
}

//Viewが表示された直後に実行される
- (void)viewDidAppear:(BOOL)animated 
{
	[super viewDidAppear:animated];

#ifdef DEBUG
	NSString *modelname = [ [ UIDevice currentDevice] model];
	if([modelname isEqualToString:@"iPhone Simulator"])
	{	//iPhone and iPad Simulator
		if (imageView_) {
			imageView_.image = [UIImage imageNamed:@"Icon32-Amazon"];
		}
		
		if (e3target_) {
			appDelegate_.app_UpdateSave = YES; // 変更あり
			// Mocへキャッシュ保存
			e3target_.photoData = [NSData dataWithData:UIImagePNGRepresentation(imageView_.image)];
			e3target_.photoUrl = [NSString stringWithFormat:PHOTO_URL_UUID_PRIFIX @"%@", uuidString()];
		}
	} else {
		[self cameraPreview];
	}
#else
	[self cameraPreview];
#endif
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{	// Return YES for supported orientations
	//return (interfaceOrientation == UIInterfaceOrientationPortrait);
    return YES;
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

	CGFloat fh;
	CGFloat fw;
	CGRect rect;
	// ファインダーをカメラの縦横に合わせる
	switch (orientation) {
		case UIInterfaceOrientationPortrait:
			previewLayer_.orientation = AVCaptureVideoOrientationPortrait;
			fh = 390;
			fw = fh * 480/640;
			rect = CGRectMake((320-fw)/2, 5, fw, fh);
			ibLbCamera.hidden = NO;
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			previewLayer_.orientation = AVCaptureVideoOrientationPortraitUpsideDown;
			fh = 390;
			fw = fh * 480/640;
			rect = CGRectMake((320-fw)/2, 5, fw, fh);
			ibLbCamera.hidden = NO;
			break;
		case UIInterfaceOrientationLandscapeLeft:
			previewLayer_.orientation = AVCaptureVideoOrientationLandscapeLeft;
			fh = 260;
			fw = fh * 640/480;
			rect = CGRectMake((480-fw)/2, 3, fw, fh);
			ibLbCamera.hidden = YES;
			break;
		case UIInterfaceOrientationLandscapeRight:
			previewLayer_.orientation = AVCaptureVideoOrientationLandscapeRight;
			fh = 260;
			fw = fh * 640/480;
			rect = CGRectMake((480-fw)/2, 3, fw, fh);
			ibLbCamera.hidden = YES;
			break;
	}
	if (appDelegate_.app_is_iPad) {
		rect.size.width *= 1.5;
		rect.size.height *= 1.5;
	}
	DEBUG_LOG_RECT(rect, @"previewLayer_.frame");
	previewLayer_.frame = rect;

/*	// 撮影イメージを写真の縦横に合わせる
	if (UIInterfaceOrientationIsPortrait(orientation)) {	// デバイス縦
		if (ibImageView.image.size.width < 600) {	// 写真タテ
			fh = 390;
			fw = fh * 480/640;
			rect = CGRectMake((320-fw)/2, 5, fw, fh);
		} else {		// 写真ヨコ
			fw = 310;
			fh = fw * 480/640;
			rect = CGRectMake(5, (390-fh)/2, fw, fh);
		}
	}
	else {		// デバイス横
		if (ibImageView.image.size.width < 600) {	// 写真タテ
			fh = 255;
			fw = fh * 480/640;
			rect = CGRectMake((480-fw)/2, 3, fw, fh);
		} else {		// 写真ヨコ
			fh = 255;
			fw = fh * 640/480;
			rect = CGRectMake((480-fw)/2, 3, fw, fh);
		}
	}
	if (appDelegate_.app_is_iPad) {
		rect.size.width *= 1.5;
		rect.size.height *= 1.5;
	}
	DEBUG_LOG_RECT(rect, @"ibImageView.frame");
	ibImageView.frame = rect;		//UIViewContentModeScaleAspectFit である。
	//[ibImageView setFrame:rect]; 
 */
	ibImageView.backgroundColor = [UIColor grayColor];
}

// ユーザインタフェースの回転を始める前にこの処理が呼ばれる。 ＜＜OS 3.0以降の推奨メソッド＞＞
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{	// この時点で self.view.frame はまだ回転していない。
	[self rotateToOrientation:orientation];
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
