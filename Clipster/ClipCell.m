//
//  VideoCell.m
//  Clipster
//
//  Created by Nathan Speller on 4/6/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "ClipCell.h"
#import "YouTubeVideo.h"

@interface ClipCell ()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet PFImageView *thumbnail;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *youTubeLabel;
@property (weak, nonatomic) IBOutlet PFImageView *profileThumbnailView;
@end

@implementation ClipCell

- (void)setClip:(Clip *)clip
{
    _clip = clip;
    [self refreshUI];
}

- (void)refreshUI
{
    self.titleLabel.text = self.clip.text;
    self.descriptionLabel.text = self.clip.formattedTimestamp;
    self.usernameLabel.text = self.clip.username;
    if (self.clip.thumbnail) {
        self.thumbnail.file = self.clip.thumbnail;
        [self.thumbnail loadInBackground];
    } else {
        self.thumbnail.image = [UIImage imageNamed:@"stream_thumbnail_placeholder.gif"];
    }
    [self.thumbnail setClipsToBounds:YES];
    self.thumbnail.layer.cornerRadius = 2.0;
    self.thumbnail.layer.masksToBounds = YES;

    self.youTubeLabel.text = self.clip.videoTitle;

    if ([self.clip.user isDataAvailable]) {
        [self refreshUserThumbnail:self.clip.user];
    } else {
        [self.clip.user fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (error) {
                NSLog(@"Error grabbing profile thumbnail: %@", error);
            } else {
                [self refreshUserThumbnail:(User *)object];
            }
        }];
    }
}

- (void)refreshUserThumbnail:(User *)user
{
    if (user.thumbnail) {
        self.profileThumbnailView.file = user.thumbnail;
        [self.profileThumbnailView loadInBackground];
    } else {
        self.profileThumbnailView.image = [UIImage imageNamed:@"tim.png"];
    }
    [self.profileThumbnailView setClipsToBounds:YES];
    self.profileThumbnailView.layer.cornerRadius = self.profileThumbnailView.frame.size.width/2;
    self.profileThumbnailView.layer.masksToBounds = YES;
}

@end
