//
//  YoutubeParser.m
//  Clipster
//
//  Created by Nhan Nguyen on 4/25/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "YouTubeParser.h"
#import <HCYoutubeParser/HCYoutubeParser.h>

@implementation YouTubeParser
+ (void)videoURLWithYoutubeID:(NSString*)youtubeID done:(void(^)(NSURL *videoURL, NSError *error))done {
    if (youtubeID) {
        // TODO: think about what queue we should be running on
        dispatch_queue_t queue = dispatch_queue_create("YoutubeParser.backgroundqueue", 0);
        dispatch_async(queue, ^{
            NSDictionary *videoDictionary = [HCYoutubeParser h264videosWithYoutubeID:youtubeID];
            
            // TODO: We need to consider what our video quality strategy should be
            // not all qualities will be available at all time and what our connectivity is
            NSString *videoURL = nil;
            if (videoDictionary && videoDictionary.count > 0) {
                videoURL = videoDictionary[@"medium"];
                if (!videoURL) {
                    videoURL = [videoDictionary allValues][0];
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!videoURL) {
                    done(nil, [NSError errorWithDomain:@"YouTubeParser" code:1002 userInfo:@{ NSLocalizedDescriptionKey: @"This video cannot be played on mobile." }]);
                }

                done([NSURL URLWithString:videoURL], nil);
            });
        });
    } else {
        done(nil, [NSError errorWithDomain:@"YouTubeParser" code:1001 userInfo:@{ NSLocalizedDescriptionKey: @"Invalid YouTube Video ID" }]);
    }
}
@end
