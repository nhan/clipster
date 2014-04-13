//
//  MenuViewController.m
//  twitter
//
//  Created by Nhan Nguyen on 4/7/14.
//  Copyright (c) 2014 codepath. All rights reserved.
//

#import <objc/runtime.h>
#import "HamburgerMenuController.h"

#pragma mark - UIViewController (HamburgerMenuItem)
@implementation UIViewController (HamburgerMenuItem)
static char HamburgerMenuControllerKey;
- (void)setHamburgerMenuController:(HamburgerMenuController *)hamburgerMenuController
{
    // why is there not better syntactic sugar in the language for doing this?!
	objc_setAssociatedObject(self, &HamburgerMenuControllerKey, hamburgerMenuController, OBJC_ASSOCIATION_RETAIN);
}
- (HamburgerMenuController *)hamburgerMenuController
{
    return objc_getAssociatedObject(self, &HamburgerMenuControllerKey);
}
@end

#pragma mark - HamburgerMenuController
# pragma mark - private constants
// how much the active view gets shifted over to reveal the menu view
static CGFloat const DefaultMenuItemHeight = 44.0f;
static CGFloat const DefaultRevealOffsetFactor = .75f;
static CGFloat const DefaultMinTranslationToTriggerChange = 20.0f;
static CGFloat const DefaultMaxAnimationDuration = 0.5;


@interface HamburgerMenuController ()
@property (nonatomic, assign) BOOL isMenuRevealed;
@property (nonatomic, strong) UIViewController* activeViewController;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end

@implementation HamburgerMenuController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.backGroundColor = [UIColor colorWithWhite:0.15 alpha:1];
        self.defaultTextColor = [UIColor colorWithWhite:0.90 alpha:1];
        self.selectionColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.5 alpha:1];
        self.menuRevealOffsetFactor = DefaultRevealOffsetFactor;
        self.minTranslationToTriggerChange = DefaultMinTranslationToTriggerChange;
        self.maxAnimationDuration = DefaultMaxAnimationDuration;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = self.backGroundColor;
    self.tableView.scrollEnabled = NO;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"DefaultCell"];

    // hides empty separators
    UIView *dummyFooter = [[UIView alloc] initWithFrame:CGRectZero];
    dummyFooter.backgroundColor = [UIColor clearColor];
    [self.tableView setTableFooterView:dummyFooter];

    [self reloadMenuItems];
}

#pragma mark - setters

- (void)setDelegate:(id<HamburgerMenuDelegate>)delegate
{
    _delegate = delegate;
    if (delegate) {
        self.activeViewController = [delegate viewControllerAtIndex:0 hamburgerMenuController:self];
        [self reloadMenuItems];
    }
}

- (void) setActiveViewController:(UIViewController *)activeViewController
{
    // TODO: CALL ALL THOSE CHILD VIEW CONTROLLER METHODS
    CGRect frame;
    if (_activeViewController) {
        frame = _activeViewController.view.frame;
    } else {
        frame = self.view.frame;
    }
    _activeViewController = activeViewController;
    [self updateActiveViewWithFrame:frame];
}


#pragma mark - UITableViewDataSource, UITableViewDelegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* ret = nil;

    if ([self.delegate respondsToSelector:@selector(cellForMenuItemAtIndex:hamburgerMenuController:)]) {
        ret = [self.delegate cellForMenuItemAtIndex:indexPath.row hamburgerMenuController:self];
    }

    if (ret == nil && [self.delegate respondsToSelector:@selector(viewControllerAtIndex:hamburgerMenuController:)]) {
        ret = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell" forIndexPath:indexPath];
        ret.backgroundColor = self.backGroundColor;
        if (ret.selectedBackgroundView.backgroundColor != self.selectionColor) { // only allocate once per cell
            NSLog(@"Getting Cell");
            ret.selectedBackgroundView = [[UIView alloc] initWithFrame:ret.bounds];
            ret.selectedBackgroundView.backgroundColor = self.selectionColor;
        }
        ret.textLabel.textColor = self.defaultTextColor;
        ret.textLabel.text = [self.delegate viewControllerAtIndex:indexPath.row hamburgerMenuController:self].title;
    }
    return ret;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.delegate) {
        return [self.delegate numberOfItemsInMenu:self];
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(heightForItemAtIndex:hamburgerMenuController:)]) {
        return [self.delegate heightForItemAtIndex:indexPath.row hamburgerMenuController:self];
    }
    return DefaultMenuItemHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIViewController *selectedViewController = [self.delegate viewControllerAtIndex:indexPath.row hamburgerMenuController:self];
    
    if (selectedViewController) {
        self.activeViewController = selectedViewController;
        [self hideMenuWithDuration:self.maxAnimationDuration];
    }

    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self.delegate didSelectItemAtIndex:indexPath.row hamburgerMenuController:self];
}

