//
//  ProfileClipCell.h
//  Clipster
//
//  Created by Nathan Speller on 4/27/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/PFImageView.h>
#import "Clip.h"

@interface ProfileClipCell : UITableViewCell
@property (weak, nonatomic) IBOutlet PFImageView *thumbnail;
@property (weak, nonatomic) IBOutlet UILabel *clipTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeAgoLabel;
@property (nonatomic, strong) Clip *clip;

+ (CGFloat)heightForClip:(Clip *)clip cell:(ProfileClipCell *)prototype;
- (void)setClip:(Clip *)clip;
- (void)refreshUI;
@end
