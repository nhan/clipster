//
//  VideoCell.m
//  Clipster
//
//  Created by Nathan Speller on 4/6/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "ClipCell.h"
#import "YouTubeVideo.h"
#import "YouTubeParser.h"
#import "ProfileViewController.h"
#import "VideoPlayerViewController.h"
//#import <QuartzCore/QuartzCore.h>

@interface ClipCell ()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet PFImageView *clipThumnailImageView;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *youTubeLabel;
@property (weak, nonatomic) IBOutlet UIView *thumbnailContainer;
@property (weak, nonatomic) IBOutlet UIView *card;
@property (weak, nonatomic) IBOutlet PFImageView *profileThumbnailView;
@property (weak, nonatomic) IBOutlet UIButton *likeButton;
@property (weak, nonatomic) IBOutlet UILabel *timeAgoLabel;
@property (weak, nonatomic) IBOutlet UILabel *likeCountLabel;

- (IBAction)onLikeButton:(id)sender;

@property (nonatomic, strong) VideoPlayerViewController *videoPlayer;
@property (nonatomic, assign) BOOL likeButtonState;
@property (nonatomic, assign) BOOL isVideoPlaying;
@property (nonatomic, assign) BOOL isVideoReady;
@property NSDictionary *titleLabelTextAttributes;
@end

@implementation ClipCell

static CGFloat lineHeight = 24.f;

- (void)awakeFromNib
{
    self.videoPlayer = [[VideoPlayerViewController alloc] init];
    self.videoPlayer.isLooping = YES;
    
    NSMutableParagraphStyle *style  = [[NSMutableParagraphStyle alloc] init];
    style.minimumLineHeight = lineHeight;
    style.maximumLineHeight = lineHeight;
    self.titleLabelTextAttributes = @{NSParagraphStyleAttributeName : style};
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [self addGestureRecognizers];
    
    [self.thumbnailContainer setClipsToBounds:YES];
    self.thumbnailContainer.layer.cornerRadius = self.thumbnailContainer.frame.size.width/2;
    self.thumbnailContainer.layer.masksToBounds = YES;
    self.thumbnailContainer.backgroundColor = [UIColor whiteColor];
    
    [self.card setClipsToBounds:YES];
    self.card.layer.cornerRadius = 5.0;
    
    self.card.layer.borderColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.28].CGColor;
    self.card.layer.borderWidth = 1;
}

- (void)addGestureRecognizers
{
    UITapGestureRecognizer *clipTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onClipThumbnailTap:)];
    self.clipThumnailImageView.userInteractionEnabled = YES;
    [self.clipThumnailImageView addGestureRecognizer:clipTapGestureRecognizer];
    
    UITapGestureRecognizer *userTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onUserThumbnailTap:)];
    [self.thumbnailContainer addGestureRecognizer:userTapGestureRecognizer];
    
    UITapGestureRecognizer *usernameTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onUserThumbnailTap:)];
    self.usernameLabel.userInteractionEnabled = YES;
    [self.usernameLabel addGestureRecognizer:usernameTapGestureRecognizer];

}

- (void)setClip:(Clip *)clip
{
    _clip = clip;
    self.isVideoReady = NO;
    self.isVideoPlaying = NO;
    [self removePlayer];
    [self refreshUI];
}

- (void)refreshUI
{
    
    if (self.clip.text == nil) {
        self.clip.text = @"";
    }
    
    self.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:self.clip.text attributes:self.titleLabelTextAttributes];
    
    self.usernameLabel.text = self.clip.username;
    self.timeAgoLabel.text = [self.clip timeAgo];
    [self refreshLikes];
    
    if (self.clip.thumbnail) {
        self.clipThumnailImageView.file = self.clip.thumbnail;
        [self.clipThumnailImageView loadInBackground];
    } else {
        self.clipThumnailImageView.image = [UIImage imageNamed:@"stream_thumbnail_placeholder.gif"];
    }
    [self.clipThumnailImageView setClipsToBounds:YES];
    self.clipThumnailImageView.layer.cornerRadius = 5.0;
    self.clipThumnailImageView.layer.masksToBounds = YES;

    self.youTubeLabel.text = self.clip.videoTitle;

    self.profileThumbnailView.alpha = 0.0;
    if ([self.clip.user isDataAvailable]) {
        [self refreshUserThumbnail:self.clip.user];
    } else {
        [self.clip.user fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (error) {
                NSLog(@"Error grabbing profile thumbnail: %@", error);
            } else {
                [self refreshUserThumbnail:(User *)object];
            }
        }];
    }
    
    self.likeButtonState = [self.clip isLikedByUser:[User currentUser]];
}

