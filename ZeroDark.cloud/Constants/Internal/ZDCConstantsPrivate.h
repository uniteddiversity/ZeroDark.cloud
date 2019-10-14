/**
 * ZeroDark.cloud
 * 
 * Homepage      : https://www.zerodark.cloud
 * GitHub        : https://github.com/4th-ATechnologies/ZeroDark.cloud
 * Documentation : https://zerodarkcloud.readthedocs.io/en/latest/
 * API Reference : https://apis.zerodark.cloud
**/

#import <Foundation/Foundation.h>
#import "ZDCConstants.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kZDCDirPrefix_Fake; // Used for "static" nodes with a fixed set of children

extern NSString *const kZDCContext_Conflict;

extern NSString *const ZDCSkippedOperationsNotification;
extern NSString *const ZDCSkippedOperationsNotification_UserInfo_Ops;

// Names of special files found at resourcesURL

extern NSString *const kSupportedConfigurations;

// KEYS USED IN fetchConfigWithCompletionQueue

extern NSString *const kSupportedConfigurations_Key_AWSRegions;
extern NSString *const kSupportedConfigurations_Key_AWSRegions_ComingSoon;
extern NSString *const kSupportedConfigurations_Key_Providers;
extern NSString *const kSupportedConfigurations_Key_AppleIAP;

// Auth0 Error codes

extern NSString *const kAuth0Error_RateLimit;
extern NSString *const kAuth0Error_Unauthorized;
extern NSString *const kAuth0Error_InvalidRefreshToken;
extern NSString *const kAuth0Error_InvalidGrant;
extern NSString *const kAuth0Error_UserExists;
extern NSString *const kAuth0Error_UserNameExists;

extern NSString *const kAuth0ErrorDescription_Blocked; // extra qualifier for unauthorized


@interface ZDCConstants: NSObject

+ (BOOL)isIPhone;      // if (ZDCConstants.isIPhone) ...
+ (BOOL)isIPad;        // if (ZDCConstants.isIPad) ...
+ (BOOL)isOSX;         // if (ZDCConstants.isOSX) ...
+ (BOOL)isSimulator;   // if (ZDCConstants.isSimulator) ...

+ (BOOL)appHasPhotosPermission;
+ (BOOL)appHasCameraPermission;

// Important URLS
+ (NSURL *)ZDCsplitKeyBlogPostURL;
+ (NSURL *)ZDCaccessKeyBlogPostURL;

@end

NS_ASSUME_NONNULL_END