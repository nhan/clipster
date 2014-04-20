//
//  User.m
//  Clipster
//
//  Created by Anthony Sherbondy on 4/7/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "User.h"
#import <Parse/PFObject+Subclass.h>

@implementation User
@dynamic friends;

+ (void)searchUsersWithQuery:(NSString *)queryString completionHandler:(void (^)(NSArray *, NSError *))completionHandler
{
    PFQuery *query = [User query];
    [query whereKey:@"username" containsString:queryString];
    [query findObjectsInBackgroundWithBlock:^(NSArray *users, NSError *error) {
        completionHandler(users, error);
    }];
}
@end
