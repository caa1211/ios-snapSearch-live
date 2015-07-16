//
//  CVWrapper.m
//  OpenCVT
//
//  Created by Zel Marko on 19/02/15.
//  Copyright (c) 2015 Zel Marko. All rights reserved.
//

#import "CVWrapper.h"
#import "CVSquaresHeader.h"
#import "CVText.h"

#define TOLERANCE 0.3
#define THRESHOLD 50
#define LEVELS 9
#define ACCURACY 0

@implementation CVWrapper

//Creates a Mat image and pushes it through OpenCV to detect rectangles
+ (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer {
    
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    //uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    u_int8_t *baseAddress = (u_int8_t *)malloc(bytesPerRow * height);
    memcpy(baseAddress, CVPixelBufferGetBaseAddress(imageBuffer), bytesPerRow * height); 
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow , colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);

    UIImage *finalImage = [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationUp];
    
    free(baseAddress);
    CGImageRelease(newImage);
    
    cv::Mat matImage = [CVWrapper cvMatFromUIImage:finalImage];
    
    //matImage = CVSquaresHeader::detectedSquaresInImage(matImage, TOLERANCE, THRESHOLD, LEVELS, ACCURACY);
    
    matImage = CVText::detectedTextInImage(matImage, TOLERANCE, THRESHOLD, LEVELS, ACCURACY);

    
    if (matImage.data == NULL) {
        UIImage *nilImage = [[UIImage alloc] init];
        
        return nilImage;
    }
    else {
        UIImage *result = [CVWrapper UIImageFromCVMat:matImage];
        
        return result;
    }
    
}

+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
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

+ (cv::Mat)cvMatFromUIImage:(UIImage *)image
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


+ (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    //cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
    
    cv::Mat cvMat(rows, cols, CV_8UC4);

    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    cv::Mat grayMat;
    cv::cvtColor(cvMat, grayMat, CV_RGBA2GRAY);
    
    /*
    // text area detection ===
    cv::Mat img_gray, img_sobel, img_threshold, element;
    cv::Sobel(grayMat, img_sobel, CV_8U, 1, 0, 3, 1, 0, cv::BORDER_DEFAULT);
    cv::threshold(img_sobel, img_threshold, 0, 255, CV_THRESH_OTSU+CV_THRESH_BINARY);
    cv::morphologyEx(img_threshold, img_threshold, CV_MOP_CLOSE, element); //Does the trick
    */
    
    return grayMat;
}

+ (UIImage *)UIImageGrayFromUIImage:(UIImage *)image {
    cv::Mat cvMat = [self cvMatGrayFromUIImage:image];
    return [self UIImageFromCVMat:cvMat];
}


@end
