//
//  SunCodeDB.h
//  SSSKV
//
//  Created by Sunbohong,Bohong on 2018/3/16.
//  Copyright © 2018年 Sunbohong,Bohong. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 高性能，实时，小容量的数据库，默认最多存储1024*10 的长度
// key value 的长度限制为 NSUInteger 的最大值
@interface SunCodeDB : NSObject

+ (instancetype)sharedDB;

// 返回剩余的空间大小
-(NSUInteger)setValue:(const char *)value length:(NSUInteger)length forKey:(NSString *)key;

//+ (void)reset;

@end

NS_ASSUME_NONNULL_END
