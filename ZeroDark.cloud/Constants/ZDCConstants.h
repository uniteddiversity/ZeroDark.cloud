/**
 * ZeroDark.cloud
 * 
 * Homepage      : https://www.zerodark.cloud
 * GitHub        : https://github.com/4th-ATechnologies/ZeroDark.cloud
 * Documentation : https://zerodarkcloud.readthedocs.io/en/latest/
 * API Reference : https://apis.zerodark.cloud
**/

#import <Foundation/Foundation.h>

/**
 * The block size used for encryption/decryption.
 * The TBC tweak is manually changed every so many bytes.
 */
#define kZDCNode_TweakBlockSizeInBytes 1024

/**
 * The "dirSalt" is used when hashing file names.
 * This prevents leaking file names. (i.e. well known filename, with known hash)
 */
#define kZDCNode_DirSaltKeySizeInBytes (160 / 8) // bits / 8 = bytes

/**
 * Size of S4Node.encryptionKey
 */
#define kZDCNode_EncryptionKeySizeInBytes (512 / 8) // bits / 8 = bytes

/**
 * Magic bytes (file data prefix)
 */
#define kZDCFileCloudContextMagic 0x286F202928206F29

/**
 * The primary AWS region, used for:
 * - account activation
 * - account configuration
 * - billing
 * - payment
 * - and other activities that are restricted to a single region
 */
#define AWSRegion_Master AWSRegion_US_West_2

NS_ASSUME_NONNULL_BEGIN

//
// YapDatabase collection constants
//

/** Name of collection in YapDatabase. All ZeroDark collection constants start with "ZDC" */
extern NSString *const kZDCCollection_CachedResponse;
/** Name of collection in YapDatabase. All ZeroDark collection constants start with "ZDC" */
extern NSString *const kZDCCollection_CloudNodes;
/** Name of collection in YapDatabase. All ZeroDark collection constants start with "ZDC" */
extern NSString *const kZDCCollection_Nodes;
/** Name of collection in YapDatabase. All ZeroDark collection constants start with "ZDC" */
extern NSString *const kZDCCollection_Prefs;
/** Name of collection in YapDatabase. All ZeroDark collection constants start with "ZDC" */
extern NSString *const kZDCCollection_PublicKeys;
/** Name of collection in YapDatabase. All ZeroDark collection constants start with "ZDC" */
extern NSString *const kZDCCollection_PullState;
/** Name of collection in YapDatabase. All ZeroDark collection constants start with "ZDC" */
extern NSString *const kZDCCollection_Reminders;
/** Name of collection in YapDatabase. All ZeroDark collection constants start with "ZDC" */
extern NSString *const kZDCCollection_SessionStorage;
/** Name of collection in YapDatabase. All ZeroDark collection constants start with "ZDC" */
extern NSString *const kZDCCollection_SymmetricKeys;
/** Name of collection in YapDatabase. All ZeroDark collection constants start with "ZDC" */
extern NSString *const kZDCCollection_Tasks;
/** Name of collection in YapDatabase. All ZeroDark collection constants start with "ZDC" */
extern NSString *const kZDCCollection_Users;
/** Name of collection in YapDatabase. All ZeroDark collection constants start with "ZDC" */
extern NSString *const kZDCCollection_UserAuth;
/** Name of collection in YapDatabase. All ZeroDark collection constants start with "ZDC" */
extern NSString *const kZDCCollection_SplitKeys;
/** Name of collection in YapDatabase. All ZeroDark collection constants start with "ZDC" */
extern NSString *const kZDCCollection_SplitKeyShares;

//
// Cloud Filenames
//

/**
 * Every account has a ".pubKey" file.
 * This file is accessible to the world, and is stored using a JSON format.
 * The file contains the public key information for the user.
 */
extern NSString *const kZDCCloudFileName_PublicKey;

/**
 * Every account has a ".privKey" file.
 * This file is only readable by the user who owns it.
 * The file contains a PBKDF2 encrypted version of the private key.
 * It can only be read if you have the access key (which only the user has access to).
 */
extern NSString *const kZDCCloudFileName_PrivateKey; // PBKDF2 encrypted, requires access key to unlock

//
// Cloud File Extensions
//

