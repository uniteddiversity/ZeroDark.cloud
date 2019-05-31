/**
 * ZeroDark.cloud
 * <GitHub wiki link goes here>
**/

#import <Foundation/Foundation.h>
#import <S4Crypto/S4Crypto.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (S4)

/**
 * Documentation ?
**/
- (NSString *)KDFWithSeedKey:(NSData *)seedKey label:(NSString *)label;

/**
 * Convenience method which converts string to UTF-8 data, and then returns hash of it.
 **/
- (NSData *)hashWithAlgorithm:(HASH_Algorithm)hashAlgo error:(NSError **)errorOut;


@end

NS_ASSUME_NONNULL_END
