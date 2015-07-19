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
#import "UIView+Toast.h"
#import "RecognizeButton.h"
using namespace cv;

typedef enum OCR_LANG_MODE : NSInteger {
    OCR_LANG_MODE_ENG=0,
    OCR_LANG_MODE_NUM,
    OCR_LANG_MODE_CHT,
    OCR_LANG_MODE_JPN,
    OCR_LANG_MODE_ALL
}OCR_LANG_MODE;

typedef enum EFFECT_MODE : NSInteger {
    EFFECT_MODE_GRAY=0,
    EFFECT_MODE_INVERT,
    EFFECT_MODE_FLASH
}EFFECT_MODE;

@interface CVViewController () <CvVideoCameraDelegate, G8TesseractDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet RecognizeButton *recognizeButton;
@property (weak, nonatomic) IBOutlet RecognizeTargetView *recognizeTargetView;

@property (weak, nonatomic) IBOutlet UISlider *zoomSlider;
@property (weak, nonatomic) IBOutlet UIImageView *cameraImageView;

@property (retain, nonatomic) CvVideoCamera* videoCamera;
@property (retain, nonatomic) AVCaptureDevice *videoDevice;
@property (retain, nonatomic) UIImage* currentImage;
@property (weak, nonatomic) IBOutlet UIView *recognizeWrapper;

@property (weak, nonatomic) IBOutlet UITextField *resultLabel;

@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property(strong, nonatomic) dispatch_queue_t cropImageQueue;

@property (assign, nonatomic) CGPoint startPanLoc;
@property (weak, nonatomic) IBOutlet FXBlurView *cameraViewMask;
@property (weak, nonatomic) IBOutlet UIView *ctrlView;
@property (assign, nonatomic) BOOL isRecognizing;

@property (retain, nonatomic) DKCircleButton *grayBtn;
@property (retain, nonatomic) DKCircleButton *invertBtn;
@property (retain, nonatomic) DKCircleButton *flashBtn;

@property (weak, nonatomic) IBOutlet UIView *actionBtnGroup;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UIButton *langButton;
@property (assign, nonatomic) BOOL isEditing;
@property (assign, nonatomic) OCR_LANG_MODE ocrLang;
@property (assign, nonatomic) SystemSoundID clickSoundID;
@property (weak, nonatomic) IBOutlet UIButton *clipFirstCharacter;
@property(strong, nonatomic) NSArray *langArray;
@property(assign, nonatomic) BOOL signCancelRecognize;
@end

@implementation CVViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    SystemSoundID soundID;
    NSURL *buttonURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"snap" ofType:@"wav"]];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)buttonURL, &soundID);
    self.clickSoundID = soundID;
    
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
    self.videoCamera.defaultFPS = 20;
    self.videoCamera.grayscaleMode = NO;
    self.videoCamera.delegate = self;
    
    self.cameraViewMask.dynamic = YES;
    self.cameraViewMask.blurRadius = 20;
    self.cameraViewMask.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.cameraViewMask.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
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
    self.resultLabel.borderStyle = UITextBorderStyleNone;
    [self.resultLabel setBackgroundColor:[UIColor clearColor]];
    self.resultLabel.delegate = self;
    
}

