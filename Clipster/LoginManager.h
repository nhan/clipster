//
//  LoginManager.h
//  Clipster
//
//  Created by Nhan Nguyen on 4/18/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/PFLogInViewController.h>

static NSString *kUserDidLoginNotification = @"com.clipster.userdidlogin";
static NSString *kUserDidSignupNotification = @"com.clipster.userdidsignup";
static NSString *kUserDidLogoutNotification = @"com.clipster.userdidlogout";


@interface LoginManager : NSObject<PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate>
+ (LoginManager *)instance;
- (void) logout;
@end
