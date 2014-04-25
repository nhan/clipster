//
//  YoutubeCell.m
//  Clipster
//
//  Created by Nathan Speller on 4/25/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "YouTubeCell.h"
#import <AFNetworking/UIImageView+AFNetworking.h>

@implementation YouTubeCell

+ (CGFloat)heightForVideo:(YouTubeVideo *)video cell:(YouTubeCell *)prototype{
    CGFloat textWidth = prototype.titleLabel.frame.size.width;
    UIFont *font = prototype.titleLabel.font;
    CGSize constrainedSize = CGSizeMake(textWidth, 9999);
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          font, NSFontAttributeName, nil];
    
    CGFloat height = 20;
    if ([video.title length] > 0){
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:video.title attributes:attributesDictionary];
        
        CGRect requiredHeight = [string boundingRectWithSize:constrainedSize options:NSStringDrawingUsesLineFragmentOrigin context:nil];
        
        height += requiredHeight.size.height;
    }
    if (height < 65)
        height = 65;
    
    return height;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setVideo:(YouTubeVideo *)video{
    _video = video;
    [self.thumbnail setImageWithURL:[NSURL URLWithString:video.thumbnailURL]];
    self.titleLabel.text = video.title;
    [self.thumbnail setClipsToBounds:YES];
    self.thumbnail.layer.cornerRadius = 2.0;
    self.thumbnail.layer.masksToBounds = YES;
}


@end
