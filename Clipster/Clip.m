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
// user
@dynamic timeStart;
@dynamic timeEnd;
@dynamic thumbnailURL;

- (NSString *)formattedTimestamp{
    NSInteger startSeconds = self.timeStart/1000;
    NSInteger startMinutes = startSeconds/60;
    NSInteger startRemainingSeconds = startSeconds - (startMinutes*60);
    
    NSInteger endSeconds = self.timeEnd/1000;
    NSInteger endMinutes = endSeconds/60;
    NSInteger endRemainingSeconds = endSeconds - (endMinutes*60);
    
    return [NSString stringWithFormat:@"%d:%02d - %d:%02d", startMinutes, startRemainingSeconds, endMinutes, endRemainingSeconds];
}

@end
