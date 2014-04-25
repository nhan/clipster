//
//  VideoControlView.m
//  Clipster
//
//  Created by Anthony Sherbondy on 4/22/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "VideoControlView.h"

@interface VideoControlView ()
@end

@implementation VideoControlView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self drawHistogramWithContext:context];
}

- (void)drawHistogramWithContext:(CGContextRef)context
{
    CGFloat histogramDelta = self.bounds.size.width / self.popularityHistogram.count;
    for (int i=0; i<self.popularityHistogram.count; i++) {
        CGFloat popularity = [self.popularityHistogram[i] floatValue];
        CGFloat position = i*histogramDelta;
        
        // before current playback position we are pretty much opaque, after translucent
        UIColor *backgroundColor = self.backgroundColor;
        CGFloat alpha = 0.3;
        if (position < self.currentPlaybackPosition) {
            alpha = 1.0;
            backgroundColor = [UIColor colorWithWhite:0.8 alpha:alpha];
        }
        // get color based on popularity
        UIColor *color = popularity > 0 ? self.color : backgroundColor;
        CGContextSetFillColorWithColor(context, [color colorWithAlphaComponent:alpha].CGColor);
        CGContextFillRect(context, CGRectMake( i*histogramDelta, 0, histogramDelta, self.bounds.size.height));
    }
}


@end
