//
//  StreamViewController.m
//  Clipster
//
//  Created by Nathan Speller on 4/6/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "StreamViewController.h"
#import "ClipCell.h"
#import "VideoViewController.h"
#import "SearchResultsViewController.h"
#import "ProfileViewController.h"
#import "GifExportViewController.h"
#import "ClipsterColors.h"
#import <MBProgressHUD/MBProgressHUD.h>

@interface StreamViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *clips;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, assign) BOOL isDirty;
@property (nonatomic, strong) ClipCell *prototype;
@property (nonatomic, strong) ClipCell *currentPlayingCell;
@end

@implementation StreamViewController

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setStreamDirty) name:@"SetStreamDirty" object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    UINib *clipCellNib = [UINib nibWithNibName:@"ClipCell" bundle:nil];
    self.prototype = [clipCellNib instantiateWithOwner:self options:nil][0];
    [self.tableView registerNib:clipCellNib forCellReuseIdentifier:@"ClipCell"];
    
    UIBarButtonItem *profileButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"prof5"] style:UIBarButtonItemStylePlain target:self action:@selector(onProfileButton:)];
    self.navigationItem.leftBarButtonItem = profileButton;
    
    UIBarButtonItem *searchButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"search-2"] style:UIBarButtonItemStylePlain target:self action:@selector(onSearchButton:)];
    self.navigationItem.rightBarButtonItem = searchButton;
    
    UIImage *clipsterImage = [UIImage imageNamed:@"clipster"];
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:clipsterImage];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(fetchClips) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    [self fetchClips];
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SetStreamDirty" object:nil];
}

- (void)setStreamDirty
{
    self.isDirty = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.isDirty) {
        [self fetchClips];
    }
}

- (void)fetchClips
{
    // Get clips for current user and all friends
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [[User currentUser] fetchFollowingWithCompletionHandler:^(NSArray *friends, NSError *error) {
        if (!error) {
            NSMutableArray *users = [friends mutableCopy];
            [users addObject:[User currentUser]];
            [Clip searchClipsForUsers:users completionHandler:^(NSArray *clips, NSError *error) {
                if (!error) {
                    self.isDirty = NO;
                    self.clips = clips;
                    [self.tableView reloadData];
                } else {
                    NSLog(@"Error: %@ %@", error, [error userInfo]);
                }
                [self.refreshControl endRefreshing];
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            }];
        } else {
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
}

- (void)onProfileButton:(id)sender
{
    ProfileViewController *profileVC = [[ProfileViewController alloc] initWithUser:[User currentUser]];
    [self.navigationController pushViewController:profileVC animated:YES];
}

- (void)onSearchButton:(id)sender{
    SearchResultsViewController *searchVC = [[SearchResultsViewController alloc] init];
    [self.navigationController pushViewController:searchVC animated:YES];
}

#pragma mark - UITableViewDelegate and UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ClipCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ClipCell"];
    cell.clip = self.clips[indexPath.row];
    cell.delegate = self;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    VideoViewController *clipDetailsVC = [[VideoViewController alloc] initWithClip:self.clips[indexPath.row]];
    if (self.currentPlayingCell) {
        [self.currentPlayingCell pauseClip];
    }
    [self.navigationController pushViewController:clipDetailsVC animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.clips.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [ClipCell heightForClip:self.clips[indexPath.row] prototype:self.prototype];
}

#pragma mark - StreamCellDelegate

- (void)didClickUsername:(NSString *)username
{
    ProfileViewController *profileVC = [[ProfileViewController alloc] initWithUsername:username];
    [self.navigationController pushViewController:profileVC animated:YES];
}

- (void)willStartPlaying:(ClipCell *)cell
{
    if (self.currentPlayingCell && self.currentPlayingCell != cell) {
        [self.currentPlayingCell pauseClip];
    }
    
    self.currentPlayingCell = cell;
}

- (void)exportGif:(Clip *)clip
{
    GifExportViewController *giffyVC = [[GifExportViewController alloc] initWithClip:clip];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:giffyVC];
    navController.navigationBar.barTintColor = [ClipsterColors red];
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(cancelExportGif:)];
    cancelButton.tintColor = [UIColor colorWithWhite:255 alpha:1];
    giffyVC.navigationItem.leftBarButtonItem = cancelButton;
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)cancelExportGif:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
