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
#import "VideoPlayerViewController.h"
#import "ClippingViewController.h"
#import "YouTubeVideo.h"
#import "VideoControlView.h"
#import "YouTubeParser.h"
#import "ClipsterColors.h"
#import <MBProgressHUD/MBProgressHUD.h>


@interface VideoViewController ()
@property (weak, nonatomic) IBOutlet PFImageView *thumbnailImage;
@property (weak, nonatomic) IBOutlet UIView *videoPlayerContainer;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *clippingPanel;

@property (nonatomic, assign) CGPoint panStartPosition;
@property (nonatomic, strong) NSMutableArray *clips;
@property (nonatomic, strong) Clip *activeClip;
@property (nonatomic, strong) SmallClipCell *prototype;

@property (nonatomic, strong) NSString *videoId;
@property (nonatomic, strong) NSString *videoTitle;
@property (nonatomic, assign) CGFloat clippingPanelPos;
@property (nonatomic, assign) CGFloat tableViewScrollPos;

@property (nonatomic, strong) VideoPlayerViewController *playerController;
@property (nonatomic, assign) NSInteger hudCounter;

@property (nonatomic, strong) UIButton *backButton;

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
@property (nonatomic, strong) id timeObserverHandle;
@property (weak, nonatomic) IBOutlet UIView *currentPlaybackLineView;
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

- (void)onBackButton:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (id)initWithVideoId:(NSString *)videoId andTitle:(NSString *)videoTitle
{
    self = [super init];
    if (self) {
        _hudCounter = 0;
        _videoId = videoId;
        _videoTitle = videoTitle;
        _playerController = [[VideoPlayerViewController alloc] init];
    }
    return self;
}

- (void)setActiveClip:(Clip *)activeClip
{
    _activeClip = activeClip;
    [self updatePlayerToActiveClip];
}

# pragma mark - UI updating

static const float VIDEO_MONITOR_INTERVAL = .1;
static const float VIDEO_CONTROL_MINIMIZE_INTERVAL = 3.;
static const int VIDEO_CONTROL_HEIGHT = 35;
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
    UIView *movieView = self.playerController.view;
    
    UITapGestureRecognizer *tapVideoGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapVideo:)];
    tapVideoGesture.delegate = self;
    [movieView addGestureRecognizer:tapVideoGesture];
    
    self.videoControlView = [[UIView alloc] initWithFrame:CGRectMake(movieView.frame.origin.x, movieView.frame.size.height - self.videoControlHeight, movieView.frame.size.width, self.videoControlHeight)];
    self.videoControlView.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
    
    // play/pause region
    self.playButton = [[UIButton alloc] initWithFrame:CGRectMake(0,0,PLAY_BUTTON_WIDTH,self.videoControlHeight)];
    self.playButton.alpha = 0.8;
    self.playButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.playButton addTarget:self action:@selector(onPlayButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControlView addSubview:self.playButton];
    
    // scrubbing/vis region
    self.scrubView = [[VideoControlView alloc] initWithFrame:CGRectMake(PLAY_BUTTON_WIDTH, 0, movieView.frame.size.width - PLAY_BUTTON_WIDTH, self.videoControlHeight)];
    self.scrubView.backgroundColor = [UIColor colorWithWhite:0.6 alpha:0.4];
    self.scrubView.color = [ClipsterColors green];
    // Initialize popularity histogram
    self.popularityHistogram = [[NSMutableArray alloc] init];
    for (int i=0; i<NUMBER_HISTOGRAM_BINS; i++) {
        [self.popularityHistogram addObject:@0.0];
    }
    self.scrubView.popularityHistogram = self.popularityHistogram;
    
    UIPanGestureRecognizer *panScrub = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panScrubber:)];
    [self.scrubView addGestureRecognizer:panScrub];
    UITapGestureRecognizer *tapScrub = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapScrubber:)];
    [self.scrubView addGestureRecognizer:tapScrub];
    [self.videoControlView addSubview:self.scrubView];
    
    // Setting the current playback position will set playback time and progress
    self.currentPlaybackPosition = 0;
    [self updateCurrentPlaybackLineViewWithPosition:self.currentPlaybackPosition];

    [movieView addSubview:self.videoControlView];
    [movieView bringSubviewToFront:self.videoControlView];
}

- (void)addAllClipsToHistogram
{
    for (int i=0; i<self.popularityHistogram.count; i++) {
        self.popularityHistogram[i] = @0;
    }
    for (Clip *clip in self.clips) {
        [self addClipToHistogram:clip];
    }
    // reload table simply because this is called once we have the timeline for clips
    [self.tableView reloadData];
}

