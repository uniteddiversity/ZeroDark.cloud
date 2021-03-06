/**
 * ZeroDark.cloud
 *
 * Homepage      : https://www.zerodark.cloud
 * GitHub        : https://github.com/4th-ATechnologies/ZeroDark.cloud
 * Documentation : https://zerodarkcloud.readthedocs.io/en/latest/
 * API Reference : https://apis.zerodark.cloud
**/

#import <Foundation/Foundation.h>
#import <YapDatabase/YapDatabase.h>

#import "ZDCConstants.h"
#import "AWSRegions.h"
#import "ZDCCloud.h"
#import "ZDCCloudRcrd.h"
#import "ZDCNode.h"
#import "ZDCPublicKey.h"
#import "ZDCTreesystemPath.h"
#import "ZDCTrunkNode.h"
#import "ZDCUser.h"


NS_ASSUME_NONNULL_BEGIN

/**
 * Provides various methods for inspecting the node treesystem.
 */
@interface ZDCNodeManager : NSObject

/**
 * Returns the singleton instance.
 */
+ (instancetype)sharedInstance;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Trunks & Anchors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Returns a specific trunk (top-level root node).
 *
 * This method only returns nil if you pass an invalid parameter.
 *
 * @param localUserID
 *   The localUser for which you're interested (localUserID == ZDCLocalUser.uuid)
 *
 * @param treeID
 *   The treeID you registered in the ZeroDark.cloud dashboard.
 *   This is the same treeID you passed when you created a ZeroDarkCloud instance.
 *
 * @param trunk
 *   The trunk you're looking for.
 *
 * @param transaction
 *   A database transaction - allows the method to read from the database.
 */
- (nullable ZDCTrunkNode *)trunkNodeForLocalUserID:(NSString *)localUserID
                                            treeID:(NSString *)treeID
                                             trunk:(ZDCTreesystemTrunk)trunk
                                       transaction:(YapDatabaseReadTransaction *)transaction;

/**
 * A "trunk node" is a top-level root node.
 * This method walks up the tree until it finds the corresponding trunk.
 *
 * This method only returns nil if you pass a node that isn't part of the treesystem.
 *
 * @param node
 *   Find the trunk for this node.
 *   (The node doesn't need to be stored in the database for this method to work.
 *    But it will need to have a proper `-[ZDCNode parentID]` property set.)
 *
 * @param transaction
 *   A database transaction - allows the method to read from the database.
 */
- (nullable ZDCTrunkNode *)trunkNodeForNode:(ZDCNode *)node
                                transaction:(YapDatabaseReadTransaction *)transaction;

/**
 * An "anchor node" is the nearest node in the hierarchy that
 * provides a location anchor (e.g. an AWS region & bucket).
 *
 * This could be the trunkNode (a ZDCTrunkNode instance), meaning the user's own region & bucket.
 * Or it could be another node with a non-nil anchor property, meaning some other user's region & bucket.
 *
 * The anchorNode is found by traversing up the node hierarchy towards the trunkNode,
 * and searching for a node with anchor information.
 * If not found, the trunkNode is returned.
 *
 * This method only returns nil if you pass a node that isn't part of the treesystem.
 *
 * @param node
 *   Find the anchorNode for this node.
 *   (The node doesn't need to be stored in the database for this method to work.
 *    But it will need to have a proper `-[ZDCNode parentID]` property set.)
 *
 * @param transaction
 *   A database transaction - allows the method to read from the database.
 */
- (nullable ZDCNode *)anchorNodeForNode:(ZDCNode *)node transaction:(YapDatabaseReadTransaction *)transaction;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Owners
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Returns the owner of a given node.
 *
 * This is done by traversing the node hierarchy up (towards the trunk/root).
 * The search completes when either:
 * - the trunk node is encountered
 * - an anchor node (with an explicit ownerID) is encountered
 *
 * If all else fails (e.g. because the node.parentID is invalid),
 * then node.localUserID is returned.
 *
 * @param node
 *   Find the ownerID for this node.
 *   (The node doesn't need to be stored in the database for this method to work.
 *    But it should have a proper `-[ZDCNode parentID]` set.)
 *
 * @param transaction
 *   A database transaction - allows the method to read from the database.
 */
