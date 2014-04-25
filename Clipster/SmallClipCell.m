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
#define TAP_TO_PUBLISH_TAG 9018

@interface SmallClipCell ()
@property (weak, nonatomic) IBOutlet UILabel *clipTimesLabel;
@property (weak, nonatomic) IBOutlet UIButton *usernameButton;
@property (nonatomic, assign) BOOL isShowingTimeline;
@property (nonatomic, strong) UIView *timelineView;
@end

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

- (void)setClip:(Clip *)clip
{
    _clip = clip;
    [self refreshUI];
}

- (void)setTimelineRect:(CGRect)timelineRect
{
    // simply show the timeline if someone sets this property
    self.isShowingTimeline = YES;
    _timelineRect = timelineRect;
    [self refreshUI];
}

- (UIView *)timelineView
{
    if (!_timelineView) {
        _timelineView = [[UIView alloc] init];
        _timelineView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.2];
        [self addSubview:_timelineView];
    }
    return _timelineView;
}

- (void)refreshUI
{
    Clip *clip = self.clip;
    [[self.contentView viewWithTag:TAP_TO_PUBLISH_TAG] removeFromSuperview];
    
    if ([self.clip isPublished]) {
        self.clipTextLabel.text = self.clip.text;
        self.clipTextLabel.alpha = 1.0;
        self.clipTimesLabel.alpha = 1.0;
    } else {
        self.clipTextLabel.text = @"add a comment";
        self.clipTextLabel.alpha = 0.5;
        self.clipTimesLabel.alpha = 0.0;
        
        UIImage *tapToPublish = [UIImage imageNamed:@"tapToPublish.png"];
        UIImageView *tapToPublishView = [[UIImageView alloc] initWithImage:tapToPublish];
        tapToPublishView.frame = CGRectMake(self.contentView.frame.size.width - 118,15, 108, 36);
        [tapToPublishView setTag:TAP_TO_PUBLISH_TAG];
        [self.contentView addSubview:tapToPublishView];
    }
    
    self.clipTimesLabel.text = clip.formattedTimestamp;
    [[self.contentView viewWithTag:DURATION_TAG] removeFromSuperview];
    
    [self.usernameButton setTitle:clip.username forState:UIControlStateNormal];
    
//    // TODO get real total duration of VIDEO
//    CGFloat totalSeconds = 300;
//    CGFloat durationStart = (self.clip.timeStart/1000)*(320/totalSeconds);
//    NSInteger durationLength = ((self.clip.timeEnd-self.clip.timeStart)/1000)*(320/totalSeconds);
//    if (durationLength < 1) {
//        durationLength = 1;
//    }
//    
//    UIView *durationView = [[UIView alloc] initWithFrame:CGRectMake(durationStart, 0, durationLength, [SmallClipCell heightForClip:self.clip cell:self])];
//    durationView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.05];
//    durationView.tag = DURATION_TAG;
//    [self.contentView insertSubview:durationView belowSubview:[self.contentView.subviews objectAtIndex:0]];
    
    if (self.isShowingTimeline) {
        self.timelineView.frame = self.timelineRect;
    }
    
    self.thumbnail.file = clip.thumbnail;
    [self.thumbnail loadInBackground];
    [self refreshThumbnail];
}

- (void)refreshThumbnail{
    [self.thumbnail setClipsToBounds:YES];
    self.thumbnail.layer.cornerRadius = 2.0;
    self.thumbnail.layer.masksToBounds = YES;
}

- (IBAction)onUsernameClick:(id)sender {
    [self.delegate didClickUsername:self.clip.username];
}

@end
