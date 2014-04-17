//
//  YouTubeVideo.m
//  Clipster
//
//  Created by Anthony Sherbondy on 4/17/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "YouTubeVideo.h"
#import <GTLYouTubeSearchResult.h>
#import <GTLYouTubeSearchResultSnippet.h>
#import <GTLYouTubeThumbnailDetails.h>
#import <GTLYouTubeThumbnail.h>
#import <GTLYouTubeResourceId.h>

@implementation YouTubeVideo

+ (NSArray *)videosFromSearchResults:(NSArray *)searchResults
{
    NSMutableArray *videos = [[NSMutableArray alloc] init];
    
    for (GTLYouTubeSearchResult *result in searchResults) {
        GTLYouTubeSearchResultSnippet *snippet = result.snippet;
        GTLYouTubeThumbnailDetails *thumbnails = snippet.thumbnails;
        GTLYouTubeResourceId *identifier = result.identifier;
    
        YouTubeVideo *video = [[YouTubeVideo alloc] init];
        video.title = snippet.title;
        // probably need to check what thumbnails are available
        video.thumbnailURL = thumbnails.medium.url;
        video.videoId = [identifier.JSON objectForKey:@"videoId"];
        [videos addObject:video];
    }
    return videos;
}
@end
