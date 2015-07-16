//
//  CVViewController.m
//  ios-snapSearch-live
//
//  Created by Carter Chang on 7/16/15.
//  Copyright (c) 2015 Carter Chang. All rights reserved.
//

#import "CVViewController.h"
#import <opencv2/videoio/cap_ios.h>

using namespace cv;

@interface CVViewController () <CvVideoCameraDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *cameraImageView;
@property (weak, nonatomic) IBOutlet UIImageView *resultImageView;

@property (weak, nonatomic) IBOutlet UIView *recognizeTarget;
@property (retain, nonatomic) CvVideoCamera* videoCamera;
@property (retain, nonatomic) UIImage* currentImage;
@property (weak, nonatomic) IBOutlet UIView *recognizeWrapper;

@end

@implementation CVViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:self.cameraImageView];
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetHigh;
    self.videoCamera.defaultFPS = 15;
    self.videoCamera.grayscaleMode = NO;
    self.videoCamera.delegate = self;
    [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(startCamera) userInfo:nil repeats:NO];
}

-(void) startCamera {
    [self.videoCamera start];
}


- (void)processImage:(cv::Mat&)image
{
    // OpenCV convert to scanable mode
    // image = [self imageScanableProcessing:image];
    
    /*
    //DetectLetters
    std::vector<cv::Rect> letterBBoxes= [self detectLetters:image];
    for(int i=0; i< letterBBoxes.size(); i++){
        cv::rectangle(image,letterBBoxes[i],cv::Scalar(0,255,0),3,8,0);
    }
    */
    
    self.currentImage = [self UIImageFromCVMat:image];
    [self cropByTarget];
}

- (void) cropByTarget{
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
    
    // Apply openCV effect
    cropedImg = [self UIImageFromCVMat:[self imageScanableProcessing:[self cvMatFromUIImage:cropedImg]]];
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        self.resultImageView.image = cropedImg;
    });
}

- (IBAction)onRecognize:(id)sender {
    [self cropByTarget];
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


#pragma mark - CV tools

- (cv::Mat) imageScanableProcessing:(cv::Mat)image{
    
    cv::Mat image_copy;
    cvtColor(image, image_copy, CV_BGRA2BGR);
    image = image_copy;
    
    // Invert image
    bitwise_not(image, image_copy);
    image = image_copy;
    
    // Gray image (Need to markout gray image before enable DetectLetters)
    cvtColor(image, image_copy, CV_RGBA2GRAY);
    image = image_copy;
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
