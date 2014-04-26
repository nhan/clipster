//
//  VideoPlayerView.m
//  Clipster
//
//  Created by Nhan Nguyen on 4/23/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "VideoPlayerView.h"

@implementation VideoPlayerView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayer*)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player {
    ((AVPlayerLayer *)[self layer]).videoGravity = AVLayerVideoGravityResizeAspectFill;
    ((AVPlayerLayer *)[self layer]).bounds = ((AVPlayerLayer *)[self layer]).bounds;
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

@end
