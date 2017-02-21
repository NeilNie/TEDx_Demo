//
//  MLViewController.m
//  Object_Tracking
//
//  Created by Yongyang Nie on 11/27/16.
//  Copyright © 2016 Yongyang Nie. All rights reserved.
//

#import "MLViewController.h"

@interface MLViewController ()

@end

@implementation MLViewController

- (void) detectRegions: (cv::Mat &) gray intoVector: (std::vector<std::vector<cv::Point>> &) vector{
    mserDetector(gray, vector);
}

-(void)processImage:(UIImage *)templateImage{
    
    NSMutableArray *array = [NSMutableArray array];
    
    cv::Mat image = [ImageUtils cvMatFromUIImage:templateImage];
    
    cv::Mat testImage;
    cv::cvtColor(image, testImage, CV_BGR2GRAY);
    
    std::vector<std::vector<cv::Point>> contours;
    
    int delta = 5;                  //! delta, in the code, it compares (size_{i}-size_{i-delta})/size_{i-delta}
    int minArea = 60;               //! prune the area which bigger than maxArea
    int maxArea = 14400;            //! prune the area which smaller than minArea
    double maxVariation = 0.25;     //! prune the area have simliar size to its children
    double minDiversity = 0.2;      //! trace back to cut off mser with diversity < min_diversity
    int maxEvolution = 200;         //! for color image, the evolution steps
    double areaThreshold = 1.01;    //! the area threshold to cause re-initialize
    double minMargin = 0.003;       //! ignore too small margin
    int edgeBlurSize = 0;           //! the aperture size for edge blur
    
    mserDetector = cv::MserFeatureDetector(delta, minArea, maxArea,
                                           maxVariation, minDiversity, maxEvolution,
                                           areaThreshold, minMargin, edgeBlurSize
                                           );
    
    [self detectRegions:testImage intoVector:contours];
    
    for (int i = 0; i < contours.size(); i++) {
        MSERFeature *feature = [[MSERManager sharedInstance] extractFeature:&contours[i]];
        if (feature) {
            cv::Rect bound = cv::boundingRect(contours[i]);
            cv::rectangle(image, bound, CV_RGB(41, 257, 47));
            [array addObject:feature];
        }
    }
    
    self.processedImage = [ImageUtils UIImageFromCVMat:image];
}
 
- (void) learn: (UIImage *) templateImage{
    
    cv::Mat image = [ImageUtils cvMatFromUIImage: templateImage];
    
    //get gray image
    cv::Mat gray;
    cvtColor(image, gray, CV_BGRA2GRAY);
    
    //mser with maximum area is
    std::vector<cv::Point> maxMser = [ImageUtils maxMser: &gray];
    
    [MLManager sharedInstance].logoTemplate = [[MSERManager sharedInstance] extractFeature: &maxMser];
    [MLManager sharedInstance].logoTemplate.name = [self.imageArray objectAtIndex:[self.tableView indexPathForSelectedRow].row];
    
    //store the feature
    [[MLManager sharedInstance] storeTemplate];
    
    self.results = [[NSMutableArray alloc] init];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Learned Successfully"
                                                    message:@"The template have been learned"
                                                   delegate:nil
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:nil, nil];
                          
    [self.results addObject:[NSString stringWithFormat:@"number Of Holes %li", (long)[MLManager sharedInstance].logoTemplate.numberOfHoles]];
    [self.results addObject:[NSString stringWithFormat:@"convex Hull AreaRate: %f", [MLManager sharedInstance].logoTemplate.convexHullAreaRate]];
    [self.results addObject:[NSString stringWithFormat:@"min Rect Area Rate: %f", [MLManager sharedInstance].logoTemplate.minRectAreaRate]];
    [self.results addObject:[NSString stringWithFormat:@"contour Area Rate: %f", [MLManager sharedInstance].logoTemplate.skeletLengthRate]];
    [self.results addObject:[NSString stringWithFormat:@"skelet Length Rate: %f", [MLManager sharedInstance].logoTemplate.contourAreaRate]];
    
    [alert show];
    
    self.mserImage = [ImageUtils UIImageFromCVMat: [ImageUtils mserToMat:&maxMser]];
}

#pragma mark - UITableView Delegates

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    self.image = [UIImage imageNamed:[self.imageArray objectAtIndex:indexPath.row]];
    [self learn:[UIImage imageNamed:[self.imageArray objectAtIndex:indexPath.row]]];
    [[NSUserDefaults standardUserDefaults] setObject:[self.imageArray objectAtIndex:indexPath.row] forKey:@"imagename"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self processImage:self.image];
    [self.delegate updateImage:self.processedImage mser:self.mserImage learnResult:self.results];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.imageArray.count;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 45;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"idTableCell" forIndexPath:indexPath];
    cell.textLabel.text = [self.imageArray objectAtIndex:indexPath.row];
    return cell;
}

#pragma mark - Private

-(void)loadPreviousLearning{
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"imagename"]) {
        self.image = [UIImage imageNamed:[defaults objectForKey:@"imagename"]];
        
        cv::Mat image = [ImageUtils cvMatFromUIImage: self.image];
        
        //get gray image
        cv::Mat gray;
        cvtColor(image, gray, CV_BGRA2GRAY);
        
        //mser with maximum area is
        std::vector<cv::Point> maxMser = [ImageUtils maxMser: &gray];
        
        self.mserImage = [ImageUtils UIImageFromCVMat: [ImageUtils mserToMat:&maxMser]];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.imageArray = [[NSMutableArray alloc] init];
    [self.imageArray addObject:@"Cocacola Logo"];
    [self.imageArray addObject:@"Microsoft_logo"];
    [self.imageArray addObject:@"traffic_stop_sign"];
    [self.imageArray addObject:@"green-recycling-symbol"];
    [self.imageArray addObject:@"coke_bottle"];
    
    [self loadPreviousLearning];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