- (void)refreshUserThumbnail:(User *)user
{
    if (user.thumbnail) {
        self.profileThumbnailView.file = user.thumbnail;
        [self.profileThumbnailView loadInBackground];
    } else {
        self.profileThumbnailView.image = [UIImage imageNamed:@"profile-thumbnail-placeholder.png"];
    }
    [self.profileThumbnailView setClipsToBounds:YES];
    self.profileThumbnailView.layer.cornerRadius = self.profileThumbnailView.frame.size.width/2;
    self.profileThumbnailView.layer.masksToBounds = YES;
    self.profileThumbnailView.alpha = 1.0;
}

- (void)refreshLikes{
    if (self.likeButtonState) {
        UIImage *likedImage = [UIImage imageNamed:@"liked"];
        [self.likeButton setBackgroundImage:likedImage forState:UIControlStateNormal];
    } else {
        UIImage *likeImage = [UIImage imageNamed:@"like"];
        [self.likeButton setBackgroundImage:likeImage forState:UIControlStateNormal];
    }
    if (self.clip.likers.count == 0) {
        self.likeCountLabel.text = @"";
    }
    else if (self.clip.likers.count == 1){
        self.likeCountLabel.text = @"1 like";
    } else {
        self.likeCountLabel.text = [NSString stringWithFormat:@"%ld likes", (long)self.clip.likers.count];
    }
}

- (void)onUserThumbnailTap:(id)sender
{
    [self.delegate didClickUsername:self.clip.username];
}

- (void)removePlayer
{
    [self.videoPlayer pause];
    [self.videoPlayer.view removeFromSuperview];
    self.isVideoPlaying = NO;
}

- (void)addPlayer
{
    [self.videoPlayer.view setFrame:self.clipThumnailImageView.frame];
    [self.clipThumnailImageView addSubview:self.videoPlayer.view];
}

-(void)readyVideo
{
    [YouTubeParser videoURLWithYoutubeID:self.clip.videoId done:^(NSURL *videoURL, NSError *error) {
        if (!error) {
            __weak typeof(self) weakSelf = self;
            [self.videoPlayer loadVideoWithURL:videoURL ready:^{
                weakSelf.videoPlayer.endTime = weakSelf.clip.timeEnd / 1000.0f;
                weakSelf.videoPlayer.startTime = weakSelf.clip.timeStart / 1000.0f;
                [weakSelf.videoPlayer play];
                [weakSelf addPlayer];
            }];
        }
    }];
}

- (void)onClipThumbnailTap:(id)sender
{
    if (!self.isVideoReady) {
        [self readyVideo];
        self.isVideoReady = YES;
    } else {
        if (self.isVideoPlaying) {
            [self.videoPlayer pause];
            self.isVideoPlaying = NO;
        } else {
            [self.videoPlayer play];
            self.isVideoPlaying = YES;
        }
    }
}

- (IBAction)onLikeButton:(id)sender
{
    // toggle it instantly before making the query to parse
    self.likeButtonState = !self.likeButtonState;
    [self refreshLikes];
    
    [self.clip toggleLikeForClip:self.clip success:^(Clip *clip) {
        self.likeButtonState = [self.clip isLikedByUser:[User currentUser]];
    } failure:^(NSError *error) {
        NSLog(@"LIKE BUTTON ERROR: %@", error);
    }];
    [self refreshLikes];
}

+ (CGFloat)heightForClip:(Clip *)clip prototype:(ClipCell *)prototype
{
    if (clip.text == nil || clip.text.length == 0){
        return 320;
    }
    
    CGFloat nameWidth = prototype.titleLabel.frame.size.width;
    UIFont *font = prototype.titleLabel.font;
    CGSize constrainedSize = CGSizeMake(nameWidth, 9999);
    NSLog(@"%f %@", nameWidth, clip.text);
    
    NSMutableParagraphStyle *style  = [[NSMutableParagraphStyle alloc] init];
    style.minimumLineHeight = lineHeight;
    style.maximumLineHeight = lineHeight;
    
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          font, NSFontAttributeName,
                                          style, NSParagraphStyleAttributeName, nil];
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:clip.text attributes:attributesDictionary];
    
    CGRect requiredHeight = [string boundingRectWithSize:constrainedSize options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    
    return 340+(requiredHeight.size.height);
}

@end
