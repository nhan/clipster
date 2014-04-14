//
//  ClipDetailsViewController.m
//  Clipster
//
//  Created by Nathan Speller on 4/11/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "ClipDetailsViewController.h"
#import "Clip.h"
#import "ClipCreationViewController.h"
#import "SmallClipCell.h"
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

#define VIDEO_URL @"http://r8---sn-aigllnek.googlevideo.com/videoplayback?key=yt5&upn=hpIuxpikYqk&id=o-ACP3GlGTImsTQeKLXnZw4a5fq3MrCrtm9wS_d0ipFKU2&sver=3&itag=18&ratebypass=yes&mt=1397256106&ms=au&fexp=926400%2C945030%2C921725%2C919815%2C937417%2C913434%2C936916%2C934022%2C936923&signature=F2482EBCC6888BD89C0F561186ED4275B65EDB56.374093D29335B948C5D40E98C5A28404CE9BF5CD&expire=1397277950&source=youtube&sparams=id%2Cip%2Cipbits%2Citag%2Cratebypass%2Csource%2Cupn%2Cexpire&mv=m&ipbits=0&ip=2a02%3A2498%3Ae002%3A88%3A225%3A90ff%3Afe7c%3Ab806&title=Victoria%27s+Secret+Fashion+Show+2013+Full"


@interface ClipDetailsViewController ()
@property (weak, nonatomic) IBOutlet UIView *videoPlayerContainer;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) MPMoviePlayerController *player;
@property (nonatomic, assign) CGPoint panStartPosition;
@property (nonatomic, strong) NSMutableArray *clips;
@property (nonatomic, strong) Clip *activeClip;
@property (nonatomic, strong) SmallClipCell *prototype;
@property (nonatomic, strong) Clip *aNewClip;

@property (nonatomic, strong) NSString *videoId;
@property (weak, nonatomic) IBOutlet UIView *clippingPanel;
@property (nonatomic, assign) CGFloat clippingPanelPos;
@property (nonatomic, assign) CGFloat tableViewScrollPos;

@end

@implementation ClipDetailsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _clips = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)initWithClip:(Clip *)clip {
    self = [self initWithVideoId:clip.videoId];
    if (self) {
        _activeClip = clip;
    }
    return self;
}

- (id)initWithVideoId:(NSString *)videoId
{
    self = [super self];
    if (self) {
        _videoId = videoId;
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
    Clip* clip = [[Clip alloc] init];

    // convert to miliseconds
    clip.timeStart = self.player.currentPlaybackTime * 1000;
    self.aNewClip = clip;
}

- (IBAction)doneAction:(id)sender
{
    if (self.aNewClip) {
        self.aNewClip.timeEnd = self.player.currentPlaybackTime * 1000;
        ClipCreationViewController *vc = [[ClipCreationViewController alloc] initWithClip:self.aNewClip];
        vc.delegate = self;
        [self presentViewController:vc animated:YES completion:nil];
    }
}

#pragma mark - ClipCreationDelegate

- (void)creationDone:(Clip *)clip
{
    clip.videoId = self.videoId;
    [self.clips addObject:clip];
    [clip saveInBackground];
    [self.tableView reloadData];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setActiveClip:(Clip *)activeClip
{
    _activeClip = activeClip;
    self.player.currentPlaybackTime = self.activeClip.timeStart / 1000.0f;
}

- (void)creationCanceled
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    [self setupClippingPanel];
    
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
            [self.player.view setFrame: self.videoPlayerContainer.frame];
            [self.videoPlayerContainer addSubview: self.player.view];

            [self.view bringSubviewToFront:self.videoPlayerContainer];
            
            self.player.fullscreen = NO;
            self.player.initialPlaybackTime = self.activeClip.timeStart / 1000.0f;
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

#pragma mark - UITableViewDelegate and UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SmallClipCell *cell = (SmallClipCell *)[self.tableView dequeueReusableCellWithIdentifier:@"ClipCell" forIndexPath:indexPath];
    Clip *clip = (Clip *)self.clips[indexPath.row];
    [cell setClip:clip];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
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

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.tableView.contentOffset.y < 0) {
        self.clippingPanel.frame = CGRectMake(0, self.tableView.frame.origin.y-self.tableView.contentOffset.y, self.clippingPanel.frame.size.width, self.clippingPanel.frame.size.height);
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
