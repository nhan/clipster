//
//  YoutubeCell.h
//  Clipster
//
//  Created by Nathan Speller on 4/25/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "YouTubeVideo.h"

@interface YouTubeCell : UITableViewCell
@property (weak, nonatomic) IBOutlet PFImageView *thumbnail;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) YouTubeVideo *video;

- (void)setVideo:(YouTubeVideo *)video;
+ (CGFloat)heightForVideo:(YouTubeVideo *)video cell:(YouTubeCell *)prototype;

@end