#pragma mark - public methods

- (void)reloadMenuItems
{
    for (NSInteger i = 0; i < [self.delegate numberOfItemsInMenu:self]; ++i) {
        UIViewController *menuItem = [self.delegate viewControllerAtIndex:i hamburgerMenuController:self];
        menuItem.hamburgerMenuController = self;
    }
    [self.tableView reloadData];
    [self updateActiveViewWithFrame:self.view.frame];
}

- (void)revealMenuWithDuration:(NSTimeInterval)duration
{
    CGFloat snapCenterX = (1 + 2 * self.menuRevealOffsetFactor) * self.view.center.x;
    CGPoint endingCenter = CGPointMake(snapCenterX, self.activeViewController.view.center.y);
    [self animateActiveViewWithDuration:duration endingCenter:endingCenter isMenuRevealed:YES];
    if (self.activeViewController) {
        // TODO: this causes bug where the menu button doesn't work
//        self.activeViewController.view.userInteractionEnabled = NO;
    }
}

- (void)hideMenuWithDuration:(NSTimeInterval)duration
{
    CGPoint endingCenter = CGPointMake(self.view.center.x, self.activeViewController.view.center.y);
    [self animateActiveViewWithDuration:duration endingCenter:endingCenter isMenuRevealed:NO];
    if (self.activeViewController) {
//        self.activeViewController.view.userInteractionEnabled = YES;
    }
}

#pragma mark - private methods

- (void) updateActiveViewWithFrame:(CGRect)frame;
{
    if (self.activeViewController && ![self.activeViewController.view isDescendantOfView:self.view]) {
        for (UIView* view in [self.view subviews]) {
            if (view != self.tableView) {
                [view removeFromSuperview];
            }
        }
        self.activeViewController.view.frame = frame;
        [self.view addSubview:self.activeViewController.view];
    }
}

#pragma mark - action handlers

- (IBAction)panAction:(UIPanGestureRecognizer *)recognizer
{
    static CGPoint gestureStartingLocation;
    static CGPoint activeViewStartingCenter;

    UIView *activeView = self.activeViewController.view;
    CGPoint location =  [recognizer translationInView:self.view];
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        gestureStartingLocation = location;
        activeViewStartingCenter = activeView.center;
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        // Offset the activeView's center by the translation since the gesture started.
        // Do not move left of the parent view's (i.e. our) center.
        CGFloat deltaX = location.x - gestureStartingLocation.x;
        if (activeViewStartingCenter.x + deltaX > self.view.center.x) {
            activeView.center = CGPointMake(activeViewStartingCenter.x + deltaX, activeView.center.y);
        }
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        // If the ending velocity is in the same direction as the translation and the
        // translation was sufficiently large we change the position of the active view
        // to either reveal or hide the menu.  If either of these conditions is not met we
        // move the view back to the position it was in at the start of the gesture

        CGFloat deltaX = location.x - gestureStartingLocation.x;
        CGPoint velocity = [recognizer velocityInView:self.view];
        // duration = distance / speed; capped by the MaxRevealDuration
        CGFloat duration = MIN(self.view.frame.size.width / ABS(velocity.x), self.maxAnimationDuration);
        BOOL sameDirection = (velocity.x < 0 && deltaX < 0) || (velocity.x > 0 && deltaX > 0);

        if (sameDirection && ABS(deltaX) > self.minTranslationToTriggerChange) {
            if (velocity.x > 0) {
                [self revealMenuWithDuration:duration];
            } else {
                [self hideMenuWithDuration:duration];
            }
        } else {
            if (self.isMenuRevealed) {
                [self revealMenuWithDuration:duration];
            } else {
                [self hideMenuWithDuration:duration];
            }
        }
    }
}

- (void)animateActiveViewWithDuration:(NSTimeInterval)duration endingCenter:(CGPoint)endingCenter isMenuRevealed:(BOOL)isMenuRevealed
{
    [UIView animateWithDuration:duration animations:^{
        self.activeViewController.view.center = endingCenter;
    } completion:^(BOOL finished){
        self.isMenuRevealed = isMenuRevealed;
    }];
}
@end