- (NSString *)ownerIDForNode:(ZDCNode *)node transaction:(YapDatabaseReadTransaction *)transaction;

/**
 * Invokes `ownerIDForNode:transaction:`, and then uses the result to fetch the corresponding ZDCUser.
 *
 * The ZDCUser instance may be nil if the the owner is a non-local-user and
 * the system hasn't downloaded the remote user yet.
 * You can always use the `ZDCUserManager` to download the user.
 */
- (nullable ZDCUser *)ownerForNode:(ZDCNode *)node transaction:(YapDatabaseReadTransaction *)transaction;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Pointers
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * If the given node is a pointer (node.isPointer == true),
 * then this method follows the pointer (recursively, if needed) until the target node is found.
 *
 * If the given node is not a pointer (node.isPointer == false), it simply returns the given node.
 *
 * Only returns nil if:
 * - node is a pointer
 * - node's target doesn't currently exist
 */
- (nullable ZDCNode *)targetNodeForNode:(ZDCNode *)node transaction:(YapDatabaseReadTransaction *)transaction;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Local Path
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Returns the path to the given node.
 *
 * @param node
 *   The node you're interested in.
 *
 * @param transaction
 *   A database transaction - allows the method to read from the database.
 */
- (ZDCTreesystemPath *)pathForNode:(ZDCNode *)node
                       transaction:(YapDatabaseReadTransaction *)transaction;

/**
 * Returns an array of all parent nodeID's of the given node, up to the containerNode.
 *
 * The containerNode will be at index 0,
 * and the immediate parentNodeID will be the last item in the array.
 *
 * @note The term nodeID is short for ZDCNode.uuid.
 *
 * @param node
 *   The node you're interested in.
 *
 * @param transaction
 *   A database transaction - allows the method to read from the database.
 */
- (NSArray<NSString *> *)parentNodeIDsForNode:(ZDCNode *)node
                                  transaction:(YapDatabaseReadTransaction *)transaction;

/**
 * Walks the tree from nodeID up to the root,
 * and checks to see if potentialParentID is indeed in its hierarchy.
 *
 * @note The term nodeID is short for ZDCNode.uuid.
 */
- (BOOL)isNode:(NSString *)nodeID
 aDescendantOf:(NSString *)potentialParentID
   transaction:(YapDatabaseReadTransaction *)transaction;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Enumerate Nodes
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Enumerates all ZDCNode.uuid's whose parentID property matches the given parentID.
 * 
 * This method is slightly faster than enumerating the ZDCNode objects,
 * as it can skip fetching the objects from the database.
 * 
 * This only includes the direct children of the given parent.
 * Further ancestors (grandchildren, etc) are NOT enumerated.
 * If you want a deep recursion (including grandchildren, etc),
 * then use `recursiveEnumerateNodeIDsWithParentID:transaction:usingBlock:`.
 */
- (void)enumerateNodeIDsWithParentID:(NSString *)parentID
                         transaction:(YapDatabaseReadTransaction *)transaction
                          usingBlock:(void (^NS_NOESCAPE)(NSString *nodeID, BOOL *stop))enumBlock;

