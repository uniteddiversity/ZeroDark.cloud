/**
 * ZeroDark.cloud
 * <GitHub wiki link goes here>
**/

#import "ZDCNode.h"
#import "ZDCTreesystemPath.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * The ZeroDark.cloud framework provides a tree-based "filesystem" in the cloud.
 *
 * It's important to understand: Treesystem != Filesystem
 *
 * A traditional filesystem has directories & files.
 * This design forces all content to reside in the leaves.
 * That is, if you think about a traditional filesystem as a tree,
 * you can see that all files are leaves, and all non-leaves are directories.
 *
 * In contrast, the ZeroDark.cloud treesystem acts as a generic tree,
 * where each item in the tree is simply called a "node".
 * A node can be whatever you want it to be - an object, a file, a container, etc.
 * Additionally, ALL nodes are allowed to have children.
 * (e.g. a node representing an object/file can have children).
 *
 * For more information about the treesystem, see the docs:
 * https://zerodarkcloud.readthedocs.io/en/latest/advanced/tree/
 *
 * Every user gets their own treesystem. And similar to an Operating System,
 * the treesystem comes with a home "directory", and some other special "directories".
 *
 * The ZDCContainerNode represents these top-level "directories", which are commonly referred to as containers:
 * - home
 * - msgs
 * - prefs
 * - outbox
 * - inbox
 *
 * ZDCContainerNode instances are automatically added to the database when a localUser is created.
 */
@interface ZDCContainerNode : ZDCNode <NSCoding, NSCopying>

/**
 * ZDCContainerNode's act as root nodes in the tree hierarchy,
 * and thus they use a deterministic key.
 *
 * This method returns the database key that can be used to fetch the containerNode instance from the database.
 * (Use kZDCCollection_Nodes as the database collection.)
 *
 * @note Normal ZDCNode instances have a random uuid.
 *       That is, the uuid is specific to the local device, and cannot be derived from the cloud version of the node.
 *       ZDCContainerNode's are a little different, as they represent the "virtual" nodes in the server.
 *       That is, hard-coded "root" nodes that doesn't actually exist on the server.
 */
+ (NSString *)uuidForLocalUserID:(NSString *)localUserID
                          zAppID:(NSString *)zAppID
                       container:(ZDCTreesystemContainer)container;

/**
 * The zApp "container".
 */
@property (nonatomic, copy, readonly) NSString *zAppID;

/**
 * The top-level container. E.g. "home", "msgs", "prefs", "inbox", "outbox"
 */
@property (nonatomic, assign, readonly) ZDCTreesystemContainer container;

@end

NS_ASSUME_NONNULL_END
