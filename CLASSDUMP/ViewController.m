//
//  ViewController.m
//  CLASSDUMP
//
//  Created by ccc on 2023/3/6.
//

#import <mach-o/dyld.h>
#include <objc/runtime.h>
#include <string.h>
#import "SymbolCatcher.h"
#import "ViewController.h"

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


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    SymbolCatcher *catcher = [[SymbolCatcher alloc] init];
    catcher.checkModules = @[@"UIKit", @"UIKitCore"];

    NSMutableDictionary *output = [NSMutableDictionary dictionary];
    NSDictionary *version = @{
            @"start_version": @"5.22.0"
    };
    int allCount = 0;
    // 获取类的列表
    int numClasses;
    Class *classes = objc_copyClassList(&numClasses);

    // 遍历类列表
    bool flag = false;

    for (int i = 0; i < numClasses; i++) {
        Class cls = classes[i];
        const char *className = class_getName(cls);

//      printf("Found class: %s\n", className);
        if (strcmp(className, "UIDatePicker") == 0) {
            printf("a");
            flag = true;
        }

        // 获取类的属性列表
        unsigned int propertyCount;
        objc_property_t *properties = class_copyPropertyList(cls, &propertyCount);

        for (unsigned int j = 0; j < propertyCount; j++) {
            const char *propertyName = property_getName(properties[j]);
//          printf("  Property: %s\n", propertyName);
        }

        free(properties);

        // 获取类的方法列表
        unsigned int methodCount;
        Method *methods = class_copyMethodList(cls, &methodCount);

        for (unsigned int k = 0; k < methodCount; k++) {
            SEL methodName = method_getName(methods[k]);
            const char *methodNameString = sel_getName(methodName);
//          printf("  Method: %s\n", methodNameString);
            uintptr_t ptr = (uintptr_t)IIMP(className, methodName);

            BOOL shouldCache = [catcher isSymbolInModules:ptr];
            BOOL isPrivite = [[NSString stringWithUTF8String:methodNameString] hasPrefix:@"_"];

            if (isPrivite) {
                printf("");
            }

            if (shouldCache) {
                if (isPrivite) {
                    allCount++;
                    printf("%s  Method: %s\n", className, methodNameString);
                    NSString *blackItem = [[NSString stringWithUTF8String:methodNameString] componentsSeparatedByString:@":"].firstObject;
                    output[blackItem] = version;
                }
            }
        }

        free(methods);
    }

    // 释放动态库的句柄和类列表
    free(classes);
    printf("all count %d", allCount);
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:output options:0 error:&error];

    if (!jsonData) {
        NSLog(@"JSON serialization failed with error: %@", error);
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//      NSLog(@"%@", jsonString);
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents directory

        NSError *error;
        BOOL succeed = [jsonString writeToFile:@"/Users/ccc/Downloads/hehe.json"
                                    atomically:YES
                                      encoding:NSUTF8StringEncoding
                                         error:&error];

        if (!succeed) {
            // Handle error here
        }
    }
}

@end
