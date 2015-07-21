//
//  RecognizeTargetView.m
//  ios-snapSearch-live
//
//  Created by Carter Chang on 7/18/15.
//  Copyright (c) 2015 Carter Chang. All rights reserved.
//

#import "RecognizeTargetView.h"

@interface RecognizeTargetView ()
@property(nonatomic, strong) UIColor* defaultBackgroundColor;
@end

@implementation RecognizeTargetView

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        NSString *className = NSStringFromClass([self class]);
        self.view = [[[NSBundle mainBundle] loadNibNamed:className owner:self options:nil] firstObject];
        [self addSubview:self.view];
        self.layer.cornerRadius = 35;
        self.layer.masksToBounds = YES;
        self.layer.borderWidth = 4.0f;
        self.layer.borderColor = CGColorRetain([UIColor colorWithRed:0.845 green:0.863 blue:0.860 alpha:0.580].CGColor);
        self.defaultBackgroundColor = self.view.backgroundColor;
        return self;
    }
    return nil;
}

- (void)layoutSubviews {
}

-(void) startProgressbar {
    [UIView animateWithDuration:0.2 animations:^{
        [self.view setBackgroundColor:[UIColor colorWithRed:0.872 green:0.630 blue:0.453 alpha:0.680]];
        [self.innerImageView setAlpha:1.0];
    }];
    CGRect progresMaskRect = CGRectMake(0, 0, self.innerImageView.bounds.size.width, self.innerImageView.bounds.size.height);
    CAShapeLayer* lay = [CAShapeLayer layer];
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, nil, progresMaskRect);
    lay.path = path;
    CGPathRelease(path);
    lay.fillRule = kCAFillRuleEvenOdd;
    self.innerImageView.layer.mask = lay;
}

-(void) updateProgress:(CGFloat)percent {
    int movement = percent * self.innerImageView.frame.size.width;
    [self progressAnimation:movement];
}

-(void)progressAnimation:(int) movement {
    NSTimeInterval duration = 0.1;
    [CATransaction begin];
    [CATransaction setValue:[NSNumber numberWithFloat:duration] forKey:kCATransactionAnimationDuration];
    self.innerImageView.layer.mask.position = CGPointMake(movement, 0);
    [CATransaction commit];
    
}

-(void) fillInnerImage {
   self.innerImageView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
}

-(void) setInnerImage:(UIImage *)image {
    [self.innerImageView setAlpha:0.0];
    self.innerImageView.image = image;
}

-(void) finishProgress {
    self.innerImageView.image = nil;
    self.innerImageView.layer.mask = nil;
    [UIView animateWithDuration:0.5 animations:^{
       [self.view setBackgroundColor:self.defaultBackgroundColor];
    }];
}


@end
