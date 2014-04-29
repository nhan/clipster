//
//  SignupViewController.m
//  Clipster
//
//  Created by Nathan Speller on 4/28/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "SignupViewController.h"

@interface SignupViewController ()

@end

@implementation SignupViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.signUpView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"carbon_fibre.png"]]];
    [self.signUpView setLogo:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"clipster.png"]]];
    [self.signUpView.usernameField setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.2]];
    
    [self.signUpView.passwordField setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.2]];
    [self.signUpView.emailField    setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.2]];

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
