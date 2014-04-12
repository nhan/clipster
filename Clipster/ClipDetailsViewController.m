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

#define VIDEO_URL @"http://r8---sn-aigllnek.googlevideo.com/videoplayback?key=yt5&upn=hpIuxpikYqk&id=o-ACP3GlGTImsTQeKLXnZw4a5fq3MrCrtm9wS_d0ipFKU2&sver=3&itag=18&ratebypass=yes&mt=1397256106&ms=au&fexp=926400%2C945030%2C921725%2C919815%2C937417%2C913434%2C936916%2C934022%2C936923&signature=F2482EBCC6888BD89C0F561186ED4275B65EDB56.374093D29335B948C5D40E98C5A28404CE9BF5CD&expire=1397277950&source=youtube&sparams=id%2Cip%2Cipbits%2Citag%2Cratebypass%2Csource%2Cupn%2Cexpire&mv=m&ipbits=0&ip=2a02%3A2498%3Ae002%3A88%3A225%3A90ff%3Afe7c%3Ab806&title=Victoria%27s+Secret+Fashion+Show+2013+Full"


@interface ClipDetailsViewController ()
@property (weak, nonatomic) IBOutlet UIView *videoPlayerContainer;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) MPMoviePlayerController *player;
@property (nonatomic, assign) CGPoint panStartPosition;
@property (nonatomic, strong) NSMutableArray *clips;
@property (nonatomic, strong) Clip *activeClip;
@property (weak, nonatomic) IBOutlet UIImageView *slider;
@property (nonatomic, strong) SmallClipCell *prototype;
@property (nonatomic, strong) Clip *aNewClip;
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
    self = [super self];
    if (self) {
        _activeClip = clip;
    }
    return self;
}

- (NSString *)videoURL
{
    return VIDEO_URL;
}

- (void)fetchClips
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Clip"];
    [query whereKey:@"videoId" equalTo:self.videoURL];
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
        [MBProgressHUD hideHUDForView:self.view animated:YES];
                          
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
    clip.videoId = self.videoURL;
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
    
    [self fetchClips];
    
    NSURL *myURL = [NSURL URLWithString:self.videoURL];
    self.player = [[MPMoviePlayerController alloc] initWithContentURL: myURL];
    [self.player prepareToPlay];
    [self.player.view setFrame: self.videoPlayerContainer.frame];
    [self.videoPlayerContainer addSubview: self.player.view];
    
    self.player.fullscreen = NO;
    self.player.initialPlaybackTime = self.activeClip.timeStart / 1000.0f;
    [self.player play];
    
    [self addGesturesToVideoPlayer];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    UINib *clipCellNib = [UINib nibWithNibName:@"SmallClipCell" bundle:nil];
    self.prototype = [clipCellNib instantiateWithOwner:self options:nil][0];
    [self.tableView registerNib:clipCellNib forCellReuseIdentifier:@"ClipCell"];
}

- (void)addGesturesToVideoPlayer{
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onSliderPan:)];
    [self.slider addGestureRecognizer:panGestureRecognizer];
}

- (void)onSliderPan:(UIPanGestureRecognizer *)panGestureRecognizer{
    CGPoint point    = [panGestureRecognizer locationInView:self.view];
//    CGPoint velocity = [panGestureRecognizer velocityInView:self.view];
    
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        self.panStartPosition = CGPointMake(point.x - self.slider.frame.origin.x, point.y - self.slider.frame.origin.y);
    } else if (panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        float xPos = (point.x - self.panStartPosition.x);
        if (xPos < 0) {
            xPos = 0;
        }
        self.slider.frame = CGRectMake( xPos, self.slider.frame.origin.y, self.slider.frame.size.width, self.slider.frame.size.height);
    } else if (panGestureRecognizer.state == UIGestureRecognizerStateEnded) {

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
@end
