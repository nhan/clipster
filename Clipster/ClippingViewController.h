//
//  ClippingViewController.h
//  Clipster
//
//  Created by Nathan Speller on 4/18/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "Clip.h"
#import "VideoPlayerViewController.h"

@protocol ClipCreationDelegate <NSObject>
- (void) creationDone:(Clip *)clip;
- (void) creationCanceled;
@end

@interface ClippingViewController : UIViewController<UITextViewDelegate>
@property id<ClipCreationDelegate> delegate;
- (id)initWithClip:(Clip*)clip playerController:(VideoPlayerViewController*)playerController;
@end
