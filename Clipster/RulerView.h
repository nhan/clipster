//
//  RulerView.h
//  Clipster
//
//  Created by Nathan Speller on 4/18/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RulerView : UIView
- (void)redrawLinesWithStartPos:(CGFloat)startPos scale:(CGFloat)scale;
@end
