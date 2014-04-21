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
@property (nonatomic, strong) NSMutableData *imageData;
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

- (void)updateProfileThumbnailWithFacebook
{
    // Create request for user's Facebook data
    FBRequest *request = [FBRequest requestForMe];

    // Send request to Facebook
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            // result is a dictionary with the user's Facebook data
            NSDictionary *userData = (NSDictionary *)result;
            NSString *facebookID = userData[@"id"];
            
            // URL should point to https://graph.facebook.com/{facebookId}/picture?type=large&return_ssl_resources=1
            NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID]];
            
            // Download the user's facebook profile picture
            _imageData = [[NSMutableData alloc] init]; // the data will be loaded in here
            NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:pictureURL
                                                                      cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                                  timeoutInterval:2.0f];
            // Run network request asynchronously
            NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
            
        }
    }];
}

// Called every time a chunk of the data is received
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.imageData appendData:data]; // Build the image
}

// Called when the entire image is finished downloading
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // Set the thumbnail image for current user and save
    User *user = [User currentUser];
    user.thumbnail = [PFFile fileWithData:self.imageData];
    [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [self refreshUI];
    }];
}

- (IBAction)linkWithFacebookClicked:(id)sender
{
    User *user = [User currentUser];
    if (![PFFacebookUtils isLinkedWithUser:user]) {
        [PFFacebookUtils linkUser:user permissions:nil block:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                // facebook link succeeded
                [self updateProfileThumbnailWithFacebook];
            }
        }];
    } else {
        // already linked user
        [self updateProfileThumbnailWithFacebook];
    }
}

@end
