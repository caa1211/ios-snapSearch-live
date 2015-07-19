//
//  RecognizeTargetView.h
//  ios-snapSearch-live
//
//  Created by Carter Chang on 7/18/15.
//  Copyright (c) 2015 Carter Chang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RecognizeTargetView : UIView

@property (nonatomic, weak) IBOutlet UIView *view;
@property (weak, nonatomic) IBOutlet UIImageView *innerImageView;

-(void) fillInnerImage;
-(void) setInnerImage:(UIImage *)image;
-(void) startProgressbar;
-(void) updateProgress:(CGFloat)percent;
-(void) finishProgress;
@end
