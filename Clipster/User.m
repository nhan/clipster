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

- (void)fetchFollowingWithCompletionHandler:(void (^)(NSArray *, NSError *))completionHandler
{
    PFQuery *query = [self.friends query];
    [query findObjectsInBackgroundWithBlock:^(NSArray *following, NSError *error) {
        completionHandler(following, error);
    }];
}

- (NSString *)timeAgo
{
    int secondsAgo = (int) [[NSDate date] timeIntervalSinceDate:self.createdAt];
    if (secondsAgo < 60){ //seconds
        return [NSString stringWithFormat:@"%d seconds", secondsAgo];
    } else if (secondsAgo < (60*60)){ //minutes
        return [NSString stringWithFormat:@"%d minutes", secondsAgo/60];
    } else if(secondsAgo < (60*60*24)) { // hours
        return [NSString stringWithFormat:@"%d hours", secondsAgo/(60*60)];
    } else { // days
        return [NSString stringWithFormat:@"%d days", secondsAgo/(60*60*24)];
    }
}

@end
