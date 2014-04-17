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
@property (weak, nonatomic) IBOutlet PFImageView *thumnail;

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
    self.descriptionLabel.text = [NSString stringWithFormat:@"%d, %d", self.clip.timeStart, self.clip.timeEnd];
    if (self.clip.thumbnail) {
        self.thumnail.file = self.clip.thumbnail;
        [self.thumnail loadInBackground];
    } else {
        self.thumnail.image = [UIImage imageNamed:@"stream_thumbnail_placeholder.gif"];
    }
}

@end
