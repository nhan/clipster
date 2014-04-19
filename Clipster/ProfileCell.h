//
//  ProfileCell.h
//  Clipster
//
//  Created by Nathan Speller on 4/17/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

@interface ProfileCell : UITableViewCell
@property (strong, nonatomic) User *user;
@property (nonatomic, assign) BOOL isFriend;
@end
