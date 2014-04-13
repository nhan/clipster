//
//  SearchResultsViewController.m
//  Clipster
//
//  Created by Nhan Nguyen on 4/13/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "SearchResultsViewController.h"
#import <GTMOAuth2ViewControllerTouch.h>
#import <GTLServiceYouTube.h>
#import <GTLYouTubeConstants.h>


//static NSString *const DEFAULT_KEYWORD = @"ytdl";
//static NSString *const UPLOAD_PLAYLIST = @"Replace me with the playlist ID you want to upload into";
static NSString *const kClientID = @"631925512135-l32nr494d04d5epj2gqs3vbqgjdk3dv4.apps.googleusercontent.com";
static NSString *const kClientSecret = @"xNG1Lc9Ii9urSEu0A_hOtJjV";
static NSString *const kKeychainItemName = @"Clipster";

@interface SearchResultsViewController ()
@property (nonatomic, strong) GTLServiceYouTube *youtubeService;
@end

@implementation SearchResultsViewController

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
    // Initialize the youtube service & load existing credentials from the keychain if available
    self.youtubeService = [[GTLServiceYouTube alloc] init];
    self.youtubeService.authorizer =
    [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
                                                          clientID:kClientID
                                                      clientSecret:kClientSecret];
    if (![self isAuthorized]) {
        // Not yet authorized, request authorization and push the login UI onto the navigation stack.
        [[self navigationController] pushViewController:[self createAuthController] animated:YES];
    }

}

- (BOOL)isAuthorized {
    return [((GTMOAuth2Authentication *)self.youtubeService.authorizer) canAuthorize];
}

- (GTMOAuth2ViewControllerTouch *)createAuthController
{
    GTMOAuth2ViewControllerTouch *authController;
    
    authController = [[GTMOAuth2ViewControllerTouch alloc] initWithScope:kGTLAuthScopeYouTube
                                                                clientID:kClientID
                                                            clientSecret:kClientSecret
                                                        keychainItemName:kKeychainItemName
                                                                delegate:self
                                                        finishedSelector:@selector(viewController:finishedWithAuth:error:)];
    return authController;
}

- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController finishedWithAuth:(GTMOAuth2Authentication *)authResult error:(NSError *)error {
    if (error != nil) {
        NSLog(@"Error: %@", error);
        self.youtubeService.authorizer = nil;
    } else {
        self.youtubeService.authorizer = authResult;
        NSLog(@"Authed: %@", authResult);
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