/**
 * Enumerates all ZDCNode.uuid's who are ancestors of the given parentID.
 * This includes direct children, as well as further ancestors (grandchildren, etc).
 *
 * The recursion process is performed using a depth first algorithm,
 * and the path to each nodeID is provided via the enumBlock.
 *
 * The `pathFromParent` array does not contain the parentID, nor the nodeID parameter.
 * It only contains all nodeIDs between the parentID & the nodeID.
 * Thus, direct children of the parentID will have an empty pathFromParent array.
 * The array is ordered such that the node closest to the parent is at index zero.
 *
 * @warning The `pathFromParent` array is mutable, and gets changed between each invocation of the block.
 *          So if you need to store it outside the block context, you'll need to make a copy.
 *
 * The `recurseInto` parameter can be set to NO
 * for any node's for which you aren't interested in the children/descendents.
 *
 * @note This method is slightly faster than enumerating the ZDCNode objects,
 *       as it can skip fetching the objects from the database.
 *
 * @param parentID
 *   The node for which you wish to enumerate the children & ancestors.
 *   (parentID == nodeID_of_parent == ZDCNode.uuid)
 *
 * @param transaction
 *   A database transaction - allows the method to read from the database.
 *
 * @param enumBlock
 *   The block to invoke for each encountered nodeID during the recursive process.
 */
- (void)recursiveEnumerateNodeIDsWithParentID:(NSString *)parentID
                                  transaction:(YapDatabaseReadTransaction *)transaction
                                   usingBlock:(void (^NS_NOESCAPE)(NSString *nodeID,
                                                                   NSArray<NSString*> *pathFromParent,
                                                                   BOOL *recurseInto,
                                                                   BOOL *stop))enumBlock;

/**
 * Enumerates all ZDCNode's whose parentID property matches the given parentID.
 * 
 * This only includes the direct children of the given parent.
 * Further ancestors (grandchildren, etc) are NOT enumerated.
 * If you want a deep recursion (including grandchildren, etc),
 * then use `recursiveEnumerateNodesWithParentID:transaction:usingBlock:`.
 */
- (void)enumerateNodesWithParentID:(NSString *)parentID
                       transaction:(YapDatabaseReadTransaction *)transaction
                        usingBlock:(void (^NS_NOESCAPE)(ZDCNode *node, BOOL *stop))enumBlock;

/**
 * Enumerates all ZDCNodes's who are ancestors of the given parentID.
 * This includes direct children, as well as further ancestors (grandchildren, etc).
 *
 * The recursion process is performed using a depth first algorithm,
 * and the path to each nodeID is provided via the enumBlock.
 *
 * The `pathFromParent` array is does not contain the parent, nor the node parameter.
 * It only contains all nodes between the parent & the node.
 * Thus, direct children of the parent will have an empty pathFromParent array.
 * The array is ordered such that the node closest to the parent is at index zero.
 *
 * @warning The `pathFromParent` array is mutable, and gets changed between each invocation of the block.
 *          So if you need to store it outside the block context, you'll need to make a copy.
 *
 * The `recurseInto` parameter can be set to NO
 * for any node's for which you aren't interested in the children/descendents.
 *
 * @param parentID
 *   The node for which you wish to enumerate the children & ancestors.
 *   (parentID == nodeID_of_parent == ZDCNode.uuid)
 *
 * @param transaction
 *   A database transaction - allows the method to read from the database.
 *
 * @param enumBlock
 *   The block to invoke for each encountered node during the recursive process.
 */
- (void)recursiveEnumerateNodesWithParentID:(NSString *)parentID
                                transaction:(YapDatabaseReadTransaction *)transaction
                                 usingBlock:(void (^NS_NOESCAPE)(ZDCNode *node,
                                                                 NSArray<ZDCNode*> *pathFromParent,
                                                                 BOOL *recurseInto,
                                                                 BOOL *stop))enumBlock;

/**
 * Returns whether or not the node has any children.
 */
- (BOOL)hasChildren:(ZDCNode *)node transaction:(YapDatabaseReadTransaction *)transaction;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Find Nodes
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Finds the node with the given name, if it exists, and returns it.
 *
 * In most cases this lookup is performed in O(log n),
 * where `n` is number of ZDCNode's where node.parentID == parentID.
 * 
 * @param name
 *   The ZDCNode.name to find. (i.e. the cleartext name, such as "Inventory.numbers")
 *   The name comparison is both case-insensitive & localized. (So in German: daß == dass)
 *
 * @param parentID
 *   A reference to the parent node. (parentID == nodeID == ZDCNode.uuid)
 *
 * @param transaction
 *   A database transaction - allows the method to read from the database.
 * 
 * @return The matching ZDCNode, or nil if it doesn't exist.
 */
