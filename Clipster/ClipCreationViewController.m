//
//  ClipCreationViewController.m
//  Clipster
//
//  Created by Nhan Nguyen on 4/11/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "ClipCreationViewController.h"

@interface ClipCreationViewController ()
@property (strong, nonatomic) Clip *clip;
@property (weak, nonatomic) IBOutlet UITextView *annotationTextView;
@end

@implementation ClipCreationViewController

- (id) initWithClip:(Clip *)clip {
    self = [super init];
    if (self) {
        _clip = clip;
    }
    return self;
}

- (IBAction)doneAction:(id)sender {
    self.clip.text = self.annotationTextView.text;
    [self.delegate creationDone:self.clip];
}

- (IBAction)cancelAction:(id)sender {
    [self.delegate creationCanceled];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
