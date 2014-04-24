//
//  VideoCell.m
//  Clipster
//
//  Created by Nathan Speller on 4/6/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "ClipCell.h"
#import "YouTubeVideo.h"
#import "ProfileViewController.h"
//#import <QuartzCore/QuartzCore.h>

@interface ClipCell ()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet PFImageView *thumbnail;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *youTubeLabel;
@property (weak, nonatomic) IBOutlet UIView *thumbnailContainer;
@property (weak, nonatomic) IBOutlet UIView *card;
@property (weak, nonatomic) IBOutlet PFImageView *profileThumbnailView;
@property (weak, nonatomic) IBOutlet UIButton *likeButton;
@property (weak, nonatomic) IBOutlet UILabel *timeAgoLabel;
@property (weak, nonatomic) IBOutlet UILabel *likeCountLabel;
- (IBAction)onLikeButton:(id)sender;
@end

@implementation ClipCell

static CGFloat lineHeight = 24.f;

- (void)setClip:(Clip *)clip
{
    _clip = clip;
    [self refreshUI];
}

- (void)refreshUI
{
    NSMutableParagraphStyle *style  = [[NSMutableParagraphStyle alloc] init];
    style.minimumLineHeight = lineHeight;
    style.maximumLineHeight = lineHeight;
    NSDictionary *attributes = @{NSParagraphStyleAttributeName : style,};
    
    if (self.clip.text == nil) {
        self.clip.text = @"";
    }
    self.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:self.clip.text
                                                                         attributes:attributes];
    
    self.usernameLabel.text = self.clip.username;
    self.timeAgoLabel.text = [self.clip timeAgo];
    [self refreshLikes];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (self.clip.thumbnail) {
        self.thumbnail.file = self.clip.thumbnail;
        [self.thumbnail loadInBackground];
    } else {
        self.thumbnail.image = [UIImage imageNamed:@"stream_thumbnail_placeholder.gif"];
    }
    [self.thumbnail setClipsToBounds:YES];
    self.thumbnail.layer.cornerRadius = 5.0;
    self.thumbnail.layer.masksToBounds = YES;
    self.profileThumbnailView.alpha = 0.0;
    
    [self.thumbnailContainer setClipsToBounds:YES];
    self.thumbnailContainer.layer.cornerRadius = self.thumbnailContainer.frame.size.width/2;
    self.thumbnailContainer.layer.masksToBounds = YES;
    self.thumbnailContainer.backgroundColor = [UIColor whiteColor];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onThumbnailTap:)];
    [self.thumbnailContainer addGestureRecognizer:tapGestureRecognizer];
    
    [self.card setClipsToBounds:YES];
    self.card.layer.cornerRadius = 5.0;
    
//    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:self.card.bounds];
//    self.card.layer.masksToBounds = NO;
//    self.card.layer.shadowColor = [UIColor blackColor].CGColor;
//    self.card.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
//    self.card.layer.shadowOpacity = 0.1f;
//    self.card.layer.shadowPath = shadowPath.CGPath;
    self.card.layer.borderColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.28].CGColor;
    self.card.layer.borderWidth = 1;

    self.youTubeLabel.text = self.clip.videoTitle;

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
}

- (void)refreshUserThumbnail:(User *)user
{
    if (user.thumbnail) {
        self.profileThumbnailView.file = user.thumbnail;
        [self.profileThumbnailView loadInBackground];
    } else {
        self.profileThumbnailView.image = [UIImage imageNamed:@"tim.png"];
    }
    [self.profileThumbnailView setClipsToBounds:YES];
    self.profileThumbnailView.layer.cornerRadius = self.profileThumbnailView.frame.size.width/2;
    self.profileThumbnailView.layer.masksToBounds = YES;
    self.profileThumbnailView.alpha = 1.0;
}

- (void)refreshLikes{
    if ([self.clip isLikedByUser:[User currentUser]]) {
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

- (void)onThumbnailTap:(id)sender{
    [self.delegate didClickUsername:self.clip.username];
}

- (IBAction)onLikeButton:(id)sender {
    [self.clip toggleLikeForClip:self.clip success:^(Clip *clip) {
        [self refreshLikes];
    } failure:^(NSError *error) {
        NSLog(@"LIKE BUTTON ERROR: %@", error);
    }];
}

+ (CGFloat)heightForClip:(Clip *)clip prototype:(ClipCell *)prototype{
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
