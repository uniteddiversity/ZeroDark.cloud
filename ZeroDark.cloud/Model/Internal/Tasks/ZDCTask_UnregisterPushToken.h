/**
 * ZeroDark.cloud
 * <GitHub wiki link goes here>
**/

#import "ZDCTask.h"
#import "AWSRegions.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * When a localUser is deleted, we no longer have the ZDCLocalUser in the database.
 * So we store the pushToken unregistration task here.
 */
@interface ZDCTask_UnregisterPushToken : ZDCTask <NSCoding, NSCopying>

/**
 * If you don't know the region, just pass AWSRegion_Invalid.
 */
- (instancetype)initWithUserID:(NSString *)userID region:(AWSRegion)region;

@property (nonatomic, copy, readonly) NSString *userID;
@property (nonatomic, assign, readonly) AWSRegion region;

@end

NS_ASSUME_NONNULL_END
