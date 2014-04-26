//
//  YoutubeParser.h
//  Clipster
//
//  Created by Nhan Nguyen on 4/25/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YouTubeParser : NSObject
+ (void)videoURLWithYoutubeID:(NSString*)youtubeID done:(void(^)(NSURL *videoURL, NSError *error))done;
@end
