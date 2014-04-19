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
#import <MBProgressHud/MBProgressHUD.h>

@interface ProfileViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *clips;
@property (nonatomic, strong) User *user;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) ProfileCell *profileCell;
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

- (void)setUser:(User *)user
{
    _user = user;
    self.username = user.username;
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
    [self.tableView reloadData];
}

- (void)fetchUser
{
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
    SmallClipCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SmallClipCell"];
    cell.clip = self.clips[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.clips.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 120;
}

@end
