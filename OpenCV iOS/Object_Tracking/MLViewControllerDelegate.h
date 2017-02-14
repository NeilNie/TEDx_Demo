//
//  MLViewControllerDelegate.h
//  OpenCV_iOS
//
//  Created by Yongyang Nie on 2/13/17.
//  Copyright © 2017 Yongyang Nie. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MLViewControllerDelegate <NSObject>

@required
-(void)updateImage:(UIImage *)image mser:(UIImage *)mser learnResult:(NSMutableArray *)result;

@end
