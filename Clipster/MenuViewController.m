//
//  MenuViewController.m
//  Clipster
//
//  Created by Nathan Speller on 4/6/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "MenuViewController.h"
#import "StreamViewController.h"
#import <Parse/Parse.h>

@interface MenuViewController ()
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic, strong) UITapGestureRecognizer *tapToCloseMenuGestureRecognizer;
- (IBAction)onLogout:(id)sender;
@end

@implementation MenuViewController

static float openMenuPosition = 265; //open menu x position

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        StreamViewController *streamViewController = [[StreamViewController alloc] init];
        
        self.navigationController = [[UINavigationController alloc] initWithRootViewController:streamViewController];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleMenu) name:@"toggleMenu" object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.contentView addSubview:self.navigationController.view];
}

- (void)toggleMenu{
    // move the contentView to reveal/hide the menu
    float xPos = (self.contentView.frame.origin.x == 0) ? openMenuPosition : 0;
    [UIView animateWithDuration:0.3 animations:^{
        self.contentView.frame = CGRectMake( xPos, 0, self.contentView.frame.size.width, self.contentView.frame.size.height);
    }];
    
    // initialize the tap gesture on the contentView to close an open menu
    if (self.tapToCloseMenuGestureRecognizer == nil) {
        self.tapToCloseMenuGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleMenu)];
        self.tapToCloseMenuGestureRecognizer.numberOfTapsRequired = 1;
        [self.contentView addGestureRecognizer:self.tapToCloseMenuGestureRecognizer];
    }
    
    // disable interaction with the contentView if the menu is open
    BOOL isMenuOpen = self.contentView.frame.origin.x == 0;
    [self.contentView.subviews[0] setUserInteractionEnabled:isMenuOpen];
    self.tapToCloseMenuGestureRecognizer.enabled = !isMenuOpen;
}

- (IBAction)onLogout:(id)sender {
    [PFUser logOut];
    [self toggleMenu];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UserDidLogout" object:nil];
}
@end
