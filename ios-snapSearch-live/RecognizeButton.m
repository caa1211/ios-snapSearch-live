//
//  RecognizeButton.m
//  ios-snapSearch-live
//
//  Created by Carter Chang on 7/20/15.
//  Copyright (c) 2015 Carter Chang. All rights reserved.
//

#import "RecognizeButton.h"
#import "NSString+FontAwesome.h"

@implementation RecognizeButton

-(void) setRecognizeMode:(BOOL)recognizeMode {
    _recognizeMode = recognizeMode;
    if(_recognizeMode){
        [self setToRecognizeStyle];
    }else{
        [self setToCancelStyle];
    }
}

- (void)layoutSubviews {
    
    [super layoutSubviews];
    
    // Everytime to set cornerRadius will cause layoutSubviews,
    // so add below check for avoid infinite loop
    if (self.cornerRadius == self.frame.size.width / 2) {
        return;
    }
    
    [self setToRecognizeStyle];
    self.cornerRadius = self.frame.size.width / 2;
    self.rippleFromTapLocation = NO;
    self.isRaised = YES;
    self.rippleBeyondBounds = YES;
    self.loweredShadowOffset = CGSizeMake(0, -1);
    self.liftedShadowOffset = CGSizeMake(0, 0);
    self.tapCircleDiameter = MAX(self.frame.size.width, self.frame.size.height) * 8;
    self.titleLabel.font = [UIFont fontWithName:@"FontAwesome" size:88];
    [self setTitle:[NSString fontAwesomeIconStringForIconIdentifier:@"fa-bullseye"] forState:UIControlStateNormal];
}

-(void)setToCancelStyle {
    //[self setTitle:[NSString fontAwesomeIconStringForIconIdentifier:@"fa-times-circle-o"] forState:UIControlStateNormal];
    [self setTitleColor:[UIColor colorWithRed:0.223 green:0.402 blue:0.547 alpha:1.000] forState:UIControlStateNormal];
    self.tapCircleColor = [UIColor colorWithRed:0.964 green:0.951 blue:1.000 alpha:0.300];
}

-(void)setToRecognizeStyle {
    [self setTitleColor:[UIColor colorWithRed:0.908 green:0.472 blue:0.324 alpha:1.000] forState:UIControlStateNormal];
    self.tapCircleColor = [UIColor colorWithRed:1.000 green:0.672 blue:0.532 alpha:0.300];
}



@end
