//
//  SmallClipCell.m
//  Clipster
//
//  Created by Nathan Speller on 4/11/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "SmallClipCell.h"
#import <Parse/PFImageView.h>

#define DURATION_TAG 9017

@implementation SmallClipCell

+ (CGFloat)heightForClip:(Clip *)clip cell:(SmallClipCell *)prototype{
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

-(void)setClip:(Clip *)clip
{
    _clip = clip;
    [self refreshUI];
}

- (void)refreshUI
{
    Clip *clip = self.clip;
    
    if ([self.clip isPublished]) {
        self.clipTextLabel.text = self.clip.text;
    } else {
        self.clipTextLabel.text = @"New clip (press to publish)";
    }
    
    self.clipTimesLabel.text = clip.formattedTimestamp;
    
    self.thumbnail.layer.cornerRadius = 2.0;
    self.thumbnail.layer.masksToBounds = YES;
    
    [[self.contentView viewWithTag:DURATION_TAG]removeFromSuperview];
    
    // TODO get real total duration of VIDEO
    CGFloat totalSeconds = 300;
    CGFloat durationStart = (self.clip.timeStart/1000)*(320/totalSeconds);
    NSInteger durationLength = ((self.clip.timeEnd-self.clip.timeStart)/1000)*(320/totalSeconds);
    if (durationLength < 1) {
        durationLength = 1;
    }
    
    UIView *durationView = [[UIView alloc] initWithFrame:CGRectMake(durationStart, 0, durationLength, [SmallClipCell heightForClip:self.clip cell:self])];
    durationView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.05];
    durationView.tag = DURATION_TAG;
    [self.contentView insertSubview:durationView belowSubview:[self.contentView.subviews objectAtIndex:0]];
    
    self.thumbnail.file = clip.thumbnail;
    [self.thumbnail loadInBackground];
    
    
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
