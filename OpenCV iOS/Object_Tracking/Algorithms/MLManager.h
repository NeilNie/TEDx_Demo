//
//  MLManager.h
//  LogoDetector
//
//  Created By Yongyang Nie 11/20/2016
//  Copyright (c) 2016 Yongyang Nie. All rights reserved.
//  License:
//  You may not copy, redistribute, use without quoting the author.
//  By using this file, you agree to the following LICENSE:
//  https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "MSERFeature.h"

/*
 This singleton class wraps object recognition function
 */
@interface MLManager : NSObject

#pragma mark - Properties

@property (strong) NSDictionary *preference;

@property (strong, nonatomic) NSMutableArray <MSERFeature *> *templates;

@property (strong) MSERFeature *logoTemplate;

#pragma mark - Class methods

+ (MLManager *) sharedInstance;

+ (MLManager *) sharedInstanceWithPreference:(NSDictionary *)dic;

#pragma mark - Instance methods 

/*
 Stores feature from the biggest MSER in the templateImage
 */
- (void) learn: (UIImage *) templateImage;

/*
 Sum of differences between logo feature and given feature
 */
- (double) distance: (MSERFeature *) feature;

/*
 Returns true if the given feature is similar to the one learned from the template
 */
- (BOOL) isFeature: (MSERFeature *) feature thisMSER:(MSERFeature *)MserTemplate;

-(void)storeTemplate:(MSERFeature *)feature;

- (void) storeTemplate;

-(void)removeTemplate:(NSString *)name;

- (void) loadTemplate;

-(void)setPreference:(NSDictionary *)newPreference;

-(NSDictionary *)getPreference;

@end
