/**
 * ZeroDark.cloud
 * 
 * Homepage      : https://www.zerodark.cloud
 * GitHub        : https://github.com/4th-ATechnologies/ZeroDark.cloud
 * Documentation : https://zerodarkcloud.readthedocs.io/en/latest/
 * API Reference : https://apis.zerodark.cloud
**/

#import "ZeroDarkCloud.h"
#import "ZDCLocalUserAuth.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * If an error occurs (i.e. an error is returned via completionBlock),
 * and the NSError.domain is AWSCredentialsManager,
 * then the NSError.code will be set to one of the following values.
 */
typedef NS_ENUM(NSInteger, AWSCredentialsErrorCode) {
	AWSCredentialsErrorCode_MissingInvalidUser,
	AWSCredentialsErrorCode_NoRefreshTokens,
	AWSCredentialsErrorCode_InvalidIDToken,
	AWSCredentialsErrorCode_InvalidServerResponse
};

/**
 * Most of the ZeroDark REST API's require valid AWS credentials.
 *
 * These are provided via a standard delegation system.
 * A refreshToken is used to request temporary AWS credentials.
 * As long as the refreshToken hasn't been revoked, the server will return AWS credentials.
 * The temporary credentials are only valid for a short period of time (a few hours).
 *
 * This manager is responsible for caching these temporary credentials,
 * and automatically refreshing them on demand.
 */
@interface AWSCredentialsManager : NSObject

/**
 * Standard initialization from ZeroDarkCloud, called during database unlock.
 */
- (instancetype)initWithOwner:(ZeroDarkCloud *)owner;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark User API
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Fetches the AWS credentials for the given ZDCLocalUser.uuid.
 *
 * If cached credentials are available (and not expired), they'll be used.
 * Otherwise the manager will attempt to refresh the AWS credentials using the user's refreshToken.
 */
- (void)getAWSCredentialsForUser:(NSString *)userID
                 completionQueue:(nullable dispatch_queue_t)completionQueue
                 completionBlock:(void (^)(ZDCLocalUserAuth *_Nullable auth, NSError *_Nullable error))completionBlock;

/**
 * Deletes the user's AWS credentials, by deleting the corresponding properties in ZDCLocalUserAuth.
 *
 * If the `deleteRefreshToken` parameter is TRUE, then:
 * - ZDCLocalUserAuth.auth0_refreshToken will be deleted
 * - ZDCLocalUser.accountNeedsA0Token will be set to TRUE
 *
 * Use this as a way to force-logout the user, without actually deleting the localUser account.
 * This might be done, for example, if the user's account is blocked due to non-payment.
 */
- (void)flushAWSCredentialsForUser:(NSString *)userID
                deleteRefreshToken:(BOOL)deleteRefreshToken
                   completionQueue:(nullable dispatch_queue_t)completionQueue
                   completionBlock:(dispatch_block_t)completionBlock;

/**
 * After the user logs back into the system, this can be used to reset & restart the authentication flow.
 */
- (void)resetAWSCredentialsForUser:(NSString *)userID
                  withRefreshToken:(NSString *)refreshToken
                   completionQueue:(nullable dispatch_queue_t)completionQueue
                   completionBlock:(void (^)(ZDCLocalUserAuth *_Nullable auth, NSError *_Nullable error))completionBlock;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Low-Level API
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Low-level API.
 *
 * Fetches the AWS credentials using the non-expired idToken (JWT).
 */
- (void)fetchAWSCredentialsWithIDToken:(NSString *)idToken
                                 stage:(NSString *)stage
                       completionQueue:(nullable dispatch_queue_t)completionQueue
                       completionBlock:(void (^)(NSDictionary *_Nullable delegation, NSError *_Nullable error))completionBlock;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Utilities
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Utility method for parsing the delegation dictionary returned from the server.
 */
- (BOOL)parseLocalUserAuth:(ZDCLocalUserAuth *_Nullable *_Nonnull)localUserAuth
            fromDelegation:(NSDictionary *)delegationToken
              refreshToken:(NSString *)refreshToken
                   idToken:(NSString *)idToken;

@end

NS_ASSUME_NONNULL_END
