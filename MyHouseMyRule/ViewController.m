//
//  ViewController.m
//  MyHouseMyRule
//
//  Created by leave on 2020/6/28.
//  Copyright © 2020 leave. All rights reserved.
//

#import "ViewController.h"
#import "ServiceManager.h"

@interface ViewController()
//@property BOOL isWorkModeOn;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(refreashModeUI) userInfo:nil repeats:YES];
}

- (void)viewWillAppear {
    [super viewWillAppear];
    [self refreashModeUI];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    // Update the view, if already loaded.
}


- (IBAction)didTapBackground:(id)sender {
    [self didTapSwitchButton:nil];
}

- (IBAction)didTapSwitchButton:(id)sender {
    [self.progressIndicator startAnimation:nil];
    self.switchButton.enabled = NO;

    __weak typeof(self) wself = self;
    __auto_type completion = ^(){
        [wself.progressIndicator stopAnimation:nil];
        [wself refreashModeUI];
        wself.switchButton.enabled = YES;
    };
    
    if ([ServiceManager isOn]) {
        [ServiceManager stopWithCompletion:completion];
    } else {
        [ServiceManager startWithCompletion:completion];
    }
}


- (void)refreashModeUI {
    if ([ServiceManager isOn]) {
        [self.modeLabel setStringValue:@"On"];
        [self.modeLabel setTextColor:[NSColor systemBlueColor]];
        [self.switchButton setTitle:@"clean all"];
    } else {
        [self.modeLabel setStringValue:@"Off"];
        [self.modeLabel setTextColor:[NSColor systemGreenColor]];
        [self.switchButton setTitle:@"to work"];
    }
}




@end
