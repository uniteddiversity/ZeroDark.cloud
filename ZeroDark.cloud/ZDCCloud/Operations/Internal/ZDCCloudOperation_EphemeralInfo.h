/**
 * ZeroDark.cloud
 * 
 * Homepage      : https://www.zerodark.cloud
 * GitHub        : https://github.com/4th-ATechnologies/ZeroDark.cloud
 * Documentation : https://zerodarkcloud.readthedocs.io/en/latest/
 * API Reference : https://apis.zerodark.cloud
**/

#import <Foundation/Foundation.h>

#import "ZDCCloudOperation_AsyncData.h"

@class ZDCData;
@class ZDCPollContext;
@class ZDCMultipollContext;
@class ZDCTouchContext;

NS_ASSUME_NONNULL_BEGIN

/**
 * Encapsulates ephemeral information about the operation that isn't stored to disk.
 *
 * This includes information used by the PushManager while the application is running.
 * It is for use solely by the ZeroDarkCloud framework.
 */
@interface ZDCCloudOperation_EphemeralInfo : NSObject

/**
 * Stored temporarily, while preparing the operation for upload.
 * This occurs when the delegate gives us ZDCData that we need to pre-process before we can use.
 */
@property (atomic, strong, readwrite, nullable) ZDCCloudOperation_AsyncData *asyncData;

/**
 * Stored temporarily, while preparing the operation for upload.
 * This occurs when the delegate gives us ZDCData that we need to pre-process before we can use.
 * Meaning the ZDCTaskContext gets destroyed, and recreated again later.
 */
@property (atomic, copy, readwrite, nullable) NSSet<NSUUID*> *duplicateOpUUIDs;

@property (atomic, strong, readwrite, nullable) ZDCData *multipartData;

@property (atomic, strong, readwrite, nullable) ZDCPollContext *pollContext;
@property (atomic, strong, readwrite, nullable) ZDCMultipollContext *multipollContext;
@property (atomic, strong, readwrite, nullable) ZDCTouchContext *touchContext;

@property (atomic, assign, readwrite) BOOL abortRequested;
@property (atomic, assign, readwrite) BOOL resolveByPulling;

@property (atomic, copy, readwrite, nullable) NSString *lastChangeToken;
@property (atomic, copy, readwrite, nullable) NSUUID *postResolveUUID;

@property (atomic, copy, readwrite, nullable) NSString *continuation_rcrd;
@property (atomic, copy, readwrite, nullable) NSString *continuation_data;

// Why is the infinite-loop-protection stuff separated ?
//
// Because a common infinite loop is:
// - the S4 server (our serverless code) rejects a request (for whatever reason)
// - the client doesn't properly respond to rejection reason
// - the client performs upload again
//
// If we were to clear a general purpose fail count when S3 succeeds, then we're missing the bigger picture.
// That is, we're missing the larger infinite loop in the system.
//
// I.E.
// - S3      : success
// - Polling : success
// - S4      : fail
// - S3      : success
// - Polling : success
// - S4      : fail
// - S3      : success
// - Polling : success
// - S4      : fail
// ...inifinite loop in system, but only detectable in S4 component...

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Operation monitoring - S3
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSUInteger)s3_didFailWithStatusCode:(NSNumber *)statusCode;
- (void)s3_didSucceed;

@property (atomic, readonly) NSUInteger s3_successiveFailCount;
@property (atomic, readonly, nullable) NSNumber *s3_successiveFail_statusCode;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Operation monitoring - Polling
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSUInteger)polling_didFail;
- (void)polling_didSucceed;

@property (atomic, readonly) NSUInteger polling_successiveFailCount;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Operation monitoring - S4
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSUInteger)s4_didFailWithExtStatusCode:(NSNumber *)statusCode;
- (void)s4_didSucceed;

@property (atomic, readonly) NSUInteger s4_successiveFailCount;
@property (atomic, readonly, nullable) NSNumber *s4_successiveFail_extStatusCode;

@end

NS_ASSUME_NONNULL_END
