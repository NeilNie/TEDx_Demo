
//
//  CameraViewController.h
//  LogoDetector
//
//  License:
//  You may not copy, redistribute, use without quoting the author.
//  By using this file, you agree to the following LICENSE:
//  https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode


#import <UIKit/UIKit.h>
#import <opencv2/highgui/cap_ios.h>
#import "MSERManager.h"
#import "MLManager.h"
#import "ImageUtils.h"

#ifdef DEBUG
#import "FPS.h"
#endif

@interface CameraViewController : UIViewController < CvVideoCameraDelegate >

@property (weak, nonatomic) IBOutlet UIImageView *img;

@end
