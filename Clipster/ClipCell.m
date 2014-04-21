//
//  VideoCell.m
//  Clipster
//
//  Created by Nathan Speller on 4/6/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "ClipCell.h"

@interface ClipCell ()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet PFImageView *thumbnail;
@property (weak, nonatomic) IBOutlet UIImageView *profileThumbnail;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;


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
    
    [self.profileThumbnail setClipsToBounds:YES];
    self.profileThumbnail.layer.cornerRadius = self.profileThumbnail.frame.size.width/2;
    self.profileThumbnail.layer.masksToBounds = YES;
}

@end
