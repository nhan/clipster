//
//  AppDelegate.m
//  Clipster
//
//  Created by Nathan Speller on 4/6/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "AppDelegate.h"
#import "MenuViewController.h"
#import "LoginViewController.h"
#import "ClipDetailsViewController.h"
#import <Parse/Parse.h>
#import "Clip.h"
#import "User.h"

@interface AppDelegate ()
@property (nonatomic, strong) MenuViewController *menuViewController;
@property (nonatomic, strong) LoginViewController *loginViewController;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.menuViewController = [[MenuViewController alloc] init];
    self.loginViewController = [[LoginViewController alloc] init];
    
    // Register my model sublcasses
    [Clip registerSubclass];
    [User registerSubclass];
    
    [Parse setApplicationId:@"ijASx0FwG5H1x75wkkAt3dVSd3f3COyX12ZvoXuv"
                  clientKey:@"LsmTAORgFrbm8r0hJqE8nI5Xcuv6dYy3YjXWP9Po"];
    [PFFacebookUtils initializeFacebook];
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    [self setRootViewController];
    [self subscribeToUserNotifications];
    
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
}

- (void)setRootViewController
{
//    PFUser *currentUser = [PFUser currentUser];
    self.window.rootViewController = [[ClipDetailsViewController alloc] init];
    
//    if (currentUser) {
//        self.window.rootViewController = self.menuViewController;
//        NSLog(@"%@", currentUser.username);
//    } else {
//        self.window.rootViewController = self.loginViewController;
//    }
}

- (void)subscribeToUserNotifications{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setRootViewController) name:@"UserDidLogin" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setRootViewController) name:@"UserDidLogout" object:nil];
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
