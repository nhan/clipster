//
//  ClipDetailsViewController.m
//  Clipster
//
//  Created by Nathan Speller on 4/11/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "ClipDetailsViewController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface ClipDetailsViewController ()
@property (weak, nonatomic) IBOutlet UIView *videoPlayerContainer;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIImageView *slider;
@property (strong, nonatomic) MPMoviePlayerController *player;
@property (nonatomic, assign) CGPoint panStartPosition;
@end

@implementation ClipDetailsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    NSURL *myURL = [NSURL URLWithString:@"http://r8---sn-aigllnek.googlevideo.com/videoplayback?key=yt5&upn=hpIuxpikYqk&id=o-ACP3GlGTImsTQeKLXnZw4a5fq3MrCrtm9wS_d0ipFKU2&sver=3&itag=18&ratebypass=yes&mt=1397256106&ms=au&fexp=926400%2C945030%2C921725%2C919815%2C937417%2C913434%2C936916%2C934022%2C936923&signature=F2482EBCC6888BD89C0F561186ED4275B65EDB56.374093D29335B948C5D40E98C5A28404CE9BF5CD&expire=1397277950&source=youtube&sparams=id%2Cip%2Cipbits%2Citag%2Cratebypass%2Csource%2Cupn%2Cexpire&mv=m&ipbits=0&ip=2a02%3A2498%3Ae002%3A88%3A225%3A90ff%3Afe7c%3Ab806&title=Victoria%27s+Secret+Fashion+Show+2013+Full"];
    self.player = [[MPMoviePlayerController alloc] initWithContentURL: myURL];
    [self.player prepareToPlay];
    [self.player.view setFrame: self.videoPlayerContainer.frame];
    [self.videoPlayerContainer addSubview: self.player.view];
    
    self.player.fullscreen = NO;
    [self.player play];
    
    [self addGesturesToVideoPlayer];
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
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

@end
