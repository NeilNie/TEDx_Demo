//
//  ViewController.m
//  ScanIt
//
//  Created by Yongyang Nie on 3/11/16.
//  Copyright © 2016 Yongyang Nie. All rights reserved.
//

#import "ScanViewController.h"

static void * CapturingStillImageContext = &CapturingStillImageContext;
static void * SessionRunningContext = &SessionRunningContext;

@interface ScanViewController ()

// Utilities.
@property(nonatomic) CGPoint startPoint;

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic) CVScanMode ScanMode;
@property (nonatomic) AVCamSetupResult setupResult;
@property (nonatomic, getter=isSessionRunning) BOOL sessionRunning;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;

// Session management.
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;

@end

@implementation ScanViewController

#pragma mark - Private

-(void)animationActivityIndicator{
    
    activityIndicator = [[PCAngularActivityIndicatorView alloc] initWithActivityIndicatorStyle:PCAngularActivityIndicatorViewStyleLarge];
    activityIndicator.color = [UIColor whiteColor];
    activityIndicator.center = self.view.center;
    [self.view addSubview:activityIndicator];
    [activityIndicator startAnimating];
}

#pragma mark - CloudVision Delegate

-(void)requestHasError:(NSString *)error{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Opps, something went wrong" message:error preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alert animated:YES completion:^{
            NSLog(@"error: %@", error);
        }];
    });
}

-(void)completedRequestWithResponse:(NSMutableArray *)response{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (response.count >= 3) {
            self.resultTextView.text = [NSString stringWithFormat:@"%@\n%@\n%@\n", [response[0] objectForKey:@"label"],
                                        [response[1] objectForKey:@"label"],
                                        [response[2] objectForKey:@"label"]];
        }else if (response.count == 2){
            self.resultTextView.text = [NSString stringWithFormat:@"%@\n%@\n", [response[0] objectForKey:@"label"],
                                        [response[1] objectForKey:@"label"]];
        }else{
            self.resultTextView.text = [NSString stringWithFormat:@"%@", [response[0] objectForKey:@"label"]];
        }
        [activityIndicator stopAnimating];
    });
}

#pragma mark - KVO and Notifications

- (void)addObservers
{
    [self.session addObserver:self forKeyPath:@"running" options:NSKeyValueObservingOptionNew context:SessionRunningContext];
    [self.stillImageOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew context:CapturingStillImageContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self.videoDeviceInput.device];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:self.session];
    // A session can only run when the app is full screen. It will be interrupted in a multi-app layout, introduced in iOS 9,
    // see also the documentation of AVCaptureSessionInterruptionReason. Add observers to handle these session interruptions
    // and show a preview is paused message. See the documentation of AVCaptureSessionWasInterruptedNotification for other
    // interruption reasons.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionWasInterrupted:) name:AVCaptureSessionWasInterruptedNotification object:self.session];
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.session removeObserver:self forKeyPath:@"running" context:SessionRunningContext];
    [self.stillImageOutput removeObserver:self forKeyPath:@"capturingStillImage" context:CapturingStillImageContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( context == CapturingStillImageContext ) {
        BOOL isCapturingStillImage = [change[NSKeyValueChangeNewKey] boolValue];
        
        if ( isCapturingStillImage ) {
            dispatch_async( dispatch_get_main_queue(), ^{
                self.previewView.layer.opacity = 0.0;
                [UIView animateWithDuration:0.25 animations:^{
                    self.previewView.layer.opacity = 1.0;
                }];
            } );
        }
    }
    else if ( context == SessionRunningContext ) {
        BOOL isSessionRunning = [change[NSKeyValueChangeNewKey] boolValue];
        
        dispatch_async( dispatch_get_main_queue(), ^{
            // Only enable the ability to change camera if the device has more than one camera.
            self.stillButton.enabled = isSessionRunning;
        } );
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)subjectAreaDidChange:(NSNotification *)notification
{
    CGPoint devicePoint = CGPointMake( 0.5, 0.5 );
    [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

- (void)sessionRuntimeError:(NSNotification *)notification
{
    NSError *error = notification.userInfo[AVCaptureSessionErrorKey];
    NSLog( @"Capture session runtime error: %@", error );
    
    // Automatically try to restart the session running if media services were reset and the last start running succeeded.
    // Otherwise, enable the user to try to resume the session running.
    if ( error.code == AVErrorMediaServicesWereReset ) {
        dispatch_async( self.sessionQueue, ^{
            if ( self.isSessionRunning ) {
                [self.session startRunning];
                self.sessionRunning = self.session.isRunning;
            }
        } );
    }
}

- (void)sessionWasInterrupted:(NSNotification *)notification
{
    // In some scenarios we want to enable the user to resume the session running.
    // For example, if music playback is initiated via control center while using AVCam,
    // then the user can let AVCam resume the session running, which will stop music playback.
    // Note that stopping music playback in control center will not automatically resume the session running.
    // Also note that it is not always possible to resume, see -[resumeInterruptedSession:].
    BOOL showResumeButton = NO;
    
    // In iOS 9 and later, the userInfo dictionary contains information on why the session was interrupted.
    AVCaptureSessionInterruptionReason reason = [notification.userInfo[AVCaptureSessionInterruptionReasonKey] integerValue];
    NSLog( @"Capture session was interrupted with reason %ld", (long)reason );
    
    if ( reason == AVCaptureSessionInterruptionReasonAudioDeviceInUseByAnotherClient ||
        reason == AVCaptureSessionInterruptionReasonVideoDeviceInUseByAnotherClient ) {
        showResumeButton = YES;
    }
}

#pragma mark - UIImagePickerViewController Delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    pickedImage = info[UIImagePickerControllerOriginalImage];
    
    imagePath = info[UIImagePickerControllerReferenceURL];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [picker dismissViewControllerAnimated:YES completion:NULL];
        [self performSegueWithIdentifier:@"ShowDetail" sender:nil];
    });
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Actions

- (IBAction)selectPhoto:(UIButton *)sender {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:picker animated:YES completion:NULL];
    });
}

