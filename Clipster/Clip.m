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
@dynamic canonicalText;
@dynamic isFavorite;
@dynamic videoId;
@dynamic videoTitle;
@dynamic timeStart;
@dynamic timeEnd;
@dynamic thumbnail;
@dynamic username;

+ (NSString *)formatTimeWithSeconds:(NSInteger)seconds
{
    NSInteger minutes = seconds/60;
    NSInteger remainingSeconds = seconds - (minutes*60);
    return [NSString stringWithFormat:@"%d:%02d", minutes, remainingSeconds];
}

- (NSString *)formattedTimestamp
{
    return [NSString stringWithFormat:@"%@ - %@", [Clip formatTimeWithSeconds:self.timeStart/1000], [Clip formatTimeWithSeconds:self.timeEnd/1000]];
}

- (void)setText:(NSString *)text
{
    self.canonicalText = [text lowercaseString];
    [self setObject:text forKey:@"text"];
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
    NSString *canonicalQueryString = [queryString lowercaseString];
    [query whereKey:@"canonicalText" containsString:canonicalQueryString];
    [query findObjectsInBackgroundWithBlock:^(NSArray *clips, NSError *error) {
        completionHandler(clips, error);
    }];
}

+ (void)searchClipsForUsernames:(NSArray *)usernames completionHandler:(void (^)(NSArray *, NSError *))completionHandler
{
    PFQuery *query = [Clip query];
    [query orderByDescending:@"createdAt"];
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
