//
//  ClipDetailsViewController.m
//  Clipster
//
//  Created by Nathan Speller on 4/11/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "VideoViewController.h"
#import "Clip.h"
#import "SmallClipCell.h"
#import "ProfileViewController.h"
#import "YouTubeVideo.h"
#import "VideoControlView.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <HCYoutubeParser.h>

@interface HCYoutubeParser (Async)
+ (void)h264videosWithYoutubeID:(NSString *)youtubeID
                  completeBlock:(void(^)(NSDictionary *videoDictionary, NSError *error))completeBlock;
@end

@implementation HCYoutubeParser (Async)

+ (void)h264videosWithYoutubeID:(NSString *)youtubeID
                   completeBlock:(void(^)(NSDictionary *videoDictionary, NSError *error))completeBlock {
    if (youtubeID) {
        // change this queue name, what is it for anyways??
        dispatch_queue_t queue = dispatch_queue_create("me.hiddencode.yt.backgroundqueue", 0);
        dispatch_async(queue, ^{
            NSDictionary *dict = [HCYoutubeParser h264videosWithYoutubeID:youtubeID];
            dispatch_async(dispatch_get_main_queue(), ^{
                completeBlock(dict, nil);
            });
        });
    }
    else {
        completeBlock(nil, [NSError errorWithDomain:@"me.hiddencode.yt-parser" code:1001 userInfo:@{ NSLocalizedDescriptionKey: @"Invalid YouTube URL" }]);
    }
}

@end

@interface VideoViewController ()
@property (weak, nonatomic) IBOutlet UIView *videoPlayerContainer;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) MPMoviePlayerController *player;
@property (nonatomic, assign) CGPoint panStartPosition;
@property (nonatomic, strong) NSMutableArray *clips;
@property (nonatomic, strong) Clip *activeClip;
@property (nonatomic, strong) SmallClipCell *prototype;
@property (nonatomic, strong) Clip *aNewClip;

@property (nonatomic, strong) NSString *videoId;
@property (nonatomic, strong) NSString *videoTitle;
@property (weak, nonatomic) IBOutlet UIView *clippingPanel;
@property (nonatomic, assign) CGFloat clippingPanelPos;
@property (nonatomic, assign) CGFloat tableViewScrollPos;

@property (nonatomic, strong) UIView *videoControlView;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, assign) BOOL isVideoPlaying;
@property (nonatomic, strong) VideoControlView *scrubView;
@property (nonatomic, assign) CGFloat currentPlaybackPosition;
@property (nonatomic, assign) NSTimeInterval currentPlaybackTime;
@property (nonatomic, strong) NSTimer *playbackMonitorTimer;
@property (nonatomic, assign) BOOL isScrubbing;
@property (nonatomic, assign) BOOL wasVideoPlayingBeforeScrub;
@property (nonatomic, assign) BOOL isVideoControlMinimized;
@property (nonatomic, assign) NSInteger numberTimerEventsSinceVideoInteraction;
@property (nonatomic, assign) CGFloat videoControlHeight;
@property (nonatomic, assign) CGFloat videoControlYOffset;
@property (nonatomic, strong) NSMutableArray *popularityHistogram;
@end

@implementation VideoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _clips = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)initWithClip:(Clip *)clip {
    self = [self initWithVideoId:clip.videoId andTitle:clip.videoTitle];
    if (self) {
        _activeClip = clip;
    }
    return self;
}

- (id)initWithVideoId:(NSString *)videoId andTitle:(NSString *)videoTitle
{
    self = [super self];
    if (self) {
        _videoId = videoId;
        _videoTitle = videoTitle;
    }
    return self;
}

