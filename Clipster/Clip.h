//
//  Clip.h
//  Clipster
//
//  Created by Anthony Sherbondy on 4/7/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import <Parse/Parse.h>
#import "User.h"

@interface Clip : PFObject<PFSubclassing>
+ (NSString *)parseClassName;
- (NSString *)formattedTimestamp;
- (NSString *)timeAgo;
- (NSString *)timeAgoExtended;
- (NSString *)duration;

@property (retain) User *user;
// duplicate so that we don't have to fetch the user all the time
@property (retain) NSString *username;
@property (retain) NSString *text;
@property (retain) NSString *canonicalText;
@property BOOL isFavorite;
@property BOOL eulaFlag;
@property (retain) NSString *videoId;
@property (retain) NSString *videoTitle;
@property (retain) NSMutableArray *likers;

// TODO: (nhan) consider changing the type for these to float / Float64
@property NSInteger timeStart;
@property NSInteger timeEnd;
@property (retain) PFFile *thumbnail;

- (BOOL)isPublished;
- (BOOL)isLikedByUser:(User *)user;

- (void)toggleLikeForClip:(Clip *)clip success:(void (^)(Clip *))success failure:(void (^)(NSError *))failure;

+ (NSString *)formatTimeWithSeconds:(NSInteger)seconds;

+ (void)searchClipsWithQuery:(NSString *)queryString completionHandler:(void(^)(NSArray *clips, NSError *error))completionHandler;
+ (void)searchClipsForUsers:(NSArray *)users completionHandler:(void(^)(NSArray *clips, NSError *error))completionHandler;
+ (void)searchClipsForUsernames:(NSArray *)usernames completionHandler:(void (^)(NSArray *, NSError *))completionHandler;

@end
