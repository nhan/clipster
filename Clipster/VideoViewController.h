//
//  ClipDetailsViewController.h
//  Clipster
//
//  Created by Nathan Speller on 4/11/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SmallClipCell.h"
#import "ClippingViewController.h"
#import <SWTableViewCell.h>

@interface VideoViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, ClipCreationDelegate, UIGestureRecognizerDelegate, ClipCellDelegate, SWTableViewCellDelegate>
- (id)initWithClip:(Clip *)clip;
- (id)initWithVideoId:(NSString *)videoId andTitle:(NSString *)videoTitle;
@end
