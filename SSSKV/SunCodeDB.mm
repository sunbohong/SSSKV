//
//  SunCodeDB.m
//  SSSKV
//
//  Created by Sunbohong,Bohong on 2018/3/16.
//  Copyright © 2018年 Sunbohong,Bohong. All rights reserved.
//


#include <iostream>
#include <string>
#include <unordered_map>

#import "SunCodeDB.h"

#import "Msg.pbobjc.h"
#import <sys/mman.h>

@implementation SunCodeDB {
    NSUInteger _capacity;
    NSUInteger _size;
    NSString *_path;
    char *_baseAdresses;
    char *_current;
}

+(instancetype)sharedDB{
    static SunCodeDB *db=nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        db = [[SunCodeDB alloc] init];
    });
    return db;
}

+ (NSString *)writeablePathForFile:(NSString *)fileName {
    NSArray *paths               = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:fileName];
}

-(instancetype)init{
    if (self=[super init]) {
        __block int result = 0;

        _size = _capacity = 1024*10;
        _path = [SunCodeDB writeablePathForFile:@"c.db"];

        [[NSFileManager defaultManager] createFileAtPath:_path
                                                contents:[[NSMutableData alloc] initWithLength:_size]
                                              attributes:nil];

        int fd = open([_path UTF8String], O_RDWR);
        if (fd == -1) {
            perror("open");
            result = 1;
        }
        _baseAdresses = (char *)mmap(0, _size, PROT_READ|PROT_WRITE,MAP_SHARED, fd, 0);
        _current = _baseAdresses;

        if (_baseAdresses == MAP_FAILED) {
            perror("mmap");
            result = 1;
        }
        if (close(fd) == -1) {
            perror("close");
            result = 1;
        }
        assert(0==result);
    }
    return self;
}


//    value key valueL keyL

- (void)merge {

    std::unordered_map<std::string,std::string> mymap = {};

    char *tmpCurrent = _current;
    while (tmpCurrent > _baseAdresses ) {

        tmpCurrent--;
        NSUInteger keyLength = tmpCurrent[0];

        tmpCurrent--;
        NSUInteger valueLength = tmpCurrent[0];

        tmpCurrent -= keyLength;
        std::string key = &tmpCurrent[0];

        tmpCurrent -= valueLength;
        std::string value = &tmpCurrent[0];

        std::pair<std::string,std::string> pair (key,value);

        mymap.insert (pair);
    }
    _capacity = _size;
    _current = _baseAdresses;
    memset(_baseAdresses,0,sizeof(char)*_size);

//    printf("size=%lu\n",mymap.size());
    auto map_it = mymap.cbegin();
    while (map_it != mymap.cend()) {
        [self writeValue:map_it->second forKey:map_it->first];
        ++map_it;
    }
}

// 需要填充空白
- (void)writeValue:(std::string)value forKey:(std::string)key {
//    printf("%s=%s\n",key.c_str(),value.c_str());
    [self writeValue:value.c_str() length:value.length()];
    [self writeValue:NULL];
    [self writeValue:key.c_str() length:key.length()];
    [self writeValue:NULL];
    [self writeLength:value.length()+1];
    [self writeLength:key.length()+1];
}


- (void)writeValue:(const char)value {
    _current[0] = value;
    _current++;
    _capacity--;
}

- (void)writeValue:(const char *)value length:(NSUInteger)length {
    for (NSUInteger i = 0; i < length; i++) {
        _current[0] = value[i];
        _current++;
    }
    _capacity -= length;
}

-(void)writeLength:(NSUInteger)length{
    _current[0] = length;
    _current++;

    _capacity--;
}



-(NSUInteger)setValue:(const char *)value length:(NSUInteger)length forKey:(NSString *)key {
    NSUInteger keyLength = [key lengthOfBytesUsingEncoding:NSUTF8StringEncoding]+1;

    if(_capacity < (length+keyLength)){
//        perror("空间不足");
        [self merge];
    }
    const char *aKey = [key cStringUsingEncoding:NSUTF8StringEncoding];
    [self writeValue:value length:length];
    [self writeValue:aKey length:keyLength];
    [self writeLength:length];
    [self writeLength:keyLength];

    return _capacity;
}

+(void)load{

    SunCodeDB *db = [SunCodeDB sharedDB];

    NSString *valueStr=@"abcdefghijklmnopqrstuvwxyz";

    double start= [NSDate date].timeIntervalSince1970;

    NSString *key =  @"store";
    for (int i=0; i<10000; i++) {
        const char *value = [valueStr cStringUsingEncoding:NSUTF8StringEncoding];
        NSUInteger length = [valueStr lengthOfBytesUsingEncoding:NSUTF8StringEncoding]+1;

        [db setValue:value length:length forKey:key];
    }
    double end = [NSDate date].timeIntervalSince1970;
    NSLog(@"SunCodeDB:%f",(end-start));
}


@end
