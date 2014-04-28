//
//  SmallClipCell.h
//  Clipster
//
//  Created by Nathan Speller on 4/11/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Clip.h"
#import <SWTableViewCell.h>

@protocol ClipCellDelegate<NSObject>
- (void)didClickUsername:(NSString *)username;
@end

@interface SmallClipCell : SWTableViewCell

@property (weak, nonatomic) IBOutlet UILabel *clipTextLabel;
@property (weak, nonatomic) IBOutlet PFImageView *thumbnail;
@property (nonatomic, strong) Clip *clip;
@property (nonatomic, weak) id<ClipCellDelegate> clipCellDelegate;
@property (nonatomic, assign) CGRect timelineRect;
@property (nonatomic, assign) BOOL isPlaying;

+ (CGFloat)heightForClip:(Clip *)clip cell:(SmallClipCell *)prototype;
- (void)setClip:(Clip *)clip;
- (void)refreshUI;
- (void)refreshThumbnail;
@end
