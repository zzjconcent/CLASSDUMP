//
//  SymbolCatcher.m
//  CLASSDUMP
//
//  Created by ccc on 2023/3/6.
//

#import <mach-o/dyld.h>
#include <objc/runtime.h>
#include <string.h>
#import "SymbolCatcher.h"

#define IIMP(class_name, method_name) class_getMethodImplementation(objc_getClass(class_name), sel_registerName(method_name))
#define CIMP(class_name, method_name) class_getMethodImplementation(objc_getMetaClass(class_name), sel_registerName(method_name))
#ifdef __LP64__
#define mach_header     mach_header_64
#define segment_command segment_command_64
#define LCSEGMENT       LC_SEGMENT_64
#else
#define mach_header     mach_header
#define segment_command segment_command
#define LCSEGMENT       LC_SEGMENT
#endif

char * get_filename(char *path) {
    char *filename = strrchr(path, '/'); // 找到最后一个斜杠的位置

    if (filename == NULL) {
        filename = strrchr(path, '\\'); // 如果是Windows系统，则找到最后一个反斜杠的位置
    }

    if (filename == NULL) {
        filename = path; // 如果没有斜杠，则说明整个字符串都是文件名
    } else {
        filename++; // 否则，将指针移动到斜杠后面的字符
    }

    return filename;
}

@interface SymbolCatcher ()

@property (nonatomic, strong) NSMutableArray <NSNumber *> *dylibStart;
@property (nonatomic, strong) NSMutableArray <NSNumber *> *dylibEnd;
@property (nonatomic, strong) NSMutableArray <NSString *> *dylibName;
@property (nonatomic, strong) NSMutableArray <NSNumber *> *checkIndexes;

@end

@implementation SymbolCatcher


- (instancetype)init {
    self = [super init];
    _dylibStart = [NSMutableArray array];
    _dylibEnd = [NSMutableArray array];
    _dylibName = [NSMutableArray array];
    uint32_t imageCount = _dyld_image_count();
    uintptr_t uikitStart;
    uintptr_t uikitEnd;

    for (int i = 0; i < imageCount; i++) {
        const char *imageName = _dyld_get_image_name(i);
        const struct mach_header *header = (const struct mach_header *)_dyld_get_image_header(i);
        const uint8_t *command = (const uint8_t *)(header + 1);
        uint64_t vmsize = 0;

        for (uint32_t idx = 0; idx < header->ncmds; ++idx) {
            if (((const struct load_command *)command)->cmd == LCSEGMENT) {
                const struct segment_command *seg_cmd = (const struct segment_command *)command;

                if (![[NSString stringWithCString:seg_cmd->segname encoding:NSUTF8StringEncoding] isEqualToString:@"__PAGEZERO"] || i != 0) {
                    vmsize += seg_cmd->vmsize;
                }
            }

            command += ((const struct load_command *)command)->cmdsize;
        }

        uikitStart = (uintptr_t)_dyld_get_image_header(i);
        uikitEnd = uikitStart + vmsize;
        [_dylibName addObject:[NSString stringWithUTF8String:get_filename(imageName)]];
        [_dylibStart addObject:[NSNumber numberWithUnsignedLongLong:uikitStart]];
        [_dylibEnd addObject:[NSNumber numberWithUnsignedLongLong:uikitEnd]];
    }

    return self;
}

- (void)setCheckModules:(NSMutableArray<NSString *> *)checkModules {
    self.checkIndexes = [NSMutableArray array];

    for (NSString *string in checkModules) {
        for (int i = 0; i < self.dylibStart.count; i++) {
            if ([string isEqualToString:self.dylibName[i]]) {
                [self.checkIndexes addObject:[NSNumber numberWithUnsignedInt:i]];
            }
        }
    }
}

- (BOOL)isSymbolInModules:(uintptr_t)ptr {
    for (NSNumber *index in self.checkIndexes) {
        int idx = index.unsignedIntValue;

        if (ptr >= self.dylibStart[idx].unsignedLongLongValue && ptr <= self.dylibEnd[idx].unsignedLongLongValue) {
            return true;
        }
    }

    return false;
}

- (NSString *)findMethodInModules:(uintptr_t)ptr {
    for (int i = 0; i < self.dylibName.count; i++) {
        if (ptr >= self.dylibStart[i].unsignedLongLongValue && ptr <= self.dylibEnd[i].unsignedLongLongValue) {
            return self.dylibName[i];
        }
    }

    return nil;
}

@end
