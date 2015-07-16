//
//  CVText.cpp
//  ios-caa-ocr
//
//  Created by Carter Chang on 7/15/15.
//  Copyright (c) 2015 Carter Chang. All rights reserved.
//

#include "CVText.h"

using namespace std;
using namespace cv;

static int thresh = 50, N = 11;
static float tolerance = 0.01;
static int accuracy = 0;

//adding declarations at top of file to allow public function (was main{}) at top
static void rectanglessss(const Mat& image, vector<vector<Point> >& squares);


std::vector<cv::Rect> detectLetters(cv::Mat img)
{
    std::vector<cv::Rect> boundRect;
    cv::Mat img_gray, img_sobel, img_threshold, element;
    cvtColor(img, img_gray, CV_BGR2GRAY);
    cv::Sobel(img_gray, img_sobel, CV_8U, 1, 0, 3, 1, 0, cv::BORDER_DEFAULT);
    cv::threshold(img_sobel, img_threshold, 0, 255, CV_THRESH_OTSU+CV_THRESH_BINARY);
    element = getStructuringElement(cv::MORPH_RECT, cv::Size(17, 3) );
    cv::morphologyEx(img_threshold, img_threshold, CV_MOP_CLOSE, element); //Does the trick
    std::vector< std::vector< cv::Point> > contours;
    cv::findContours(img_threshold, contours, 0, 1);
    std::vector<std::vector<cv::Point> > contours_poly( contours.size() );
    for( int i = 0; i < contours.size(); i++ )
        if (contours[i].size()>100)
        {
            cv::approxPolyDP( cv::Mat(contours[i]), contours_poly[i], 3, true );
            cv::Rect appRect( boundingRect( cv::Mat(contours_poly[i]) ));
            if (appRect.width>appRect.height)
                boundRect.push_back(appRect);
        }
    return boundRect;
}

//this public function performs the role of
//main{} in the original file
cv::Mat CVText::detectedTextInImage (cv::Mat image, float tol, int threshold, int levels, int acc)
{
    
    
    std::vector<cv::Rect> letterBBoxes=detectLetters(image);
    
    if (letterBBoxes.size() > 0) {
        cv::Rect rect = letterBBoxes[0];
        cv::Mat croppedRef(image, rect);
        cv::Mat cropped;
        croppedRef.copyTo(cropped);
        
        return cropped;
    }else{
        cv::Mat img;
        return img;
    }
    
//    vector<vector<Point> > squares;
//    
//    if( image.empty() )
//    {
//        cout << "CVSquares.m: Couldn't load " << endl;
//    }
//    
//    tolerance = tol;
//    thresh = threshold;
//    N = levels;
//    accuracy = acc;
//    
//    rectanglessss(image, squares);
//    
//    if (squares.size() > 0) {
//        vector<Point> points;
//        
//        points = squares[0];
//        
//        cv::Rect rect = boundingRect(squares[0]);
//        cv::Mat croppedRef(image, rect);
//        cv::Mat cropped;
//        croppedRef.copyTo(cropped);
//        
//        return cropped;
//    }
//    else {
//        cv::Mat img;
//        return img;
//    }
    
}


// returns sequence of squares detected on the image.
// the sequence is stored in the specified memory storage
//static void findSquares( const Mat& image, vector<vector<Point> >& squares )

static double angle( Point pt1, Point pt2, Point pt0 )
{
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    return (dx1*dx2 + dy1*dy2)/sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10);
}

static void rectanglessss(const Mat& image, vector<vector<Point> >& squares)
{
    squares.clear();
    
    // Convert to grayscale
    Mat gray;
    cvtColor(image, gray, CV_BGR2GRAY);
    
    // Use Canny instead of threshold to catch squares with gradient shading
    Mat bw;
    Canny(gray, bw, 0, 50, 5);
    
    // Find contours
    vector<vector<Point> > contours;
    findContours(bw.clone(), contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);
    
    vector<Point> approx;
    Mat dst = image.clone();
    
    for (int i = 0; i < contours.size(); i++)
    {
        // Approximate contour with accuracy proportional
        // to the contour perimeter
        approxPolyDP(Mat(contours[i]), approx, arcLength(Mat(contours[i]), true)*0.02, true);
        
        // Skip small or non-convex objects
        if (fabs(contourArea(contours[i])) < 100 || !isContourConvex(approx))
            continue;
        
        if (approx.size() == 4)
        {
            // Number of vertices of polygonal curve
            long vtc = approx.size();
            
            // Get the cosines of all corners
            vector<double> cos;
            for (int j = 2; j < vtc+1; j++)
                cos.push_back(angle(approx[j%vtc], approx[j-2], approx[j-1]));
            
            // Sort ascending the cosine values
            sort(cos.begin(), cos.end());
            
            // Get the lowest and the highest cosine
            double mincos = cos.front();
            double maxcos = cos.back();
            
            //cout << "Min. corner angle: " << mincos << "\n" << "Max. corner angle: " << maxcos << endl;
            
            if (vtc == 4 && mincos >= -0.2 && maxcos <= 0.5)
                squares.push_back(approx);
        }
    }
    
}