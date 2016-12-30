//
//  DetailView.m
//  Visionary
//
//  Created by Yongyang Nie on 3/12/16.
//  Copyright © 2016 Yongyang Nie. All rights reserved.
//

#import "DetailViewController.h"

@interface DetailViewController ()

@end

@implementation DetailViewController

#pragma UITableView Delegates

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.resultArray.count;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSString *string = [self.resultArray objectAtIndex:indexPath.row];
    
    if ([string length] < 40) {
        return 55;
    }else{
        int X = ((int)[string length] / 30) * 30 + 20;
        return X;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    ResultTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ResultCellID" forIndexPath:indexPath];
    NSDictionary *dic = [self.resultArray objectAtIndex:indexPath.row];
    cell.title.text = [dic objectForKey:@"label"];
    cell.percentage.text = [dic objectForKey:@"percentage"];
    
    cell.alpha = 0.8f;
    return cell;
}

-(void)showLabel{
    
    int constraint;
    if (_resultArray.count > 5) {
        constraint = 250;
    }else{
        constraint = 180;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [UIView animateWithDuration:1 animations:^{
            self.LabelConstraint.constant = constraint;
            [self.view layoutIfNeeded];
            
        }];
    });
}

- (IBAction)listView:(id)sender {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier:@"ShowTextView" sender:nil];
    });
    
}

#pragma mark - Life Cycle


- (void)viewDidLoad {
    
    self.LabelConstraint.constant = 0;
    self.ResultTable.backgroundColor = [UIColor clearColor];
    self.imageView.image = self.image;

    self.resultArray = [NSMutableArray array];
    
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
