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
@property (weak, nonatomic) IBOutlet UIButton *followButton;
@end

@implementation ProfileCell


- (void)setUser:(User *)user
{
    _user = user;
    [self refreshUI];
}

- (void)setIsFriend:(BOOL)isFriend
{
    _isFriend = isFriend;
    [self refreshUI];
}

- (void)refreshUI
{
    self.usernameLabel.text = self.user.username;
    if (self.isFriend) {
        self.followButton.titleLabel.text = @"Unfollow";
    } else {
        self.followButton.titleLabel.text = @"Follow";
    }
    
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
