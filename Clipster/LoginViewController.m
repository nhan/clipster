//
//  LoginViewController.m
//  Clipster
//
//  Created by Nathan Speller on 4/28/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "LoginViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface LoginViewController ()

@end

@implementation LoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.logInView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"carbon_fibre.png"]]];
    [self.logInView setLogo:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"clipster-logo-5"]]];
    [self.logInView.usernameField setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.2]];
    [self.logInView.passwordField setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.2]];
    [self.logInView.signUpButton setBackgroundImage:[UIImage imageNamed:@"red-button-2"] forState:UIControlStateNormal];
    [self.logInView.logInButton setBackgroundImage:[UIImage imageNamed:@"grey-button"] forState:UIControlStateNormal];
    [self.logInView.logInButton setBackgroundImage:[UIImage imageNamed:@"grey-button-down"] forState:UIControlStateHighlighted];
    [self.logInView.signUpButton setBackgroundImage:[UIImage imageNamed:@"red-button-down"] forState:UIControlStateHighlighted];
    [self.logInView.dismissButton removeFromSuperview];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
