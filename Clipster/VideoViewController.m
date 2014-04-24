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
@property (weak, nonatomic) IBOutlet UIView *clippingPanel;

@property (nonatomic, assign) CGPoint panStartPosition;
@property (nonatomic, strong) NSMutableArray *clips;
@property (nonatomic, strong) Clip *activeClip;
@property (nonatomic, strong) SmallClipCell *prototype;
@property (nonatomic, strong) Clip *aNewClip;

@property (nonatomic, strong) NSString *videoId;
@property (nonatomic, strong) NSString *videoTitle;
@property (nonatomic, assign) CGFloat clippingPanelPos;
@property (nonatomic, assign) CGFloat tableViewScrollPos;

@property (nonatomic, strong) VideoPlayerViewController *playerController;
@property (nonatomic, assign) NSInteger hudCounter;
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

- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    [self setupClippingPanel];
    [self addPlayerViewToContainer];
    
    [self showProgressHUD];
    [HCYoutubeParser h264videosWithYoutubeID:self.videoId completeBlock:^(NSDictionary *videoDictionary, NSError *error) {
        
        // TODO: We need to consider what our video quality strategy should be
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
            NSLog(@"video url: %@", videoURL);
            [self.playerController loadVideoWithURLString:videoURL ready:^{
                [self updatePlayerToActiveClip];
                [self.playerController play];
            }];
        }
        
        [self hideProgressHUD];
    }];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    UINib *clipCellNib = [UINib nibWithNibName:@"SmallClipCell" bundle:nil];
    self.prototype = [clipCellNib instantiateWithOwner:self options:nil][0];
    [self.tableView registerNib:clipCellNib forCellReuseIdentifier:@"ClipCell"];
    [self fetchClips];
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
    [self showProgressHUD];
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
        [self hideProgressHUD];
    }];
}

#pragma mark - ClipCreationDelegate

- (void)creationDone:(Clip *)clip
{
    [clip saveInBackground];
    NSInteger row = [self.clips indexOfObject:clip];
    
    // TODO: When we finish adding clip we need to sort correctly
    [self.tableView reloadData];
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0] animated:YES scrollPosition:UITableViewScrollPositionTop];
    [self addPlayerViewToContainer];
    [self updatePlayerToActiveClip];
    [self.playerController play];
    
    // Dirty the stream when we've created a new clip
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SetStreamDirty" object:nil];
}

- (void)creationCanceled
{
    [self addPlayerViewToContainer];
    [self updatePlayerToActiveClip];
    [self.playerController play];
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
        ClippingViewController *clippingVC = [[ClippingViewController alloc] initWithClip:clip playerController:self.playerController];
        clippingVC.delegate = self;
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

# pragma mark - Clip Button
- (IBAction)clipAction:(id)sender
{
    int currentTime = self.playerController.currentTimeInSeconds * 1000;
    
    self.aNewClip = [[Clip alloc] init];
    self.aNewClip.timeStart = currentTime;
    self.aNewClip.timeEnd = currentTime + 10000;
    self.aNewClip.videoId = self.videoId;
    self.aNewClip.videoTitle = self.videoTitle;
    self.aNewClip.user = (User *)[PFUser currentUser];
    
    [self.clips addObject:self.aNewClip];
    
    // TODO: animate to new cell
    [self.tableView reloadData];
    
    [self.playerController frameAtTimeWithSeconds:self.playerController.currentTimeInSeconds done:^(NSError *error, CGImageRef imageRef) {
        UIImage *image = [UIImage imageWithCGImage:imageRef];
        self.aNewClip.thumbnail = [PFFile fileWithData:UIImageJPEGRepresentation(image, 0.05f)];
        [self.aNewClip saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [self.tableView reloadData];
        }];
    }];
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
- (void)showProgressHUD
{
    @synchronized(self) {
        if (self.hudCounter == 0) {
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        }
        self.hudCounter++;
    }
}

- (void)hideProgressHUD
{
    @synchronized(self) {
        self.hudCounter--;
        if (self.hudCounter == 0) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        }
    }
}
@end
