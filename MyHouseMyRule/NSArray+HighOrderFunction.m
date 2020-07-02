//
//  NSArray + Functional.m
//  MapFilterReduce
//
//  Created by Gao on 12/4/15.
//  Copyright © 2015 zhihu. All rights reserved.
//

#import "NSArray+HighOrderFunction.h"


@implementation NSArray (Functional)

#define checkNilOrSafelyReturn(block) \
NSAssert(block != nil, @"Block cannot be nil"); \
 if (block == nil ) { \
    return @[]; \
} \

#define checkNilOrSafelyReturnZero(block) \
NSAssert(block != nil, @"Block cannot be nil"); \
if (block == nil ) { \
return 0; \
} \





- (nonnull NSArray *)map:(nonnull id (^)(id obj))block
{
    checkNilOrSafelyReturn(block);
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];

    for (id obj in self) {
        id value = block(obj);
        // 如果 block 内部返回 nil
        NSAssert(value, @"Invalid Map Input!!!");
        if (value) {
            [result addObject:value];
        }
    }

    return result;
}


- (nonnull NSArray *)filter:(BOOL (^)(id obj) )block {

    checkNilOrSafelyReturn(block);
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];

    for (id obj in self) {
        if (block(obj)) {
            [result addObject:obj];
        }
    }

    return result;
}

- (void)forEach:( void (^ _Nonnull)(id obj) )block{
    if (block == nil) {
        return;
    }
    for (id obj in self) {
        block(obj);
    }
}


- (nonnull NSArray*)flatMap:( id _Nullable (^ _Nonnull)(id obj))block {

    checkNilOrSafelyReturn(block);
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];

    for (id obj in self) {
        id a = block(obj);
        if (a) {
            [result addObject:a];
        }
    }

    return result;
}





- (nullable id)reduce:(id)initial withBlock:(id (^)(id sum, id obj))block
{
    checkNilOrSafelyReturn(block);
    id result = initial;

    for (id obj in self) {
        result = block(result, obj);
    }
    
    return result;
}

- (NSInteger)reduceInteger:(NSInteger)initial withBlock:(NSInteger (^)(NSInteger, id))block
{
    checkNilOrSafelyReturnZero(block);
    NSInteger result = initial;

    for (id obj in self) {
        result = block(result, obj);
    }

    return result;
}

- (CGFloat)reduceFloat:(CGFloat)inital withBlock:(CGFloat (^)(CGFloat, id))block
{
    checkNilOrSafelyReturnZero(block);
    CGFloat result = inital;

    for (id obj in self) {
        result = block(result, obj);
    }
    
    return result;
}

@end
