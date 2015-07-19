//
//  CVTools.h
//  ios-snapSearch-live
//
//  Created by Carter Chang on 7/19/15.
//  Copyright (c) 2015 Carter Chang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <opencv2/videoio/cap_ios.h>
using namespace cv;

@interface CVTools : NSObject
+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat;
+ (cv::Mat)cvMatFromUIImage:(UIImage *)image;
@end
