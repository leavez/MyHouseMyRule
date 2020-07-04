//
//  PasswordManager.m
//  MyHouseMyRule
//
//  Created by leave on 2020/7/4.
//  Copyright © 2020 leave. All rights reserved.
//

#import "PasswordManager.h"
#import "ShellCommand.h"
#import "NSData+AES256.h"

@implementation PasswordManager

NSString *p = @"A01pL5brQkYT0lUD5rBRI8eyszTp73UWN7Hv7G0tYcA=";

+ (BOOL)doesPasswordSetup {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"saved_key"] != nil;
}

+ (BOOL)validatePassword:(NSString *)p {
    if (p.length == 0) {
        return NO;
    }
    NSString *output = nil;
    [ShellCommand runScript:[NSString stringWithFormat:@"echo '%@' | sudo -S whoami", p] output:&output];
    return [output containsString:@"root"];
}


+ (void)saveRootPassword:(NSString *)password {
    NSData *data = [password dataUsingEncoding:NSUTF8StringEncoding];
    NSData *encripted = [data aes256_encrypt:p];
    [[NSUserDefaults standardUserDefaults] setObject:encripted forKey:@"saved_key"];
}

+ (NSString *)getRootPassword {
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:@"saved_key"];
    NSData *decript = [data aes256_decrypt:p];
    NSString *pass = [[NSString alloc] initWithData:decript encoding:NSUTF8StringEncoding];
    return pass;
}


@end
