//
//  NSArray + Functional.h
//  MapFilterReduce
//
//  Created by Gao on 12/4/15.
//  Copyright © 2015 zhihu. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSArray<__covariant ObjectType>  (Functional)

/**
    The nullablity notations are not fully added, beause of the fussy grammer in autocompleted block which is bad to
    readability. Every object here is nonnull, as we know, EVERYTHING in NSArray CANNOT be nil.
 */

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"

- (nonnull NSArray*) map:(id (^ _Nonnull)(ObjectType obj) )block;
/// just like `map`, but filter the ones if block return nil
- (nonnull NSArray*) flatMap:( id _Nullable (^ _Nonnull)(ObjectType obj))block;

- (nonnull NSArray<ObjectType> *)filter:(BOOL (^ _Nonnull)(ObjectType obj) )block;

- (nullable id)reduce:(nullable id)initial      withBlock:(id _Nullable (^_Nonnull)(id _Nullable sum, ObjectType _Nonnull obj))block;
- (NSInteger)  reduceInteger:(NSInteger)initial withBlock:(NSInteger (^_Nonnull)(NSInteger sum, ObjectType _Nonnull obj))block;
- (CGFloat)    reduceFloat:(CGFloat)inital      withBlock:(CGFloat (^_Nonnull)(CGFloat, ObjectType _Nonnull obj))block;

- (void)forEach:( void (^ _Nonnull)(ObjectType obj) )block;

#pragma clang diagnostic pop
@end

