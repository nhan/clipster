//
//  UserCell.m
//  Clipster
//
//  Created by Nathan Speller on 4/24/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "UserCell.h"

@implementation UserCell

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setUser:(User *)user{
    _user = user;
    [self refreshUI];
}

- (void)refreshUI{
    self.usernameLabel.text = self.user.username;
    self.userDetailsLabel.text = [NSString stringWithFormat:@"Joined %@ ago", self.user.timeAgo];

    [self.userThumbnail setClipsToBounds:YES];
    self.userThumbnail.layer.cornerRadius = self.userThumbnail.frame.size.width/2;
    self.userThumbnail.layer.masksToBounds = YES;
    
    
    if (self.user.thumbnail) {
        self.userThumbnail.file = self.user.thumbnail;
        [self.userThumbnail loadInBackground];
    }
}

@end
