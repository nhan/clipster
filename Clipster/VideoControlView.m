//
//  VideoControlView.m
//  Clipster
//
//  Created by Anthony Sherbondy on 4/22/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "VideoControlView.h"

@implementation VideoControlView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
//        [self setOpaque:NO];
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();

    // background
//    CGContextSetFillColorWithColor(context, self.bcolor.CGColor);
//    CGContextFillRect(context, self.bounds);
    
    // current playback position
    CGContextSetFillColorWithColor(context, self.color.CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, self.currentPlaybackPosition, self.bounds.size.height));
}


@end
