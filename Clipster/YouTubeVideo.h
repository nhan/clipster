//
//  YouTubeVideo.h
//  Clipster
//
//  Created by Anthony Sherbondy on 4/17/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GTLServiceYouTube.h>

@interface YouTubeVideo : NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *thumbnailURL;
@property (nonatomic, strong) NSString *videoId;

+ (NSArray *)videosFromSearchResults:(NSArray *)searchResults;
+ (GTLServiceYouTube *)youTubeService;
+ (void)searchVideosWithQuery:(NSString *)queryString completionHandler:(void(^)(NSArray *videos, NSError *error))completionHandler;
@end
