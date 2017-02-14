//
//  ProcessImageViewController.m
//  OpenCV_iOS
//
//  Created by Yongyang Nie on 2/13/17.
//  Copyright © 2017 Yongyang Nie. All rights reserved.
//

#import "ProcessImageViewController.h"

@implementation ProcessImageViewController


#pragma mark - MLViewControll Delegate

-(void)updateImage:(UIImage *)image mser:(UIImage *)mser learnResult:(NSMutableArray *)result{
    self.imageView.image = image;
    self.mserView.image = mser;
    self.result = result;
    [self.mlTable reloadData];
}

#pragma mark - UITableView Delegate

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellid" forIndexPath:indexPath];
    cell.textLabel.text = [self.result objectAtIndex:indexPath.row];
    return cell;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.result.count;
}
- (IBAction)dismiss:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
