//
//  CVViewController.m
//  ios-snapSearch-live
//
//  Created by Carter Chang on 7/16/15.
//  Copyright (c) 2015 Carter Chang. All rights reserved.
//

#import "CVViewController.h"
#import <opencv2/videoio/cap_ios.h>
#import <TesseractOCR/TesseractOCR.h>
#import <QuartzCore/QuartzCore.h>
#import "FXBlurView.h"
#import <DKCircleButton.h>
#import "RecognizeTargetView.h"
#import "NSString+FontAwesome.h"
#import <BFPaperButton.h>
#import <UIColor+BFPaperColors.h>
#import "NSString+FontAwesome.h"
#import "CVTools.h"

using namespace cv;

typedef enum OCR_LANG_MODE : NSInteger {
    OCR_LANG_MODE_ENG=0,
    OCR_LANG_MODE_NUM,
    OCR_LANG_MODE_CHT,
    OCR_LANG_MODE_JPN,
    OCR_LANG_MODE_ALL
}OCR_LANG_MODE;


@interface CVViewController () <CvVideoCameraDelegate, G8TesseractDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet BFPaperButton *recognizeButton;
@property (weak, nonatomic) IBOutlet RecognizeTargetView *recognizeTargetView;

@property (weak, nonatomic) IBOutlet UISlider *zoomSlider;
@property (weak, nonatomic) IBOutlet UIImageView *cameraImageView;

@property (retain, nonatomic) CvVideoCamera* videoCamera;
@property (retain, nonatomic) AVCaptureDevice *videoDevice;
@property (retain, nonatomic) UIImage* currentImage;
@property (weak, nonatomic) IBOutlet UIView *recognizeWrapper;

@property (weak, nonatomic) IBOutlet UILabel *resultLabel2;
@property (weak, nonatomic) IBOutlet UITextField *resultLabel;


@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property(strong, nonatomic) dispatch_queue_t cropImageQueue;

@property (assign, nonatomic) CGPoint startPanLoc;
@property (weak, nonatomic) IBOutlet FXBlurView *cameraViewMask;
@property (weak, nonatomic) IBOutlet UIView *ctrlView;
@property (assign, nonatomic) BOOL isRecognizing;

@property (assign, nonatomic) BOOL isGray;
@property (assign, nonatomic) BOOL isInvert;
@property (retain, nonatomic) DKCircleButton *grayBtn;
@property (retain, nonatomic) DKCircleButton *invertBtn;
@property (weak, nonatomic) IBOutlet UIView *actionBtnGroup;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UIButton *langButton;
@property (assign, nonatomic) BOOL isEditing;
@property (assign, nonatomic) OCR_LANG_MODE ocrLang;
@property (weak, nonatomic) IBOutlet UIButton *clipFirstCharacter;
@property(strong, nonatomic) NSArray *langArray;
@end

@implementation CVViewController

