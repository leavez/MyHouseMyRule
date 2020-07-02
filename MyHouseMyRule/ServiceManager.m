//
//  ServiceManager.m
//  MyHouseMyRule
//
//  Created by leave on 2020/6/28.
//  Copyright © 2020 leave. All rights reserved.
//

#import "ServiceManager.h"
#import "NSArray+HighOrderFunction.h"
#import "STPrivilegedTask.h"

@implementation ServiceManager

+ (void)startWithCompletion:(void (^)(void))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self switchMode:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion();
            }
        });
    });
}

+ (void)stopWithCompletion:(void (^)(void))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self switchMode:NO];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion();
            }
        });
    });
}

+ (BOOL)isOn {
    NSString *output = nil;
    int exitCode = [self runScript:@"ps -A | grep '.app/Contents/MacOS/itsec-agent'" output:&output];
    __auto_type lines = [output componentsSeparatedByString:@"\n"];
    lines = [lines filter:^BOOL(NSString *obj) {
        return ![obj containsString:@"grep"] && obj.length > 0;
    }];

    return lines.count > 0;
}

// MARK: - private

+ (void)switchMode:(BOOL)toWorkMode {
    __auto_type paths = [self getPlistPaths:!toWorkMode];
    
    // switch the demons
    NSMutableString *script = [[self switchDeamonsScript:paths enabled:toWorkMode] mutableCopy];
    
    // remove the certificate
    NSString *savedCersPath = [NSString stringWithFormat:@"%@/Library/Application Support/MyHouseMyRule", NSHomeDirectory()];
    NSString *keychainPath = [NSString stringWithFormat:@"%@/Library/Keychains/login.keychain", NSHomeDirectory()];
    if (![[NSFileManager defaultManager] fileExistsAtPath:keychainPath]) {
        keychainPath = [keychainPath stringByAppendingString:@"-db"];
    }
    if (!toWorkMode) {
        // save some certificates, as it cannot recover automatically
        [script appendFormat:@"\n mkdir -p '%@'", savedCersPath];
        [script appendFormat:@"\n security find-certificate -a -p -c pf.sankuai.info > '%@/1.pem'", savedCersPath];
        [script appendFormat:@"\n security find-certificate -a -p -c 'Go Daddy Root' > '%@/2.pem'", savedCersPath];

        // remove
        [script appendString:@"\n security delete-certificate -c localhost.moa.sankuai.com"];
        [script appendString:@"\n security delete-certificate -c pf.sankuai.info"];
        [script appendString:@"\n security delete-certificate -Z 2796BAE63F1801E277261BA0D77770028F20EEE4"]; // 'Go Daddy Class 2 Certification Authority 这个没有 common name ，只能这么删
        NSString *output;
        [self runScript:@"security find-certificate -aZc 'Go Daddy' | grep SHA-1 | cut -c 13-" output:&output];
        [[[output componentsSeparatedByString:@"\n"] map:^id(NSString *obj) {
            return [obj stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }] forEach:^(NSString *obj) {
            [script appendFormat:@"\n security delete-certificate -Z %@", obj];
        }];
    } else {
        // recover some certificates
        [script appendFormat:@"\n security import '%@/1.pem' -k '%@'", savedCersPath, keychainPath];
        [script appendFormat:@"\n security import '%@/2.pem' -k '%@'", savedCersPath, keychainPath];
    }
    [self runWithRoot:script];
}


+ (NSString *)switchDeamonsScript:(NSArray<NSString *>*)plistPaths enabled:(BOOL)enabled {
    
    NSString *script = [[plistPaths map:^id(NSString *obj) {
        if (enabled) {
            return [NSMutableString stringWithFormat:@"launchctl load -w %@;", obj];
        } else {
            return [NSMutableString stringWithFormat:@"launchctl unload -w %@;", obj];
        }
    }] componentsJoinedByString:@"\n"];
    
    if (!enabled) {
        NSString *killScript = @""
        "killall -9 itsec-agent \n" // the MOA app
        "ps -Ao comm | grep MOA.app | xargs basename | xargs killall -9 \n" // the MOA app
        "killall -9 DLPMain \n" // the DLP app
        "killall -9 DLP3.0 \n" // the DLP app
        "ps -Ao comm | grep DLP | xargs basename | xargs killall -9  \n" // the DLP app, TODO container the space, not work
        "ps -Ao comm | grep cisco | xargs basename | xargs killall -9  \n" // cisco
        "killall -9 SymDaemon \n" // symantec
        "killall -9 SymSharedSettingsd \n" // symantec
        "killall -9 com.symantec.SymLUHelper \n" // symantec
        "killall -9 com.symantec.symquald \n" // symantec
        "killall -9 symquald \n" // symantec
        ;
        script = [script stringByAppendingFormat:@"\n\n%@", killScript];
    }
    
    return script;
}


+(NSArray<NSString *> *)getPlistPaths:(BOOL)isForUnload {
    __auto_type results = [NSMutableArray new];
    
    // /Library/LaunchDaemons/
    __auto_type daemons = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/LaunchDaemons/" error:nil] map:^id(NSString *obj) {
        return [@"/Library/LaunchDaemons/" stringByAppendingPathComponent:obj];
    }];
    [results addObjectsFromArray:[daemons filter:^BOOL(NSString *obj) {
        return [obj.lastPathComponent hasPrefix:@"com.cisco.anyconnect"];
    }]];
    [results addObjectsFromArray:[daemons filter:^BOOL(NSString *obj) {
        return [obj.lastPathComponent containsString:@".DLP3"];
    }]];
    [results addObjectsFromArray:[daemons filter:^BOOL(NSString *obj) {
        return [obj.lastPathComponent containsString:@".moa"];
    }]];
    
    
    if (isForUnload) {
        [results addObjectsFromArray:[daemons filter:^BOOL(NSString *obj) {
            return [obj.lastPathComponent hasPrefix:@"com.symantec."];
        }]];
    }
    
    // /Library/LaunchAgents
    __auto_type agents = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/LaunchAgents/" error:nil] map:^id(NSString *obj) {
        return [@"/Library/LaunchAgents/" stringByAppendingPathComponent:obj];
    }];
    [results addObjectsFromArray:[agents filter:^BOOL(NSString *obj) {
        return [obj.lastPathComponent hasPrefix:@"com.symantec."];
    }]];
    [results addObjectsFromArray:[agents filter:^BOOL(NSString *obj) {
        return [obj.lastPathComponent containsString:@".moa"];
    }]];
    
    if (isForUnload) {
        [results addObjectsFromArray:[agents filter:^BOOL(NSString *obj) {
            return [obj.lastPathComponent hasPrefix:@"com.cisco.anyconnect"];
        }]];
        [results addObjectsFromArray:[agents filter:^BOOL(NSString *obj) {
            return [obj.lastPathComponent containsString:@".DLP3"];
        }]];
    }
    
    // ~/Library/LaunchAgents
    NSString *target = [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/LaunchAgents/"];
    agents = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:target error:nil] map:^id(NSString *obj) {
       return [target stringByAppendingPathComponent:obj];
    }];
    [results addObjectsFromArray:[agents filter:^BOOL(NSString *obj) {
       return [obj.lastPathComponent hasPrefix:@"com.symantec."];
    }]];

    if (isForUnload) {
       [results addObjectsFromArray:[agents filter:^BOOL(NSString *obj) {
           return [obj.lastPathComponent hasPrefix:@"com.cisco.anyconnect"];
       }]];
       [results addObjectsFromArray:[agents filter:^BOOL(NSString *obj) {
           return [obj.lastPathComponent containsString:@".moa"];
       }]];
       [results addObjectsFromArray:[agents filter:^BOOL(NSString *obj) {
           return [obj.lastPathComponent containsString:@".DLP3"];
       }]];
    }
        
    return results;
}



// MARK: - tool

+(int)runScript:(NSString*)script output:(NSString **)output
{
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/bash"];
    [task setArguments: @[@"-c", script]];

    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];

    NSFileHandle *file;
    file = [pipe fileHandleForReading];

    [task launch];
    [task waitUntilExit];

    NSData *data;
    data = [file readDataToEndOfFile];

    NSString *string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    *output = string;
    return [task terminationStatus];
}

+ (void)runWithRoot:(NSString *)script {
    
    NSString *scriptTempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"myHouseMyRule.sh"]];
    [script writeToFile:scriptTempPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    
    // Create task
    STPrivilegedTask *privilegedTask = [STPrivilegedTask new];
    [privilegedTask setLaunchPath:@"/bin/bash"];
    [privilegedTask setArguments:@[scriptTempPath]];

    // Launch it, user is prompted for password
    OSStatus err = [privilegedTask launch];
    [privilegedTask waitUntilExit];

    
    if (err == errAuthorizationSuccess) {
        NSLog(@"Task successfully launched");
    }
    else if (err == errAuthorizationCanceled) {
        NSLog(@"User cancelled");
    }
    else {
        NSLog(@"Something went wrong");
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:scriptTempPath error:nil];
}


@end

