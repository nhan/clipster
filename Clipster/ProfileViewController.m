//
//  ProfileViewController.m
//  Clipster
//
//  Created by Nathan Speller on 4/17/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "ProfileViewController.h"
#import "ProfileClipCell.h"
#import "User.h"
#import "ProfileCell.h"
#import "VideoViewController.h"
#import "EditProfileViewController.h"
#import "LoginManager.h"
#import "UIImage+ImageEffects.h"
#import <MBProgressHud/MBProgressHUD.h>

@interface ProfileViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *clips;
@property (nonatomic, strong) User *user;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) ProfileCell *profileCell;
@property (nonatomic, strong) ProfileClipCell *prototype;
@property (nonatomic, assign) BOOL isCurrentUserFollowing;
@property (nonatomic, strong) NSArray *following;
@property (weak, nonatomic) IBOutlet UIImageView *blurredBannerImage;
@property (nonatomic, strong) NSArray *followers;
@property (weak, nonatomic) IBOutlet UIImageView *bannerImage;

// facebook data
@property (nonatomic, strong) NSMutableData *thumbnailData;
@property (nonatomic, strong) NSMutableData *coverData;
@property (nonatomic, strong) NSURLConnection *thumbnailConnection;
@property (nonatomic, strong) NSURLConnection *coverConnection;
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
        [self fetchIfImFollowing];
        [self fetchFollowing];
        [self fetchFollowers];
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
        [self fetchIfImFollowing];
        [self fetchFollowing];
        [self fetchFollowers];
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
    // Do any additional setup after loading the view from its nib.
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;

    if ([self.username isEqualToString:[User currentUser].username]) {
        UIBarButtonItem *logoutButton = [[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStylePlain target:self action:@selector(onLogoutButton:)];
        self.navigationItem.rightBarButtonItem = logoutButton;
    }
    
//    self.blurredBannerImage.alpha = 0;
    
    self.tableView.tableHeaderView = self.profileCell;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    UINib *clipNib = [UINib nibWithNibName:@"ProfileClipCell" bundle:nil];
    self.prototype = [clipNib instantiateWithOwner:self options:nil][0];
    [self.tableView registerNib:clipNib forCellReuseIdentifier:@"ProfileClipCell"];
    [self refreshUI];
}

- (void)onLogoutButton:(id)sender{
    [[LoginManager instance] logout];
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
    if (self.isCurrentUserFollowing) {
        [currentUser.friends removeObject:user];
    } else {
        [currentUser.friends addObject:user];
    }
    [currentUser saveInBackground];
    self.isCurrentUserFollowing = !self.isCurrentUserFollowing;
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

- (void)setIsCurrentUserFollowing:(BOOL)isFriend
{
    _isCurrentUserFollowing = isFriend;
    [self refreshUI];
}

- (void) refreshUI
{
    self.profileCell.user = self.user;
    self.profileCell.currentUserIsFollowing = self.isCurrentUserFollowing;
    self.profileCell.numberClips = self.clips.count;
    self.profileCell.numberFollowers = self.followers.count;
    self.profileCell.numberFollowing = self.following.count;
    
    [self.tableView reloadData];
    
    if (self.user.cover) {
        [self.user.cover getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if (!error) {
                UIImage *image = [UIImage imageWithData:data];
                self.bannerImage.layer.masksToBounds = YES;
                [self.bannerImage setClipsToBounds:YES];
                
                self.blurredBannerImage.layer.masksToBounds = YES;
                [self.blurredBannerImage setClipsToBounds:YES];
                
                self.blurredBannerImage.image = [image applyDarkEffect];
                self.bannerImage.image = image;
            }
        }];
    } else {
        self.bannerImage.image = [UIImage imageNamed:@"carbon_fibre.png"];
        self.blurredBannerImage.image = [UIImage imageNamed:@"carbon_fibre.png"];
    }
    
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

- (void)fetchIfImFollowing
{
    User *currentUser = [User currentUser];
    PFQuery *query = [currentUser.friends query];
    [query whereKey:@"username" equalTo:self.username];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            NSLog(@"error fetching friendshipness");
        } else {
            if (objects.count == 1) {
                self.isCurrentUserFollowing = YES;
            }
        }
    }];
}

- (void)fetchFollowing
{
    [self.user fetchFollowingWithCompletionHandler:^(NSArray *friends, NSError *error) {
        if (error) {
            NSLog(@"error fetching friendships");
        } else {
            self.following = friends;
            [self refreshUI];
        }
    }];
}

