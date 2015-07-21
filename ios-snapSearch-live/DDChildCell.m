//
//  DDChildCell.m
//  Yelp
//
//  Created by Carter Chang on 6/22/15.
//  Copyright (c) 2015 codepath. All rights reserved.
//

#import "DDChildCell.h"
#import "NIKFontAwesomeIconFactory.h"
#import "NIKFontAwesomeIconFactory+iOS.h"
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


@interface DDChildCell ()
@property (strong, nonatomic) UIImage *markIconImg;
@property (strong, nonatomic) UIImage *noMarkIconImg;
@end


@implementation DDChildCell

-(IBAction)removeMark{
    self.isMarked = NO;
    [self setSelected:YES animated:YES];
}
-(IBAction) addMark {
    self.isMarked = YES;
    [self setSelected:YES animated:YES];
}

- (void)awakeFromNib {
    NIKFontAwesomeIconFactory *factory = [NIKFontAwesomeIconFactory tabBarItemIconFactory];
    [factory setColors:@[ UIColorFromRGB(0x007aff)]];
    self.markIconImg = [factory createImageForIcon:NIKFontAwesomeIconCheckCircleO];
    [factory setColors:@[ UIColorFromRGB(0xd4d4d4)]];
    self.noMarkIconImg = [factory createImageForIcon:NIKFontAwesomeIconCheckCircleO];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.isMarked = NO;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    if(self.isMarked){
        self.markIcon.image = self.markIconImg ;
    }else{
        self.markIcon.image = self.noMarkIconImg;
    }

    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

@end
