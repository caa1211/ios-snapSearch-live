//
//  SettingViewController.h
//  ios-snapSearch-live
//
//  Created by Carter Chang on 7/21/15.
//  Copyright (c) 2015 Carter Chang. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SettingViewControllerDelegate <NSObject>

-(void) didChangeSetting;

@end

@interface SettingViewController : UIViewController
    @property (nonatomic, weak) id<SettingViewControllerDelegate>delegate;
@end
