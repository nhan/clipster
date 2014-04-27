//
//  EditProfileViewController.m
//  Clipster
//
//  Created by Anthony Sherbondy on 4/21/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "EditProfileViewController.h"
#import "User.h"

#import <Parse/Parse.h>

@interface EditProfileViewController ()
@property (weak, nonatomic) IBOutlet PFImageView *profileThumbnailView;
@property (nonatomic, strong) NSMutableData *thumbnailData;
@property (nonatomic, strong) NSMutableData *coverData;
@property (nonatomic, strong) NSURLConnection *thumbnailConnection;
@property (nonatomic, strong) NSURLConnection *coverConnection;
@end

@implementation EditProfileViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"Edit Profile";
    [self refreshUI];
}

- (void)refreshUI
{
    User *user = [User currentUser];
    
    if (user.thumbnail) {
        self.profileThumbnailView.file = user.thumbnail;
        [self.profileThumbnailView loadInBackground];
    } else {
        self.profileThumbnailView.image = [UIImage imageNamed:@"tim.png"];
    }
    [self.profileThumbnailView setClipsToBounds:YES];
    self.profileThumbnailView.layer.cornerRadius = self.profileThumbnailView.frame.size.width/2;
    self.profileThumbnailView.layer.masksToBounds = YES;
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

- (IBAction)linkWithFacebookClicked:(id)sender
{
    User *user = [User currentUser];
    if (![PFFacebookUtils isLinkedWithUser:user]) {
        [PFFacebookUtils linkUser:user permissions:nil block:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                // facebook link succeeded
                [self updateUserFromFacebook];
            }
        }];
    } else {
        // already linked user
        [self updateUserFromFacebook];
    }
}

@end
