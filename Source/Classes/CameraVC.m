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

@implementation CameraVC
{
	AppDelegate		*appDelegate_;

	// CAPTURE: Front Camera
	AVCaptureDevice		*captureDevice_;
	AVCaptureSession		*captureSession_;
	AVCaptureStillImageOutput *captureOutput_;
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
	
	UIInterfaceOrientation interOri;
	if (appDelegate_.app_is_iPad) {
		interOri = appDelegate_.mainSVC.interfaceOrientation;
	} else {
		interOri = appDelegate_.mainNC.interfaceOrientation;
	}

	for (AVCaptureConnection *connection in captureOutput_.connections) {
		if (connection.supportsVideoOrientation) {
			switch (interOri) {	// self.interfaceOrientation はダメ
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
	AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession: captureSession_];
	previewLayer.frame = ibImageView.frame;
	previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	previewLayer.automaticallyAdjustsMirroring = NO;
	
	switch (interOri) {	// self.interfaceOrientation はダメ
		case UIInterfaceOrientationPortrait:
			previewLayer.orientation = AVCaptureVideoOrientationPortrait;
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			previewLayer.orientation = AVCaptureVideoOrientationPortraitUpsideDown;
			break;
		case UIInterfaceOrientationLandscapeLeft:
			previewLayer.orientation = AVCaptureVideoOrientationLandscapeLeft;
			break;
		case UIInterfaceOrientationLandscapeRight:
			previewLayer.orientation = AVCaptureVideoOrientationLandscapeRight;
			break;
	}
	//[self.view.layer insertSublayer: previewLayer atIndex: 0];
	[self.view.layer  addSublayer: previewLayer];
	
	[captureSession_ startRunning];
	//
	self.navigationItem.rightBarButtonItem.enabled = NO; //[Done]
	ibBuRetry.hidden = YES;
	ibBuTake.hidden = NO;
	ibLbTorch.hidden = NO;
	ibSwTorch.hidden = NO;
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
													//
													self.navigationItem.rightBarButtonItem.enabled = YES; //[Done]
													ibBuRetry.hidden = NO;
											   } 
	 ];
}


#pragma mark - Action

- (IBAction)ibBuTakeTouch:(UIButton *)button
{
	button.hidden = YES;
	ibLbTorch.hidden = YES;
	ibSwTorch.hidden = YES;
	[self cameraTake];	// カメラ撮影  ＜＜この中で saveClose を呼び出している
}

- (IBAction)ibBuRetryTouch:(UIButton *)button
{
	button.hidden = YES;
	self.navigationItem.rightBarButtonItem.enabled = NO; //[Done]
	ibImageView.image = nil;
	// Start
	[captureSession_ startRunning];
	ibBuTake.hidden = NO;
	[ibSwTorch setOn:NO];
	ibLbTorch.hidden = NO;
	ibSwTorch.hidden = NO;
}

- (IBAction)ibSwTorch:(UISwitch *)sender;
{
	NSError *error = nil;
	// カメラ設定
	if ([captureDevice_ lockForConfiguration:&error]) {
		// トーチ
		if ([sender isOn]) {
			if ([captureDevice_ isTorchModeSupported:AVCaptureTorchModeOn]) {
				captureDevice_.torchMode = AVCaptureTorchModeOn;
			}	
		} else {
			if ([captureDevice_ isTorchModeSupported:AVCaptureTorchModeOff]) {
				captureDevice_.torchMode = AVCaptureTorchModeOff;
			}	
		}
		// 完了 ロック解除
		[captureDevice_ unlockForConfiguration];
	}
}

- (void)doneClose:(UIButton*)button
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

	self.title = NSLocalizedString(@"Photo", nil);
	
	// [Done] ボタンを右側に追加する
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] 
											  initWithBarButtonSystemItem:UIBarButtonSystemItemDone
											  target:self action:@selector(doneClose:)];
	self.navigationItem.rightBarButtonItem.enabled = NO;

	[ibBuTake setTitle:NSLocalizedString(@"Camera Take",nil) forState:UIControlStateNormal];
	[ibBuRetry setTitle:NSLocalizedString(@"Camera Retry",nil) forState:UIControlStateNormal];
	ibLbTorch.text = NSLocalizedString(@"Camera Torch",nil);
	
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
}

//Viewが表示された直後に実行される
- (void)viewDidAppear:(BOOL)animated 
{
	[super viewDidAppear:animated];
	
	[self cameraPreview];
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
