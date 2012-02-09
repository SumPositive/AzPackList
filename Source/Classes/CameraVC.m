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

@interface CameraVC (PrivateMethods)
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
}
@synthesize e3target = e3target_;
@synthesize imageView = imageView_;


#pragma mark - Camera

- (void)cameraPreview
{
	if (!captureDevice_) {
		return; // カメラなし
	}
	/*if (captureSession) {
		[captureSession release];
	}*/
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
	/*if (captureOutput) {
		[captureOutput release];
	}*/
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
		interOri = appDelegate_.mainSVC.interfaceOrientation;
	} else {
		interOri = appDelegate_.mainNC.interfaceOrientation;
	}
	[self rotateToOrientation:interOri];

	//[self.view.layer insertSublayer: previewLayer atIndex: 0];
	[self.view.layer  addSublayer: previewLayer_];
	
	[captureSession_ startRunning];
	//
	//self.navigationItem.rightBarButtonItem.enabled = NO; //[Done]
	buDone_.enabled = NO;
	ibImageView.hidden = YES;
/*	ibBuRetry.hidden = YES;
	ibBuTake.hidden = NO;
	ibLbTorch.hidden = NO;
	ibSwTorch.hidden = NO;*/

	buRedo_.enabled = NO;
	buCamera_.enabled = YES;
	[buTorch_ setEnabled:YES]; //buTorch_=nil の場合があるため
	buDone_.enabled = NO;
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
													ibImageView.hidden = NO;
													//
													//self.navigationItem.rightBarButtonItem.enabled = YES; //[Done]
													//ibBuRetry.hidden = NO;
													buRedo_.enabled = YES;
													buCamera_.enabled = NO;
													[buTorch_ setEnabled:NO]; //buTorch_=nil の場合があるため
													buDone_.enabled = YES;
											   } 
	 ];
}


#pragma mark - Action

- (void)actionCamera:(UIButton *)button
{
	buCamera_.enabled = NO;
	[buTorch_ setEnabled:NO]; //buTorch_=nil の場合があるため
	[self cameraTake];	// カメラ撮影  ＜＜この中で saveClose を呼び出している
}

- (void)actionRedo:(UIButton *)button
{
	buRedo_.enabled = NO;
	buDone_.enabled = NO;
	ibImageView.hidden = YES;
	ibImageView.image = nil;
	// Start
	[captureSession_ startRunning];
	buCamera_.enabled = YES;
	[buTorch_ setEnabled:YES]; //buTorch_=nil の場合があるため
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
		e3target_.photoUrl = nil; // PicasaID
		dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
		dispatch_async(queue, ^{		// 非同期マルチスレッド処理
			e3target_.photoData = [NSData dataWithData:captureData_];
		});
		
		/*							// Picasa Upload
		 dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		 dispatch_async(queue, ^{		// 非同期マルチスレッド処理
		 
		 //NSString *err = [self vSharePlanAppend];
		 
		 dispatch_async(dispatch_get_main_queue(), ^{	// 終了後の処理
		 e3target_.photoUrl = nil; // PicasaID
		 });
		 }); */
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

/*	//self.title = NSLocalizedString(@"Photo", nil);
	// [Done] ボタンを右側に追加する
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] 
											  initWithBarButtonSystemItem:UIBarButtonSystemItemDone
											  target:self action:@selector(doneClose:)];
	self.navigationItem.rightBarButtonItem.enabled = NO;
	
	[ibBuTake setTitle:NSLocalizedString(@"Camera Take",nil) forState:UIControlStateNormal];
	[ibBuRetry setTitle:NSLocalizedString(@"Camera Retry",nil) forState:UIControlStateNormal];
	ibLbTorch.text = NSLocalizedString(@"Camera Torch",nil);
	*/

	ibLbCamera.text = NSLocalizedString(@"Camera msg",nil);

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
	
	buRedo_.enabled = NO;
	buCamera_.enabled = NO;
	[buTorch_ setEnabled:NO]; //buTorch_=nil の場合があるため
	buDone_.enabled = NO;
	
}