- (IBAction)snapStillImage:(id)sender
{
    dispatch_async( self.sessionQueue, ^{
        AVCaptureConnection *connection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
        AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.previewView.layer;
        
        // Update the orientation on the still image output video connection before capturing.
        connection.videoOrientation = previewLayer.connection.videoOrientation;
        
        // Flash set to Auto for Still Capture.
        [ScanViewController setFlashMode:AVCaptureFlashModeOff forDevice:self.videoDeviceInput.device];
        
        // Capture a still image.
        [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^( CMSampleBufferRef imageDataSampleBuffer, NSError *error ) {
            if ( imageDataSampleBuffer ) {
                // The sample buffer is not retained. Create image data before saving the still image to the photo library asynchronously.
                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                [PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
                    
                    // To preserve the metadata, we create an asset from the JPEG NSData representation.
                    // Note that creating an asset from a UIImage discards the metadata.
                    // In iOS 9, we can use -[PHAssetCreationRequest addResourceWithType:data:options].
                    
                    if ( [PHAssetCreationRequest class] ) {
                        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                            [[PHAssetCreationRequest creationRequestForAsset] addResourceWithType:PHAssetResourceTypePhoto data:imageData options:nil];
                        } completionHandler:^( BOOL success, NSError *error ) {
                            if (success) {
                                
                                pickedImage = [UIImage imageWithData:imageData];
                                self.cloudVision = [[CloudVision alloc] init];
                                self.cloudVision.mode = (int)self.ScanMode;
                                [self.cloudVision beginAnalysis:[CloudVision base64EncodeImage:pickedImage]];
                                self.cloudVision.delegate = self;
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self animationActivityIndicator];
                                });
                            }else{
                                NSLog( @"Error occurred while saving image to photo library: %@", error );
                            }
                        }];
                    }
                }];
            }
            else {
                NSLog( @"Could not capture still image: %@", error );
            }
        }];
    } );
}

- (IBAction)changeCamera:(id)sender
{
    self.cameraButton.enabled = NO;
    self.stillButton.enabled = NO;
    
    AVCaptureDevice *currentVideoDevice = self.videoDeviceInput.device;
    AVCaptureDevicePosition preferredPosition = AVCaptureDevicePositionUnspecified;
    AVCaptureDevicePosition currentPosition = currentVideoDevice.position;
    
    switch ( currentPosition )
    {
        case AVCaptureDevicePositionUnspecified:
        case AVCaptureDevicePositionFront:
            preferredPosition = AVCaptureDevicePositionBack;
            break;
        case AVCaptureDevicePositionBack:
            preferredPosition = AVCaptureDevicePositionFront;
            break;
    }
    
    AVCaptureDevice *videoDevice = [ScanViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:preferredPosition];
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
    
    [self.session beginConfiguration];
    
    // Remove the existing device input first, since using the front and back camera simultaneously is not supported.
    [self.session removeInput:self.videoDeviceInput];
    
    if ( [self.session canAddInput:videoDeviceInput] ) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:currentVideoDevice];
        
        [ScanViewController setFlashMode:AVCaptureFlashModeOff forDevice:videoDevice];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:videoDevice];
        
        [self.session addInput:videoDeviceInput];
        self.videoDeviceInput = videoDeviceInput;
    }
    else {
        [self.session addInput:self.videoDeviceInput];
    }
    
    [self.session commitConfiguration];
    
    self.cameraButton.enabled = YES;
    self.stillButton.enabled = YES;
}

