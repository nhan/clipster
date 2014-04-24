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
        [self setOpaque:NO];
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, self.backgroundColor.CGColor);
    CGContextFillRect(context, self.bounds);
}


@end
