//
//  SymbolCatcher.h
//  CLASSDUMP
//
//  Created by ccc on 2023/3/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SymbolCatcher : NSObject

@property(nonatomic, strong) NSMutableArray <NSString *>*checkModules;

- (BOOL)isSymbolInModules:(uintptr_t)ptr;
- (NSString *)findMethodInModules:(uintptr_t)ptr;

@end

NS_ASSUME_NONNULL_END
