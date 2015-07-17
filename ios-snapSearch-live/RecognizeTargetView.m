//
//  RecognizeTargetView.m
//  ios-snapSearch-live
//
//  Created by Carter Chang on 7/18/15.
//  Copyright (c) 2015 Carter Chang. All rights reserved.
//

#import "RecognizeTargetView.h"

@interface RecognizeTargetView ()

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
        self.layer.borderColor = CGColorRetain([UIColor colorWithRed:0.901 green:0.858 blue:0.859 alpha:1.000].CGColor);
        
        return self;
    }
    return nil;
}

- (void)layoutSubviews {
}

-(void) fillInnerImage {
   self.innerImageView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
}

-(void) setInnerImage:(UIImage *)image {
    self.innerImageView.image = image;
}

-(void) setupProgressbar:(UIImage *)image{
    CGRect r = CGRectMake(0, 0, image.size.width, image.size.height);
    CAShapeLayer* lay = [CAShapeLayer layer];
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, nil, r);
    lay.path = path;
    CGPathRelease(path);
    lay.fillRule = kCAFillRuleEvenOdd;
    
    self.innerImageView.layer.mask = lay;
}

-(void) updateProgress:(CGFloat)percent {
    CGRect imageRect = CGRectMake(0, 0, self.innerImageView.image.size.width, self.innerImageView.image.size.height);
    //CGFloat currentX = (imageRect.size.width) * percent;
    imageRect.origin.x = 200;//currentX;
    self.innerImageView.layer.mask.frame = imageRect;
}

-(void) finishProgress {
    self.innerImageView.image = nil;
    self.innerImageView.layer.mask = nil;
}


@end
