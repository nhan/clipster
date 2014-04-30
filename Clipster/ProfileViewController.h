//
//  ProfileViewController.h
//  Clipster
//
//  Created by Nathan Speller on 4/17/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"
#import "ProfileCell.h"

@interface ProfileViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, ProfileCellDelegate, NSURLConnectionDelegate>
- (id)initWithUsername:(NSString *)username;
- (id)initWithUser:(User *)user;
@end
