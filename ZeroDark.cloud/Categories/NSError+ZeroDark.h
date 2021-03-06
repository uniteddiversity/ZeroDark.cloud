/**
 * ZeroDark.cloud
 * 
 * Homepage      : https://www.zerodark.cloud
 * GitHub        : https://github.com/4th-ATechnologies/ZeroDark.cloud
 * Documentation : https://zerodarkcloud.readthedocs.io/en/latest/
 * API Reference : https://apis.zerodark.cloud
**/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSError (ZeroDark)

+ (NSString *)domainForClass:(Class)cls;

+ (NSError *)errorWithClass:(Class)cls code:(NSInteger)code;
+ (NSError *)errorWithClass:(Class)cls code:(NSInteger)code description:(nullable NSString *)description;

@end

NS_ASSUME_NONNULL_END
