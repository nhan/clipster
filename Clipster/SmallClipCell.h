//
//  SmallClipCell.h
//  Clipster
//
//  Created by Nathan Speller on 4/11/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Clip.h"

@protocol ClipCellDelegate<NSObject>
- (void)didClickUsername:(NSString *)username;
@end

@interface SmallClipCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *clipTextLabel;
@property (weak, nonatomic) IBOutlet PFImageView *thumbnail;
@property (nonatomic, strong) Clip *clip;
@property (nonatomic, weak) id<ClipCellDelegate> delegate;

+ (CGFloat)heightForClip:(Clip *)clip cell:(SmallClipCell *)prototype;
- (void)setClip:(Clip *)clip;
- (void)refreshUI;
- (void)refreshThumbnail;
@end
