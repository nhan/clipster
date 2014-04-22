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
            
            NSInteger row = [self.clips indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                return [self.activeClip.objectId isEqualToString:((Clip *)obj).objectId];
            }];
            
            [self.tableView reloadData];
            
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0] animated:YES scrollPosition:UITableViewScrollPositionTop];
            
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
            [self updatePlayer];
            [self.player play];
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

- (void)updatePlayer
{
    [self.player.view setFrame: self.videoPlayerContainer.frame];
    [self.videoPlayerContainer addSubview: self.player.view];
    [self.view bringSubviewToFront:self.videoPlayerContainer];
    self.player.fullscreen = NO;
    self.player.currentPlaybackTime = self.activeClip.timeStart / 1000.0f;
}

#pragma mark - ClipCreationDelegate

- (void)creationDone:(Clip *)clip
{
    [clip saveInBackground];
    NSInteger row = [self.clips indexOfObject:clip];
    
    // When we finish adding clip we need to sort correctly
    [self.tableView reloadData];
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0] animated:YES scrollPosition:UITableViewScrollPositionTop];
    
    [self updatePlayer];
    [self.player play];
    // Dirty the stream when we've created a new clip
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SetStreamDirty" object:nil];
}

- (void)creationCanceled
{
    [self updatePlayer];
    [self.player play];
}

- (void)setupClippingPanel{
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
