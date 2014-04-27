//
//  VideoCell.h
//  Clipster
//
//  Created by Nathan Speller on 4/6/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Clip.h"
#import "SmallClipCell.h"

@class ClipCell;

@protocol StreamCellDelegate<NSObject>
- (void)didClickUsername:(NSString *)username;
- (void)willStartPlaying:(ClipCell *)cell;
@end

@interface ClipCell : UITableViewCell
@property (nonatomic, strong) Clip *clip;
@property (nonatomic, weak) id<StreamCellDelegate> delegate;

- (void) playClip;
- (void) pauseClip;

+ (CGFloat)heightForClip:(Clip *)clip prototype:(ClipCell *)prototype;
@end
