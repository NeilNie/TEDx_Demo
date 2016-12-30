//
//  CloudVision.m
//  TEDx_GCV_Demo
//
//  Created by Yongyang Nie on 12/28/16.
//  Copyright © 2016 Yongyang Nie. All rights reserved.
//

#import "CloudVision.h"

@implementation CloudVision

/** some code excerpted from Google example project, source code and documentations **/
/** developers.google.com **/

#pragma mark - Google Cloud Vision API Keys

static NSString *const API_Key = @"AIzaSyDOn9QRmm2mA3rG2KL7lV4EOLb0YCYC2YI";
static NSString *const Google_URL = @"https://vision.googleapis.com/v1/images:annotate?key=";

#pragma mark - Class method

+ (NSString *) base64EncodeImage: (UIImage*)image {
    
    NSData *imagedata = UIImagePNGRepresentation(image);
    
    // Resize the image if it exceeds the 2MB API limit
    if ([imagedata length] > 2097152) {
        CGSize oldSize = [image size];
        CGSize newSize = CGSizeMake(800, oldSize.height / oldSize.width * 800);
        image = [CloudVision resizeImage: image toSize: newSize];
        imagedata = UIImagePNGRepresentation(image);
    }
    
    NSString *base64String = [imagedata base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    return base64String;
}

+ (UIImage *) resizeImage:(UIImage*)image toSize:(CGSize)newSize {
    
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark - Instance methods

- (void) beginAnalysis: (NSString*)imageData {
    
    // Create our request URL
    NSString *requestString = [NSString stringWithFormat:@"%@%@", Google_URL, API_Key];
    
    NSURL *url = [NSURL URLWithString: requestString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod: @"POST"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:[[NSBundle mainBundle] bundleIdentifier] forHTTPHeaderField:@"X-Ios-Bundle-Identifier"];
    
    // Build our API request
    NSString *type;
    
    switch (self.mode) {
        case 0:
            type = @"LABEL_DETECTION";
            break;
        case 1:
            type = @"TEXT_DETECTION";
            break;
        default:
            break;
    }
    
    NSDictionary *paramsDictionary =
    @{@"requests":@[
              @{@"image":
                    @{@"content":imageData},
                @"features":@[
                        @{@"type":[NSString stringWithFormat:@"%@", type],
                          @"maxResults":@10}]}]};
    NSLog(@"type %@", type);
    
    NSError *error;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:paramsDictionary options:0 error:&error];
    [request setHTTPBody: requestData];
    
    // Run the request on a imageView thread
    [self runRequestOnimageViewThread: request];
}

- (void)runRequestOnimageViewThread: (NSMutableURLRequest*) request {
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^ (NSData *data, NSURLResponse *response, NSError *error) {
        [self analyzeResults:data withMode:self.mode];
    }];
    [task resume];
}

- (void)analyzeResults: (NSData*)dataToParse withMode:(CloudVisionMode)mode{
    
    // Update UI on the main thread
    NSError *e = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:dataToParse options:kNilOptions error:&e];
    NSArray *responses = [json objectForKey:@"responses"];
    NSDictionary *responseData = [responses objectAtIndex: 0];
    NSDictionary *errorObj = [json objectForKey:@"error"];
    NSLog(@"%@", responses);

    // Check for errors
    if (errorObj) {
        NSString *errorString1 = @"Error code ";
        NSString *errorCode = [errorObj[@"code"] stringValue];
        NSString *errorString2 = @": ";
        NSString *errorMsg = errorObj[@"message"];
        [self.delegate requestHasError:[NSString stringWithFormat:@"%@%@%@%@", errorString1, errorCode, errorString2, errorMsg]];
        self.result = nil;
    }else{
        switch (self.mode) {
            case 0:
                [self LabelResultWithJson:responseData];
                break;
            case 1:
                [self TextResultWithJson:responseData];
                break;
            default:
                break;
        }
    }
}

#pragma mark - Private

-(void)LabelResultWithJson:(NSDictionary *)responseData{
    
    // Get label annotations
    NSDictionary *labelAnnotations = [responseData objectForKey:@"labelAnnotations"];
    NSInteger numLabels = [labelAnnotations count];
    
    self.result = [NSMutableArray array];
    
    if (numLabels > 0) {
        
        for (NSDictionary *label in labelAnnotations) {
            NSString *labelString = [label objectForKey:@"description"];
            NSString *number = [label objectForKey:@"score"];
            NSString *percent = [NSString stringWithFormat:@"%2.0f%%", [number floatValue] * 100];
            [self.result addObject:@{@"label": labelString,
                                     @"percentage": percent}];
        }
    } else {
        [self.result addObject:@{@"label": @"sorry, no result",
                                 @"percentage": @""}];
    }
    [self.delegate completedRequestWithResponse:self.result];
}

-(void)TextResultWithJson:(NSDictionary *)responseData{
    
    NSArray *textAnnotations = [responseData objectForKey:@"textAnnotations"];
    if (textAnnotations > 0) {
        self.result = [NSMutableArray arrayWithObject:[[textAnnotations objectAtIndex:0] objectForKey:@"description"]];
        
    } else
        self.result = [NSMutableArray arrayWithObject:@[@"Sorry, no result found"]];
    [self.delegate completedRequestWithResponse:self.result];
}

@end
