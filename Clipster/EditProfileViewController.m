//
//  EditProfileViewController.m
//  Clipster
//
//  Created by Anthony Sherbondy on 4/21/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "EditProfileViewController.h"
#import "User.h"

@interface EditProfileViewController ()
@property (weak, nonatomic) IBOutlet PFImageView *profileThumbnailView;
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

- (IBAction)linkWithFacebookClicked:(id)sender
{
}

@end
