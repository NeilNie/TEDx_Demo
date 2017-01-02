//
//  ViewController.h
//  ScanIt
//
//  Created by Yongyang Nie on 3/11/16.
//  Copyright © 2016 Yongyang Nie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iOSUILib/MDButton.h"
#import "PCAngularActivityIndicatorView.h"
#import "DetailViewController.h"
#import "AAPLPreviewView.h"

@import Photos;

typedef NS_ENUM( NSInteger, AVCamSetupResult ) {
    AVCamSetupResultSuccess,
    AVCamSetupResultCameraNotAuthorized,
    AVCamSetupResultSessionConfigurationFailed
};

typedef NS_ENUM( NSInteger, CVScanMode ) {
    CVScanModeLabel,
    CVScanModeText,
    CVScanModeQR
};

@interface ScanViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MDButtonDelegate, CloudVisionDelegate>{
    
    PCAngularActivityIndicatorView *activityIndicator;
    NSArray *array;
    UIImage *pickedImage;
    UIImage *imagePath;
}
// For use in the storyboards.
@property (weak, nonatomic) IBOutlet UITextView *resultTextView;
@property (nonatomic, weak) IBOutlet UIButton *cameraButton;
@property (weak, nonatomic) IBOutlet MDButton *btMore;
@property (weak, nonatomic) IBOutlet MDButton *btLabel;
@property (weak, nonatomic) IBOutlet MDButton *btText;
@property (weak, nonatomic) IBOutlet UILabel *indicationLb;

@property (nonatomic, weak) IBOutlet AAPLPreviewView *previewView;
@property (nonatomic, weak) IBOutlet UIButton *stillButton;
@property (strong, nonatomic) CloudVision *cloudVision;

@end
