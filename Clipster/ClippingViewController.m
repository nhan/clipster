//
//  ClippingViewController.m
//  Clipster
//
//  Created by Nathan Speller on 4/18/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "ClippingViewController.h"
#import "RulerView.h"

@interface ClippingViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *startSlider;
@property (weak, nonatomic) IBOutlet UIImageView *endSlider;
@property (nonatomic, assign) CGPoint startPosition;
@property (nonatomic, assign) CGPoint   endPosition;
@property (weak, nonatomic) IBOutlet UIView *rulerContainer;
@property (nonatomic, assign) CGFloat startTime;
@property (nonatomic, assign) CGFloat   endTime;
@property (weak, nonatomic) IBOutlet UILabel *startTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *endTimeLabel;
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
    
    //Draw the ruler
    RulerView *ruler = [[RulerView alloc] initWithFrame:CGRectMake(0, 0, self.rulerContainer.frame.size.width, self.rulerContainer.frame.size.height)];
    [ruler redrawLinesWithStartPos:self.startSlider.frame.origin.x scale:0.4];
    [self.rulerContainer addSubview:ruler];
    
    // Get this from the clip later
    self.startTime = 10.0;
    self.endTime = 20.0;
    self.startTimeLabel.text = [NSString stringWithFormat:@"%f", self.startTime];
    self.endTimeLabel.text = [NSString stringWithFormat:@"%f", self.endTime];
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
        
        //update the Labels - DELETE
        CGFloat originalTimeDiff = self.endTime - self.startTime;
        CGFloat newTimeDiff = ((endSliderHomePos - self.startSlider.frame.origin.x)/(endSliderHomePos - startSliderHomePos))*originalTimeDiff;
        self.startTimeLabel.text = [NSString stringWithFormat:@"%f", self.endTime-newTimeDiff];
        
    } else if (panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        //update starting time
        CGFloat originalTimeDiff = self.endTime - self.startTime;
        CGFloat newTimeDiff = ((endSliderHomePos - self.startSlider.frame.origin.x)/(endSliderHomePos - startSliderHomePos))*originalTimeDiff;
        self.startTime = self.endTime-newTimeDiff;
        
        CGFloat newScale = (((originalTimeDiff/newTimeDiff)*self.rulerContainer.frame.size.width)-self.rulerContainer.frame.size.width)/2;
        CGFloat halfWidth = self.rulerContainer.frame.size.width/2;
        CGFloat translation = -newScale*((self.endSlider.frame.origin.x+(self.endSlider.frame.size.width/2))-halfWidth)/halfWidth;
        
        CGAffineTransform translate = CGAffineTransformMakeTranslation(translation,0);
        CGAffineTransform scale = CGAffineTransformMakeScale(originalTimeDiff/newTimeDiff, 1.0);
        CGAffineTransform transform =  CGAffineTransformConcat(scale, translate);
        RulerView *rulerView = self.rulerContainer.subviews[0];
        
        [UIView animateWithDuration:0.5 animations:^{
            self.startSlider.frame = CGRectMake( startSliderHomePos, self.startSlider.frame.origin.y, self.startSlider.frame.size.width, self.startSlider.frame.size.height);
            rulerView.transform = transform;
        } completion:^(BOOL finished) {
            NSLog(@"returned start slider to home position");
            [rulerView removeFromSuperview];
            RulerView *newRulerView = [[RulerView alloc] initWithFrame:CGRectMake(0,0,self.rulerContainer.frame.size.width, self.rulerContainer.frame.size.height)];
            [self.rulerContainer addSubview:newRulerView];
            [rulerView redrawLinesWithStartPos:self.startSlider.frame.origin.x scale:0.4];
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
        
        //update ending time
        CGFloat originalTimeDiff = self.endTime - self.startTime;
        CGFloat newTimeDiff = ((self.endSlider.frame.origin.x - startSliderHomePos)/(endSliderHomePos - startSliderHomePos))*originalTimeDiff;
        self.endTimeLabel.text = [NSString stringWithFormat:@"%f", self.startTime+newTimeDiff];
        
        
    } else if (panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        //update ending time
        CGFloat originalTimeDiff = self.endTime - self.startTime;
        CGFloat newTimeDiff = ((self.endSlider.frame.origin.x - startSliderHomePos)/(endSliderHomePos - startSliderHomePos))*originalTimeDiff;
        self.endTime = self.startTime+newTimeDiff;
        
        CGFloat newScale = (((originalTimeDiff/newTimeDiff)*self.rulerContainer.frame.size.width)-self.rulerContainer.frame.size.width)/2;
        CGFloat translation = newScale*(((self.rulerContainer.frame.size.width/2)-(startSliderHomePos+(self.startSlider.frame.size.width/2)))/(self.rulerContainer.frame.size.width/2));
        
        CGAffineTransform translate = CGAffineTransformMakeTranslation(translation,0);
        CGAffineTransform scale = CGAffineTransformMakeScale(originalTimeDiff/newTimeDiff, 1.0);
        CGAffineTransform transform =  CGAffineTransformConcat(scale, translate);
        RulerView *rulerView = self.rulerContainer.subviews[0];
        
        [UIView animateWithDuration:0.5 animations:^{
            self.endSlider.frame = CGRectMake( endSliderHomePos, self.endSlider.frame.origin.y, self.endSlider.frame.size.width, self.endSlider.frame.size.height);
            rulerView.transform = transform;
        } completion:^(BOOL finished) {
            NSLog(@"returned end slider to home position");
            [rulerView removeFromSuperview];
            RulerView *newRulerView = [[RulerView alloc] initWithFrame:CGRectMake(0,0,self.rulerContainer.frame.size.width, self.rulerContainer.frame.size.height)];
            [self.rulerContainer addSubview:newRulerView];
            [rulerView redrawLinesWithStartPos:self.startSlider.frame.origin.x scale:0.4];
        }];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
