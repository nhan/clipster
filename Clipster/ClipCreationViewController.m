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

- (void)doneAction:(id)sender {
    self.clip.text = self.annotationTextView.text;
    [self.delegate creationDone:self.clip];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.leftBarButtonItem.title = @"Cancel";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(doneAction:)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
