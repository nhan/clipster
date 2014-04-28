//
//  ProfileClipCell.m
//  Clipster
//
//  Created by Nathan Speller on 4/27/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "ProfileClipCell.h"

@implementation ProfileClipCell

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (CGFloat)heightForClip:(Clip *)clip cell:(ProfileClipCell *)prototype{
    CGFloat textWidth = prototype.clipTextLabel.frame.size.width;
    UIFont *font = prototype.clipTextLabel.font;
    CGSize constrainedSize = CGSizeMake(textWidth, 9999);
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          font, NSFontAttributeName, nil];
    
    CGFloat height = 50;
    if ([clip.text length] > 0){
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:clip.text attributes:attributesDictionary];
        
        CGRect requiredHeight = [string boundingRectWithSize:constrainedSize options:NSStringDrawingUsesLineFragmentOrigin context:nil];
        
        height += requiredHeight.size.height;
    }
    if (height < 65)
        height = 65;
    
    return height;
}

- (void)setClip:(Clip *)clip
{
    _clip = clip;
    [self refreshUI];
}

- (void)refreshUI
{
    self.clipTextLabel.text = self.clip.text;
    self.timeAgoLabel.text = self.clip.timeAgoExtended;
    
    self.thumbnail.file = self.clip.thumbnail;
    [self.thumbnail loadInBackground];
    [self.thumbnail setClipsToBounds:YES];
    self.thumbnail.layer.cornerRadius = 2.0;
    self.thumbnail.layer.masksToBounds = YES;
}

@end