- (IBAction)turnTorchOn:(id)sender{
    
    // check if flashlight available
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch]){
            
            [device lockForConfiguration:nil];
            if (device.torchMode == AVCaptureTorchModeOn) {
                [device setTorchMode:AVCaptureTorchModeOff];
            } else {
                [device setTorchMode:AVCaptureTorchModeOn];
            }
            [device unlockForConfiguration];
        }
    }
}

- (IBAction)focusAndExposeTap:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint devicePoint = [(AVCaptureVideoPreviewLayer *)self.previewView.layer captureDevicePointOfInterestForPoint:[gestureRecognizer locationInView:gestureRecognizer.view]];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeAutoExpose atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
}
- (IBAction)allClear:(id)sender {
    self.resultTextView.text = @"";
}

- (IBAction)details:(id)sender {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier:@"ShowDetail" sender:nil];
    });
}

#pragma mark - Device Configuration

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
    dispatch_async( self.sessionQueue, ^{
        AVCaptureDevice *device = self.videoDeviceInput.device;
        NSError *error = nil;
        if ( [device lockForConfiguration:&error] ) {
            // Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
            // Call -set(Focus/Exposure)Mode: to apply the new point of interest.
            if ( device.isFocusPointOfInterestSupported && [device isFocusModeSupported:focusMode] ) {
                device.focusPointOfInterest = point;
                device.focusMode = focusMode;
            }
            
            if ( device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode] ) {
                device.exposurePointOfInterest = point;
                device.exposureMode = exposureMode;
            }
            
            device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange;
            [device unlockForConfiguration];
        }
        else {
            NSLog( @"Could not lock device for configuration: %@", error );
        }
    } );
}

+ (void)setFlashMode:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device
{
    if ( device.hasFlash && [device isFlashModeSupported:flashMode] ) {
        NSError *error = nil;
        if ( [device lockForConfiguration:&error] ) {
            device.flashMode = flashMode;
            [device unlockForConfiguration];
        }
        else {
            NSLog( @"Could not lock device for configuration: %@", error );
        }
    }
}

+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = devices.firstObject;
    
    for ( AVCaptureDevice *device in devices ) {
        if ( device.position == position ) {
            captureDevice = device;
            break;
        }
    }
    return captureDevice;
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate method implementation

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    
    // Check if the metadataObjects array is not nil and it contains at least one object.
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        // Get the metadata object.
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            
            // If the found metadata is equal to the QR code metadata then update the status label's text,
            // stop reading and change the bar button item's title and the flag's value.
            // Everything is done on the main thread.
            //[_lblStatus performSelectorOnMainThread:@selector(setText:) withObject:[metadataObj stringValue] waitUntilDone:NO];
            [self performSelectorOnMainThread:@selector(stopReading) withObject:nil waitUntilDone:NO];
            
            self.sessionRunning = self.session.isRunning;
            
            // If the audio player is not nil, then play the sound effect.
            if (_audioPlayer) {
                [_audioPlayer play];
            }
        }
    }
}

-(void)stopReading{
    
    dispatch_async( self.sessionQueue, ^{
        if ( self.setupResult == AVCamSetupResultSuccess ) {
            [self.session stopRunning];
            [self removeObservers];
        }
    } );
}

