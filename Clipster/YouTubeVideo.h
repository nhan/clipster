//
//  YouTubeVideo.h
//  Clipster
//
//  Created by Anthony Sherbondy on 4/17/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YouTubeVideo : NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *thumbnailURL;
@property (nonatomic, strong) NSString *videoId;

+ (NSArray *)videosFromSearchResults:(NSArray *)searchResults;
@end
