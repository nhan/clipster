//
//  SearchResultsViewController.m
//  Clipster
//
//  Created by Nhan Nguyen on 4/13/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "SearchResultsViewController.h"
#import <MBProgressHUD/MBProgressHUD.h>

#import <AFNetworking/UIImageView+AFNetworking.h>

#import "HamburgerMenuController.h"
#import "SmallClipCell.h"
#import "VideoViewController.h"
#import "YouTubeVideo.h"
#import "ProfileViewController.h"

#define CLIP_SEARCH 0
#define USER_SEARCH 1
#define YOUTUBE_SEARCH 2

@interface SearchResultsViewController ()
@property (nonatomic, strong) NSArray *searchResults;
@property (nonatomic, strong) GTLServiceYouTube *youtubeService;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *searchTypeControl;
@end

@implementation SearchResultsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Search";
        _searchResults = @[];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    UINib *nib = [UINib nibWithNibName:@"SmallClipCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"ClipCell"];
    
    self.searchBar.delegate = self;
    
    // Initialize search to clips
    self.searchTypeControl.selectedSegmentIndex = CLIP_SEARCH;
}

// Dismiss keyboard when we scroll the table
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.searchBar resignFirstResponder];
}

- (IBAction)searchTypeChanged:(id)sender
{
    // Clear the results
    self.searchResults = @[];
    [self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    switch (self.searchTypeControl.selectedSegmentIndex) {
        case CLIP_SEARCH:
            [self searchClips:searchBar.text];
            break;
        case USER_SEARCH:
            [self searchUsers:searchBar.text];
            break;
        case YOUTUBE_SEARCH:
            [self searchYouTube:searchBar.text];
            break;
    }
}

- (void)searchClips:(NSString *) queryString
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [Clip searchClipsWithQuery:queryString completionHandler:^(NSArray *clips, NSError *error) {
        if (error) {
            NSLog(@"Error searching clips ---------------------- !\n%@", error);
        } else {
            self.searchResults = clips;
            [self.tableView reloadData];
        }
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }];
}

- (void)searchUsers:(NSString *) queryString
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [User searchUsersWithQuery:queryString completionHandler:^(NSArray *users, NSError *error) {
        if (error) {
            NSLog(@"Error searching users ---------------------- !\n%@", error);
        } else {
            self.searchResults = users;
            [self.tableView reloadData];
        }
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }];
}

- (void)searchYouTube:(NSString *) queryString
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [YouTubeVideo searchVideosWithQuery:queryString completionHandler:^(NSArray *videos, NSError *error) {
        if (error) {
            NSLog(@"Error searching videos ---------------------- !\n%@", error);
        } else {
            self.searchResults = videos;
            [self.tableView reloadData];
        }
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.searchResults.count;
}

- (UITableViewCell *) cellForVideoRowAtIndexPath:(NSIndexPath *)indexPath
{
    SmallClipCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"ClipCell" forIndexPath:indexPath];
    YouTubeVideo *video = self.searchResults[indexPath.row];
    cell.clipTextLabel.text = video.title;
    [cell.thumbnail setImageWithURL:[NSURL URLWithString:video.thumbnailURL]];
    [cell refreshThumbnail];
    return cell;
}

- (UITableViewCell *) cellForClipRowAtIndexPath:(NSIndexPath *)indexPath
{
    SmallClipCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"ClipCell" forIndexPath:indexPath];
    Clip *clip = self.searchResults[indexPath.row];
    cell.clip = clip;
    return cell;
}

- (UITableViewCell *) cellForUserRowAtIndexPath:(NSIndexPath *)indexPath
{
    SmallClipCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"ClipCell" forIndexPath:indexPath];
    User *user = self.searchResults[indexPath.row];
    cell.clipTextLabel.text = user.username;
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (self.searchTypeControl.selectedSegmentIndex) {
        case CLIP_SEARCH:
            return [self cellForClipRowAtIndexPath:indexPath];
            break;
        case USER_SEARCH:
            return [self cellForUserRowAtIndexPath:indexPath];
            break;
        case YOUTUBE_SEARCH:
            return [self cellForVideoRowAtIndexPath:indexPath];
            break;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIViewController *vc = nil;
    if (self.searchTypeControl.selectedSegmentIndex == CLIP_SEARCH) {
        Clip *clip = self.searchResults[indexPath.row];
        vc = [[VideoViewController alloc] initWithClip:clip];
    } else if (self.searchTypeControl.selectedSegmentIndex == USER_SEARCH) {
        User *user = self.searchResults[indexPath.row];
        vc = [[ProfileViewController alloc] initWithUser:user];
    } else if (self.searchTypeControl.selectedSegmentIndex == YOUTUBE_SEARCH) {
        YouTubeVideo *video = self.searchResults[indexPath.row];
        vc = [[VideoViewController alloc] initWithVideoId:video.videoId andTitle:video.title];
    }
    [self.navigationController pushViewController:vc animated:YES];
}

@end
