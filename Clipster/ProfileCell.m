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
    
    if (self.user == [User currentUser]) {
        // User's profile, follow button becomes button to edit profile
        [self.followButton setTitle:@"Edit" forState:UIControlStateNormal];
    } else {
        // follow/unfollow button
        if (self.isFriend) {
            [self.followButton setTitle:@"Unfollow" forState:UIControlStateNormal];
        } else {
            [self.followButton setTitle:@"Follow" forState:UIControlStateNormal];
        }
    }
}

- (IBAction)followButtonClicked:(id)sender
{
    if (self.user != [User currentUser]) {
        [self.delegate toggleFriendship:self.user];
    }
}


@end
