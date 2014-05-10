//
//  GifExportViewController.m
//  Clipster
//
//  Created by Nhan Nguyen on 5/9/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "GifExportViewController.h"
#import "VideoPlayerViewController.h"
#import "YouTubeParser.h"
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "UIImage+animatedGIF.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface GifExportViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *gifImage;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (strong, nonatomic) VideoPlayerViewController *videoPlayer;
@property (strong, nonatomic) Clip *clip;
@property (strong, nonatomic) NSOperationQueue *myQueue;
@property (weak, nonatomic) IBOutlet UIButton *saveToCameraRollButton;
@end

@implementation GifExportViewController

- (id)initWithClip:(Clip *)clip
{
    self = [super init];
    if (self) {
        self.title = @"Export GIF";
        _clip = clip;
        _videoPlayer = [[VideoPlayerViewController alloc] init];
        _myQueue = [[NSOperationQueue alloc] init];
        _myQueue.name =  @"Gif Generation Queue";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.descriptionLabel.text = self.clip.text;
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [YouTubeParser videoURLWithYoutubeID:self.clip.videoId done:^(NSURL *videoURL, NSError *error) {
        if (!error) {
            __weak typeof(self) weakSelf = self;
            [self.videoPlayer loadVideoWithURL:videoURL ready:^{
                weakSelf.videoPlayer.endTime = weakSelf.clip.timeEnd / 1000.0f;
                weakSelf.videoPlayer.startTime = weakSelf.clip.timeStart / 1000.0f;
                [self.myQueue addOperationWithBlock:^{
                    [weakSelf generateGif];
                }];
                
            }];
        }
    }];
}

- (void)generateGif
{
    [self.videoPlayer framesForGifWithStartTime:(self.clip.timeStart/1000.0f) endTime:(self.clip.timeEnd/1000.0f) done:^(NSError *error, NSArray *frames) {
        if (!error) {
            NSLog(@"Creating gif with %d frames", frames.count);
            NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"clipster_animated.gif"];
            NSURL *url = [NSURL fileURLWithPath:path];
            
            CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)url, kUTTypeGIF, frames.count, NULL);
            NSDictionary *frameProperties = [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.1] forKey:(NSString *)kCGImagePropertyGIFDelayTime] forKey:(NSString *)kCGImagePropertyGIFDictionary];
            NSDictionary *gifProperties = [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCGImagePropertyGIFLoopCount]
                                                                      forKey:(NSString *)kCGImagePropertyGIFDictionary];
            
            for (UIImage *frame in frames) {
                CGImageDestinationAddImage(destination, frame.CGImage, (__bridge CFDictionaryRef)frameProperties);
            }
            CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)gifProperties);
            CGImageDestinationFinalize(destination);
            CFRelease(destination);
            
            __weak typeof(self) weakSelf = self;
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                UIImage *myGif = [UIImage animatedImageWithAnimatedGIFURL:(NSURL *)url];
                weakSelf.gifImage.image = myGif;
                [weakSelf.gifImage setClipsToBounds:YES];
                [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
            }];
        }
    }];

}

- (IBAction)clickSaveToCameraRoll:(UIButton *)sender
{
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"clipster_animated.gif"];
    NSURL *url = [NSURL fileURLWithPath:path];

    NSData *data = [NSData dataWithContentsOfURL:url];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    __weak typeof(self) weakSelf = self;
    [library writeImageDataToSavedPhotosAlbum:data metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
        self.saveToCameraRollButton.enabled = NO;
        [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
    }];
    
}

@end