- (void)fetchClips
{
    [MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Clip"];
    [query whereKey:@"videoId" equalTo:self.videoId];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            // The find succeeded.
            NSLog(@"Successfully retrieved %d clips.", objects.count);
            self.clips = [objects mutableCopy];
            
            // update histogram with clips
            [self addAllClipsToHistogram];
            
            NSInteger row = [self.clips indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                return [self.activeClip.objectId isEqualToString:((Clip *)obj).objectId];
            }];
            
            [self.tableView reloadData];
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0] animated:YES scrollPosition:UITableViewScrollPositionTop];
            [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0] animated:YES];
            
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
        [MBProgressHUD hideHUDForView:self.tableView animated:YES];
    }];
}

- (IBAction)clipAction:(id)sender
{
    self.aNewClip = [[Clip alloc] init];
    int currentTime = self.player.currentPlaybackTime * 1000;
    self.aNewClip.timeStart = currentTime;
    self.aNewClip.timeEnd = currentTime + 10000;
    self.aNewClip.videoId = self.videoId;
    self.aNewClip.videoTitle = self.videoTitle;
    self.aNewClip.user = (User *)[PFUser currentUser];
    
    [self.clips addObject:self.aNewClip];
    
    // animate to new cell
    [self.tableView reloadData];
    
    NSNumber *thumnailTime = [NSNumber numberWithFloat:(currentTime/1000.0f)];
    [self.player requestThumbnailImagesAtTimes:@[thumnailTime] timeOption:MPMovieTimeOptionExact];
}

- (void)setActiveClip:(Clip *)activeClip
{
    _activeClip = activeClip;
    self.player.currentPlaybackTime = self.activeClip.timeStart / 1000.0f;
}

- (void)thumnailRequestDone:(NSNotification *)notification
{
    if (notification.userInfo[MPMoviePlayerThumbnailImageKey]) {
        UIImage *thumbnail = notification.userInfo[MPMoviePlayerThumbnailImageKey];
        self.aNewClip.thumbnail = [PFFile fileWithData:UIImageJPEGRepresentation(thumbnail, 0.05f)];
        [self.aNewClip saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [self.tableView reloadData];
        }];
    }
    // Create even if thumbnail creation fails
//    [self creationDone:self.aNewClip];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerThumbnailImageRequestDidFinishNotification object:nil];
}

static const float VIDEO_MONITOR_INTERVAL = .2;
static const float VIDEO_CONTROL_MINIMIZE_INTERVAL = 3.;
static const int VIDEO_CONTROL_HEIGHT = 20;
static const int VIDEO_CONTROL_HEIGHT_MIN = 5;
static const int PLAY_BUTTON_WIDTH = 70;
static const int NUMBER_HISTOGRAM_BINS = 100;

- (CGFloat)videoControlHeight
{
    return self.isVideoControlMinimized ? VIDEO_CONTROL_HEIGHT_MIN : VIDEO_CONTROL_HEIGHT;
}

#pragma mark - Custom Video Control
- (void)setupCustomVideoControl
{
    // add custom video control to player
    self.player.controlStyle = MPMovieControlStyleNone;
    
    UIView *movieView = self.player.view;
    
    // have to disable all previous gesture recognizers
    for (UIGestureRecognizer *gesture in movieView.gestureRecognizers) {
        gesture.enabled = NO;
    }
    UITapGestureRecognizer *tapVideoGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapVideo:)];
    tapVideoGesture.delegate = self;
    [movieView addGestureRecognizer:tapVideoGesture];
    
    self.videoControlView = [[UIView alloc] initWithFrame:CGRectMake(movieView.frame.origin.x, movieView.frame.size.height - self.videoControlHeight, movieView.frame.size.width, self.videoControlHeight)];
    self.videoControlView.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
    
    // play/pause region
    self.playButton = [[UIButton alloc] initWithFrame:CGRectMake(0,0,PLAY_BUTTON_WIDTH,self.videoControlHeight)];
    [self.playButton setTitle:@"P" forState:UIControlStateNormal];
    self.playButton.alpha = 0.3;
    [self.playButton addTarget:self action:@selector(onPlayButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControlView addSubview:self.playButton];
    
    // scrubbing/vis region
    self.scrubView = [[VideoControlView alloc] initWithFrame:CGRectMake(PLAY_BUTTON_WIDTH, 0, movieView.frame.size.width - PLAY_BUTTON_WIDTH, self.videoControlHeight)];
    self.scrubView.backgroundColor = [UIColor colorWithWhite:0.6 alpha:0.4];
    self.scrubView.color = [UIColor colorWithRed:61/255. green:190/255. blue:206/255. alpha:1.0];
    // Initialize popularity histogram
    self.popularityHistogram = [[NSMutableArray alloc] init];
    for (int i=0; i<NUMBER_HISTOGRAM_BINS; i++) {
        [self.popularityHistogram addObject:@0.0];
    }
    self.scrubView.popularityHistogram = self.popularityHistogram;
    
    UIPanGestureRecognizer *panScrub = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panScrubber:)];
    [self.scrubView addGestureRecognizer:panScrub];
    [self.videoControlView addSubview:self.scrubView];
    
    // Setting the current playback position will set playback time and progress
    self.currentPlaybackPosition = 0;
    
    [movieView addSubview:self.videoControlView];
    [movieView bringSubviewToFront:self.videoControlView];
}

