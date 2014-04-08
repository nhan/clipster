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

@end
