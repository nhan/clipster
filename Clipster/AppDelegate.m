//
//  AppDelegate.m
//  Clipster
//
//  Created by Nathan Speller on 4/6/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "AppDelegate.h"
#import "LoginViewController.h"
#import <Parse/Parse.h>
#import "Clip.h"
#import "User.h"

#import "VideoViewController.h"
#import "StreamViewController.h"
#import "SearchResultsViewController.h"
#import "ProfileViewController.h"
#import "ClippingViewController.h"
#import "LoginManager.h"

@interface AppDelegate ()
@property (nonatomic, strong) PFLogInViewController *loginViewController;
@property (nonatomic, strong) UITableViewCell *logoutCell;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Register my model sublcasses
    [Clip registerSubclass];
    [User registerSubclass];
    
    [Parse setApplicationId:@"ijASx0FwG5H1x75wkkAt3dVSd3f3COyX12ZvoXuv"
                  clientKey:@"LsmTAORgFrbm8r0hJqE8nI5Xcuv6dYy3YjXWP9Po"];
    [PFFacebookUtils initializeFacebook];
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    [self setRootViewController];
    [self subscribeToUserNotifications];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)styleNavigationController:(UINavigationController *)navigationController{
    navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.871 green:0.180 blue:0.153 alpha:1.000];
    navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    [[UINavigationBar appearance] setTitleTextAttributes: @{ NSForegroundColorAttributeName : [UIColor whiteColor] }];
}

- (void)setRootViewController
{
    User *currentUser = (User *)[PFUser currentUser];
    if (currentUser) {
        
        StreamViewController *streamViewController = [[StreamViewController alloc] init];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:streamViewController];
        [self styleNavigationController:navigationController];
        self.window.rootViewController = navigationController;
        NSLog(@"====== User name ===== %@", currentUser.username);
    } else {
        LoginManager *loginManager = [LoginManager instance];
        
        PFLogInViewController *logInViewController = self.loginViewController = [[PFLogInViewController alloc] init];
        [logInViewController setDelegate:loginManager]; // Set ourselves as the delegate
        
        // Create the sign up view controller
        PFSignUpViewController *signUpViewController = [[PFSignUpViewController alloc] init];
        [signUpViewController setDelegate:loginManager]; // Set ourselves as the delegate
        
        // Assign our sign up controller to be displayed from the login controller
        [logInViewController setSignUpController:signUpViewController];
        self.window.rootViewController = logInViewController;
    }
    
}

- (void)subscribeToUserNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setRootViewController) name:kUserDidLoginNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setRootViewController) name:kUserDidSignupNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setRootViewController) name:kUserDidLogoutNotification object:nil];
}

- (void)unsubscribeToUserNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setRootViewController) name:kUserDidLoginNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setRootViewController) name:kUserDidSignupNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setRootViewController) name:kUserDidLogoutNotification object:nil];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self unsubscribeToUserNotification];
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return [FBAppCall handleOpenURL:url
                  sourceApplication:sourceApplication
                        withSession:[PFFacebookUtils session]];
}

@end