- (void)viewDidLoad {
    [super viewDidLoad];
  
    self.langArray = [NSArray arrayWithObjects:
                      @{
                        @"ocr": @"eng",
                        @"title": @"English"
                        },
                      @{
                        @"ocr": @"eng",
                        @"title": @"Number"
                        },
                      @{
                        @"ocr": @"chi_tra",
                        @"title": @"Chinese"
                        },
                      @{
                        @"ocr": @"jpn",
                        @"title": @"Japan"
                        }
                      , nil];
    
    [self.langButton setTitle: self.langArray[self.ocrLang][@"title"] forState:UIControlStateNormal];
    
    self.isGray = YES;
    self.isInvert = YES;
    self.title = @"Snap Search";
    self.ocrLang = OCR_LANG_MODE_ENG;
    self.isEditing = NO;
    
    UIBarButtonItem *settingButton = [[UIBarButtonItem alloc] initWithTitle:[NSString fontAwesomeIconStringForIconIdentifier:@"fa-cog"] style:UIBarButtonItemStylePlain target:self action:@selector(onSetting:)];
    [settingButton setTintColor:[UIColor whiteColor]];
    [settingButton setTitleTextAttributes:@{
                                         NSFontAttributeName: [UIFont fontWithName:@"FontAwesome" size:20.0],
                                         NSForegroundColorAttributeName: [UIColor whiteColor]
                                         } forState:UIControlStateNormal];
    
    self.navigationItem.rightBarButtonItem = settingButton;
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    [self.navigationController.navigationBar setBarTintColor:[[UIColor alloc] initWithRed:0.280 green:0.533 blue:0.542 alpha:1.000]];
    
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.cropImageQueue = dispatch_queue_create("crop_queue", nil);
    
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:self.cameraImageView];
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetHigh;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.grayscaleMode = NO;
    self.videoCamera.delegate = self;
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(startCamera) userInfo:nil repeats:NO];
    
    self.cameraViewMask.dynamic = YES;
    self.cameraViewMask.blurRadius = 20;
    self.cameraViewMask.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.cameraViewMask.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
    self.cameraViewMask.layer.shadowRadius = 2.0f;
    self.cameraViewMask.layer.shadowOpacity = 1.0f;
    self.cameraViewMask.underlyingView = self.cameraImageView;
    
    NSArray * devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice * device in devices )
    {
        if ( AVCaptureDevicePositionBack == [ device position ] )
        {
            self.videoDevice = device;
        }
    }
    
    self.isRecognizing = NO;
    CGAffineTransform trans = CGAffineTransformMakeRotation(-1 * M_PI_2);
    self.zoomSlider.transform = trans;

    self.editButton.titleLabel.font = [UIFont fontWithName:@"FontAwesome" size:25];
    [self.editButton setTitle:[NSString fontAwesomeIconStringForIconIdentifier:@"fa-pencil-square-o"] forState:UIControlStateNormal];
    
    [self.clipFirstCharacter setHidden:YES];
    self.clipFirstCharacter.titleLabel.font = [UIFont fontWithName:@"FontAwesome" size:25];
    [self.clipFirstCharacter setTitle:[NSString fontAwesomeIconStringForIconIdentifier:@"fa-long-arrow-right"] forState:UIControlStateNormal];
    
    [self setupEffectButtons];
    
    self.resultLabel.text = @"";
    
    //fa-dot-circle-o
    [self.recognizeButton setTitle:[NSString fontAwesomeIconStringForIconIdentifier:@"fa-bullseye"] forState:UIControlStateNormal];
    self.recognizeButton.titleLabel.font = [UIFont fontWithName:@"FontAwesome" size:88];
    [self.recognizeButton setTitleColor:[UIColor colorWithRed:0.908 green:0.472 blue:0.324 alpha:1.000] forState:UIControlStateNormal];
    self.recognizeButton.backgroundColor = [UIColor colorWithRed:1.000 green:0.984 blue:0.990 alpha:1.000];
    self.recognizeButton.cornerRadius = self.recognizeButton.frame.size.width / 2;
    self.recognizeButton.rippleFromTapLocation = NO;
    self.recognizeButton.isRaised = YES;
    self.recognizeButton.rippleBeyondBounds = YES;
    self.recognizeButton.loweredShadowOffset = CGSizeMake(0, 0);
    self.recognizeButton.liftedShadowOffset = CGSizeMake(0, 0);
    self.recognizeButton.tapCircleColor = [UIColor colorWithRed:1.000 green:0.672 blue:0.532 alpha:0.300];
    self.recognizeButton.tapCircleDiameter = MAX(self.recognizeButton.frame.size.width, self.recognizeButton.frame.size.height) * 8;
    
    self.resultLabel.borderStyle = UITextBorderStyleNone;
    [self.resultLabel setBackgroundColor:[UIColor clearColor]];
    self.resultLabel.delegate = self;
    
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self.editButton setTitle:[NSString fontAwesomeIconStringForIconIdentifier:@"fa-check"] forState:UIControlStateNormal];
    [self openEditMode:YES];
    self.resultLabel.borderStyle = UITextBorderStyleRoundedRect;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self.editButton setTitle:[NSString fontAwesomeIconStringForIconIdentifier:@"fa-pencil-square-o"] forState:UIControlStateNormal];
    [self openEditMode:NO];
    self.resultLabel.borderStyle = UITextBorderStyleNone;
}

- (void) openEditMode:(BOOL)isediting {
    [self animateView:isediting];
    self.grayBtn.hidden = isediting;
    self.invertBtn.hidden = isediting;
    self.zoomSlider.hidden = isediting;
    self.recognizeTargetView.hidden = isediting;
    self.langButton.hidden = isediting;
    self.recognizeButton.hidden = isediting;
    self.isEditing = isediting;
    [self.clipFirstCharacter setHidden:!isediting];
}

- (IBAction)onClipFirstCharacter:(id)sender {
    if([self.resultLabel.text length] != 0){
        NSString *tempStr = [[NSString alloc] init];
        tempStr = [self.resultLabel.text substringFromIndex:1];
        self.resultLabel.text = tempStr;
    }
}

