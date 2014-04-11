//
//  ClipCreationViewController.h
//  Clipster
//
//  Created by Nhan Nguyen on 4/11/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Clip.h"

@protocol ClipCreationDelegate <NSObject>
- (void) creationDone:(Clip *)clip;
- (void) creationCanceled;
@end

@interface ClipCreationViewController : UIViewController
@property id<ClipCreationDelegate> delegate;
- (id) initWithClip:(Clip *)clip;
@end
