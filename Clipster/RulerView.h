//
//  RulerView.h
//  Clipster
//
//  Created by Nathan Speller on 4/18/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RulerView : UIView
@property (nonatomic, assign) CGFloat startPos;
@property (nonatomic, assign) CGFloat startTime;
@property (nonatomic, assign) CGFloat endPos;
@property (nonatomic, assign) CGFloat endTime;
@property (nonatomic, assign) CGFloat sliderOffset;
@end
