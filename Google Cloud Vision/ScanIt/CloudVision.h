//
//  CloudVision.h
//  TEDx_GCV_Demo
//
//  Created by Yongyang Nie on 12/28/16.
//  Copyright © 2016 Yongyang Nie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

typedef enum {
    CVMLabel = 0,
    CVMFace,
    CVMText,
} CloudVisionMode;

@interface CloudVision : NSObject

@property CloudVisionMode mode;
@property (strong, nonatomic) NSMutableArray *result;
@property (strong, nonatomic) id delegate;

#pragma mark - Methods

- (void) beginAnalysis: (NSString*)imageData;
+ (NSString *) base64EncodeImage: (UIImage*)image;

@end

@protocol CloudVisionDelegate <NSObject>

-(void)completedRequestWithResponse:(NSMutableArray *)response;
-(void)requestHasError:(NSString *)error;

@end
