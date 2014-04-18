//
//  ClippingViewController.m
//  Clipster
//
//  Created by Nathan Speller on 4/18/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "ClippingViewController.h"

@interface ClippingViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *startSlider;
@property (weak, nonatomic) IBOutlet UIImageView *endSlider;
@property (nonatomic, assign) CGPoint startPosition;
@property (nonatomic, assign) CGPoint   endPosition;
@end

@implementation ClippingViewController

static NSInteger startSliderHomePos = 50;
static NSInteger   endSliderHomePos = 240;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Clipping";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    // Add pan gestures to draggable sliders
    UIPanGestureRecognizer *startPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onStartSliderDrag:)];
    [self.startSlider addGestureRecognizer:startPanGestureRecognizer];
    
    UIPanGestureRecognizer *endPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onEndSliderDrag:)];
    [self.endSlider addGestureRecognizer:endPanGestureRecognizer];
}

- (void)onStartSliderDrag:(UIPanGestureRecognizer *)panGestureRecognizer{
    CGPoint point    = [panGestureRecognizer locationInView:self.view];
    
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        self.startPosition = CGPointMake(point.x - self.startSlider.frame.origin.x, point.y - self.startSlider.frame.origin.y);
    } else if (panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        float xPos = (point.x - self.startPosition.x);
        if (xPos < 0) {
            xPos = 0;
        }
        if (xPos > (self.endSlider.frame.origin.x - self.startSlider.frame.size.width)){
            xPos = self.endSlider.frame.origin.x - self.startSlider.frame.size.width;
        }
        self.startSlider.frame = CGRectMake( xPos, self.startSlider.frame.origin.y, self.startSlider.frame.size.width, self.startSlider.frame.size.height);
    } else if (panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [UIView animateWithDuration:0.5 animations:^{
            self.startSlider.frame = CGRectMake( startSliderHomePos, self.startSlider.frame.origin.y, self.startSlider.frame.size.width, self.startSlider.frame.size.height);
        } completion:^(BOOL finished) {
            NSLog(@"returned start slider to home position");
        }];
    }
}

- (void)onEndSliderDrag:(UIPanGestureRecognizer *)panGestureRecognizer{
    CGPoint point    = [panGestureRecognizer locationInView:self.view];
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        self.endPosition = CGPointMake(point.x - self.endSlider.frame.origin.x, point.y - self.endSlider.frame.origin.y);
    } else if (panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        float xPos = (point.x - self.endPosition.x);
        if (xPos > 320-(self.endSlider.frame.size.width)) {
            xPos = 320-(self.endSlider.frame.size.width);
        }
        if (xPos < (self.startSlider.frame.origin.x + self.startSlider.frame.size.width)){
            xPos = (self.startSlider.frame.origin.x + self.startSlider.frame.size.width);
        }
        self.endSlider.frame = CGRectMake( xPos, self.endSlider.frame.origin.y, self.endSlider.frame.size.width, self.endSlider.frame.size.height);
    } else if (panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [UIView animateWithDuration:0.5 animations:^{
            self.endSlider.frame = CGRectMake( endSliderHomePos, self.endSlider.frame.origin.y, self.endSlider.frame.size.width, self.endSlider.frame.size.height);
        } completion:^(BOOL finished) {
            NSLog(@"returned end slider to home position");
        }];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
