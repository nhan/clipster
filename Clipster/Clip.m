//
//  Clip.m
//  Clipster
//
//  Created by Anthony Sherbondy on 4/7/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "Clip.h"
#import <Parse/PFObject+Subclass.h>


@implementation Clip
+ (NSString *)parseClassName {
    return @"Clip";
}

@dynamic text;
@dynamic isFavorite;
@dynamic videoId;
@dynamic timeStart;
@dynamic timeEnd;
@dynamic thumbnail;
@dynamic username;

- (NSString *)formattedTimestamp
{
    NSInteger startSeconds = self.timeStart/1000;
    NSInteger startMinutes = startSeconds/60;
    NSInteger startRemainingSeconds = startSeconds - (startMinutes*60);
    
    NSInteger endSeconds = self.timeEnd/1000;
    NSInteger endMinutes = endSeconds/60;
    NSInteger endRemainingSeconds = endSeconds - (endMinutes*60);
    
    return [NSString stringWithFormat:@"%d:%02d - %d:%02d", startMinutes, startRemainingSeconds, endMinutes, endRemainingSeconds];
}

- (void)setUser:(User *)user
{
    self.username = user.username;
    [self setObject:user forKey:@"user"];
}

- (User*)user
{
    return [self objectForKey:@"user"];
}

- (BOOL)isPublished
{
    return !!self.text;
}

+ (void)searchClipsWithQuery:(NSString *)queryString completionHandler:(void (^)(NSArray *, NSError *))completionHandler
{
    PFQuery *query = [Clip query];
    [query whereKey:@"text" containsString:queryString];
    [query findObjectsInBackgroundWithBlock:^(NSArray *clips, NSError *error) {
        completionHandler(clips, error);
    }];
}

+ (void)searchClipsForUsernames:(NSArray *)usernames completionHandler:(void (^)(NSArray *, NSError *))completionHandler
{
    PFQuery *query = [Clip query];
    [query whereKey:@"username" containedIn:usernames];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        completionHandler(objects, error);
    }];
}

+ (void)searchClipsForUsers:(NSArray *)users completionHandler:(void (^)(NSArray *, NSError *))completionHandler
{
    NSMutableArray *usernames = [[NSMutableArray alloc] init];
    for (User *user in users) {
        [usernames addObject:user.username];
    }
    [Clip searchClipsForUsernames:usernames completionHandler:completionHandler];
}

@end
