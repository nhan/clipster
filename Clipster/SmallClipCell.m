//
//  SmallClipCell.m
//  Clipster
//
//  Created by Nathan Speller on 4/11/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "SmallClipCell.h"

@implementation SmallClipCell


-(void)setClip:(Clip *)clip{
    NSLog(@"CLIP");
    _clip = clip;
    self.clipTextLabel.text = clip.text;
    self.clipTimesLabel.text = [NSString stringWithFormat:@"%ld - %ld", (long)clip.timeStart, (long)clip.timeEnd];
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

@end
