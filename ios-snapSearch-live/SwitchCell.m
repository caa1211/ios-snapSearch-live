//
//  SwitchCell.m
//  Yelp
//
//  Created by Carter Chang on 6/21/15.
//  Copyright (c) 2015 codepath. All rights reserved.
//

#import "SwitchCell.h"

@interface SwitchCell()

@property (weak, nonatomic) IBOutlet UISwitch *toggleSwitch;

- (IBAction)switchValueCHanged:(id)sender;

@end

@implementation SwitchCell

- (void)awakeFromNib {
    // Initialization code
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.clipsToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setOn:(BOOL)on {
    [self setOn:on animated:NO];
}

- (void) setOn:(BOOL)on animated:(BOOL)animated{
    _on = on;
    [self.toggleSwitch setOn:on animated:animated];
}

- (IBAction)switchValueCHanged:(id)sender {
    [self.delegate switchCell:self didUpdateValue:self.toggleSwitch.on];
}
@end
