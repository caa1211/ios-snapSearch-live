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
#import <BFPaperButton.h>
#import <UIColor+BFPaperColors.h>
#import "NSString+FontAwesome.h"
#import "NSTimer+Blocks.h"

using namespace cv;

@interface CVViewController () <CvVideoCameraDelegate, G8TesseractDelegate>
@property (weak, nonatomic) IBOutlet UISlider *zoomSlider;
@property (weak, nonatomic) IBOutlet UIImageView *cameraImageView;

@property (retain, nonatomic) CvVideoCamera* videoCamera;
@property (retain, nonatomic) AVCaptureDevice *videoDevice;
@property (retain, nonatomic) UIImage* currentImage;
@property (weak, nonatomic) IBOutlet UIView *recognizeWrapper;

@property (weak, nonatomic) IBOutlet UILabel *resultLabel;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property(strong, nonatomic) dispatch_queue_t cropImageQueue;

@property (assign, nonatomic) CGPoint startPanLoc;

@property (weak, nonatomic) IBOutlet UIView *recognizeTarget;
@property (weak, nonatomic) IBOutlet UIImageView *targetImageView;

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

@end

@implementation CVViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.isGray = YES;
    self.isInvert = YES;
    self.title = @"Snap Search";
    
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
    self.videoCamera.defaultFPS = 15;
    self.videoCamera.grayscaleMode = NO;
    self.videoCamera.delegate = self;
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(startCamera) userInfo:nil repeats:NO];
    
    self.cameraViewMask.dynamic = YES;
    self.cameraViewMask.blurRadius = 20;

    self.recognizeTarget.layer.cornerRadius = 35;
    self.recognizeTarget.layer.masksToBounds = YES;
    self.recognizeTarget.layer.borderWidth = 4.0f;
    self.recognizeTarget.layer.borderColor = CGColorRetain([UIColor colorWithRed:0.901 green:0.858 blue:0.859 alpha:1.000].CGColor);
    
    
    self.cameraViewMask.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.cameraViewMask.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
    self.cameraViewMask.layer.shadowRadius = 2.0f;
    self.cameraViewMask.layer.shadowOpacity = 1.0f;
    
    
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
    //[self updateMask];
    
    
    self.editButton.titleLabel.font = [UIFont fontWithName:@"FontAwesome" size:25];
    [self.editButton setTitle:[NSString fontAwesomeIconStringForIconIdentifier:@"fa-pencil-square-o"] forState:UIControlStateNormal];

}

-(void) onSetting:(id) sender{

}

-(void) viewDidLayoutSubviews{
    [self setupEffectButtons];
    [self setupActionButtons];
}