- (void)addClipToHistogram:(Clip *)clip
{
    NSArray *timeBins = [self timeBinsForClip:clip];
    int startBin = [timeBins[0] integerValue];
    int endBin = [timeBins[1] integerValue];
    for (int i=startBin; i<endBin; i++) {
        self.popularityHistogram[i] = @([self.popularityHistogram[i] floatValue] + 0.2);
    }
    [self.videoControlView setNeedsDisplay];
}

- (NSArray *)timeBinsForClip:(Clip *)clip
{
    float durationMS = self.playerController.duration * 1000.0f;
    int startBin = floor(clip.timeStart*NUMBER_HISTOGRAM_BINS/durationMS);
    int endBin = ceil(clip.timeEnd*NUMBER_HISTOGRAM_BINS/durationMS);
    startBin = startBin < 0 ? 0 : startBin;
    endBin = endBin > (NUMBER_HISTOGRAM_BINS-1) ? (NUMBER_HISTOGRAM_BINS-1) : endBin;
    return @[@(startBin), @(endBin)];
}

- (CGRect)rectForClip:(Clip *)clip cell:(SmallClipCell *)cell
{
    NSArray *timeBins = [self timeBinsForClip:clip];
    // offset to midpoint of bins
    float startBin = [timeBins[0] floatValue];
    float endBin = [timeBins[1] floatValue];
    float sizeBin = (cell.frame.size.width - PLAY_BUTTON_WIDTH) / NUMBER_HISTOGRAM_BINS;
    float width = (endBin - startBin) * sizeBin;
    float x = startBin * sizeBin + PLAY_BUTTON_WIDTH;
    return CGRectMake(x, 0, width, cell.frame.size.height);
}

- (void)updateCurrentPlaybackLineViewWithPosition:(CGFloat)position
{
    // Let's respect the bins for position
    CGFloat width = self.view.frame.size.width - PLAY_BUTTON_WIDTH;
    CGFloat binnedPosition = (ceil(position*NUMBER_HISTOGRAM_BINS/width)-0.5) * width/NUMBER_HISTOGRAM_BINS;
    
    CGRect frame = self.currentPlaybackLineView.frame;
    self.currentPlaybackLineView.frame = CGRectMake(binnedPosition + PLAY_BUTTON_WIDTH, frame.origin.y, frame.size.width, frame.size.height);
}

- (void)setIsVideoControlMinimized:(BOOL)isVideoControlMinimized
{
    _isVideoControlMinimized = isVideoControlMinimized;
    
    // hide the play button
    UIView *movieView = self.playerController.view;
    self.playButton.hidden = isVideoControlMinimized;
    self.videoControlView.frame = CGRectMake(movieView.frame.origin.x, movieView.frame.size.height - self.videoControlHeight, movieView.frame.size.width, self.videoControlHeight);
    self.scrubView.frame = CGRectMake(PLAY_BUTTON_WIDTH, 0, movieView.frame.size.width - PLAY_BUTTON_WIDTH, self.videoControlHeight);
    
    // show/hide the back button
    self.backButton.hidden = isVideoControlMinimized;
    
    // set past frame resizes automatically
    self.currentPlaybackPosition = self.currentPlaybackPosition;
}

- (void)setIsVideoPlaying:(BOOL)isVideoPlaying
{
    if (isVideoPlaying) {
        [self.playButton setImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateNormal];
        [self.playerController play];
        [self startMonitorPlaybackTimer];
    } else if (!isVideoPlaying) {
        [self.playButton setImage:[UIImage imageNamed:@"play.png"] forState:UIControlStateNormal];
        [self.playerController pause];
        [self stopMonitorPlaybackTimer];
    }
    self.numberTimerEventsSinceVideoInteraction = 0;
    _isVideoPlaying = isVideoPlaying;
}

- (void)startMonitorPlaybackTimer
{
    __weak typeof(self) weakSelf = self;
    self.timeObserverHandle = [self.playerController addTimeObserverWithBlock:^(float time) {
        [weakSelf monitorPlayback:time];
    }];
}

- (void)stopMonitorPlaybackTimer
{
    [self.playerController removeTimeObserver:self.timeObserverHandle];
}

