//
//  MenuViewController.m
//  Clipster
//
//  Created by Nathan Speller on 4/6/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "MenuViewController.h"
#import "StreamViewController.h"

@interface MenuViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (nonatomic, strong) UINavigationController *navigationController;

@property (nonatomic, strong) UITapGestureRecognizer *tapToCloseMenuGestureRecognizer;
@end

@implementation MenuViewController

static float openMenuPosition = 265; //open menu x position

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        StreamViewController *streamViewController = [[StreamViewController alloc] init];
        
        self.navigationController = [[UINavigationController alloc] initWithRootViewController:streamViewController];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleMenu) name:@"toggleMenu" object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self.contentView addSubview:self.navigationController.view];
}

- (void)toggleMenu{
    // move the contentView to reveal/hide the menu
    float xPos = (self.contentView.frame.origin.x == 0) ? openMenuPosition : 0;
    [UIView animateWithDuration:0.3 animations:^{
        self.contentView.frame = CGRectMake( xPos, 0, self.contentView.frame.size.width, self.contentView.frame.size.height);
    }];
    
    // initialize the tap gesture on the contentView to close an open menu
    if (self.tapToCloseMenuGestureRecognizer == nil) {
        self.tapToCloseMenuGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleMenu)];
        self.tapToCloseMenuGestureRecognizer.numberOfTapsRequired = 1;
        [self.contentView addGestureRecognizer:self.tapToCloseMenuGestureRecognizer];
    }
    
    // disable interaction with the contentView if the menu is open
    BOOL isMenuOpen = self.contentView.frame.origin.x == 0;
    [self.contentView.subviews[0] setUserInteractionEnabled:isMenuOpen];
    self.tapToCloseMenuGestureRecognizer.enabled = !isMenuOpen;
}


#pragma mark - UITableViewDelegate and UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [[UITableViewCell alloc] init];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

@end
