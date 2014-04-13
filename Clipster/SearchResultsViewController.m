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
#import <GTLQueryYouTube.h>
#import <GTLYouTubeSearchListResponse.h>
#import <MBProgressHUD/MBProgressHUD.h>

//static NSString *const DEFAULT_KEYWORD = @"ytdl";
//static NSString *const UPLOAD_PLAYLIST = @"Replace me with the playlist ID you want to upload into";
static NSString *const kClientID = @"631925512135-l32nr494d04d5epj2gqs3vbqgjdk3dv4.apps.googleusercontent.com";
static NSString *const kClientSecret = @"xNG1Lc9Ii9urSEu0A_hOtJjV";
static NSString *const kKeychainItemName = @"Clipster";

@interface SearchResultsViewController ()
@property (nonatomic, strong) NSArray *searchResults;
@property (nonatomic, strong) GTLServiceYouTube *youtubeService;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end

@implementation SearchResultsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _searchResults = @[];
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
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    
    
    self.searchBar.delegate = self;
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

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
//    [self fetchMyChannelList];
    [self searchYouTube:searchBar.text];
}

- (void)searchYouTube:(NSString *) queryString{
    
    GTLServiceYouTube *service = self.youtubeService;
    
    GTLQueryYouTube *query = [GTLQueryYouTube queryForSearchListWithPart:@"snippet"];
    query.q = @"Victoria";
    query.type = @"video";
    
    // maxResults specifies the number of results per page.  Since we earlier
    // specified shouldFetchNextPages=YES, all results should be fetched,
    // though specifying a larger maxResults will reduce the number of fetches
    // needed to retrieve all pages.
    query.maxResults = 10;
    
    // We can specify the fields we want here to reduce the network
    // bandwidth and memory needed for the fetched collection.
    //
    // For example, leave query.fields as nil during development.
    // When ready to test and optimize your app, specify just the fields needed.
    // For example, this sample app might use
    //
    // query.fields = @"kind,etag,items(id,etag,kind,contentDetails)";
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [service executeQuery:query completionHandler:^(GTLServiceTicket *ticket, GTLYouTubeSearchListResponse *response, NSError *error) {
        if (error) {
            NSLog(@"Error --------------------------- !\n%@", error);
        } else {
            self.searchResults = response.items;
            [self.tableView reloadData];
        }
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }];
    
//    [self updateUI];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.searchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    GTLYouTubeSearchResult *result = self.searchResults[indexPath.row];


    return cell;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