- (void)setCurrentPlaybackPosition:(CGFloat)currentPlaybackPosition
{
    // Change width of scrub depending on new playback position
    self.scrubView.currentPlaybackPosition = currentPlaybackPosition;
    [self.scrubView setNeedsDisplay];
    
    // Change position of current line view
    [self updateCurrentPlaybackLineViewWithPosition:_currentPlaybackPosition];
    
    _currentPlaybackPosition = currentPlaybackPosition;
}

- (void)monitorPlayback:(float)currentPlaybackTime
{
    // Set the playback position feedback
    CGFloat percentPlayed = currentPlaybackTime / self.playerController.duration;
    self.currentPlaybackPosition = self.scrubView.frame.size.width * percentPlayed;
    
    // If we have not interacted with the video in a while lets minimize
    int maxNumberIntervalsBeforeMinimize = ceil(VIDEO_CONTROL_MINIMIZE_INTERVAL / VIDEO_MONITOR_INTERVAL);
    
    if (self.isVideoPlaying && !self.isVideoControlMinimized && self.numberTimerEventsSinceVideoInteraction > maxNumberIntervalsBeforeMinimize) {
        self.isVideoControlMinimized = YES;
    } else {
        // Increment number of fires since video interaction
        self.numberTimerEventsSinceVideoInteraction++;
    }
}

- (void)tapVideo:(UITapGestureRecognizer *)tapGesture
{
    // unminimize video controls
    self.numberTimerEventsSinceVideoInteraction = 0;
    self.isVideoControlMinimized = NO;
}

- (void)tapScrubber:(UITapGestureRecognizer *)tapGesture
{
    CGPoint point = [tapGesture locationInView:self.scrubView];
    self.currentPlaybackPosition = point.x;
    CGFloat percentPlayed = self.currentPlaybackPosition / self.scrubView.bounds.size.width;
    [self.playerController seekToTime:(self.playerController.duration * percentPlayed) done:nil];
    self.numberTimerEventsSinceVideoInteraction = 0;
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
        [self.playerController seekToTime:(self.playerController.duration * percentPlayed) done:nil];
        self.numberTimerEventsSinceVideoInteraction = 0;
    } else if (panGesture.state == UIGestureRecognizerStateEnded) {
        self.isScrubbing = NO;
    } else if (panGesture.state == UIGestureRecognizerStateFailed) {
        self.isScrubbing = NO;
    }
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

- (void)onPlayButtonClicked
{
    self.isVideoPlaying = !self.isVideoPlaying;
}

#pragma mark - UIView

- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    [self setupClippingPanel];
    [self addPlayerViewToContainer];
    
    self.backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.backButton setImage:[UIImage imageNamed:@"back_btn.png"] forState:UIControlStateNormal];
    self.backButton.alpha = 0.5;
    self.backButton.frame = CGRectMake(5, 5, 50, 50);
    [self.backButton addTarget:self action:@selector(onBackButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.playerController.view addSubview:self.backButton];
    [self.playerController.view bringSubviewToFront:self.backButton];
    
    if (self.activeClip && self.activeClip.thumbnail) {
        self.thumbnailImage.file = self.activeClip.thumbnail;
        [self.thumbnailImage loadInBackground];
    }
    
    
    [self pendingNetworkRequest];
    
    [YouTubeParser videoURLWithYoutubeID:self.videoId done:^(NSURL *videoURL, NSError *error) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
        } else {
            // TODO: come up with a better way to call addAllClipsToHistogram without blocking the hud from disappearing
            // it has to wait three things to finish: clips to load, the video url parsing to finish, and the video to load
            [self pendingNetworkRequest];
            [self.playerController loadVideoWithURL:videoURL ready:^{
                [self updatePlayerToActiveClip];
                [self setupCustomVideoControl];
                [self pendingNetworkRequestDone];
                self.isVideoPlaying = TRUE;
            }];
            
        }
        
        [self pendingNetworkRequestDone];
    }];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    UINib *clipCellNib = [UINib nibWithNibName:@"SmallClipCell" bundle:nil];
    self.prototype = [clipCellNib instantiateWithOwner:self options:nil][0];
    [self.tableView registerNib:clipCellNib forCellReuseIdentifier:@"ClipCell"];
    [self fetchClips];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewWillAppear:(BOOL)animated{
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:YES
                                            withAnimation:UIStatusBarAnimationFade];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self stopMonitorPlaybackTimer];
    [super viewWillDisappear:animated];
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:NO
                                            withAnimation:UIStatusBarAnimationFade];
}

