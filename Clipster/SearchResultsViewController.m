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
#import "YouTubeCell.h"
#import "ProfileViewController.h"
#import "UserCell.h"

#define CLIP_SEARCH 0
#define USER_SEARCH 1
#define YOUTUBE_SEARCH 2


@interface UISearchBar (Textcolor)
- (void)setTextColor:(UIColor *)color;
@end

@implementation UISearchBar (TextColor)
- (void)setTextColor:(UIColor *)color
{
    // do a depth first search through the descendants of the search bar for a UITextView and set its color
    NSMutableArray* stack = [NSMutableArray arrayWithObject:self];
    while (stack.count > 0) {
        UIView *subview = [stack lastObject];
        [stack removeLastObject];
        
        if ([subview isKindOfClass:[UITextField class]]) {
            UITextField* textField = ((UITextField *) subview);
            textField.textColor = color;
            break;
        }
        [stack addObjectsFromArray:subview.subviews];
    }
}
@end

@interface SearchResultsViewController ()
@property (nonatomic, strong) NSArray *searchResults;
@property (nonatomic, strong) GTLServiceYouTube *youtubeService;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *searchTypeControl;
@property (nonatomic, strong) SmallClipCell *smallClipCellPrototype;
@property (nonatomic, strong) YouTubeCell *youTubeCellPrototype;
@property (nonatomic, strong) UISearchBar *searchBar;
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

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.navigationItem.hidesBackButton = YES;
    
    // Right cancel button
    UIBarButtonItem *rightCancel = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(onCancelButton:)];
    self.navigationItem.rightBarButtonItem = rightCancel;
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(-5.0, 0.0, 320.0, 44.0)];
    self.searchBar.tintColor = [UIColor whiteColor];
    self.searchBar.barTintColor = [UIColor whiteColor];
    [self.searchBar setTextColor:[UIColor whiteColor]];
    [self.searchBar setImage:[UIImage imageNamed:@"search-white"] forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
    [self.searchBar setImage:[UIImage imageNamed:@"close"] forSearchBarIcon:UISearchBarIconClear state:UIControlStateNormal];

    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UIView *searchBarView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 310.0, 44.0)];
    searchBarView.autoresizingMask = 0;
    self.searchBar.delegate = self;
    [searchBarView addSubview:self.searchBar];
    self.navigationItem.titleView = searchBarView;
    [self.searchBar becomeFirstResponder];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    UINib *nib = [UINib nibWithNibName:@"SmallClipCell" bundle:nil];
    self.smallClipCellPrototype = [nib instantiateWithOwner:self options:nil][0];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"ClipCell"];
    
    UINib *userNib = [UINib nibWithNibName:@"UserCell" bundle:nil];
    [self.tableView registerNib:userNib forCellReuseIdentifier:@"UserCell"];
    
    UINib *youTubeNib = [UINib nibWithNibName:@"YouTubeCell" bundle:nil];
    self.youTubeCellPrototype = [youTubeNib instantiateWithOwner:self options:nil][0];
    [self.tableView registerNib:youTubeNib forCellReuseIdentifier:@"YouTubeCell"];
    
    self.searchBar.delegate = self;
    
    // Initialize search to clips
    self.searchTypeControl.selectedSegmentIndex = CLIP_SEARCH;
}


- (void)onCancelButton:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
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
    YouTubeCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"YouTubeCell" forIndexPath:indexPath];
    YouTubeVideo *video = self.searchResults[indexPath.row];
    [cell setVideo:video];
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
    UserCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"UserCell" forIndexPath:indexPath];
    User *user = self.searchResults[indexPath.row];
    [cell setUser:user];
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
    if (self.searchTypeControl.selectedSegmentIndex == CLIP_SEARCH) {
        CGFloat estimatedHeight = [SmallClipCell heightForClip:self.searchResults[indexPath.row] cell:self.smallClipCellPrototype];
        return estimatedHeight;
    } else if (self.searchTypeControl.selectedSegmentIndex == USER_SEARCH) {
        return 74;
    } else if (self.searchTypeControl.selectedSegmentIndex == YOUTUBE_SEARCH) {
        CGFloat estimatedHeight = [YouTubeCell heightForVideo:self.searchResults[indexPath.row] cell:self.youTubeCellPrototype];
        return estimatedHeight;
        return 100;
    }
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
