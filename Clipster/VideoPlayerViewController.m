//
//  VideoPlayerViewController.m
//  Clipster
//
//  Created by Nhan Nguyen on 4/23/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "VideoPlayerViewController.h"

static const NSInteger BaseTimeScale = 600;
static const NSString * PlayerItemStatusContext;
typedef void (^TimeObserverBlock)(float);


@interface VideoPlayerViewController ()
@property (weak, nonatomic) IBOutlet VideoPlayerView *playerView;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UIView *loadingOverlay;

@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *playerItem;

@property (copy) void (^readyBlock)(void);
@property (assign, nonatomic) BOOL isObservingStatus;

@property (strong, nonatomic) NSMutableDictionary *timeObservers;
@property (strong, nonatomic) id timeObserverHandle;

@property (nonatomic, assign) BOOL isReady;
@property (nonatomic, assign) BOOL shouldPlayWhenReady;

@property (nonatomic, strong) NSOperation *seekDoneOperation;

@property (strong, nonatomic) UIActivityIndicatorView *spinner;
@end

@implementation VideoPlayerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _player = [[AVPlayer alloc] init];
        _readyBlock = nil;
        _isObservingStatus = NO;
        
        _timeObservers = [NSMutableDictionary dictionary];
        
        // call timeObserverCallback ever 100 miliseconds of playblack
        __weak typeof(self) weakSelf = self;
        _timeObserverHandle = [_player addPeriodicTimeObserverForInterval:CMTimeMake(BaseTimeScale/10, BaseTimeScale) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            [weakSelf timeObserverCallback:time];
        }];
        
        _isReady = NO;
        _shouldPlayWhenReady = NO;
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];

    }
    return self;
}

- (void)dealloc
{
    [self.player removeTimeObserver:self.timeObserverHandle];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.loadingOverlay.alpha = 0.4f;

    self.currentTimeLabel.hidden = YES;
    self.spinner.hidesWhenStopped = YES;
    [self.view addSubview:self.spinner];
    [self.view bringSubviewToFront:self.spinner];
    
    [self.playerView setPlayer:self.player];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &PlayerItemStatusContext) {
        if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
            self.isReady = YES;
            // no longer need this observer once it's ready
            [self removeStatusObserverForPlayerItem:self.playerItem];

            // TODO: (nhan) should probably allow user to specify queue here, but we'd have to store it
            __weak typeof(self) weakSelf = self;
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (weakSelf.readyBlock) {
                    weakSelf.readyBlock();
                    weakSelf.readyBlock = nil;
                }

                NSOperation *playOperation = [NSBlockOperation blockOperationWithBlock:^{
                    if (weakSelf.shouldPlayWhenReady) {
                        [weakSelf.player play];
                        [weakSelf hideLoadingState];
                        weakSelf.shouldPlayWhenReady = NO;
                    }
                }];
                
                if (self.seekDoneOperation) {
                    [playOperation addDependency:self.seekDoneOperation];
                }
                [[NSOperationQueue mainQueue] addOperation:playOperation];
            }];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)showLoadingState
{
    self.spinner.center = self.view.center;
    self.loadingOverlay.hidden = NO;
    self.playerView.hidden = YES;
    [self.spinner startAnimating];
}

- (void)hideLoadingState
{
    [self.spinner stopAnimating];
    self.loadingOverlay.hidden = YES;
    self.playerView.hidden = NO;
}

- (void)loadVideoWithURL:(NSURL *)url ready:(void (^)(void))readyBlock
{
    [self showLoadingState];
    // remove observer on old playerItem before creating a new one in case the old one has not finished loading
    [self removeStatusObserverForPlayerItem:self.playerItem];
    
    self.readyBlock = readyBlock;
    self.playerItem = [AVPlayerItem playerItemWithURL:url];
    [self addStatusObserverForPlayerItem:self.playerItem];
    [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
}

- (void)addStatusObserverForPlayerItem:(AVPlayerItem *)item
{
    NSAssert(!self.isObservingStatus, @"Tried to add a status observer to AVPlayerItem when one was already present!");
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial context:&PlayerItemStatusContext];
    self.isObservingStatus = YES;
}

