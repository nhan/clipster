//
//  UserCell.h
//  Clipster
//
//  Created by Nathan Speller on 4/24/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

@interface UserCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet PFImageView *userThumbnail;
@property (weak, nonatomic) IBOutlet UILabel *userDetailsLabel;
@property (nonatomic, strong) User *user;

- (void)setUser:(User *)user;
@end