//Viewが表示された直後に実行される
- (void)viewDidAppear:(BOOL)animated 
{
	[super viewDidAppear:animated];
	
	[self cameraPreview];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{	// Return YES for supported orientations
    return YES;
	//return (interfaceOrientation == UIInterfaceOrientationPortrait);
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

	CGRect rect = ibImageView.frame;
	if (ibImageView.hidden==NO) {
		if (UIInterfaceOrientationIsPortrait(orientation)) {	// デバイス縦
			if (ibImageView.image.size.width < 600) {	// 写真タテ
				rect.size = CGSizeMake(240, 320);
			} else {		// 写真ヨコ
				rect.size = CGSizeMake(288, 216); //288 = 320 * 0.45
			}
		}
		else {		// デバイス横
			if (ibImageView.image.size.width < 600) {	// 写真タテ
				rect.size = CGSizeMake(240, 320);
			} else {		// 写真ヨコ
				rect.size = CGSizeMake(320, 240);
			}
		}
		//rect.origin.x = (self.view.frame.size.width - rect.size.width)/2;
		ibImageView.frame = rect;
	}
	else {
		switch (orientation) {
			case UIInterfaceOrientationPortrait:
				previewLayer_.orientation = AVCaptureVideoOrientationPortrait;
				rect.size = CGSizeMake(240, 320);
				break;
			case UIInterfaceOrientationPortraitUpsideDown:
				previewLayer_.orientation = AVCaptureVideoOrientationPortraitUpsideDown;
				rect.size = CGSizeMake(240, 320);
				break;
			case UIInterfaceOrientationLandscapeLeft:
				previewLayer_.orientation = AVCaptureVideoOrientationLandscapeLeft;
				rect.size = CGSizeMake(320, 240);
				break;
			case UIInterfaceOrientationLandscapeRight:
				previewLayer_.orientation = AVCaptureVideoOrientationLandscapeRight;
				rect.size = CGSizeMake(320, 240);
				break;
		}
		//rect.origin.x = (self.view.frame.size.width - rect.size.width)/2;
		ibImageView.frame = rect;
		previewLayer_.frame = rect;
	}
	
/*	if (UIInterfaceOrientationIsPortrait(orientation)) {	// デバイス縦
		rect = ibLbTorch.frame;		rect.origin = CGPointMake(221, 349);		ibLbTorch.frame = rect;
		rect = ibSwTorch.frame;	rect.origin = CGPointMake(221, 369);		ibSwTorch.frame = rect;
		rect = ibBuTake.frame;		rect.origin = CGPointMake(128, 365);		ibBuTake.frame = rect;
		rect = ibBuRetry.frame;		rect.origin = CGPointMake(  40, 362);		ibBuRetry.frame = rect;
	}
	else {		// デバイス横
		rect = ibLbTorch.frame;		rect.origin = CGPointMake(20+320+30,   10);		ibLbTorch.frame = rect;
		rect = ibSwTorch.frame;	rect.origin = CGPointMake(20+320+30,   30);		ibSwTorch.frame = rect;
		rect = ibBuTake.frame;		rect.origin = CGPointMake(20+320+30, 150);		ibBuTake.frame = rect;
		rect = ibBuRetry.frame;		rect.origin = CGPointMake(20+320+30, 250);		ibBuRetry.frame = rect;
	}*/
}

// ユーザインタフェースの回転を始める前にこの処理が呼ばれる。 ＜＜OS 3.0以降の推奨メソッド＞＞
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{	// この時点で self.view.frame はまだ回転していない。
	[self rotateToOrientation:orientation];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	
	[captureSession_ stopRunning];
	captureSession_ = nil;
	captureOutput_ = nil;
}


@end
