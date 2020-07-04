//
//  PasswordViewController.m
//  MyHouseMyRule
//
//  Created by leave on 2020/7/4.
//  Copyright © 2020 leave. All rights reserved.
//

#import "PasswordViewController.h"
#import "PasswordManager.h"

@interface PasswordViewController ()
@property (weak) IBOutlet NSSecureTextField *passwordField;
@property (weak) IBOutlet NSTextField *hintLabel;
@property (weak) IBOutlet NSButton *doneButto;
@property (weak) IBOutlet NSButton *cancelButton;
@property void(^completionBlock)(BOOL);
@end

@implementation PasswordViewController

- (void)setCompletion:(void (^)(BOOL))block {
    self.completionBlock = block;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}
- (IBAction)didTapDone:(id)sender {
    [self.doneButto setEnabled:NO];
    NSString *password = self.passwordField.stringValue;
    if ([PasswordManager validatePassword:password]) {
        [PasswordManager saveRootPassword:password];
        [self dismissController:nil];
        if (self.completionBlock) {
            self.completionBlock(YES);
        }
    } else {
        [self.hintLabel setHidden:NO];
        [self.passwordField setStringValue:@""];
        [self.doneButto setEnabled:YES];
    }
    
}

- (IBAction)didTapCancel:(id)sender {
    [self dismissController:nil];
    if (self.completionBlock) {
        self.completionBlock(NO);
    }
}
@end
