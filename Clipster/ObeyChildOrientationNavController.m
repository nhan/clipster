//
//  PortraitOnlyViewController.m
//  Clipster
//
//  Created by Anthony Sherbondy on 4/29/14.
//  Copyright (c) 2014 Nathan Speller. All rights reserved.
//

#import "ObeyChildOrientationNavController.h"

@interface ObeyChildOrientationNavController ()

@end

@implementation ObeyChildOrientationNavController

-(NSUInteger)supportedInterfaceOrientations
{
    return [[self.viewControllers lastObject] supportedInterfaceOrientations];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
