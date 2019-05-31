/**
 * ZeroDark.cloud
 * <GitHub wiki link goes here>
**/

#import <Foundation/Foundation.h>

#import "YapDatabaseCloudCorePipelineDelegate.h"
@class ZDCCloudOperation;

/**
 * The sync process can be broken down into 2 components:
 * - Push
 * - Pull
 *
 * If you've used git before, you're already familiar with the process.
 * You push changes (made locally) to the cloud. And you pull changes (made on remote devices) from the cloud.
 *
 * This class handles the PUSH side of things.
 */
@interface ZDCPushManager : NSObject <YapDatabaseCloudCorePipelineDelegate>

- (void)abortOperationsForLocalUserID:(NSString *)localUserID appID:(NSString *)appID;

- (void)abortOperations:(NSArray<ZDCCloudOperation *> *)operations;

@end
