//
//  DDChildCell.h
//  Yelp
//
//  Created by Carter Chang on 6/22/15.
//  Copyright (c) 2015 codepath. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DDChildCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *markIcon;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic, assign) BOOL isMarked;

-(IBAction)addMark;
-(IBAction)removeMark;

@end
