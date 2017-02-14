//
//  MLViewController.h
//  Object_Tracking
//
//  Created by Yongyang Nie on 11/27/16.
//  Copyright © 2016 Yongyang Nie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MLManager.h"
#import "MSERManager.h"
#import "ImageUtils.h"
#import "MLViewControllerDelegate.h"

@interface MLViewController : UITableViewController

@property (strong, nonatomic) NSMutableArray *imageArray;
@property (strong, nonatomic) NSMutableArray *results;
@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) UIImage *mserImage;
@property (retain, nonatomic) id delegate;

@end
