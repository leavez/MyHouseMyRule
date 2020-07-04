//
//  PasswordManager.h
//  MyHouseMyRule
//
//  Created by leave on 2020/7/4.
//  Copyright © 2020 leave. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PasswordManager : NSObject

+ (BOOL)doesPasswordSetup;
+ (void)saveRootPassword:(NSString *)password;
+ (NSString *)getRootPassword;

@end

NS_ASSUME_NONNULL_END
