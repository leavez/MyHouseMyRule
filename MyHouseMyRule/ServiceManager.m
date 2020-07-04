//
//  ServiceManager.m
//  MyHouseMyRule
//
//  Created by leave on 2020/6/28.
//  Copyright © 2020 leave. All rights reserved.
//

#import "ServiceManager.h"
#import "NSArray+HighOrderFunction.h"
#import "PasswordManager.h"

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

    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    
    // make sudo require no password in the flowing lines
    [lines addObject:@"echo $1 | sudo -S pwd > /dev/null"];
    // switch the demons
    [lines addObject:[self switchDeamonsScript:paths enabled:toWorkMode]];
    
    
    // remove the certificate
    NSString *savedCersPath = [NSString stringWithFormat:@"%@/Library/Application Support/MyHouseMyRule", NSHomeDirectory()];
    NSString *keychainPath = [NSString stringWithFormat:@"%@/Library/Keychains/login.keychain", NSHomeDirectory()];
    if (![[NSFileManager defaultManager] fileExistsAtPath:keychainPath]) {
        keychainPath = [keychainPath stringByAppendingString:@"-db"];
    }
    if (!toWorkMode) {
        // save some certificates, as it cannot recover automatically
        [lines addObject:[NSString stringWithFormat:@"mkdir -p '%@'", savedCersPath]];
        [lines addObject:[NSString stringWithFormat:@"security find-certificate -a -p -c pf.sankuai.info > '%@/1.pem'", savedCersPath]];
        [lines addObject:[NSString stringWithFormat:@"security find-certificate -a -p -c 'Go Daddy Root' > '%@/2.pem'", savedCersPath]];

        // remove
        [lines addObject:@"security delete-certificate -c localhost.moa.sankuai.com"];
        [lines addObject:@"security delete-certificate -c pf.sankuai.info"];
        [lines addObject:@"security delete-certificate -Z 2796BAE63F1801E277261BA0D77770028F20EEE4"]; // 'Go Daddy Class 2 Certification Authority 这个没有 common name ，只能这么删
        NSString *output;
        [self runScript:@"security find-certificate -aZc 'Go Daddy' | grep SHA-1 | cut -c 13-" output:&output];
        [[[output componentsSeparatedByString:@"\n"] map:^id(NSString *obj) {
            return [obj stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }] forEach:^(NSString *obj) {
            if (obj.length > 0) {
                [lines addObject:[NSString stringWithFormat:@"security delete-certificate -Z %@", obj]];
            }
        }];
    } else {
        // recover some certificates
        [lines addObject:[NSString stringWithFormat:@"security import '%@/1.pem' -k '%@'", savedCersPath, keychainPath]];
        [lines addObject:[NSString stringWithFormat:@"security import '%@/2.pem' -k '%@'", savedCersPath, keychainPath]];
    }
    
    __auto_type script = [lines componentsJoinedByString:@"\n"];
    NSString *scriptTempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"myHouseMyRule.sh"]];
    [script writeToFile:scriptTempPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    __auto_type password = [PasswordManager getRootPassword];
    __auto_type commands = [NSString stringWithFormat:@"bash '%@' '%@' &>'%@.out'", scriptTempPath, password, scriptTempPath];
    [self run:@"/bin/bash" args:@[@"-c", commands] output:nil];
}


+ (NSString *)switchDeamonsScript:(NSArray<NSString *>*)plistPaths enabled:(BOOL)enabled {
    
    NSArray *commands = [plistPaths map:^id(NSString *obj) {
        if (enabled) {
            return [NSMutableString stringWithFormat:@"launchctl load -w %@;", obj];
        } else {
            return [NSMutableString stringWithFormat:@"launchctl unload -w %@;", obj];
        }
        
    }];
    // /Library 中是要以 root 权限执行的
    // ~/Library 中的要以普通用户身份执行
    //
    // 不知道为什么在用 STPrivilegedTask 获得 root 权限运行时，虽然 whoami 是 root，但 launchctl
    // 的执行结果不是 root。所以这里使用 sudo 强制 root 执行。
    commands  = [commands map:^id(NSString *obj) {
        if ([obj containsString:@"/Users"] || [obj containsString:@"~/"]) {
            // user's, add nothing
            return obj;
        } else {
            // root
            NSString *s = [NSString stringWithFormat:@"sudo %@", obj];
            if ([s containsString:@"unload"]) {
                s = [s stringByAppendingString:@"\n"];
                s = [s stringByAppendingString:obj]; // 修复之前版本中因为权限问题，而使用普通用户 enable 的 service
            }
            return s;
        }
    }];
    NSString *script = [commands componentsJoinedByString:@"\n"];
    
    
    if (!enabled) {
        // the app is not the service itself, so it will not be killed when service turning off
        NSString *killScript = @"\n\n"
        "sudo killall -9 itsec-agent \n" // the MOA app
        "ps -Ao comm | grep MOA.app | xargs basename | xargs sudo killall -9 \n" // the MOA app
        "sudo killall -9 DLP3.0 \n" // the DLP app
        "ps -Ao comm | grep DLP | xargs basename | xargs sudo killall -9  \n" // the DLP app, TODO container the space, not work
        ;
        script = [script stringByAppendingString:killScript];
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
    [results addObjectsFromArray:[daemons filter:^BOOL(NSString *obj) {
        return [obj.lastPathComponent.lowercaseString containsString:@"meituan"];
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
    [results addObjectsFromArray:[agents filter:^BOOL(NSString *obj) {
        return [obj.lastPathComponent.lowercaseString containsString:@"meituan"];
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
    [results addObjectsFromArray:[agents filter:^BOOL(NSString *obj) {
        return [obj.lastPathComponent.lowercaseString containsString:@"meituan"];
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