- (IBAction)onEdit:(id)sender {
    if(self.resultLabel.editing == NO){
      [self.resultLabel becomeFirstResponder];
    }else{
       [self.view endEditing:YES];
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.resultLabel resignFirstResponder];
    return YES;
}

- (void) animateView:(BOOL) up
{
    const int movementDistance = 200;
    const float movementDuration = 0.3f;

    int movement = (up ? -movementDistance : movementDistance);
    int labelMovement = (up ? 20 : -20);
    int cameralMovement = (up ? -100 : 100);
    
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    
    self.ctrlView.frame = CGRectOffset(self.ctrlView.frame, 0, movement);
    self.resultLabel.frame = CGRectOffset(self.resultLabel.frame, 0, labelMovement);
    self.cameraImageView.frame = CGRectOffset(self.cameraImageView.frame, 0, cameralMovement);
    [UIView commitAnimations];
}

- (IBAction)onLang:(id)sender {
    int langInteger = (int)self.ocrLang;
    int allLang = (int)OCR_LANG_MODE_ALL;
    langInteger = (langInteger +1) % allLang;
    self.ocrLang = (OCR_LANG_MODE)langInteger;
    [self.langButton setTitle: self.langArray[langInteger][@"title"] forState:UIControlStateNormal];
}

-(void) onSetting:(id) sender{
    NSLog(@"=============onSetting==============");
}

- (void)viewDidLayoutSubviews {
    //[self setupEffectButtons];
}