/**
 * The RCRD file contains ONLY the treesystem metadata.
 * That is:
 * - the (encrypted) filename
 * - the list of permissions
 * - the (encrypted) file encryption key
 * - other bookkeeping information used by the sync system such as the server-assigned cloudID
 */
extern NSString *const kZDCCloudFileExtension_Rcrd;

/**
 * The DATA file contains the (encrypted) content of the node.
 * The DATA file is always in ZDCCryptoFileFormat_CloudFile.
 *
 * A DATA file requires a corresponding RCRD file to accompany it on the server.
 * The DATA file can only be decrypted using the corresponding file encryption key.
 */
extern NSString *const kZDCCloudFileExtension_Data;

//
// Names of special files, paths
//

/**
 * A "DirPrefix" is a part of the encrypted cloudName of a file.
 * It corresponds with the parent node.
 * Treesystem trunks have a hard-coded dirPrefix, and regular nodes have a randomly generated dirPrefix.
 *
 * For more information about how ZeroDark.cloud encrypts node-names to maintain zero-knowledge in the cloud,
 * see the [docs](https://zerodarkcloud.readthedocs.io/en/latest/overview/encryption/)
 */
extern NSString *const kZDCDirPrefix_Home;

/**
 * A "DirPrefix" is a part of the encrypted cloudName of a file.
 * It corresponds with the parent node.
 * Treesystem trunks have a hard-coded dirPrefix, and regular nodes have a randomly generated dirPrefix.
 *
 * For more information about how ZeroDark.cloud encrypts node-names to maintain zero-knowledge in the cloud,
 * see the [docs](https://zerodarkcloud.readthedocs.io/en/latest/overview/encryption/)
 */
extern NSString *const kZDCDirPrefix_Prefs;

/**
 * A "DirPrefix" is a part of the encrypted cloudName of a file.
 * It corresponds with the parent node.
 * Treesystem trunks have a hard-coded dirPrefix, and regular nodes have a randomly generated dirPrefix.
 *
 * For more information about how ZeroDark.cloud encrypts node-names to maintain zero-knowledge in the cloud,
 * see the [docs](https://zerodarkcloud.readthedocs.io/en/latest/overview/encryption/)
 */
extern NSString *const kZDCDirPrefix_MsgsIn;

/**
 * A "DirPrefix" is a part of the encrypted cloudName of a file.
 * It corresponds with the parent node.
 * Treesystem trunks have a hard-coded dirPrefix, and regular nodes have a randomly generated dirPrefix.
 *
 * For more information about how ZeroDark.cloud encrypts node-names to maintain zero-knowledge in the cloud,
 * see the [docs](https://zerodarkcloud.readthedocs.io/en/latest/overview/encryption/)
 */
extern NSString *const kZDCDirPrefix_MsgsOut;

/**
 * A "DirPrefix" is a part of the encrypted cloudName of a file.
 * It corresponds with the parent node.
 * Treesystem trunks have a hard-coded dirPrefix, and regular nodes have a randomly generated dirPrefix.
 *
 * For more information about how ZeroDark.cloud encrypts node-names to maintain zero-knowledge in the cloud,
 * see the [docs](https://zerodarkcloud.readthedocs.io/en/latest/overview/encryption/)
 */
extern NSString *const kZDCDirPrefix_Avatar;

/**
 * A "DirPrefix" is a part of the encrypted cloudName of a file. (Deprecated)
 *
 * @see kZDCDirPrefix_MsgsIn
 * @see kZDCDirPrefix_MsgsOut
 */
extern NSString *const kZDCDirPrefix_Deprecated_Msgs;

/**
 * A "DirPrefix" is a part of the encrypted cloudName of a file. (Deprecated)
 *
 * @see kZDCDirPrefix_MsgsIn
 * @see kZDCDirPrefix_MsgsOut
 */
extern NSString *const kZDCDirPrefix_Deprecated_Inbox;

/**
 * A "DirPrefix" is a part of the encrypted cloudName of a file. (Deprecated)
 *
 * @see kZDCDirPrefix_MsgsIn
 * @see kZDCDirPrefix_MsgsOut
 */
extern NSString *const kZDCDirPrefix_Deprecated_Outbox;

NS_ASSUME_NONNULL_END
