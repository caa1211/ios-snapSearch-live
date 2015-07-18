//
//  ActionButtonGroup.m
//  ios-snapSearch-live
//
//  Created by Carter Chang on 7/18/15.
//  Copyright (c) 2015 Carter Chang. All rights reserved.
//

#import "ActionButtonGroup.h"
#import <BFPaperButton.h>
#import <UIColor+BFPaperColors.h>
#import "NSString+FontAwesome.h"

@implementation ActionButtonGroup

- (void)layoutSubviews {
    [super layoutSubviews];
    [self setupActionButtons];
}

-(void) setupActionButtons {
    CGRect parentRect = self.bounds;
    
    self.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
    self.layer.shadowRadius = 2.0f;
    self.layer.shadowOpacity = 0.5;
    
    BFPaperButton *ecBtn = [[BFPaperButton alloc] initWithFrame:CGRectMake(0, 0, parentRect.size.width/2, parentRect.size.height/2) raised:NO];
    ecBtn.titleLabel.font = [UIFont fontWithName:@"FontAwesome" size:28];
    [ecBtn setTitle:[NSString fontAwesomeIconStringForIconIdentifier:@"fa-shopping-cart"] forState:UIControlStateNormal];
    ecBtn.backgroundColor = [UIColor colorWithRed:0.447 green:0.580 blue:0.555 alpha:1.000];
    [ecBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [ecBtn addTarget:self action:@selector(onECBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:ecBtn];
    
    BFPaperButton *searchBtn = [[BFPaperButton alloc] initWithFrame:CGRectMake(parentRect.size.width/2, 0, parentRect.size.width/2, parentRect.size.height/2) raised:NO];
    searchBtn.titleLabel.font = [UIFont fontWithName:@"FontAwesome" size:28];
    [searchBtn setTitle:[NSString fontAwesomeIconStringForIconIdentifier:@"fa-search"] forState:UIControlStateNormal];
    searchBtn.backgroundColor = [UIColor colorWithRed:0.387 green:0.528 blue:0.529 alpha:1.000];
    [searchBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [searchBtn addTarget:self action:@selector(onSearchBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:searchBtn];
    
    BFPaperButton *dicthBtn = [[BFPaperButton alloc] initWithFrame:CGRectMake(0, parentRect.size.height/2, parentRect.size.width/2, parentRect.size.height/2) raised:NO];
    dicthBtn.titleLabel.font = [UIFont fontWithName:@"FontAwesome" size:28];
    [dicthBtn setTitle:[NSString fontAwesomeIconStringForIconIdentifier:@"fa-book"] forState:UIControlStateNormal];
    dicthBtn.backgroundColor = [UIColor colorWithRed:0.286 green:0.428 blue:0.455 alpha:1.000];
    [dicthBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [dicthBtn addTarget:self action:@selector(onDictBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:dicthBtn];
    
    BFPaperButton *copyBtn = [[BFPaperButton alloc] initWithFrame:CGRectMake(parentRect.size.width/2, parentRect.size.height/2, parentRect.size.width/2, parentRect.size.height/2) raised:NO];
    copyBtn.titleLabel.font = [UIFont fontWithName:@"FontAwesome" size:28];
    [copyBtn setTitle:[NSString fontAwesomeIconStringForIconIdentifier:@"fa-files-o"] forState:UIControlStateNormal];
    copyBtn.backgroundColor = [UIColor colorWithRed:0.223 green:0.361 blue:0.399 alpha:1.000];
    [copyBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [copyBtn addTarget:self action:@selector(onCopyBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:copyBtn];
}

-(void) onECBtnClick:(id)sender {
    //[self bringSubviewToFront:sender];
    NSLog(@"==========onECBtnClick================");
}

-(void) onCopyBtnClick:(id)sender {
   // [self bringSubviewToFront:sender];
    NSLog(@"===========onCopyBtnClick===============");
}

-(void) onDictBtnClick:(id)sender {
   // [self bringSubviewToFront:sender];
    NSLog(@"===========onDictBtnClick================");
}

-(void) onSearchBtnClick:(id)sender {
   // [self bringSubviewToFront:sender];
    NSLog(@"===========onSearchBtnClick================");
}

@end
