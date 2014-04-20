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
#import "HamburgerMenuController.h"
#import <MBProgressHUD/MBProgressHUD.h>

@interface StreamViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *clips;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, assign) BOOL isDirty;
@end

@implementation StreamViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Stream";
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
    [self.tableView registerNib:clipCellNib forCellReuseIdentifier:@"ClipCell"];
    
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"] style:UIBarButtonItemStylePlain target:self action:@selector(onMenuButton:)];
    self.navigationItem.leftBarButtonItem = menuButton;
    
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
    [[User currentUser] fetchFriendsWithCompletionHandler:^(NSArray *friends, NSError *error) {
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

- (void)onMenuButton:(id)sender
{
    HamburgerMenuController* menuController = self.navigationController.hamburgerMenuController;
    NSLog(@"Hamburger Menu %@", menuController);
    if (menuController.isMenuRevealed) {
        [menuController hideMenuWithDuration:menuController.maxAnimationDuration];
    } else {
        [menuController revealMenuWithDuration:menuController.maxAnimationDuration];
    }
}

#pragma mark - UITableViewDelegate and UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ClipCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ClipCell"];
    cell.clip = self.clips[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    VideoViewController *clipDetailsVC = [[VideoViewController alloc] initWithClip:self.clips[indexPath.row]];
    [self.navigationController pushViewController:clipDetailsVC animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.clips.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 240;
}

@end