-(void) setupEffectButtons {
    self.grayBtn = [[DKCircleButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    //230
    self.grayBtn.center = CGPointMake(30, 100);
    self.grayBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [self.grayBtn setTitleColor:[UIColor colorWithWhite:1 alpha:1.0] forState:UIControlStateNormal];
    self.grayBtn.animateTap = NO;
    [self.grayBtn setTitle:NSLocalizedString(@"G", nil) forState:UIControlStateNormal];
    self.grayBtn.tag = 1;
    [self.grayBtn addTarget:self action:@selector(tapOnButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.grayBtn];
    
    //280
    self.invertBtn = [[DKCircleButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    self.invertBtn.center = CGPointMake(30, 150);
    self.invertBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [self.invertBtn setTitleColor:[UIColor colorWithWhite:1 alpha:1.0] forState:UIControlStateNormal];
    self.invertBtn.tag = 2;
    self.invertBtn.animateTap = NO;
    [self.invertBtn setTitle:NSLocalizedString(@"I", nil) forState:UIControlStateNormal];
    
    [self.invertBtn addTarget:self action:@selector(tapOnButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.invertBtn];
    
    [self updateButtonStatus:self.grayBtn];
    [self updateButtonStatus:self.invertBtn];
}

-(void)updateButtonStatus:(DKCircleButton *)btn{
    
    if (btn == self.invertBtn && self.isInvert) {
        btn.backgroundColor = [UIColor colorWithRed:0.817 green:0.773 blue:0.344 alpha:0.590];
    }else if(btn == self.grayBtn && self.isGray){
        btn.backgroundColor = [UIColor colorWithRed:0.817 green:0.773 blue:0.344 alpha:0.590];
    }else {
        btn.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
    }
}


-(void) tapOnButton:(id)sender{
    DKCircleButton *btn = (DKCircleButton *)sender;
    if (btn.tag == 1){
        self.isGray = self.isGray == YES ? NO: YES;
      
    }else if(btn.tag == 2) {
        self.isInvert = self.isInvert == YES ? NO: YES;
    }
    
    [self updateButtonStatus:btn];
}

- (UIImage*) createInvertMask:(UIImage *)maskImage withTargetImage:(UIImage *) image {
    
    CGImageRef maskRef = maskImage.CGImage;
    
    CGBitmapInfo bitmapInfo = kCGImageAlphaNone;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGImageRef mask = CGImageCreate(CGImageGetWidth(maskRef),
                                    CGImageGetHeight(maskRef),
                                    CGImageGetBitsPerComponent(maskRef),
                                    CGImageGetBitsPerPixel(maskRef),
                                    CGImageGetBytesPerRow(maskRef),
                                    CGColorSpaceCreateDeviceGray(),
                                    bitmapInfo,
                                    CGImageGetDataProvider(maskRef),
                                    nil, NO,
                                    renderingIntent);
    
    
    CGImageRef masked = CGImageCreateWithMask([image CGImage], mask);
    
    CGImageRelease(mask);
    CGImageRelease(maskRef);
    
    return [UIImage imageWithCGImage:masked];
}


-(UIImage*) maskImage:(UIImage *)image withMask:(UIImage *)maskImage {
    
    CGImageRef maskRef = maskImage.CGImage;
    CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                        CGImageGetHeight(maskRef),
                                        CGImageGetBitsPerComponent(maskRef),
                                        CGImageGetBitsPerPixel(maskRef),
                                        CGImageGetBytesPerRow(maskRef),
                                        CGImageGetDataProvider(maskRef), NULL, false);
    
    CGImageRef masked = CGImageCreateWithMask([image CGImage], mask);
    return [UIImage imageWithCGImage:masked];
}

-(void) cameraZoom:(float)zoom {
    NSError *error = nil;
    if ([self.videoDevice lockForConfiguration:&error]) {
        self.videoDevice.videoZoomFactor = zoom;
        [self.videoDevice unlockForConfiguration];
    }else {
        NSLog(@"error: %@", error);
    }
}

-(void) startCamera {
    [self.videoCamera start];
    [self cameraZoom:self.zoomSlider.value];
}


- (void)processImage:(cv::Mat&)image
{
    // OpenCV convert to scanable mode
    //image = [self imageScanableProcessing:image];
    
    /*
    //DetectLetters
    std::vector<cv::Rect> letterBBoxes= [self detectLetters:image];
    for(int i=0; i< letterBBoxes.size(); i++){
        cv::rectangle(image,letterBBoxes[i],cv::Scalar(0,255,0),3,8,0);
    }
    */
    
    self.currentImage = [CVTools UIImageFromCVMat:image];
    //[self cropByTarget:nil];
}

- (void) cropByTarget:(void(^)(UIImage *image))completion{
    UIImage *image = self.currentImage;
    CGRect wrapperRect = self.recognizeWrapper.frame;
    CGRect frameRect = self.recognizeTargetView.frame;
    CGFloat scaleW = image.size.width / wrapperRect.size.width;
    CGFloat scaleH = image.size.height / wrapperRect.size.height;

    CGRect rect = CGRectMake(
                             (frameRect.origin.x )*scaleW,
                             (frameRect.origin.y )*scaleH,
                             frameRect.size.width*scaleW,
                             (frameRect.size.height )*scaleH
                             );
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], rect);
    UIImage *cropedImg = [UIImage imageWithCGImage:imageRef ];
    
    CGImageRelease(imageRef);
    
   
    // textDetection
//    cv::Mat mat = [self cvMatFromUIImage:cropedImg];
//    std::vector<cv::Rect> letterBBoxes= [self detectLetters:mat];
//    for(int i=0; i< letterBBoxes.size(); i++){
//        cv::rectangle(mat,letterBBoxes[i],cv::Scalar(0,255,0),3,8,0);
//    }
//    cropedImg = [self UIImageFromCVMat:mat];

    
    // Apply openCV effect
    cropedImg = [CVTools UIImageFromCVMat:[self imageScanableProcessing:[CVTools cvMatFromUIImage:cropedImg]]];
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.recognizeTargetView setInnerImage:cropedImg];
        [self.recognizeTargetView setupProgressbar:cropedImg];
        
    });
    
    if (completion!=nil) {
        completion(cropedImg);
    }

}

- (void) doRecognition:(UIImage*)image complete:(void(^)(NSString *recognizedText))complete{
    UIImage *bwImage = [image g8_blackAndWhite];
    
    NSString *ocrKey = self.langArray[self.ocrLang][@"ocr"];
    G8RecognitionOperation *operation = [[G8RecognitionOperation alloc]initWithLanguage:ocrKey];
    operation.tesseract.maximumRecognitionTime = 10.0;
    //operation.tesseract.engineMode = G8OCREngineModeTesseractOnly;
    //operation.tesseract.pageSegmentationMode = G8PageSegmentationModeSingleLine;
    
    operation.delegate = self;
    operation.tesseract.image = bwImage;
    
    if(self.ocrLang == OCR_LANG_MODE_ENG){
        //operation.tesseract.charWhitelist = @"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    }else if(self.ocrLang == OCR_LANG_MODE_NUM){
        operation.tesseract.charWhitelist = @"0123456789";
    }
    //operation.tesseract.charBlacklist = @".|\\/,';:`~-_^";
    
    operation.recognitionCompleteBlock = ^(G8Tesseract *tesseract) {
        // Fetch the recognized text
        NSString *recognizedText = tesseract.recognizedText;
        NSLog(@"recognizedText= %@", recognizedText);
        complete(recognizedText);
        [G8Tesseract clearCache];
    };
    [self.operationQueue addOperation:operation];
}