- (void)updatePlayerToActiveClip
{
    [self.playerController seekToTime:self.activeClip.timeStart/1000.0f done:nil];
}

- (void)addPlayerViewToContainer
{
    if (![self.playerController.view isDescendantOfView:self.videoPlayerContainer]) {
        [self.playerController.view setFrame: self.videoPlayerContainer.frame];
        [self.videoPlayerContainer addSubview: self.playerController.view];
    }
}

#pragma mark - Network fetching

- (void)fetchClips
{
    [self pendingNetworkRequest];
    PFQuery *query = [PFQuery queryWithClassName:@"Clip"];
    [query whereKey:@"videoId" equalTo:self.videoId];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            // The find succeeded.
            NSLog(@"Successfully retrieved %d clips.", objects.count);
            self.clips = [objects mutableCopy];
            
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
        [self pendingNetworkRequestDone];
    }];
}

#pragma mark - ClipCreationDelegate

- (void)creationDone:(Clip *)clip
{
    // Do we need this save if we are already saving after thumbnail?
    [clip saveInBackground];
    
    [self.playerController frameAtTimeWithSeconds:self.playerController.currentTimeInSeconds done:^(NSError *error, CGImageRef imageRef) {
        UIImage *image = [UIImage imageWithCGImage:imageRef];
        clip.thumbnail = [PFFile fileWithData:UIImageJPEGRepresentation(image, 0.05f)];
        [clip saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [self.tableView reloadData];
        }];
    }];
    
    // We need to add the clip to the histogram
    [self addClipToHistogram:clip];
    
    [self.clips addObject:clip];
    [self.tableView reloadData];
    
    // TODO: When we finish adding clip we need to sort correctly
    NSInteger row = [self.clips indexOfObject:clip];
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0] animated:YES scrollPosition:UITableViewScrollPositionTop];
    [self addPlayerViewToContainer];
    [self updatePlayerToActiveClip];
    self.isVideoPlaying = YES;
    
    // Dirty the stream when we've created a new clip
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SetStreamDirty" object:nil];
}

- (void)creationCanceled
{
    [self addPlayerViewToContainer];
    [self updatePlayerToActiveClip];
    self.isVideoPlaying = YES;
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
    if (self.playerController.duration > 0) {
        cell.timelineRect = [self rectForClip:clip cell:cell];
    }
    cell.clipCellDelegate = self;
    
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor: [ClipsterColors red]
                                                title:@"Delete"];
    cell.rightUtilityButtons = rightUtilityButtons;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    Clip *clip = self.clips[indexPath.row];
    self.activeClip = clip;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.clips.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [SmallClipCell heightForClip:[self.clips objectAtIndex:indexPath.row] cell:self.prototype];
}

# pragma mark - Clip Button
    
- (IBAction)clipAction:(id)sender
{
    int currentTime = self.playerController.currentTimeInSeconds * 1000;
    
    Clip *clip = [[Clip alloc] init];
    clip.timeStart = currentTime;
    clip.timeEnd = currentTime + 10000;
    clip.videoId = self.videoId;
    clip.videoTitle = self.videoTitle;
    clip.user = (User *)[PFUser currentUser];
    
    ClippingViewController *clippingVC = [[ClippingViewController alloc] initWithClip:clip playerController:self.playerController];
    clippingVC.delegate = self;
    [self.navigationController pushViewController:clippingVC animated:YES];
}

- (void)setupClippingPanel{
    self.clippingPanelPos = self.clippingPanel.frame.origin.y;
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(scrollClippingPanel:)];
    panGestureRecognizer.delegate = self;
    [self.tableView addGestureRecognizer:panGestureRecognizer];
    [self.view bringSubviewToFront:self.videoPlayerContainer];
}

- (void)scrollClippingPanel:(UIPanGestureRecognizer *)panGestureRecognizer{
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        self.clippingPanelPos = self.clippingPanel.frame.origin.y;
        self.tableViewScrollPos = self.tableView.contentOffset.y;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
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

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

# pragma mark - MBProgressHUD helpers
- (void)pendingNetworkRequest
{
    @synchronized(self) {
        if (self.hudCounter == 0) {
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        }
        self.hudCounter++;
    }
}

- (void)pendingNetworkRequestDone
{
    @synchronized(self) {
        self.hudCounter--;
        if (self.hudCounter == 0) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [self updateAfterAllNetworkRequests];
        }
    }
}

- (void) updateAfterAllNetworkRequests
{
    // update histogram with clips
    [self addAllClipsToHistogram];
}

@end
