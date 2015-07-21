//
//  DDParentCell.m
//  Yelp
//
//  Created by Carter Chang on 6/22/15.
//  Copyright (c) 2015 codepath. All rights reserved.
//

#import "DDParentCell.h"
#import "NIKFontAwesomeIconFactory.h"
#import "NIKFontAwesomeIconFactory+iOS.h"
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@implementation DDParentCell

- (void)awakeFromNib {
    // Initialization code
    NIKFontAwesomeIconFactory *factory = [NIKFontAwesomeIconFactory tabBarItemIconFactory];
    [factory setColors:@[ UIColorFromRGB(0x007aff) ]];
    UIImage *downArrow = [factory createImageForIcon:NIKFontAwesomeIconAngleDown];
   
    self.arrowIcon.image = downArrow;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.clipsToBounds = YES;
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