- (nullable ZDCNode *)findNodeWithName:(NSString *)name
                              parentID:(NSString *)parentID
                           transaction:(YapDatabaseReadTransaction *)transaction;

/**
 * Finds the node with the given path components.
 * 
 * @param path
 *   The path of the node, such as "/Documents/Inventory.numbers".
 * 
 * @param localUserID
 *   This is the associated user account identifier. (localUserID == ZDCLocalUser.uuid)
 *
 * @param treeID
 *   The treesystem identifier.
 *   All nodes are segregated by treeID.
 *
 * @param transaction
 *   A database transaction - allows the method to read from the database.
 * 
 * @return The matching ZDCNode, or nil if it doesn't exist.
 */
- (nullable ZDCNode *)findNodeWithPath:(ZDCTreesystemPath *)path
                           localUserID:(NSString *)localUserID
                                treeID:(NSString *)treeID
                           transaction:(YapDatabaseReadTransaction *)transaction
NS_SWIFT_NAME(findNode(withPath:localUserID:treeID:transaction:));

/**
 * Finds the node with the given cloudName.
 * This method is primarily for use by the PullManager.
 *
 * @note
 *   A cloudName is a hash of the cleartext name, combined with the parent diretory's salt.
 *   That is, a cloudName prevents the cleartext name from being revealed to the server.
 *   You can get the cloudName for any node via the various methods in `ZDCCloudPathManager`.
 *
 * @param cloudName
 *   The cloudName of the node to find. (e.g. "58fidhxeyyfzgp73hgefpr956jaxa6xs")
 *
 * @param parentID
 *   The parentID of the node. (parentID == ZDCNode.parentID == parentNode.uuid)
 *
 * @param transaction
 *   A database transaction - allows the method to read from the database.
 *
 * @return The matching ZDCNode, or nil if it doesn't exist.
 */
- (nullable ZDCNode *)findNodeWithCloudName:(NSString *)cloudName
                                   parentID:(NSString *)parentID
                                transaction:(YapDatabaseReadTransaction *)transaction;

/**
 * Finds the node with the given cloudID & localUserID.
 * This method is primarily for use by the PullManager.
 *
 * A SecondaryIndex in the database is utilized to make this a very fast lookup.
 *
 * @note
 *   Since nodes may be moved around (e.g. renamed or moved to different "directories"),
 *   the current location of the node in the cloud may not match the local path.
 *   However, the cloudID is immutable (set by the server, and cannot be changed),
 *   and is thus the most reliable way to lookup a matching node given the cloud version.
 *
 * @param cloudID
 *   The server-assigned identifier for the node.
 *   This value is immutable - the server doesn't allow it to be changed.
 *
 * @param localUserID
 *   This is the associated user account identifier. (localUserID == ZDCLocalUser.uuid)
 *
 * @param treeID
 *   The treesystem identifier, as registered in the [dashboard](https://dashboard.zerodark.cloud).
 *   All nodes are segregated by treeID.
 *
 * @param transaction
 *   A database transaction - allows the method to read from the database.
 *
 * @return The matching ZDCNode, or nil if it doesn't exist.
 */
- (nullable ZDCNode *)findNodeWithCloudID:(NSString *)cloudID
                              localUserID:(NSString *)localUserID
                                   treeID:(NSString *)treeID
                              transaction:(YapDatabaseReadTransaction *)transaction;

/**
 * Locates the node using only the cloud path information.
 * This method is primarily for use by the PullManager.
 *
 * @return The matching ZDCNode, or nil if it doesn't exist.
 */
