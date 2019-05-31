/**
 * ZeroDark.cloud
 * <GitHub wiki link goes here>
 **/


#import <UIKit/UIKit.h>
#import "ZDCUITools.h"

@class ZeroDarkCloud;

NS_ASSUME_NONNULL_BEGIN

@interface LocalUserSettingsViewController_IOS : UIViewController

@property (nonatomic, weak, readonly)					ZeroDarkCloud*	owner;
@property (nonatomic, weak, readonly)					NSString*	localUserID;

- (instancetype)initWithOwner:(ZeroDarkCloud*)inOwner
						localUserID:(NSString* __nonnull)inLocalUserID;


@end

NS_ASSUME_NONNULL_END