-(void) setupActionButtons {
    CGRect parentRect = self.actionBtnGroup.bounds;

    self.actionBtnGroup.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.actionBtnGroup.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
    self.actionBtnGroup.layer.shadowRadius = 2.0f;
    self.actionBtnGroup.layer.shadowOpacity = 0.5;
    
    BFPaperButton *ecBtn = [[BFPaperButton alloc] initWithFrame:CGRectMake(0, 0, parentRect.size.width/2, parentRect.size.height/2) raised:NO];
    ecBtn.titleLabel.font = [UIFont fontWithName:@"FontAwesome" size:30];
    [ecBtn setTitle:[NSString fontAwesomeIconStringForIconIdentifier:@"fa-shopping-cart"] forState:UIControlStateNormal];
    ecBtn.loweredShadowOpacity = 0.1;
    ecBtn.backgroundColor = [UIColor colorWithRed:0.447 green:0.580 blue:0.555 alpha:1.000];
    [ecBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [ecBtn addTarget:self action:@selector(onSearchBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.actionBtnGroup addSubview:ecBtn];
    
    BFPaperButton *searchBtn = [[BFPaperButton alloc] initWithFrame:CGRectMake(parentRect.size.width/2, 0, parentRect.size.width/2, parentRect.size.height/2) raised:NO];
    searchBtn.titleLabel.font = [UIFont fontWithName:@"FontAwesome" size:30];
    [searchBtn setTitle:[NSString fontAwesomeIconStringForIconIdentifier:@"fa-search"] forState:UIControlStateNormal];
    searchBtn.loweredShadowOpacity = 0.1;
    searchBtn.backgroundColor = [UIColor colorWithRed:0.387 green:0.528 blue:0.529 alpha:1.000];
    [searchBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [searchBtn addTarget:self action:@selector(onSearchBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.actionBtnGroup addSubview:searchBtn];
    
    BFPaperButton *dicthBtn = [[BFPaperButton alloc] initWithFrame:CGRectMake(0, parentRect.size.height/2, parentRect.size.width/2, parentRect.size.height/2) raised:NO];
    dicthBtn.titleLabel.font = [UIFont fontWithName:@"FontAwesome" size:30];
    [dicthBtn setTitle:[NSString fontAwesomeIconStringForIconIdentifier:@"fa-book"] forState:UIControlStateNormal];
    dicthBtn.loweredShadowOpacity = 0.1;
    dicthBtn.backgroundColor = [UIColor colorWithRed:0.286 green:0.428 blue:0.455 alpha:1.000];
    [dicthBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [dicthBtn addTarget:self action:@selector(onSearchBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.actionBtnGroup addSubview:dicthBtn];
    
    BFPaperButton *copyBtn = [[BFPaperButton alloc] initWithFrame:CGRectMake(parentRect.size.width/2, parentRect.size.height/2, parentRect.size.width/2, parentRect.size.height/2) raised:NO];
    copyBtn.titleLabel.font = [UIFont fontWithName:@"FontAwesome" size:30];
    [copyBtn setTitle:[NSString fontAwesomeIconStringForIconIdentifier:@"fa-clipboard"] forState:UIControlStateNormal];
    copyBtn.loweredShadowOpacity = 0.1;
    copyBtn.backgroundColor = [UIColor colorWithRed:0.223 green:0.361 blue:0.399 alpha:1.000];
    [copyBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [dicthBtn addTarget:self action:@selector(onSearchBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.actionBtnGroup addSubview:copyBtn];
  
    
}

-(void) onSearchBtnClick:(id)sender {
    [self.actionBtnGroup bringSubviewToFront:sender];
}

-(void) setupEffectButtons {
    self.grayBtn = [[DKCircleButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    
    self.grayBtn.center = CGPointMake(30, 230);
    self.grayBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [self.grayBtn setTitleColor:[UIColor colorWithWhite:1 alpha:1.0] forState:UIControlStateNormal];
    //grayBtn.animateTap = NO;
    [self.grayBtn setTitle:NSLocalizedString(@"G", nil) forState:UIControlStateNormal];
    //zoom1x.tag = @"1x";
    self.grayBtn.tag = 1;
    [self.grayBtn addTarget:self action:@selector(tapOnButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.grayBtn];
    
    self.invertBtn = [[DKCircleButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    self.invertBtn.center = CGPointMake(30, 280);
    self.invertBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [self.invertBtn setTitleColor:[UIColor colorWithWhite:1 alpha:1.0] forState:UIControlStateNormal];
    self.invertBtn.tag = 2;
    //invertBtn.animateTap = NO;
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
    
    [self updateButtonStatus:btn ];
}

-(void) updateMask {
    
    CGRect r = self.cameraViewMask.bounds;
    CGRect r2 = self.recognizeTarget.frame;    CAShapeLayer* lay = [CAShapeLayer layer];
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, nil, r2);
    CGPathAddRect(path, nil, r);
    lay.path = path;
    CGPathRelease(path);
    lay.fillRule = kCAFillRuleEvenOdd;
    
    self.cameraViewMask.layer.mask = lay;
}

- (UIImage *)blurWithCoreImage:(UIImage *)sourceImage
{
    CIImage *inputImage = [CIImage imageWithCGImage:sourceImage.CGImage];
    
    // Apply Affine-Clamp filter to stretch the image so that it does not
    // look shrunken when gaussian blur is applied
    CGAffineTransform transform = CGAffineTransformIdentity;
    CIFilter *clampFilter = [CIFilter filterWithName:@"CIAffineClamp"];
    [clampFilter setValue:inputImage forKey:@"inputImage"];
    [clampFilter setValue:[NSValue valueWithBytes:&transform objCType:@encode(CGAffineTransform)] forKey:@"inputTransform"];
    
    // Apply gaussian blur filter with radius of 30
    CIFilter *gaussianBlurFilter = [CIFilter filterWithName: @"CIGaussianBlur"];
    [gaussianBlurFilter setValue:clampFilter.outputImage forKey: @"inputImage"];
    [gaussianBlurFilter setValue:@30 forKey:@"inputRadius"];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [context createCGImage:gaussianBlurFilter.outputImage fromRect:[inputImage extent]];
    
    // Set up output context.
    UIGraphicsBeginImageContext(self.view.frame.size);
    CGContextRef outputContext = UIGraphicsGetCurrentContext();
    
    // Invert image coordinates
    CGContextScaleCTM(outputContext, 1.0, -1.0);
    CGContextTranslateCTM(outputContext, 0, -self.view.frame.size.height);
    
    // Draw base image.
    CGContextDrawImage(outputContext, self.view.frame, cgImage);
    
    // Apply white tint
    CGContextSaveGState(outputContext);
    CGContextSetFillColorWithColor(outputContext, [UIColor colorWithWhite:1 alpha:0.2].CGColor);
    CGContextFillRect(outputContext, self.view.frame);
    CGContextRestoreGState(outputContext);
    
    // Output image is ready.
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return outputImage;
}



-(void) maskWithImage:(UIImage*) maskImage TargetView:(UIView*) targetView{
    CALayer *_maskingLayer = [CALayer layer];
    _maskingLayer.frame = targetView.bounds;
    [_maskingLayer setContents:(id)[maskImage CGImage]];
    [targetView.layer setMask:_maskingLayer];
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
    
    
    self.currentImage = [self UIImageFromCVMat:image];
    //[self cropByTarget:nil];
}

- (void) cropByTarget:(void(^)(UIImage *image))completion{
    UIImage *image = self.currentImage;
    CGRect wrapperRect = self.recognizeWrapper.frame;
    CGRect frameRect = self.recognizeTarget.frame;
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
    
//    dispatch_sync(dispatch_get_main_queue(), ^{
//        //self.resultImageView.image = cropedImg;
//        self.targetImageView.image = cropedImg;
//    });
    
    // Apply openCV effect
    cropedImg = [self UIImageFromCVMat:[self imageScanableProcessing:[self cvMatFromUIImage:cropedImg]]];
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        self.targetImageView.image = cropedImg;
        [self setupProgressbar:cropedImg];
        
    });
    
    if (completion!=nil) {
        completion(cropedImg);
    }

}

-(void) setupProgressbar:(UIImage *)image{
    CGRect r = CGRectMake(0, 0, image.size.width, image.size.height);
    CAShapeLayer* lay = [CAShapeLayer layer];
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, nil, r);
    lay.path = path;
    CGPathRelease(path);
    lay.fillRule = kCAFillRuleEvenOdd;
    
    self.targetImageView.layer.mask = lay;
}

-(void) updateProgress:(CGFloat)percent {
    CGRect imageRect = CGRectMake(0, 0, self.targetImageView.image.size.width, self.targetImageView.image.size.height);
    //CGFloat currentX = (imageRect.size.width) * percent;
    imageRect.origin.x = 200;//currentX;
    self.targetImageView.layer.mask.frame = imageRect;
}

- (void) doRecognition:(UIImage*)image{
    UIImage *bwImage = [image g8_blackAndWhite];
    G8RecognitionOperation *operation = [[G8RecognitionOperation alloc]initWithLanguage:@"eng"];
    operation.tesseract.maximumRecognitionTime = 10.0;
    //operation.tesseract.engineMode = G8OCREngineModeTesseractCubeCombined;
    //operation.tesseract.pageSegmentationMode = G8PageSegmentationModeSingleLine;
    
    operation.delegate = self;
    operation.tesseract.image = bwImage;
    //operation.tesseract.charWhitelist = @"0123456789";
    operation.tesseract.charWhitelist = @"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    //operation.tesseract.charBlacklist = @".|\\/,';:`~-_^";
    self.isRecognizing = YES;
    
    operation.recognitionCompleteBlock = ^(G8Tesseract *tesseract) {
        // Fetch the recognized text
        NSString *recognizedText = tesseract.recognizedText;
        NSLog(@"recognizedText= %@", recognizedText);
        self.resultLabel.text = recognizedText;
        self.targetImageView.image = nil;
        self.targetImageView.layer.mask = nil;
        
        [G8Tesseract clearCache];
        self.isRecognizing = NO;
    };
    [self.operationQueue addOperation:operation];
}


- (IBAction)onRecognize:(id)sender {
    
    SystemSoundID soundID;
    NSURL *buttonURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"snap" ofType:@"wav"]];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)buttonURL, &soundID);
    AudioServicesPlaySystemSound(soundID);
    
    dispatch_async(self.cropImageQueue, ^{
        [self fillRargetImage];
        [self cropByTarget:^(UIImage *image) {
            [self doRecognition:image];
        }];
    });
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


- (IBAction)onZoomChange:(id)sender {
   [self cameraZoom:self.zoomSlider.value];
}

- (void) fillRargetImage {
    self.targetImageView.frame = CGRectMake(0, 0, self.recognizeTarget.frame.size.width, self.recognizeTarget.frame.size.height);
}
- (IBAction)onPan:(UIPanGestureRecognizer *)sender {
    if (self.isRecognizing) {
        return;
    }
    
    CGPoint loc = [sender locationInView:self.cameraImageView];
    if(sender.state == UIGestureRecognizerStateBegan){
        self.startPanLoc = loc;
    }else if(sender.state == UIGestureRecognizerStateChanged){
        int invertX = self.startPanLoc.x > self.recognizeTarget.center.x ? 1: -1;
        int invertY = self.startPanLoc.y > self.recognizeTarget.center.y ? 1: -1;
        CGFloat scalex = invertX*(loc.x - self.startPanLoc.x)/10; //loc.x - self.startPanLoc.x > 1 ? 3: -3;
        CGFloat scaley = invertY*(loc.y - self.startPanLoc.y)/10; //loc.y - self.startPanLoc.y> 1 ? 3:-3;
 
        CGRect newFrame = self.recognizeTarget.frame;
        CGPoint center =  self.recognizeTarget.center;
        newFrame.size.width = MIN(newFrame.size.width + scalex, 290);
        newFrame.size.height = MIN(newFrame.size.height + scaley, 250);
        newFrame.size.width = MAX(newFrame.size.width + scalex, 100);
        newFrame.size.height = MAX(newFrame.size.height + scaley, 40);
        
        self.recognizeTarget.frame = newFrame;
        self.recognizeTarget.center = center;
        
        if (newFrame.size.height < 80){
            self.recognizeTarget.layer.cornerRadius = 35 * newFrame.size.height/80;
        }
        
//        NSArray * devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
//        AVCaptureDevice *videoDevice;
//        
//        NSError *error = nil;
//        for ( AVCaptureDevice * device in devices )
//        {
//            if ( AVCaptureDevicePositionBack == [ device position ] )
//            {
//                videoDevice = device;
//            }
//        }
//        if ([videoDevice lockForConfiguration:&error]) {
//            if(videoDevice.videoZoomFactor + scalex < 2  && videoDevice.videoZoomFactor > 1){
//                videoDevice.videoZoomFactor = videoDevice.videoZoomFactor + scalex;
//            }
//            [videoDevice unlockForConfiguration];
//        }else {
//            NSLog(@"error: %@", error);
//        }
        
        
        //[self updateMask];
    }else if(sender.state == UIGestureRecognizerStateEnded){
        [self fillRargetImage];
    }
}
#pragma mark - G8Tesseract

- (void)progressImageRecognitionForTesseract:(G8Tesseract *)tesseract {

    //NSLog(@"progress: %lu", (unsigned long)tesseract.progress);
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self updateProgress:(unsigned long)tesseract.progress / 100.0];
   });
}

#pragma mark - CV tools

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

-(std::vector<cv::Rect>) detectLetters:(cv::Mat)img{
    std::vector<cv::Rect> boundRect;
    cv::Mat img_gray, img_sobel, img_threshold, element;
    cvtColor(img, img_gray, CV_BGR2GRAY);
    cv::Sobel(img_gray, img_sobel, CV_8U, 1, 0, 3, 1, 0, cv::BORDER_DEFAULT);
    cv::threshold(img_sobel, img_threshold, 0, 255, CV_THRESH_OTSU+CV_THRESH_BINARY);
    element = getStructuringElement(cv::MORPH_RECT, cv::Size(17, 3) );
    cv::morphologyEx(img_threshold, img_threshold, CV_MOP_CLOSE, element);
    std::vector< std::vector< cv::Point> > contours;
    cv::findContours(img_threshold, contours, 0, 1);
    std::vector<std::vector<cv::Point> > contours_poly( contours.size() );
    for( int i = 0; i < contours.size(); i++ ){
        if (contours[i].size()>100)
        {
            cv::approxPolyDP( cv::Mat(contours[i]), contours_poly[i], 3, true );
            cv::Rect appRect( boundingRect( cv::Mat(contours_poly[i]) ));
            if (appRect.width>appRect.height)
                boundRect.push_back(appRect);
        }
    }
    return boundRect;
}


// Ref: http://docs.opencv.org/doc/tutorials/ios/image_manipulation/image_manipulation.html
-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

// Ref: http://docs.opencv.org/doc/tutorials/ios/image_manipulation/image_manipulation.html
- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

@end