-(void)setUpCam{
    
    // Disable UI. The UI is enabled if and only if the session starts running.
    self.stillButton.enabled = NO;
    
    // Create the AVCaptureSession.
    self.session = [[AVCaptureSession alloc] init];
    
    // Setup the preview view.
    self.previewView.session = self.session;
    
    // Communicate with the session and other session objects on this queue.
    self.sessionQueue = dispatch_queue_create( "session queue", DISPATCH_QUEUE_SERIAL );
    
    self.setupResult = AVCamSetupResultSuccess;
    
    // Check video authorization status. Video access is required and audio access is optional.
    // If audio access is denied, audio is not recorded during movie recording.
    switch ( [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] )
    {
        case AVAuthorizationStatusAuthorized:
        {
            // The user has previously granted access to the camera.
            break;
        }
        case AVAuthorizationStatusNotDetermined:
        {
            // The user has not yet been presented with the option to grant video access.
            // We suspend the session queue to delay session setup until the access request has completed to avoid
            // asking the user for audio access if video access is denied.
            // Note that audio access will be implicitly requested when we create an AVCaptureDeviceInput for audio during session setup.
            dispatch_suspend( self.sessionQueue );
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^( BOOL granted ) {
                if ( ! granted ) {
                    self.setupResult = AVCamSetupResultCameraNotAuthorized;
                }
                dispatch_resume( self.sessionQueue );
            }];
            break;
        }
        default:
        {
            // The user has previously denied access.
            self.setupResult = AVCamSetupResultCameraNotAuthorized;
            break;
        }
    }
    
    
    if (self.ScanMode == CVScanModeQR) {
        // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
        AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
        [self.session addOutput:captureMetadataOutput];
        
        // Create a new serial dispatch queue.
        dispatch_queue_t dispatchQueue;
        dispatchQueue = dispatch_queue_create("myQueue", NULL);
        [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
        [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
        
        // Start video capture.
        [self.session commitConfiguration];
        
    }else{
        
        // Setup the capture session.
        // In general it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
        // Why not do all of this on the main queue?
        // Because -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue
        // so that the main queue isn't blocked, which keeps the UI responsive.
        
        dispatch_async( self.sessionQueue, ^{
            if ( self.setupResult != AVCamSetupResultSuccess ) {
                return;
            }
            
            self.backgroundRecordingID = UIBackgroundTaskInvalid;
            NSError *error = nil;
            
            AVCaptureDevice *videoDevice = [ScanViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
            AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
            
            if ( ! videoDeviceInput ) {
                NSLog( @"Could not create video device input: %@", error );
            }
            
            [self.session beginConfiguration];
            
            if ( [self.session canAddInput:videoDeviceInput] ) {
                [self.session addInput:videoDeviceInput];
                self.videoDeviceInput = videoDeviceInput;
                
                dispatch_async( dispatch_get_main_queue(), ^{
                    
                    // Why are we dispatching this to the main queue?
                    // Because AVCaptureVideoPreviewLayer is the backing layer for AAPLPreviewView and UIView
                    // can only be manipulated on the main thread.
                    // Note: As an exception to the above rule, it is not necessary to serialize video orientation changes
                    // on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                    
                    // Use the status bar orientation as the initial video orientation. Subsequent orientation changes are handled by
                    // -[viewWillTransitionToSize:withTransitionCoordinator:].
                    
                    UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
                    AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
                    if ( statusBarOrientation != UIInterfaceOrientationUnknown ) {
                        initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
                    }
                    
                    AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.previewView.layer;
                    previewLayer.connection.videoOrientation = initialVideoOrientation;
                } );
            }
            else {
                NSLog( @"Could not add video device input to the session" );
                self.setupResult = AVCamSetupResultSessionConfigurationFailed;
            }
            
            AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
            AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
            
            if ( ! audioDeviceInput ) {
                NSLog( @"Could not create audio device input: %@", error );
            }
            
            if ( [self.session canAddInput:audioDeviceInput] ) {
                [self.session addInput:audioDeviceInput];
            }
            else {
                NSLog( @"Could not add audio device input to the session" );
            }
            
            AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
            if ( [self.session canAddOutput:stillImageOutput] ) {
                stillImageOutput.outputSettings = @{AVVideoCodecKey : AVVideoCodecJPEG};
                [self.session addOutput:stillImageOutput];
                self.stillImageOutput = stillImageOutput;
            }
            else {
                NSLog( @"Could not add still image output to the session" );
                self.setupResult = AVCamSetupResultSessionConfigurationFailed;
            }
            
            [self.session commitConfiguration];
        } );
    }
    
}

-(void)startRunningCamera{
    
    dispatch_async(self.sessionQueue, ^{
        switch (self.setupResult)
        {
            case AVCamSetupResultSuccess:
            {
                // Only setup observers and start the session running if setup succeeded.
                [self addObservers];
                [self.session startRunning];
                self.sessionRunning = self.session.isRunning;
                break;
            }
            case AVCamSetupResultCameraNotAuthorized:
            {
                dispatch_async( dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString( @"AVCam doesn't have permission to use the camera, please change privacy settings", @"Alert message when the user has denied access to the camera" );
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Visionary" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    // Provide quick access to Settings.
                    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"Settings", @"Alert button to open Settings" ) style:UIAlertActionStyleDefault handler:^( UIAlertAction *action ) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                    }];
                    [alertController addAction:settingsAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                } );
                break;
            }
            case AVCamSetupResultSessionConfigurationFailed:
            {
                dispatch_async( dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString( @"Unable to capture media", @"Alert message when something goes wrong during capture session configuration" );
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Visionary" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                } );
                break;
            }
        }
    } );
    
}

