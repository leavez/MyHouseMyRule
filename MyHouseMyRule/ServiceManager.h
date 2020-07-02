//
//  ServiceManager.h
//  MyHouseMyRule
//
//  Created by leave on 2020/6/28.
//  Copyright © 2020 leave. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ServiceManager : NSObject

+ (void)startWithCompletion:(void(^)(void))completion;
+ (void)stopWithCompletion:(void(^)(void))completion;
+ (BOOL)isOn;

@end

NS_ASSUME_NONNULL_END
