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
        self.layer.borderColor = CGColorRetain([UIColor colorWithRed:0.437 green:0.401 blue:0.421 alpha:0.200].CGColor);
        
        return self;
    }
    return nil;
}

- (void)layoutSubviews {
}

-(void) startProgressbar {
    self.defaultBackgroundColor = self.view.backgroundColor;
    [self.view setBackgroundColor:[UIColor colorWithRed:0.167 green:0.379 blue:0.368 alpha:0.360]];
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
    NSTimeInterval duration = 0.2;
    [CATransaction begin];
    [CATransaction setValue:[NSNumber numberWithFloat:duration] forKey:kCATransactionAnimationDuration];
    self.innerImageView.layer.mask.position = CGPointMake(movement, 0);
    [CATransaction commit];
    
}

-(void) fillInnerImage {
   self.innerImageView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
}

-(void) setInnerImage:(UIImage *)image {
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
