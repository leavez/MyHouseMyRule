//
//  ShellCommand.m
//  MyHouseMyRule
//
//  Created by leave on 2020/7/4.
//  Copyright © 2020 leave. All rights reserved.
//

#import "ShellCommand.h"

@implementation ShellCommand


+(int)runScript:(NSString*)script output:(NSString **)output {
    return [self run:@"/bin/bash" args:@[@"-c", script] output:output];
}

+(int)run:(NSString*)path args:(NSArray *)args output:(NSString **)output
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:path];
    [task setArguments:args];

    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];

    NSFileHandle *file = [pipe fileHandleForReading];

    [task launch];
    [task waitUntilExit];

    if (output) {
        NSData *data = [file readDataToEndOfFile];
        NSString *string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
        *output = string;
    }
    return [task terminationStatus];
}


@end