- (IBAction)onRecognize:(id)sender {
    
    if (self.isRecognizing) {
        return;
    }
    
    self.isRecognizing = YES;
    SystemSoundID soundID;
    NSURL *buttonURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"snap" ofType:@"wav"]];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)buttonURL, &soundID);
    AudioServicesPlaySystemSound(soundID);

    dispatch_async(self.cropImageQueue, ^{
        [self.recognizeTargetView fillInnerImage];
        [self cropByTarget:^(UIImage *image) {
            [self doRecognition:image complete:^(NSString *recognizedText) {
                self.resultLabel.text = recognizedText;
                [self.recognizeTargetView finishProgress];
                self.isRecognizing = NO;
            }];
        }];
    });
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onZoomChange:(id)sender {
   [self cameraZoom:self.zoomSlider.value];
}

-(void) cameraFocusAtTarget
{
    CGFloat x = self.recognizeTargetView.center.x / self.cameraImageView.bounds.size.width;
    CGFloat y = self.recognizeTargetView.center.y / self.cameraImageView.bounds.size.height;
    
    CGPoint point = CGPointMake(x, y);
    if ([self.videoDevice isFocusPointOfInterestSupported] && [self.videoDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        NSError *error;
        if ([self.videoDevice lockForConfiguration:&error]) {
            [self.videoDevice setFocusPointOfInterest:point];
            [self.videoDevice setFocusMode:AVCaptureFocusModeAutoFocus];
            [self.videoDevice unlockForConfiguration];
        } else {
            NSLog(@"Error in Focus Mode");
        }
    }
}

- (IBAction)onCameraViewTap:(UITapGestureRecognizer *)sender {

    if (self.isEditing) {
        [self.resultLabel resignFirstResponder];
    }

    [self cameraFocusAtTarget];
}

- (IBAction)onPan:(UIPanGestureRecognizer *)sender {
    if (self.isRecognizing) {
        return;
    }
    
    CGPoint loc = [sender locationInView:self.cameraImageView];
    if(sender.state == UIGestureRecognizerStateBegan){
        self.startPanLoc = loc;
    }else if(sender.state == UIGestureRecognizerStateChanged){
        
        int invertX = self.startPanLoc.x > self.recognizeTargetView.center.x ? 1: -1;
        int invertY = self.startPanLoc.y > self.recognizeTargetView.center.y ? 1: -1;
        CGFloat offsetX = invertX*(loc.x - self.startPanLoc.x)/8; //loc.x - self.startPanLoc.x > 1 ? 3: -3;
        CGFloat offsetY = invertY*(loc.y - self.startPanLoc.y)/8; //loc.y - self.startPanLoc.y> 1 ? 3:-3;
 
        CGRect newFrame = self.recognizeTargetView.frame;
        CGPoint center =  self.recognizeTargetView.center;
        newFrame.size.width = MIN(newFrame.size.width + offsetX, 290);
        newFrame.size.height = MIN(newFrame.size.height + offsetY, 250);
        newFrame.size.width = MAX(newFrame.size.width + offsetX, 100);
        newFrame.size.height = MAX(newFrame.size.height + offsetY, 40);
        
        self.recognizeTargetView.frame = newFrame;
        self.recognizeTargetView.center = center;
        
        if (newFrame.size.height < 80){
            self.recognizeTargetView.layer.cornerRadius = 35 * newFrame.size.height/80;
        }
   
    }else if(sender.state == UIGestureRecognizerStateEnded){
        [self.recognizeTargetView fillInnerImage];
    }
}
#pragma mark - G8Tesseract

- (void)progressImageRecognitionForTesseract:(G8Tesseract *)tesseract {
    //NSLog(@"progress: %lu", (unsigned long)tesseract.progress);
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.recognizeTargetView updateProgress:(unsigned long)tesseract.progress / 100.0];
   });
}

#pragma mark - openCV
- (cv::Mat) imageScanableProcessing:(cv::Mat)image{
    cv::Mat image_copy;
    cvtColor(image, image_copy, CV_BGRA2BGR);
    image = image_copy;
    
    
    if (self.isInvert) {
        // Invert image
        bitwise_not(image, image_copy);
        image = image_copy;
    }
    
    if (self.isGray) {
        // Gray image (Need to markout gray image before enable DetectLetters)
        cvtColor(image, image_copy, CV_RGBA2GRAY);
        image = image_copy;
    }
    return image;
}
@end
