//
//  ShellCommand.h
//  MyHouseMyRule
//
//  Created by leave on 2020/7/4.
//  Copyright © 2020 leave. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ShellCommand : NSObject

+(int)runScript:(NSString*)script output:(NSString **)output;
+(int)run:(NSString*)path args:(NSArray *)args output:(NSString **)output;

@end

NS_ASSUME_NONNULL_END
