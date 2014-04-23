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

@interface ClipCell : UITableViewCell
@property (nonatomic, strong) Clip *clip;
@property (nonatomic, weak) id<ClipCellDelegate> delegate;
@end