- (IBAction)onLang:(id)sender {
    if (self.isRecognizing) {
        return;
    }
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
    [self startCamera];
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
    // This function should be run in background thread
    
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
    
    if (completion!=nil) {
        completion(cropedImg);
    }

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
        CGFloat offsetX = invertX*(loc.x - self.startPanLoc.x)/5;
        CGFloat offsetY = invertY*(loc.y - self.startPanLoc.y)/5;
 
        CGRect newFrame = self.recognizeTargetView.bounds;
        newFrame.size.width = MIN(newFrame.size.width + offsetX, 290);
        newFrame.size.height = MIN(newFrame.size.height + offsetY, 250);
        newFrame.size.width = MAX(newFrame.size.width + offsetX, 100);
        newFrame.size.height = MAX(newFrame.size.height + offsetY, 40);
        
        self.recognizeTargetView.bounds = newFrame;
        //self.recognizeTargetView.center = center;
        
        if (newFrame.size.height < 80){
            self.recognizeTargetView.layer.cornerRadius = 35 * newFrame.size.height/80;
        }
   
    }else if(sender.state == UIGestureRecognizerStateEnded){
        [self.recognizeTargetView fillInnerImage];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - OCR


- (void) doRecognition:(UIImage*)image complete:(void(^)(NSString *recognizedText))complete{
    
    // Mark below for avoiding BSXPCMessage error
    //UIImage *bwImage =[image g8_blackAndWhite];
    
    NSString *ocrKey = self.langArray[self.ocrLang][@"ocr"];
    G8RecognitionOperation *operation = [[G8RecognitionOperation alloc]initWithLanguage:ocrKey];
    operation.tesseract.maximumRecognitionTime = 10.0;
    //operation.tesseract.engineMode = G8OCREngineModeTesseractOnly;
    //operation.tesseract.pageSegmentationMode = G8PageSegmentationModeSingleLine;
    
    operation.delegate = self;
    operation.tesseract.image = image;
    
    if(self.ocrLang == OCR_LANG_MODE_ENG){
        //operation.tesseract.charWhitelist = @"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    }else if(self.ocrLang == OCR_LANG_MODE_NUM){
        operation.tesseract.charWhitelist = @"0123456789";
    }else if (self.ocrLang == OCR_LANG_MODE_CHT){
        operation.tesseract.maximumRecognitionTime = 30.0;
    }else if (self.ocrLang == OCR_LANG_MODE_JPN){
        operation.tesseract.maximumRecognitionTime = 30.0;
    }
    //operation.tesseract.charBlacklist = @".|\\/,';:`~-_^";
    
    NSLog(@"operation  out");
    
    operation.recognitionCompleteBlock = ^(G8Tesseract *tesseract) {
        
        NSLog(@"operation  done");
        
        // Fetch the recognized text
        NSString *recognizedText = tesseract.recognizedText;
        NSLog(@"recognizedText= %@", recognizedText);
        complete(recognizedText);
        [G8Tesseract clearCache];
    };
    [self.operationQueue addOperation:operation];
}

-(void) ocrStarting{
    [self.recognizeTargetView startProgressbar];
    self.recognizeButton.recognizeMode = NO;
    self.signCancelRecognize = NO;
}

-(void) ocrFinished:(NSString *)recognizedText{
    [self.recognizeTargetView updateProgress: 1];
    [self.recognizeTargetView finishProgress];
    self.isRecognizing = NO;
    self.recognizeButton.recognizeMode = YES;
    
    if (!self.signCancelRecognize) {
        self.resultLabel.text = recognizedText;
    }else{
        [self.actionBtnGroup makeToast:@"cancel recognizing" duration: 0.5 position:[NSValue valueWithCGPoint:CGPointMake(self.actionBtnGroup.bounds.size.width/2, -25)]];
    }
    self.signCancelRecognize = NO;
}

- (IBAction)onRecognize:(id)sender {
    
    if (self.isRecognizing) {
        self.signCancelRecognize = YES;
        return;
    }
    
    self.isRecognizing = YES;
    AudioServicesPlaySystemSound(self.clickSoundID);
    
    dispatch_async(self.cropImageQueue, ^{
        [self.recognizeTargetView fillInnerImage];
        [self cropByTarget:^(UIImage *image) {
            
            //Start OCR -----
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.recognizeTargetView setInnerImage:image];
                [self ocrStarting];
                
                
                [self doRecognition:image complete:^(NSString *recognizedText) {
                    [self ocrFinished:recognizedText];
                    //Finish OCR ----
                }];
                
            });
        }];
    });
}

- (NSString*) recognizedResult{
    return self.resultLabel.text;
}

- (void)progressImageRecognitionForTesseract:(G8Tesseract *)tesseract {
    // NSLog(@"progress: %lu", (unsigned long)tesseract.progress);
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.recognizeTargetView updateProgress: (unsigned long)tesseract.progress / 100.0];
    });
}

- (BOOL)shouldCancelImageRecognitionForTesseract:(G8Tesseract *)tesseract {
    return self.signCancelRecognize;
}


#pragma mark - effect buttons