- (void)addAllClipsToHistogram
{
    NSTimeInterval duration = self.player.duration;
    if (duration == 0) {
        NSTimer *timer = [NSTimer timerWithTimeInterval:VIDEO_MONITOR_INTERVAL target:self selector:@selector(addAllClipsToHistogram) userInfo:nil repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        return;
    }
    for (int i=0; i<self.popularityHistogram.count; i++) {
        self.popularityHistogram[i] = @0;
    }
    for (Clip *clip in self.clips) {
        [self addClipToHistogram:clip];
    }
}

- (void)addClipToHistogram:(Clip *)clip
{
    float durationMS = self.player.duration * 1000.0f;
    int startBin = floor(clip.timeStart*NUMBER_HISTOGRAM_BINS/durationMS);
    int endBin = ceil(clip.timeEnd*NUMBER_HISTOGRAM_BINS/durationMS);
    for (int i=startBin; i<endBin; i++) {
        self.popularityHistogram[i] = @([self.popularityHistogram[i] floatValue] + 0.2);
    }
    [self.videoControlView setNeedsDisplay];
}

- (void)setIsVideoControlMinimized:(BOOL)isVideoControlMinimized
{
    _isVideoControlMinimized = isVideoControlMinimized;
    
    // hid the play button
    UIView *movieView = self.player.view;
    self.playButton.hidden = isVideoControlMinimized;
    self.videoControlView.frame = CGRectMake(movieView.frame.origin.x, movieView.frame.size.height - self.videoControlHeight, movieView.frame.size.width, self.videoControlHeight);
    self.scrubView.frame = CGRectMake(PLAY_BUTTON_WIDTH, 0, movieView.frame.size.width - PLAY_BUTTON_WIDTH, self.videoControlHeight);
    // set past frame resizes automatically
    self.currentPlaybackPosition = self.currentPlaybackPosition;
}

- (void)setIsVideoPlaying:(BOOL)isVideoPlaying
{
    if (isVideoPlaying) {
        self.playButton.alpha = 0.3;
        [self.player play];
        [self startMonitorPlaybackTimer];
        
    } else if (!isVideoPlaying) {
        self.playButton.alpha = 1.;
        [self.player pause];
        [self stopMonitorPlaybackTimer];
    }
    self.numberTimerEventsSinceVideoInteraction = 0;
    _isVideoPlaying = isVideoPlaying;
}

- (void)startMonitorPlaybackTimer
{
    self.playbackMonitorTimer = [NSTimer timerWithTimeInterval:VIDEO_MONITOR_INTERVAL target:self selector:@selector(monitorPlayback) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.playbackMonitorTimer forMode:NSDefaultRunLoopMode];
}

- (void)stopMonitorPlaybackTimer
{
    [self.playbackMonitorTimer invalidate];
}

- (void)setCurrentPlaybackPosition:(CGFloat)currentPlaybackPosition
{
    // Change width of scrub depending on new playback position
    self.scrubView.currentPlaybackPosition = currentPlaybackPosition;
    [self.scrubView setNeedsDisplay];
    _currentPlaybackPosition = currentPlaybackPosition;
}

- (void)monitorPlayback
{
    if (self.player.duration) {
        // Set the playback position feedback
        CGFloat percentPlayed = self.player.currentPlaybackTime / self.player.duration;
        self.currentPlaybackPosition = self.scrubView.frame.size.width * percentPlayed;
    }
    
    // If we have not interacted with the video in a while lets minimize
    int maxNumberIntervalsBeforeMinimize = ceil(VIDEO_CONTROL_MINIMIZE_INTERVAL / VIDEO_MONITOR_INTERVAL);
    if (self.isVideoPlaying && !self.isVideoControlMinimized && self.numberTimerEventsSinceVideoInteraction++ > maxNumberIntervalsBeforeMinimize) {
        self.isVideoControlMinimized = YES;
    }
}

- (void)tapVideo:(UITapGestureRecognizer *)tapGesture
{
    // unminimize video controls
    self.numberTimerEventsSinceVideoInteraction = 0;
    self.isVideoControlMinimized = NO;
}

- (void)setIsScrubbing:(BOOL)isScrubbing
{
    if (!_isScrubbing && isScrubbing) {
        // Going from not scrubbing to scrubbing capture video play state
        self.wasVideoPlayingBeforeScrub = self.isVideoPlaying;
        self.isVideoPlaying = NO;
    } else if (_isScrubbing && !isScrubbing) {
        // Going from scrubbing to not scrubbing
        self.isVideoPlaying = self.wasVideoPlayingBeforeScrub;
    }
    _isScrubbing = isScrubbing;
}

- (void)panScrubber:(UIPanGestureRecognizer *)panGesture
{
    if (panGesture.state == UIGestureRecognizerStateBegan) {
        // might want to only start scrubbing if we are close to the current playback position
        self.isScrubbing = YES;
        self.numberTimerEventsSinceVideoInteraction = 0;
    } else if (panGesture.state == UIGestureRecognizerStateChanged && self.isScrubbing) {
        // change current playback time based on position
        CGPoint point = [panGesture locationInView:self.scrubView];
        self.currentPlaybackPosition = point.x;
        CGFloat percentPlayed = self.currentPlaybackPosition / self.scrubView.bounds.size.width;
        self.player.currentPlaybackTime = self.player.duration * percentPlayed;
        self.numberTimerEventsSinceVideoInteraction = 0;
    } else if (panGesture.state == UIGestureRecognizerStateEnded) {
        self.isScrubbing = NO;
    } else if (panGesture.state == UIGestureRecognizerStateFailed) {
        self.isScrubbing = NO;
    }
}

- (void)onPlayButtonClicked
{
    self.isVideoPlaying = !self.isVideoPlaying;
}

#pragma mark - UIView

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    [self setupClippingPanel];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(thumnailRequestDone:) name:MPMoviePlayerThumbnailImageRequestDidFinishNotification object:nil];

    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [HCYoutubeParser h264videosWithYoutubeID:self.videoId completeBlock:^(NSDictionary *videoDictionary, NSError *error) {
        
        // We need to consider what our video quality strategy should be
        // not all qualities will be available at all time and what our connectivity is
        NSString *videoURL = nil;
        
        if (videoDictionary && videoDictionary.count > 0) {
            videoURL = videoDictionary[@"medium"];
            if (!videoURL) {
                videoURL = [videoDictionary allValues][0];
            }
        }
        
        if (!videoURL) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Cannot view this video on mobile" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
        } else {
            self.player = [[MPMoviePlayerController alloc] initWithContentURL: [NSURL URLWithString:videoURL]];
            [self.player prepareToPlay];
            self.player.initialPlaybackTime = self.activeClip.timeStart / 1000.0f;
            [self updatePlayer];
            [self setupCustomVideoControl];
        }
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    UINib *clipCellNib = [UINib nibWithNibName:@"SmallClipCell" bundle:nil];
    self.prototype = [clipCellNib instantiateWithOwner:self options:nil][0];
    [self.tableView registerNib:clipCellNib forCellReuseIdentifier:@"ClipCell"];
    
    [self fetchClips];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.playbackMonitorTimer invalidate];
    [super viewWillDisappear:animated];
}

