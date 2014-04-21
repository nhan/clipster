//
//  ProfileViewController.m
//  Clipster
//
//  Created by Nathan Speller on 4/17/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "ProfileViewController.h"
#import "HamburgerMenuController.h"
#import "SmallClipCell.h"
#import "User.h"
#import "ProfileCell.h"
#import "VideoViewController.h"
#import "EditProfileViewController.h"

#import <MBProgressHud/MBProgressHUD.h>

@interface ProfileViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *clips;
@property (nonatomic, strong) User *user;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) ProfileCell *profileCell;
@property (nonatomic, strong) SmallClipCell *prototype;
@property (nonatomic, assign) BOOL isFriend;
@end

@implementation ProfileViewController

- (id)initWithUsername:(NSString *)username
{
    self = [super init];
    if (self) {
        _username = username;
        self.title = username;
        [self fetchUser];
        [self fetchClips];
        [self fetchFriendship];
    }
    return self;
}

- (id)initWithUser:(User *)user
{
    self = [super init];
    if (self) {
        self.title = @"Profile";
        _user = user;
        _username = user.username;
        [self fetchClips];
        [self fetchFriendship];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;

    if (self.navigationController.viewControllers.count == 1) {
        UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"] style:UIBarButtonItemStylePlain target:self action:@selector(onMenuButton:)];
        self.navigationItem.leftBarButtonItem = menuButton;
    }
    self.tableView.tableHeaderView = self.profileCell;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    UINib *clipNib = [UINib nibWithNibName:@"SmallClipCell" bundle:nil];
    self.prototype = [clipNib instantiateWithOwner:self options:nil][0];
    [self.tableView registerNib:clipNib forCellReuseIdentifier:@"ClipCell"];
    
    [self refreshUI];
}

- (ProfileCell *)profileCell
{
    if (!_profileCell) {
        UINib *profileCellNib = [UINib nibWithNibName:@"ProfileCell" bundle:nil];
        _profileCell = [profileCellNib instantiateWithOwner:self options:nil][0];
        _profileCell.delegate = self;
    }
    return _profileCell;
}

#pragma mark - ProfileCellDelegate
- (void)toggleFriendship:(User *)user
{
    User *currentUser = [User currentUser];
    if (self.isFriend) {
        [currentUser.friends removeObject:user];
    } else {
        [currentUser.friends addObject:user];
    }
    [currentUser saveInBackground];
    self.isFriend = !self.isFriend;
}

- (void)editProfile
{
    [self.navigationController pushViewController:[[EditProfileViewController alloc] init] animated:YES];
}

- (void)setUser:(User *)user
{
    _user = user;
    self.username = user.username;
    if (user == [User currentUser]) {
        self.title = @"Profile";
    }
    [self refreshUI];
}

- (void)setIsFriend:(BOOL)isFriend
{
    _isFriend = isFriend;
    [self refreshUI];
}

- (void) refreshUI
{
    self.profileCell.user = self.user;
    self.profileCell.isFriend = self.isFriend;
    self.profileCell.numberClips = self.clips.count;
    self.profileCell.numberFollowers = 1;
    self.profileCell.numberFollowing = 1;
    [self.tableView reloadData];
}

- (void)fetchUser
{
    User *currentUser = [User currentUser];
    if ([self.username isEqualToString:currentUser.username]) {
        self.user = currentUser;
    } else {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        PFQuery *query = [User query];
        [query whereKey:@"username" equalTo:self.username];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                // only one user should match
                if (objects.count == 1) {
                    self.user = objects[0];
                }
            } else {
                // Log details of the failure
                NSLog(@"Error: %@ %@", error, [error userInfo]);
            }
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        }];
    }
}

- (void)fetchFriendship
{
    User *currentUser = [User currentUser];
    PFQuery *query = [currentUser.friends query];
    [query whereKey:@"username" equalTo:self.username];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            NSLog(@"error fetching friendshipness");
        } else {
            if (objects.count == 1) {
                self.isFriend = YES;
            }
        }
    }];
}

- (void)fetchClips
{
    [Clip searchClipsForUsernames:@[self.username] completionHandler:^(NSArray *clips, NSError *error) {
        if (!error) {
            self.clips = clips;
            self.profileCell.numberClips = self.clips.count;
            [self.tableView reloadData];
        } else {
            // Log details of the failure
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDelegate and UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SmallClipCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ClipCell"];
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
    return [SmallClipCell heightForClip:[self.clips objectAtIndex:indexPath.row] cell:self.prototype];
}

@end
