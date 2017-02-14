//
//  ProcessImageViewController.h
//  OpenCV_iOS
//
//  Created by Yongyang Nie on 2/13/17.
//  Copyright © 2017 Yongyang Nie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MLViewControllerDelegate.h"

@interface ProcessImageViewController : UIViewController <MLViewControllerDelegate, UISplitViewControllerDelegate>

@property (strong, nonatomic) NSMutableArray *result;
@property (weak, nonatomic) IBOutlet UITableView *mlTable;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *mserView;
@property (nonatomic, weak) IBOutlet UINavigationItem *navBarItem;
@property (nonatomic, strong) UIPopoverController *popover;

@end
