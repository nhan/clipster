//
//  RulerView.m
//  Clipster
//
//  Created by Nathan Speller on 4/18/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "RulerView.h"

@implementation RulerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat penColor[4] = {0.8f, 0.8f, 0.8f, 1.0f};
    NSInteger gapSize = 20;
    CGContextSetStrokeColor(context, penColor);
    
    for (int i = 1; i <= 1000; i++)
    {
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, i*gapSize, 0);
        CGContextAddLineToPoint(context, i*gapSize, 50);
        CGContextStrokePath(context);
    }
}

- (void)redrawLinesWithStartPos:(CGFloat)startPos scale:(CGFloat)scale{
    [self setNeedsDisplay];
}


@end
