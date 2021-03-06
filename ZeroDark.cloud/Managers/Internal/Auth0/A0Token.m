/**
 * ZeroDark.cloud
 *
 * Homepage      : https://www.zerodark.cloud
 * GitHub        : https://github.com/4th-ATechnologies/ZeroDark.cloud
 * Documentation : https://zerodarkcloud.readthedocs.io/en/latest/
 * API Reference : https://apis.zerodark.cloud
**/

#import "A0Token.h"

@implementation A0Token

- (instancetype)initWithAccessToken:(NSString *)accessToken
							idToken:(NSString *)idToken
						  tokenType:(NSString *)tokenType
					   refreshToken:(NSString *)refreshToken {
	self = [super init];
	if (self) {
		NSAssert(tokenType.length > 0, @"Must have a valid token type");
		_accessToken = [accessToken copy];
		_idToken = [idToken copy];
		_tokenType = [tokenType copy];
		_refreshToken = [refreshToken copy];
	}
	return self;
}

+(A0Token*) tokenFromAccessToken:(NSString *)access_token
				   refreshToken:(NSString *)refresh_token
{
	A0Token* token = nil;

	if(refresh_token  || access_token)
	{
		token = [[A0Token alloc] initWithAccessToken:access_token
											 idToken:nil
										   tokenType:@"Bearer"
										refreshToken:refresh_token];
	}


	return token;
}


+(A0Token* __nullable) tokenFromDictionary:(NSDictionary*) dict
{
	NSString* access_token    = dict[@"access_token"];
	NSString*  id_token       = dict [@"id_token"];
	NSString*  refresh_token  = dict [@"refresh_token"];
	NSString*  token_type     = dict [@"token_type"];

	A0Token* token = nil;

	if(token_type && (id_token || access_token))
	{
		token = [[A0Token alloc] initWithAccessToken:access_token
											 idToken:id_token
										   tokenType:token_type
										refreshToken:refresh_token];
	}
	return token;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	return [self initWithAccessToken:[aDecoder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(accessToken))]
							 idToken:[aDecoder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(idToken))]
						   tokenType:[aDecoder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(tokenType))]
						refreshToken:[aDecoder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(refreshToken))]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	if (self.accessToken) {
		[aCoder encodeObject:self.accessToken forKey:NSStringFromSelector(@selector(accessToken))];
	}
	if (self.refreshToken) {
		[aCoder encodeObject:self.refreshToken forKey:NSStringFromSelector(@selector(refreshToken))];
	}
	[aCoder encodeObject:self.idToken forKey:NSStringFromSelector(@selector(idToken))];
	[aCoder encodeObject:self.tokenType forKey:NSStringFromSelector(@selector(tokenType))];
}

+ (BOOL)supportsSecureCoding {
	return YES;
}

-(NSString *) description
{
	NSString *description = [NSString stringWithFormat:@"<%@: %#x (\naccessToken: %@ \nidToken: %@ \ntokenType: %@ \nrefreshToken: %@\n)>",
							 NSStringFromClass([self class]), (unsigned int) self,
							 _accessToken,_idToken,_tokenType,_refreshToken
							 ];
	return description;
}

@end
