//
//  Clip.h
//  Clipster
//
//  Created by Anthony Sherbondy on 4/7/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import <Parse/Parse.h>

@interface Clip : PFObject<PFSubclassing>
+ (NSString *)parseClassName;
- (NSString *)formattedTimestamp;

@property (retain) NSString *text;
@property BOOL isFavorite;
@property (retain) NSString *videoId;
// user
@property NSInteger timeStart;
@property NSInteger timeEnd;
@property (retain) PFFile *thumbnail;

- (BOOL)isPublished;
@end
