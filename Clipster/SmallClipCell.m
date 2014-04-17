//
//  SmallClipCell.m
//  Clipster
//
//  Created by Nathan Speller on 4/11/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "SmallClipCell.h"

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
    return height;
}

-(void)setClip:(Clip *)clip{
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
