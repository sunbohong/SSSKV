//
//  SunProtoDB.m
//  SSSKV
//
//  Created by Sunbohong,Bohong on 2018/3/16.
//  Copyright © 2018年 Sunbohong,Bohong. All rights reserved.
//

#import "SunProtoDB.h"

#import "Msg.pbobjc.h"

#import <sys/mman.h>

@implementation SunProtoDB
{
    NSUInteger _capacity;
    NSUInteger _size;
    NSString *_path;
    char *_baseAdresses;
    char *_current;
}

+(instancetype)sharedDB{
    static SunProtoDB *db=nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        db = [[SunProtoDB alloc] init];
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
        _path = [SunProtoDB writeablePathForFile:@"pb.db"];

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


// 这里简化了微信的实现，每次赋值都直接从起始位置存储数据
-(NSUInteger)setData:( NSData *)data forKey:(nonnull NSString *)key {
    _current = _baseAdresses;
    _capacity = _size;

    //    ps.这种方案比 bytes 的方案效率更高
    [data enumerateByteRangesUsingBlock:^(const void * _Nonnull bytes, NSRange byteRange, BOOL * _Nonnull stop) {
        [self writeValue:bytes length:byteRange.length];
    }];
    return _capacity;
}

+(void)load{

    SunProtoDB *db = [SunProtoDB sharedDB];

    NSString *valueStr=@"abcdefghijklmnopqrstuvwxyz";

    double start= [NSDate date].timeIntervalSince1970;

    NSString *key =  @"store";

    SUNRecord *record = [[SUNRecord alloc] init];
    SUNRecordItem *item = [[SUNRecordItem alloc] init];
    item.data_p = valueStr;
    [record.objArray addObject:item];

    for (int i=0; i<10000; i++) {
        NSData *data = [record data];
        [db setData:data forKey:key];
    }
    double end = [NSDate date].timeIntervalSince1970;
    NSLog(@"SunProtoDB:%f",(end-start));

}
@end
