/**
 * ZeroDark.cloud
 * <GitHub wiki link goes here>
**/

#import "NSError+S4.h"


@implementation NSError (S4)

NSString *const S4FrameworkErrorDomain   =   @"S4FrameworkErrorDomain";

+ (NSError *)errorWithS4Error:(S4Err)err
{
	char errorBuf[256];
//	S4_GetErrorString(err, sizeof(errorBuf), errorBuf);
	S4_GetErrorString(err, errorBuf);
	
	NSString *errStr = [NSString stringWithUTF8String:errorBuf];
	
	NSDictionary *userInfo = nil;
	if (errStr) {
		userInfo = @{ NSLocalizedDescriptionKey: errStr };
	}
	
	return [NSError errorWithDomain:S4FrameworkErrorDomain code:err userInfo:userInfo];
}

@end
