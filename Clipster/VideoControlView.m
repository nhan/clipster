//
//  VideoControlView.m
//  Clipster
//
//  Created by Anthony Sherbondy on 4/22/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "VideoControlView.h"
#import "ClipsterColors.h"

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
    [self drawVideoProgress:context];
}

- (void)drawVideoProgress:(CGContextRef)context
{
    CGFloat alpha = 0.5;
    UIColor *color = self.color;
    CGContextSetFillColorWithColor(context, [color colorWithAlphaComponent:alpha].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, self.currentPlaybackPosition, self.bounds.size.height));
}

// current progress should just be a rect with green color drawn over everything with alpha higher

- (void)drawHistogramWithContext:(CGContextRef)context
{
    CGFloat histogramDelta = self.bounds.size.width / self.popularityHistogram.count;
    for (int i=0; i<self.popularityHistogram.count; i++) {
        CGFloat popularity = [self.popularityHistogram[i] floatValue];
        
        // get color based on popularity
        if (popularity > 0) {
            // linearly interpolate the alpha based on popularity 0-1 --> 0.2-0.8
            CGFloat alpha = 0.6 * popularity + 0.2;
            
            UIColor *color = [[ClipsterColors red] colorWithAlphaComponent:alpha];
            CGContextSetFillColorWithColor(context, color.CGColor);
            CGContextFillRect(context, CGRectMake( i*histogramDelta, 0, histogramDelta, self.bounds.size.height));
        }
    }
}


@end
