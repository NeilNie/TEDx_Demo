
//
//  ImageUtils.h
//  LogoDetector
//
//  Created by altaibayar tseveenbayar on 15/05/15.
//  Copyright (c) 2015 altaibayar tseveenbayar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#include <opencv2/opencv.hpp>

@interface ImageUtils : NSObject

extern const cv::Scalar RED;
extern const cv::Scalar GREEN;
extern const cv::Scalar BLUE;
extern const cv::Scalar BLACK;
extern const cv::Scalar WHITE;
extern const cv::Scalar YELLOW;
extern const cv::Scalar LIGHT_GRAY;

+ (cv::Mat) cvMatFromUIImage: (NSImage *) image;
+ (cv::Mat) cvMatGrayFromUIImage: (NSImage *)image;

+ (NSImage *) UIImageFromCVMat: (cv::Mat)cvMat;

+ (cv::Mat) mserToMat: (std::vector<cv::Point> *) mser;

+ (void) drawMser: (std::vector<cv::Point> *) mser intoImage: (cv::Mat *) image withColor: (cv::Scalar) color;

+ (std::vector<cv::Point>) maxMser: (cv::Mat *) gray;

@end
