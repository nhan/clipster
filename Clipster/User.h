//
//  User.h
//  Clipster
//
//  Created by Anthony Sherbondy on 4/7/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import <Parse/Parse.h>

@interface User : PFUser


@property (retain) NSString *thumbnailURL;
@property (retain) NSString *name;
// following users

@end