- (void)fetchFollowers
{
    // Create a query for People in Australia
    PFQuery *usernameQuery = [User query];
    [usernameQuery whereKey:@"username" equalTo:self.username];
    
    // Create a query for Places liked by People in Australia.
    PFQuery *friendsQuery = [User query];
    [friendsQuery whereKey:@"friends" matchesQuery:usernameQuery];
    [friendsQuery findObjectsInBackgroundWithBlock:^(NSArray *followers, NSError*error) {
        if (error) {
            NSLog(@"error fetching followers");
        } else {
            self.followers = followers;
            [self refreshUI];
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


#pragma mark - UITableViewDelegate and UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ProfileClipCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ProfileClipCell"];
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
    return [ProfileClipCell heightForClip:[self.clips objectAtIndex:indexPath.row] cell:self.prototype];
}

#pragma mark - ScrollView
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.tableView.contentOffset.y > 0) {
        //move it up at proper size
        CGRect newFrame = CGRectMake(0,-self.tableView.contentOffset.y, 320, 200);
        self.bannerImage.frame = newFrame;
        self.blurredBannerImage.frame = newFrame;
    } else {
        //grow
        CGRect newFrame = CGRectMake(0,0, 320, 200-self.tableView.contentOffset.y);
        self.bannerImage.frame = newFrame;
        self.blurredBannerImage.frame = newFrame;
        self.blurredBannerImage.alpha = 1+self.tableView.contentOffset.y/100.0;
    }
}

#pragma mark - Facebook Update
- (void)editProfile
{
    User *user = [User currentUser];
    if (![PFFacebookUtils isLinkedWithUser:user]) {
        [PFFacebookUtils linkUser:user permissions:nil block:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                // facebook link succeeded
                [self updateUserFromFacebook];
            } else {
                NSLog(@"Failed Facebook Authentication because %@", error);
            }
        }];
    } else {
        // already linked user
        [self updateUserFromFacebook];
    }
}

- (void)updateUserFromFacebook
{
    [FBRequestConnection startWithGraphPath:@"me?fields=id,name,cover"
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                              if (!error) {
                                  // Sucess! Include your code to handle the results here
                                  // result is a dictionary with the user's Facebook data
                                  NSDictionary *userData = (NSDictionary *)result;
                                  NSString *facebookID = userData[@"id"];
                                  NSString *coverURL = [userData valueForKeyPath:@"cover.source"];
                                  
                                  if (facebookID) {
                                      [self updateProfileThumbnailWithID:facebookID];
                                  }
                                  if (coverURL) {
                                      [self updateCoverWithURL:coverURL];
                                  }
                                  
                                  
                              } else {
                                  // An error occurred, we need to handle the error
                                  // See: https://developers.facebook.com/docs/ios/errors
                                  NSLog(@"Error updating cover photo");
                              }
                          }];
}

- (void)updateProfileThumbnailWithID:(NSString *)facebookID
{
    // URL should point to https://graph.facebook.com/{facebookId}/picture?type=large&return_ssl_resources=1
    NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID]];
    
    // Download the user's facebook profile picture
    self.thumbnailData = [[NSMutableData alloc] init]; // the data will be loaded in here
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:pictureURL
                                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                          timeoutInterval:2.0f];
    // Run network request asynchronously
    self.thumbnailConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
}

- (void)updateCoverWithURL:(NSString *)url
{
    // Download the user's facebook cover picture
    self.coverData = [[NSMutableData alloc] init]; // the data will be loaded in here
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                          timeoutInterval:2.0f];
    // Run network request asynchronously
    self.coverConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
}

#pragma mark - NSURLConnectionDelegate
// Called every time a chunk of the data is received
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (connection == self.thumbnailConnection) {
        [self.thumbnailData appendData:data];
    } else if (connection == self.coverConnection) {
        [self.coverData appendData:data];
    }
}

// Called when the entire image is finished downloading
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if (connection == self.thumbnailConnection) {
        // Set the thumbnail image for current user and save
        User *user = [User currentUser];
        user.thumbnail = [PFFile fileWithData:self.thumbnailData];
        [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [self refreshUI];
        }];
        NSLog(@"updated profile!");
    } else if (connection == self.coverConnection) {
        // Set the thumbnail image for current user and save
        User *user = [User currentUser];
        user.cover = [PFFile fileWithData:self.coverData];
        [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [self refreshUI];
        }];
        NSLog(@"updated cover!");
    }
}

@end