- (void)removeStatusObserverForPlayerItem:(AVPlayerItem *)item
{
    if (self.isObservingStatus) {
        [item removeObserver:self forKeyPath:@"status" context:&PlayerItemStatusContext];
        self.isObservingStatus = NO;
    }
}

- (void)timeObserverCallback:(CMTime)time
{
    self.currentTimeLabel.text = [NSString stringWithFormat:@"%f", CMTimeGetSeconds(time)];
    // TODO: (nhan) this is happening on the same queue that timeObserverCallback is being called on (right now main queue).  Should allow for custom queue
    for (TimeObserverBlock block in self.timeObservers.allValues) {
        block(CMTimeGetSeconds(time));
    }
    
    // do looping behavior
    if (self.isLooping && CMTimeGetSeconds(time) >= self.endTime) {
        [self.player seekToTime:CMTimeMakeWithSeconds(self.startTime, BaseTimeScale)];
    }
}

- (NSString *)uuidString {
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidString = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);
    return uuidString;
}

- (id)addTimeObserverWithBlock:(void (^)(float))block
{
    if (block) {
        NSString *uuid = [self uuidString];
        [self.timeObservers setObject:block forKey:uuid];
        return uuid;
    }
    return nil;
}

- (void)removeTimeObserver:(id)observerId
{
    if (observerId) {
        [self.timeObservers removeObjectForKey:observerId];
    }
}

- (float)currentTimeInSeconds
{
    CMTime time = self.playerItem.currentTime;
    return CMTimeGetSeconds(time);
}

- (float)duration
{
    CMTime duration = self.playerItem.duration;
    return CMTimeGetSeconds(duration);
}

- (void)play
{
    if (self.isReady) {
        [self.player play];
        [self hideLoadingState];
    } else {
        self.shouldPlayWhenReady = YES;
    }
}

- (void)pause
{
    [self.player pause];
}

- (void)frameAtTimeWithSeconds:(float)time done:(void (^)(NSError *error, CGImageRef image))done;
{
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.playerItem.asset];
    CMTime cmTime = CMTimeMakeWithSeconds(time, 600);
    NSArray *timesArray = @[[NSValue valueWithCMTime:cmTime]];
    
    [imageGenerator generateCGImagesAsynchronouslyForTimes:timesArray completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
        if (result == AVAssetImageGeneratorSucceeded) {
            done(nil, image);
        } else if (result == AVAssetImageGeneratorFailed) {
            done(error, nil);
        } else if (result == AVAssetImageGeneratorCancelled) {
            NSError *canceledError = [NSError errorWithDomain:@"VideoPlayerViewController: frame capture canceled" code:1 userInfo:nil];
            done(canceledError, nil);
        }
    }];
}

- (void)seekToTime:(float)time done:(void (^)())done
{
    __weak typeof(self) weakSelf = self;
    self.seekDoneOperation = [NSBlockOperation blockOperationWithBlock:^{
        if (done) {
            done();
        }
        weakSelf.seekDoneOperation = nil;
    }];
    
    if (self.isReady) {
        CMTime cmTime = CMTimeMakeWithSeconds(time, BaseTimeScale);
        [self.playerItem seekToTime:cmTime completionHandler:^(BOOL finished) {
            NSLog(@"Seek to time: %f", time);
            [[NSOperationQueue mainQueue] addOperation:self.seekDoneOperation];
        }];
    } else {
        NSLog(@"Warning: failed to seek because player was not ready");
        [[NSOperationQueue mainQueue] addOperation:self.seekDoneOperation];
    }
}

- (void)setStartTime:(float)startTime
{
    _startTime = startTime;
    if (self.isReady && self.currentTimeInSeconds < self.startTime) {
        [self seekToTime:startTime done:nil];
    }
}

@end