- (nullable ZDCNode *)findNodeWithCloudPath:(ZDCCloudPath *)cloudPath
                                     bucket:(NSString *)bucket
                                     region:(AWSRegion)region
                                localUserID:(NSString *)localUserID
                                     treeID:(NSString *)treeID
                                transaction:(YapDatabaseReadTransaction *)transaction
NS_SWIFT_NAME(findNode(withCloudPath:bucket:region:localUserID:treeID:transaction:));

/**
 * Finds the node with a matching dirPrefix.
 *
 * A SecondaryIndex is utilized to make this a very fast lookup.
 */
- (nullable ZDCNode *)findNodeWithDirPrefix:(NSString *)prefix
                                     bucket:(NSString *)bucket
                                     region:(AWSRegion)region
                                localUserID:(NSString *)localUserID
                                     treeID:(NSString *)treeID
                                transaction:(YapDatabaseReadTransaction *)transaction;

/**
 * Finds the pointer node with the given pointeeID.
 */
- (nullable ZDCNode *)findNodeWithPointeeID:(NSString *)pointeeID
                                localUserID:(NSString *)localUserID
                                     treeID:(NSString *)treeID
                                transaction:(YapDatabaseReadTransaction *)transaction;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Lists
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Returns a list of all nodeID's belonging to the given user (regardless of treeID).
 *
 * @note This list doesn't include trunk nodes.
 */
- (NSArray<NSString *> *)allNodeIDsWithLocalUserID:(NSString *)localUserID
                                       transaction:(YapDatabaseReadTransaction *)transaction;

/**
 * Returns a list of all nodeID's belonging to the given user.
 *
 * @note This list doesn't include trunk nodes.
 */
- (NSArray<NSString *> *)allNodeIDsWithLocalUserID:(NSString *)localUserID
                                            treeID:(NSString *)treeID
                                       transaction:(YapDatabaseReadTransaction *)transaction;

/**
 * Returns all ZDCNode.uuid's where ZDCNode.cloudID is non-nil.
 * That is, the node has been uploaded at least once.
 *
 * Important: uploaded once != fully synced right at this moment.
 * Rather it means that we expect it to be on the server.
 *
 * Note: This method has been optimized for performance, and is the recommended approach.
 */
- (NSArray<NSString *> *)allUploadedNodeIDsWithLocalUserID:(NSString *)localUserID
                                                    treeID:(NSString *)treeID
                                               transaction:(YapDatabaseReadTransaction *)transaction;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Permissions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Updates the permissons for the node to match those of its parent.
 *
 * @param node
 *   The node to modify.
 *   The passed instance must not be immutable, as this method intends to modify node.shareList.
 *
 * @return YES on success. NO on failure (node is immutable, doesn't have parentID, etc)
 */
- (BOOL)resetPermissionsForNode:(ZDCNode *)node transaction:(YapDatabaseReadWriteTransaction *)transaction;

/**
 * Updates the permissions for the node to match the given shareList.
 *
 * @param node
 *   The node to modify.
 *   The passed instance must not be immutable, as this method intends to modify node.shareList.
 */
- (void)resetPermissionsForNode:(ZDCNode *)node withParentShareList:(ZDCShareList *)parentShareList;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Conflict Resolution
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * This method may be used to resolve a conflict that can occur when
 * two nodes are attempting to use the same name.
 *
 * This method appends a number to the end of the name until it's unique.
 * For example, if the given node.name is "Foobar.ext", this method may return "Foobar 2.ext".
 *
 * @param node
 *   The node that's in conflict with another node.
 *
 * @param transaction
 *   A database transaction - allows the method to read from the database.
 *
 * @return A node.name that's safe to use (i.e. without it being in conflict with another known node)
 */
- (NSString *)resolveNamingConflict:(ZDCNode *)node transaction:(YapDatabaseReadTransaction *)transaction;

@end

NS_ASSUME_NONNULL_END