-(DKCircleButton *) effectButtonWithTitle:(NSString*)title in:(CGPoint)pos tag:(EFFECT_MODE)tag{
    DKCircleButton *btn = [[DKCircleButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    btn.center = pos;
    btn.titleLabel.font = [UIFont systemFontOfSize:16];
    [btn setTitleColor:[UIColor colorWithWhite:0 alpha:0.2] forState:UIControlStateNormal];
    [btn setBackgroundImage:[self imageWithColor:[UIColor colorWithRed:0.817 green:0.773 blue:0.344 alpha:0.590]] forState:UIControlStateSelected];
    [btn setTitleColor:[UIColor colorWithWhite:1 alpha:1.0] forState:UIControlStateNormal];
    btn.tag = tag;
    btn.animateTap = YES;
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setSelected:YES];
    [btn addTarget:self action:@selector(tapOnEffectButton:) forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

-(void) setupEffectButtons {
    self.grayBtn = [self effectButtonWithTitle:@"G" in:CGPointMake(30, 288) tag:EFFECT_MODE_GRAY];
    self.invertBtn = [self effectButtonWithTitle:@"I" in:CGPointMake(30, 340) tag:EFFECT_MODE_INVERT];
    self.flashBtn = [self effectButtonWithTitle:@"flash" in:CGPointMake(30, 100) tag:EFFECT_MODE_FLASH];
    self.flashBtn.titleLabel.font = [UIFont fontWithName:@"FontAwesome" size:20];
    [self.flashBtn setTitle:[NSString fontAwesomeIconStringForIconIdentifier:@"fa-bolt"] forState:UIControlStateNormal];
    [self.flashBtn setSelected:NO];
    
    [self.view addSubview:self.grayBtn];
    [self.view addSubview:self.invertBtn];
    [self.view addSubview:self.flashBtn];
}

-(void) tapOnEffectButton:(id)sender{
    UIButton* btn = (UIButton*)sender;
    btn.selected = !btn.selected;
    if ((EFFECT_MODE)btn.tag == EFFECT_MODE_FLASH) {
        [self cameraTurnTorchOn:btn.selected];
    }
}

#pragma mark - edit


- (UIImage *) imageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
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
        
        // Movie cursor to the left
        UITextPosition *beginPos = self.resultLabel.beginningOfDocument;
        UITextRange *selection = [self.resultLabel textRangeFromPosition:beginPos toPosition:beginPos];
        [self.resultLabel setSelectedTextRange:selection];
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


#pragma mark - Camera

-(void) startCamera {
    [self.videoCamera start];
    [self cameraZoom:self.zoomSlider.value];
}

- (IBAction)onZoomChange:(id)sender {
    [self cameraZoom:self.zoomSlider.value];
}

- (IBAction)onCameraViewTap:(UITapGestureRecognizer *)sender {
    if (self.isEditing) {
        [self.resultLabel resignFirstResponder];
    }
    
    [self cameraFocusAtTarget];
}

- (void) cameraTurnTorchOn: (bool) on {
    if ([self.videoDevice hasTorch] && [self.videoDevice hasFlash]){
        
        [self.videoDevice lockForConfiguration:nil];
        if (on) {
            [self.videoDevice setTorchMode:AVCaptureTorchModeOn];
            [self.videoDevice setFlashMode:AVCaptureFlashModeOn];
        } else {
            [self.videoDevice setTorchMode:AVCaptureTorchModeOff];
            [self.videoDevice setFlashMode:AVCaptureFlashModeOff];
        }
        [self.videoDevice unlockForConfiguration];
    }
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

-(void) cameraFocusAtTarget
{
    CGFloat x = self.recognizeTargetView.center.x / self.view.bounds.size.width;
    CGFloat y = self.recognizeTargetView.center.y / self.view.bounds.size.height;
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


#pragma mark - openCV

- (cv::Mat) imageScanableProcessing:(cv::Mat)image{
    cv::Mat image_copy;
    cvtColor(image, image_copy, CV_BGRA2BGR);
    image = image_copy;
    
    
    if (self.invertBtn.selected) {
        // Invert image
        bitwise_not(image, image_copy);
        image = image_copy;
    }
    
    if (self.grayBtn.selected) {
        // Gray image (Need to markout gray image before enable DetectLetters)
        cvtColor(image, image_copy, CV_RGBA2GRAY);
        image = image_copy;
    }
    return image;
}



@end
