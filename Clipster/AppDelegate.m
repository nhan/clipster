//
//  AppDelegate.m
//  Clipster
//
//  Created by Nathan Speller on 4/6/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "AppDelegate.h"
#import "HamburgerMenuController.h"
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
@property (nonatomic, strong) HamburgerMenuController *menuViewController;
@property (nonatomic, strong) NSArray* viewControllers;
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
    
    self.logoutCell = [[UITableViewCell alloc] init];
    self.logoutCell.backgroundColor = [UIColor clearColor];
    self.logoutCell.textLabel.textColor = [UIColor whiteColor];
    self.logoutCell.textLabel.text = @"Logout";
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)databaseTestStuffThatWeMightNeedLater
{
    // Make some models
    Clip *clip = [Clip object];
    clip.text = @"Deadlift standards.";
    clip.isFavorite = YES;
    clip.videoId = @"videoid";
    clip.timeStart = 0;
    clip.timeEnd = 100;
    // Save to Parse
    [clip saveInBackground];
    
    
    // Test some retrieval
    PFQuery *query = [PFQuery queryWithClassName:@"Clip"];
    [query whereKey:@"isFavorite" equalTo:@(YES)];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            // The find succeeded.
            NSLog(@"Successfully retrieved %d clips.", objects.count);
            // Do something with the found objects
            for (Clip *c in objects) {
                NSLog(@"%@", c.text);
            }
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
    
    // Test some relationship query
    User *currentUser = (User *)[PFUser currentUser];
    PFQuery *uquery = [User query];
    [uquery whereKey:@"username" equalTo:@"nhan"];
    [uquery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        [currentUser.friends addObject:objects[0]];
        [currentUser saveInBackground];
    }];
    
    PFQuery *rquery = [currentUser.friends query];
    [rquery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        NSLog(@"I have the following friends:");
        for (User *friend in objects) {
            NSLog(@"%@", friend.username);
        }
    }];
}

- (UINavigationController *) wrapInNavigationController:(UIViewController *)uiVC
{
    UINavigationController *ret = [[UINavigationController alloc] initWithRootViewController:uiVC];
    [self styleNavigationController:ret];
    return ret;
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
        
        ProfileViewController *profileVC = [[ProfileViewController alloc] initWithUser:currentUser];
        self.viewControllers = @[[self wrapInNavigationController:[[StreamViewController alloc] init]],
                                 [self wrapInNavigationController:[[SearchResultsViewController alloc] init]],
                                 [self wrapInNavigationController: profileVC],
                                 [self wrapInNavigationController:[[ClippingViewController alloc] init]]
                                 ];
        
        self.menuViewController = [[HamburgerMenuController alloc] init];
        
        self.menuViewController.delegate = self;
        [self.menuViewController reloadMenuItems];
        self.window.rootViewController = self.menuViewController;
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

# pragma mark - HamburgerMenuDelegate

- (NSInteger)numberOfItemsInMenu:(HamburgerMenuController *)hamburgerMenuController
{
    return self.viewControllers.count + 1;
}

- (UIViewController *)viewControllerAtIndex:(NSInteger)index hamburgerMenuController:(HamburgerMenuController *)hamburgerMenuController
{
    if (index < self.viewControllers.count) {
        return self.viewControllers[index];
    }
    
    return nil;
}

- (UITableViewCell *)cellForMenuItemAtIndex:(NSInteger)index hamburgerMenuController:(HamburgerMenuController *)hamburgerMenuController
{
    if (index == self.viewControllers.count) {
        return self.logoutCell;
    }
    return nil;
}

- (void)didSelectItemAtIndex:(NSInteger)index hamburgerMenuController:(HamburgerMenuController *)hamburgerMenuController
{
    UIViewController *selectedController = [self viewControllerAtIndex:index hamburgerMenuController:hamburgerMenuController];
    if ([selectedController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navController = (UINavigationController *) selectedController;
        [navController popToRootViewControllerAnimated:YES];
    } else if (index == self.viewControllers.count) {
        [[LoginManager instance] logout];
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
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [self unsubscribeToUserNotification];
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
