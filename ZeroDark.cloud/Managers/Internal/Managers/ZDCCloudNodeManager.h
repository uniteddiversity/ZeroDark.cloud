#import <Foundation/Foundation.h>

#import "AWSRegions.h"
#import "ZDCDatabaseManager.h"
#import "ZDCCloudNode.h"
#import "ZDCCloudPath.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * The framework sometimes needs to represent nodes that exist in the cloud,
 * but don't exist in the local treesystem (as a ZDCCNode) because either:
 *
 * - the node has been deleted locally (but we haven't yet pushed the delete request to the server)
 * - the node appears to be an orphan (the rcrd file exists on the server, but there's no matching data file)
 *
 * For these situations, the framework stores an internal object called a ZDCCloudNode.
 * And this manager provides various utilities for finding these "cloud nodes".
 */
@interface ZDCCloudNodeManager : NSObject

/**
 * Returns singleton instance.
 */
+ (instancetype)sharedInstance;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Find CloudNode
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Locates the cloudNode using only the cloud path information.
 *
 * Use this method when you're only interested in what information we have for a specific cloud location.
 */
- (nullable ZDCCloudNode *)findCloudNodeWithCloudPath:(ZDCCloudPath *)cloudPath
                                               bucket:(NSString *)bucket
                                               region:(AWSRegion)region
                                          localUserID:(NSString *)localUserID
                                          transaction:(YapDatabaseReadTransaction *)transaction;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Enumerate CloudNodes
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Enumerates all ZDCCloudNode's whose cloudLocator.cloudPath.dirPrefix matches the given parent.dirPrefix.
 *
 * This only includes the direct (first generation) children of the given parent.
 * Further ancestors (grandchildren, etc) are NOT enumerated.
 */
- (void)enumerateCloudNodesWithParent:(ZDCCloudNode *)parent
                          transaction:(YapDatabaseReadTransaction *)transaction
                           usingBlock:(void (^)(ZDCCloudNode *cloudNode, BOOL *stop))enumBlock;

/**
 * Enumerates all ZDCCloudNodes's who are ancestors of the given parent.
 *
 * This includes direct children, as well as further ancestors (grandchildren, etc).
 */
- (void)recursiveEnumerateCloudNodesWithParent:(ZDCCloudNode *)parent
                                   transaction:(YapDatabaseReadTransaction *)transaction
                                    usingBlock:(void (^)(ZDCCloudNode *cloudNode, BOOL *stop))enumBlock;

/**
 * Returns a list of all cloudNodeID's belonging to the given user.
 */
- (NSArray<NSString *> *)allCloudNodeIDsWithLocalUserID:(NSString *)localUserID
                                            transaction:(YapDatabaseReadTransaction *)transaction;

@end

NS_ASSUME_NONNULL_END
