//
//  MenuViewController.h
//  twitter
//
//  Created by Nhan Nguyen on 4/7/14.
//  Copyright (c) 2014 codepath. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HamburgerMenuController;

@interface UIViewController (HamburgerMenuItem)
@property (nonatomic, readonly, strong) HamburgerMenuController* hamburgerMenuController;
@end

@protocol HamburgerMenuDelegate <NSObject>
@required
- (NSInteger) numberOfItemsInMenu:(HamburgerMenuController*)hamburgerMenuController;
@optional
// For any given index at least one of viewControllerAtIndex:hamburgerMenuController:
// and cellForMenuItemAtIndex:hamhamburgerMenuController: must be implemented!
- (UIViewController*) viewControllerAtIndex:(NSInteger)index hamburgerMenuController:(HamburgerMenuController*)hamburgerMenuController;
- (UITableViewCell*) cellForMenuItemAtIndex:(NSInteger)index hamburgerMenuController:(HamburgerMenuController*)hamburgerMenuController;
- (CGFloat) heightForItemAtIndex:(NSInteger)index hamburgerMenuController:(HamburgerMenuController*)hamburgerMenuController;
- (void) didSelectItemAtIndex:(NSInteger)index hamburgerMenuController:(HamburgerMenuController*)hamburgerMenuController;
@end

@interface HamburgerMenuController : UIViewController<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, assign, readonly) BOOL isMenuRevealed;
@property (nonatomic, assign) CGFloat menuRevealOffsetFactor;
@property (nonatomic, assign) CGFloat minTranslationToTriggerChange;
@property (nonatomic, assign) CGFloat maxAnimationDuration;
@property (nonatomic, strong) UIColor *backGroundColor;
@property (nonatomic, strong) UIColor *selectionColor;
@property (nonatomic, strong) UIColor *defaultTextColor;
@property (nonatomic, strong) id<HamburgerMenuDelegate> delegate;

- (void)reloadMenuItems;
- (void)revealMenuWithDuration:(NSTimeInterval)duration;
- (void)hideMenuWithDuration:(NSTimeInterval)duration;
@end
