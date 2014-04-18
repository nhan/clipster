//
//  ProfileCell.m
//  Clipster
//
//  Created by Nathan Speller on 4/17/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "ProfileCell.h"

@interface ProfileCell ()
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@end

@implementation ProfileCell


- (void)setUser:(User *)user
{
    _user = user;
    [self refreshUI];
}

- (void)refreshUI
{
    self.usernameLabel.text = self.user.username;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
