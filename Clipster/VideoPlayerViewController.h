//
//  VideoPlayerViewController.h
//  Clipster
//
//  Created by Nhan Nguyen on 4/23/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "VideoPlayerView.h"

@interface VideoPlayerViewController : UIViewController
// TODO: (nhan) consider changing the type for these to Float64
@property (nonatomic, assign) float startTime;
@property (nonatomic, assign) float endTime;
@property (nonatomic, assign) BOOL isLooping;

// TODO: (nhan) think about which queue the blocks should run on and whether we need a queue argument
- (void)loadVideoWithURL:(NSURL *)url ready:(void (^)(void))readyBlock;
// use the returned handle to remove block
- (id)addTimeObserverWithBlock:(void (^)(float time))block;
- (void)removeTimeObserver:(id)observerId;

// indicates whether the video is ready for playback
@property (nonatomic, assign, readonly) BOOL isReady;

// behavior is undefined unless the the player isReady
@property (nonatomic, assign, readonly) float currentTimeInSeconds;
@property (nonatomic, assign, readonly) float duration;
- (void)play;
- (void)pause;
- (void)frameAtTimeWithSeconds:(float)time done:(void (^)(NSError *error, CGImageRef image))done;
- (void)seekToTime:(float)time done:(void (^)())done;
- (void)seekToExactTime:(float)time done:(void (^)())done;

// TODO: (nhan) These really shouldn't be public.  This is a hack so the loading state can be shown while the we are parsing the youtube URL.
- (void)showLoadingState;
- (void)hideLoadingState;
@end