#pragma mark - MDButton

-(void)setUpButtons{
    
    self.btMore.mdButtonDelegate = self;
    self.btMore.rotated = NO;
    //invisible all related buttons
    self.btText.alpha = 0.f;
    self.btLabel.alpha = 0.f;
    
    _startPoint = CGPointMake(self.btMore.center.x - 18, self.btMore.center.y - 100);
    self.btLabel.center = _startPoint;
    self.btText.center = _startPoint;
    [self.btMore setImageSize:25.0f];
}

- (IBAction)btnClicked:(id)sender {
    
    if (sender == self.btMore) {
        self.btMore.rotated = NO; //reset floating finging button
        return;
    }
    if (sender == self.btText) {
        self.indicationLb.text = @"Smart OCR";
        self.ScanMode = CVScanModeText;
    }
    if (sender == self.btLabel) {
        self.indicationLb.text = @"Content and Labels";
        self.ScanMode = CVScanModeLabel;
    }
}

-(void)rotationStarted:(id)sender {
    
    if (self.btMore == sender){
        int padding = 90;
        CGFloat duration = 0.2f;
        if (!self.btMore.isRotated) {
            [UIView animateWithDuration:duration
                                  delay:0.0
                                options: (UIViewAnimationOptionAllowUserInteraction|UIViewAnimationCurveEaseOut)
                             animations:^{
                                 
                                 self.btText.alpha = 1;
                                 self.btText.transform = CGAffineTransformMakeScale(1.0,.5);
                                 self.btText.transform = CGAffineTransformConcat(CGAffineTransformMakeTranslation(0, +padding*3.2f), CGAffineTransformMakeScale(1.0, 1.0));
                                 
                                 self.btLabel.alpha = 1;
                                 self.btLabel.transform = CGAffineTransformMakeScale(1.0,.6);
                                 self.btLabel.transform = CGAffineTransformConcat(CGAffineTransformMakeTranslation(0, +padding*2.5f), CGAffineTransformMakeScale(1.0, 1.0));
                                 
                             } completion:^(BOOL finished) {}];
        } else {
            [UIView animateWithDuration:duration/2
                                  delay:0.0
                                options: kNilOptions
                             animations:^{
                                 self.btLabel.alpha = 0;
                                 self.btLabel.transform = CGAffineTransformMakeTranslation(0, 0);
                                 
                                 self.btText.alpha = 0;
                                 self.btText.transform = CGAffineTransformMakeTranslation(0, 0);
                             } completion:^(BOOL finished) {}];
        }
    }
}

#pragma mark - Life Cycle

-(void)viewDidAppear:(BOOL)animated{
    
    [self startRunningCamera];
    [super viewDidAppear:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
    dispatch_async( self.sessionQueue, ^{
        if ( self.setupResult == AVCamSetupResultSuccess ) {
            [self.session stopRunning];
            [self removeObservers];
        }
    } );
    [super viewDidDisappear:animated];
}

- (void)viewDidLoad {
    
    self.ScanMode = CVScanModeLabel;
    self.indicationLb.text = @"Content and Labels";
    [self setUpButtons];
    [self setUpCam];
    self.previewView.frame = self.view.frame;
    [super viewDidLoad];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue destinationViewController] isKindOfClass:[DetailViewController class]]) {
        DetailViewController *destination =(DetailViewController *)segue.destinationViewController;
        destination.resultArray = self.cloudVision.result;
        destination.image = pickedImage;
        
    }else if ([[segue destinationViewController] isKindOfClass:[TextViewController class]]){
        TextViewController *destination = (TextViewController *)segue.destinationViewController;
        destination.text = [self.cloudVision.result objectAtIndex:0];
    }
}

@end
