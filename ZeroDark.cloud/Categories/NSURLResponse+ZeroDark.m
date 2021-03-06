/**
 * ZeroDark.cloud
 * 
 * Homepage      : https://www.zerodark.cloud
 * GitHub        : https://github.com/4th-ATechnologies/ZeroDark.cloud
 * Documentation : https://zerodarkcloud.readthedocs.io/en/latest/
 * API Reference : https://apis.zerodark.cloud
**/

#import "NSURLResponse+ZeroDark.h"
#import "AWSDate.h"


@implementation NSURLResponse (ZeroDark)

- (NSInteger)httpStatusCode
{
	NSInteger statusCode = 0;
	
	if ([self isKindOfClass:[NSHTTPURLResponse class]])
	{
		NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse *)self;
		statusCode = httpResponse.statusCode;
	}
	
	return statusCode;
}

- (NSString *)eTag
{
	NSString *eTag = nil;

	if ([self isKindOfClass:[NSHTTPURLResponse class]])
	{
		NSDictionary *headers = [(NSHTTPURLResponse *)self allHeaderFields];

		eTag = headers[@"ETag"];
		if (eTag)
		{
			NSCharacterSet *quotes = [NSCharacterSet characterSetWithCharactersInString:@"\""];
			eTag = [eTag stringByTrimmingCharactersInSet:quotes];
		}
	}

	return eTag;
}

- (NSDate *)lastModified
{
	NSString *lastModifiedStr = nil;
	
	if ([self isKindOfClass:[NSHTTPURLResponse class]])
	{
		NSDictionary *headers = [(NSHTTPURLResponse *)self allHeaderFields];
		
		lastModifiedStr = headers[@"Last-Modified"];
	}
	
	if (lastModifiedStr)
		return [AWSDate parseTimestamp:lastModifiedStr];
	else
		return nil;
}

@end
