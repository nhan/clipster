//
//  User.h
//  Clipster
//
//  Created by Anthony Sherbondy on 4/7/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import <Parse/Parse.h>

@interface User : PFUser
@property (retain) PFRelation *friends;

+ (void)searchUsersWithQuery:(NSString *)queryString completionHandler:(void(^)(NSArray *users, NSError *error))completionHandler;
@end