- (void)updatePlayer
{
    [self.player.view setFrame: self.videoPlayerContainer.frame];
    [self.videoPlayerContainer addSubview: self.player.view];
    [self.view bringSubviewToFront:self.videoPlayerContainer];
    self.player.fullscreen = NO;
    self.player.currentPlaybackTime = self.activeClip.timeStart / 1000.0f;
    
    self.isVideoPlaying = YES;
}

#pragma mark - ClipCreationDelegate

- (void)creationDone:(Clip *)clip
{
    [clip saveInBackground];
    NSInteger row = [self.clips indexOfObject:clip];
    
    // We need to add the clip to the histogram
    [self addClipToHistogram:clip];
    
    // When we finish adding clip we need to sort correctly
    [self.tableView reloadData];
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0] animated:YES scrollPosition:UITableViewScrollPositionTop];
    
    [self updatePlayer];
    
    // Dirty the stream when we've created a new clip
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SetStreamDirty" object:nil];
}

- (void)creationCanceled
{
    [self updatePlayer];
}

- (void)setupClippingPanel
{
    self.clippingPanelPos = self.clippingPanel.frame.origin.y;
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(scrollClippingPanel:)];
    panGestureRecognizer.delegate = self;
    [self.tableView addGestureRecognizer:panGestureRecognizer];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)scrollClippingPanel:(UIPanGestureRecognizer *)panGestureRecognizer{    
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        self.clippingPanelPos = self.clippingPanel.frame.origin.y;
        self.tableViewScrollPos = self.tableView.contentOffset.y;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ClipCellDelegate

- (void)didClickUsername:(NSString *)username
{
    ProfileViewController *profileVC = [[ProfileViewController alloc] initWithUsername:username];
    [self.navigationController pushViewController:profileVC animated:YES];
}

#pragma mark - UITableViewDelegate and UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SmallClipCell *cell = (SmallClipCell *)[self.tableView dequeueReusableCellWithIdentifier:@"ClipCell" forIndexPath:indexPath];
    Clip *clip = (Clip *)self.clips[indexPath.row];
    cell.clip = clip;
    cell.delegate = self;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    Clip *clip = self.clips[indexPath.row];
    if ([clip isPublished]) {
        self.activeClip = clip;
    } else {
        ClippingViewController *clippingVC = [[ClippingViewController alloc] initWithClip:clip moviePlayer:self.player];
        clippingVC.delegate = self;
        [self.player pause];
        [self.navigationController pushViewController:clippingVC animated:YES];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.clips.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [SmallClipCell heightForClip:[self.clips objectAtIndex:indexPath.row] cell:self.prototype];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.tableView.contentOffset.y <= 0) {
        self.clippingPanel.frame = CGRectMake(0, self.tableView.frame.origin.y, self.clippingPanel.frame.size.width, self.clippingPanel.frame.size.height);
    } else {
        CGFloat newPos = self.clippingPanelPos+ (self.tableViewScrollPos - self.tableView.contentOffset.y);
        if (newPos < (self.tableView.frame.origin.y-self.clippingPanel.frame.size.height)) {
            newPos = self.tableView.frame.origin.y-self.clippingPanel.frame.size.height;
        } else if (newPos > self.tableView.frame.origin.y){
            newPos = self.tableView.frame.origin.y;
        }
        self.clippingPanel.frame = CGRectMake(0, newPos, self.clippingPanel.frame.size.width, self.clippingPanel.frame.size.height);
    }
}
@end
