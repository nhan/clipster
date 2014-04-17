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

// Query
#import <GTLQueryYouTube.h>
#import <GTLYouTubeSearchListResponse.h>

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

static NSString *const kAPIKey = @"AIzaSyC2068T7T8YpkzNsHK-Cx5kMVJ7f-ZNhOw";
+ (GTLServiceYouTube *)youTubeService
{
    static dispatch_once_t once;
    static GTLServiceYouTube *service;
    dispatch_once(&once, ^{
        service = [[GTLServiceYouTube alloc] init];
        service.APIKey = kAPIKey;
    });
    return service;
}

+ (void)searchVideosWithQuery:(NSString *)queryString completionHandler:(void (^)(NSArray *, NSError *))completionHandler
{
    GTLServiceYouTube *service = [YouTubeVideo youTubeService];
    
    GTLQueryYouTube *query = [GTLQueryYouTube queryForSearchListWithPart:@"snippet,id"];
    query.q = queryString;
    query.type = @"video";
    
    // maxResults specifies the number of results per page.  Since we earlier
    // specified shouldFetchNextPages=YES, all results should be fetched,
    // though specifying a larger maxResults will reduce the number of fetches
    // needed to retrieve all pages.
    query.maxResults = 10;
    
    // We can specify the fields we want here to reduce the network
    // bandwidth and memory needed for the fetched collection.
    //
    // For example, leave query.fields as nil during development.
    // When ready to test and optimize your app, specify just the fields needed.
    // For example, this sample app might use
    //
    // query.fields = @"kind,etag,items(id,etag,kind,contentDetails)";
    
    [service executeQuery:query completionHandler:^(GTLServiceTicket *ticket, GTLYouTubeSearchListResponse *response, NSError *error) {
        NSArray *videos = error ? nil : [YouTubeVideo videosFromSearchResults:response.items];
        completionHandler(videos, error);
    }];
    
}



@end
