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
    //draw every half second
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat penColor[4] = {0.65f, 0.65f, 0.65f, 1.0f};
    CGFloat gapSize = (self.endPos - self.startPos)/(self.endTime - self.startTime); //one second
    CGFloat offset = self.startPos - gapSize*(self.startTime - floor(self.startTime));
    
    CGContextSetStrokeColor(context, penColor);
    
    for (int i = -100; i <= 100; i++)
    {
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, i*gapSize+offset+self.sliderOffset, 0);
        CGContextAddLineToPoint(context, i*gapSize+offset+self.sliderOffset, 50);
        CGContextStrokePath(context);
    }
}

- (void)redrawLinesWithStartPos:(CGFloat)startPos scale:(CGFloat)scale{
    [self setNeedsDisplay];
}


@end
