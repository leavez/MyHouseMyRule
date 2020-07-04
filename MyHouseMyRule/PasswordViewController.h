//
//  PasswordViewController.h
//  MyHouseMyRule
//
//  Created by leave on 2020/7/4.
//  Copyright © 2020 leave. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface PasswordViewController : NSViewController

- (void)setCompletion:(void(^)(BOOL))block;

@end

NS_ASSUME_NONNULL_END
