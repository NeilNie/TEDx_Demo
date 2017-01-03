
//
//  CameraViewController.m
//  LogoDetector
//
//  License:
//  You may not copy, redistribute, use without quoting the author.
//  By using this file, you agree to the following LICENSE:
//  https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode


#import "CameraViewController.h"

#define KEY_LEARNED @"KEY_LEARNED"

//this two values are dependant on defaultAVCaptureSessionPreset
#define W (480)
#define H (640)

@interface CameraViewController(){
    CvVideoCamera *camera;
    BOOL started;
}

@end

@implementation CameraViewController

- (void) viewDidLoad{
    
    [super viewDidLoad];
    
    //setup cv cam
}

//cvpressbutton

-(void)processImage:(cv::Mat &)image{
    
    //cvpsetup
    
    //cvpframe
    
    //cvpprocessing
    
    //cvlo
    
}

@end
