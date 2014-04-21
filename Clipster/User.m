//
//  User.m
//  Clipster
//
//  Created by Anthony Sherbondy on 4/7/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "User.h"
#import <Parse/PFObject+Subclass.h>

//@interface User ()
//@property (nonatomic, strong) NSArray *cachedFriends;
//@end

@implementation User
@dynamic friends;
@dynamic thumbnail;

+ (void)searchUsersWithQuery:(NSString *)queryString completionHandler:(void (^)(NSArray *, NSError *))completionHandler
{
    PFQuery *query = [User query];
    [query whereKey:@"username" containsString:queryString];
    [query findObjectsInBackgroundWithBlock:^(NSArray *users, NSError *error) {
        completionHandler(users, error);
    }];
}

- (void)fetchFriendsWithCompletionHandler:(void (^)(NSArray *, NSError *))completionHandler
{
    PFQuery *query = [self.friends query];
    [query findObjectsInBackgroundWithBlock:^(NSArray *friends, NSError *error) {
        completionHandler(friends, error);
    }];
    
//    if (self.cachedFriends) {
//        completionHandler(self.cachedFriends, nil);
//    } else {
//        PFQuery *query = [self.friends query];
//        [query findObjectsInBackgroundWithBlock:^(NSArray *friends, NSError *error) {
//            self.cachedFriends = friends;
//            completionHandler(friends, error);
//        }];
//    }
}

@end
