//
//  LoginViewController.m
//  Clipster
//
//  Created by Nathan Speller on 4/6/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "LoginViewController.h"
#import "User.h"
#import <Parse/Parse.h>

@interface LoginViewController ()
- (IBAction)onFacebookLogin:(id)sender;
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onFacebookLogin:(id)sender {
    NSArray *permissions = [NSArray array];
    [PFFacebookUtils logInWithPermissions:permissions block:^(PFUser *user, NSError *error) {
        if (!user) {
            NSLog(@"Uh oh. The user cancelled the Facebook login.");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UserDidLogout" object:nil];
        } else if (user.isNew) {
            User *myUser = (User *)user;
            [myUser saveInBackground];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UserDidLogin" object:nil];
        } else {
            NSLog(@"User logged in through Facebook!");
//            User *myUser = (User *)user;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UserDidLogin" object:nil];
        }
    }];
}
@end
