//
//  DetailView.h
//  Visionary
//
//  Created by Yongyang Nie on 3/12/16.
//  Copyright © 2016 Yongyang Nie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PCAngularActivityIndicatorView.h"
#import "TextViewController.h"
#import "PreferenceViewController.h"
#import "ResultTableViewCell.h"
#import "CloudVision.h"

@interface DetailViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>{
    
    PCAngularActivityIndicatorView *ActivityIndicator;
    NSString *ObjectString;
    NSString *TextViewText;
    
    BOOL isWeb;
}

@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) NSMutableArray *resultArray;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *LabelConstraint;
@property (weak, nonatomic) IBOutlet UITableView *ResultTable;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end
