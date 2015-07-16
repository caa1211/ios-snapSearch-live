//
//  CVText.h
//  ios-caa-ocr
//
//  Created by Carter Chang on 7/15/15.
//  Copyright (c) 2015 Carter Chang. All rights reserved.
//

#ifndef __ios_caa_ocr__CVText__
#define __ios_caa_ocr__CVText__

#include <stdio.h>



#endif /* defined(__ios_caa_ocr__CVText__) */


#ifndef OpenCVT_CVText_h
#define OpenCVT_CVText_h

#import <opencv2/opencv.hpp>

class CVText {
    
public:
    static cv::Mat detectedTextInImage(cv::Mat image, float tol, int threshold, int levels, int accuracy);
};

#endif
