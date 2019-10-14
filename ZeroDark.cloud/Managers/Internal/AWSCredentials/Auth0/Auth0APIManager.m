/**
 * ZeroDark.cloud
 * 
 * Homepage      : https://www.zerodark.cloud
 * GitHub        : https://github.com/4th-ATechnologies/ZeroDark.cloud
 * Documentation : https://zerodarkcloud.readthedocs.io/en/latest/
 * API Reference : https://apis.zerodark.cloud
**/

#import "Auth0APIManager.h"

#import "ZDCConstants.h"
#import "ZDCAsyncCompletionDispatch.h"

// Categories
#import "NSError+Auth0API.h"
#import "NSURLResponse+ZeroDark.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h> // For [[UIDevice currentDevice] name]
#endif

// Auth0 parameters
NSString * const A0ParameterClientID     = @"client_id";
NSString * const A0ParameterEmail        = @"email";
NSString * const A0ParameterUsername     = @"username";
NSString * const A0ParameterPassword     = @"password";
NSString * const A0ParameterScope        = @"scope";
NSString * const A0ParameterDevice       = @"device";
NSString * const A0ParameterGrantType    = @"grant_type";
NSString * const A0ParameterAPIType      = @"api_type";
NSString * const A0ParameterRefreshToken = @"refresh_token";
NSString * const A0ParameterIdToken      = @"id_token";
NSString * const A0ParameterRealm        = @"realm";
NSString * const A0ParameterState        = @"state";
NSString * const A0ParameterRedirectURI  = @"redirect_uri";
NSString * const A0ParameterResponseType = @"response_type";
NSString * const A0ParameterConnection   = @"connection";

#define TRACK_DEVICE 1


@implementation Auth0LoginResult

@synthesize refreshToken = _refreshToken;
@synthesize idToken = _idToken;

- (instancetype)initWithRefreshToken:(NSString *)refreshToken idToken:(NSString *)idToken
{
	NSParameterAssert(refreshToken != nil);
	NSParameterAssert(idToken != nil);
	
	if ((self = [super init]))
	{
		_refreshToken = [refreshToken copy];
		_idToken = [idToken copy];
	}
	return self;
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation Auth0LoginProfileResult

@synthesize profile = _profile;

- (instancetype)initWithRefreshToken:(NSString *)refreshToken
                             idToken:(NSString *)idToken
                             profile:(A0UserProfile *)profile
{
	NSParameterAssert(refreshToken != nil);
	NSParameterAssert(idToken != nil);
	
	if ((self = [super initWithRefreshToken:refreshToken idToken:idToken]))
	{
		_profile = profile;
	}
	return self;
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation Auth0APIManager {
	
	ZDCAsyncCompletionDispatch *pendingRequests;
}

static Auth0APIManager *sharedInstance = nil;

+ (void)initialize
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{

		sharedInstance = [[Auth0APIManager alloc] init];
	});
}

+ (Auth0APIManager *)sharedInstance
{
	return sharedInstance;
}

- (Auth0APIManager *)init
{
	NSAssert(sharedInstance == nil, @"You MUST use the sharedInstance - class is a singleton");

	if ((self = [super init]))
	{
		pendingRequests = [[ZDCAsyncCompletionDispatch alloc] init];
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Errors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSError *)errorWithDescription:(NSString *)description
{
	NSDictionary *userInfo = nil;
	if (description)
		userInfo = @{ NSLocalizedDescriptionKey: description };

	NSString *domain = NSStringFromClass([self class]);
	return [NSError errorWithDomain:domain code:0 userInfo:userInfo];
}

- (NSError *)errorWithDescription:(NSString *)description a0Code:(NSString*)a0Code
{
	NSMutableDictionary *userInfo = nil;

	if (description || a0Code)
	{
		userInfo = NSMutableDictionary.dictionary;

		if(description)
			[userInfo setObject:description forKey:NSLocalizedDescriptionKey];

		if(a0Code)
			[userInfo setObject:a0Code forKey:Auth0APIManagerErrorDataKey];

 	}

	NSString *domain = NSStringFromClass([self class]);
	return [NSError errorWithDomain:domain code:0 userInfo:userInfo];
}

- (NSError *)errorWithStatusCode:(NSInteger)statusCode responseData:(id)responseData
{
	NSDictionary *details = nil;
	NSString *responseString = nil;

	if ([responseData isKindOfClass:[NSData class]])
	{
		responseString = [[NSString alloc] initWithData:(NSData *)responseData encoding:NSUTF8StringEncoding];
	}

	if (responseString || responseData)
	{
		details = @{ NSUnderlyingErrorKey: (responseString ?: responseData) };
	}

	NSString *domain = NSStringFromClass([self class]);
	return [NSError errorWithDomain:domain code:statusCode userInfo:details];
}

- (NSError *)errorWithStatusCode:(NSInteger)statusCode description:(NSString *)description
{
	NSDictionary *details = nil;

	if (description)
	{
		details = @{ NSUnderlyingErrorKey: description };
	}

	NSString *domain = NSStringFromClass([self class]);
	return [NSError errorWithDomain:domain code:statusCode userInfo:details];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Utilities
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSString *)deviceName
{
#if TARGET_OS_IPHONE
	return [[UIDevice currentDevice] name];
#else
	return [[NSHost currentHost] localizedName];
#endif
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Login & Profile
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)loginAndGetProfileWithUsername:(NSString *)username
                              password:(NSString *)password
                       auth0Connection:(NSString *)auth0Connection
                       completionQueue:(nullable dispatch_queue_t)inCompletionQueue
                       completionBlock:(void (^)(Auth0LoginProfileResult *_Nullable result,
                                                 NSError *_Nullable error))completionBlock
{
#ifndef NS_BLOCK_ASSERTIONS
	NSParameterAssert(username != nil);
	NSParameterAssert(password != nil);
	NSParameterAssert(auth0Connection != nil);
	NSParameterAssert(completionBlock != nil);
#else
	if (completionBlock == nil) return;
#endif
	
	dispatch_queue_t completionQueue = inCompletionQueue ?: dispatch_get_main_queue();

	void (^Fail)(NSError*) = ^(NSError *error){
		
		NSParameterAssert(error != nil);
		
		dispatch_async(completionQueue, ^{ @autoreleasepool {
			completionBlock(nil, error);
		}});
	};
	
	void (^Succeed)(Auth0LoginProfileResult*) = ^(Auth0LoginProfileResult *result){
		
		NSParameterAssert(result != nil);
		NSParameterAssert(result.refreshToken != nil);
		NSParameterAssert(result.idToken != nil);
		NSParameterAssert(result.profile != nil);
		
		dispatch_async(completionQueue, ^{ @autoreleasepool {
			completionBlock(result, nil);
		}});
	};
	
	dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

	[self loginWithUsername: username
	               password: password
	        auth0Connection: auth0Connection
	        completionQueue: backgroundQueue
	        completionBlock:^(Auth0LoginResult *loginResult, NSError *error)
	{
		if (error)
		{
			Fail(error);
			return;
		}

		[self getAccessTokenWithRefreshToken: loginResult.refreshToken
		                     completionQueue: backgroundQueue
		                     completionBlock:^(NSString *accessToken, NSError *error)
		{
			if (error)
			{
				Fail(error);
				return;
			}
			
			[self getUserProfileWithAccessToken: accessToken
			                    completionQueue: backgroundQueue
			                    completionBlock:^(A0UserProfile *profile, NSError *error)
			{
				if (error)
				{
					Fail(error);
					return;
				}
				
				Auth0LoginProfileResult *profileResult =
				  [[Auth0LoginProfileResult alloc] initWithRefreshToken: loginResult.refreshToken
				                                                idToken: loginResult.idToken
				                                                profile: profile];
				
				Succeed(profileResult);
			}];
		}];
	}];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Login
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)loginWithUsername:(NSString *)username
                 password:(NSString *)password
          auth0Connection:(NSString *)auth0Connection
          completionQueue:(nullable dispatch_queue_t)inCompletionQueue
          completionBlock:(void (^)(Auth0LoginResult *result, NSError *error))completionBlock
{
#ifndef NS_BLOCK_ASSERTIONS
	NSParameterAssert(username != nil);
	NSParameterAssert(password != nil);
	NSParameterAssert(auth0Connection != nil);
	NSParameterAssert(completionBlock != nil);
#else
	if (completionBlock == nil) return;
#endif
	
	dispatch_queue_t completionQueue = inCompletionQueue ?: dispatch_get_main_queue();

	void (^Fail)(NSError*) = ^(NSError *error){
		
		NSParameterAssert(error != nil);
		
		dispatch_async(completionQueue, ^{ @autoreleasepool {
			completionBlock(nil, error);
		}});
	};
	
	void (^Succeed)(Auth0LoginResult*) = ^(Auth0LoginResult *result){
		
		NSParameterAssert(result != nil);
		NSParameterAssert(result.refreshToken != nil);
		NSParameterAssert(result.idToken != nil);
		
		dispatch_async(completionQueue, ^{ @autoreleasepool {
			completionBlock(result, nil);
		}});
	};

	NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
	NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];

	NSURLComponents *urlComponents = [[NSURLComponents alloc] init];
	urlComponents.scheme = @"https";
	urlComponents.host = kAuth04thADomain;
	urlComponents.path = @"/oauth/token";

	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithCapacity:8];
	jsonDict[A0ParameterClientID]  = kAuth04thA_AppClientID;
	jsonDict[A0ParameterUsername]  = username;
	jsonDict[A0ParameterPassword]  = password;
	jsonDict[A0ParameterGrantType] = @"http://auth0.com/oauth/grant-type/password-realm";
	jsonDict[A0ParameterRealm]     = auth0Connection;
	jsonDict[A0ParameterScope]     = @"openid offline_access"; // see discussion below
#if TRACK_DEVICE
	jsonDict[A0ParameterDevice]    = [self deviceName];
#endif

	// DISCUSSION:
	//
	// There are 3 different tokens we need from Auth0:
	//
	// - refresh_token
	//
	//   This is the token that doesn't expire.
	//   It can be used to fetch fresh versions of the access_token and the id_token.
	//   In other words, the other tokens expire.
	//   And this token can be used to refresh them.
	//
	// - id_token
	//
	//   This is a JWT - a signed document with an expiration.
	//   We can exchange this for AWS credentials.
	//
	// - access_token
	//
	//   We only need the access_token for one reason:
	//   It's required in order to fetch the user's profile from auth0.
	//
	// No here's the crazy part:
	//
	// When we login here, we'll receive all 3 tokens.
	// But the access_token we get back is garbage.
	// If we try to use it to fetch the user's profile, auth0 will give us back a truncated profile.
	//
	// If we add 'profile' to the scope above, it still doesn't work.
	// The ONLY way we're able to get the user's full profile is if we:
	//
	// - use the refresh_token to obtain an access_token, and set the scope to include ONLY 'profile'
	// - then use the returned access_token to request the user's profile
	//
	// So we basically need to ignore the access_token we receive here.
	
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];

	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[urlComponents URL]];
	request.HTTPMethod = @"POST";
	request.HTTPBody = jsonData;

	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

	NSURLSessionDataTask *task =
	  [session dataTaskWithRequest: request
	             completionHandler:^(NSData *responseObject, NSURLResponse *response, NSError *error)
	{
		if (error)
		{
			Fail(error);
			return;
		}
		
		NSDictionary *jsonDict = nil;
		Auth0LoginResult *result = nil;
		
		if ([responseObject isKindOfClass:[NSData class]] && (responseObject.length > 0))
		{
			jsonDict = [NSJSONSerialization JSONObjectWithData:(NSData *)responseObject options:0 error:&error];
			
			if (![jsonDict isKindOfClass:[NSDictionary class]]) {
				jsonDict = nil;
			}
		}

		if (jsonDict)
		{
			if (jsonDict[@"error"])
			{
				NSString *description = jsonDict[@"error_description"];
				
				if ([description isKindOfClass:[NSString class]]) {
					error = [self errorWithDescription:description];
				}
			}
			else
			{
				NSString *refreshToken = jsonDict[@"refresh_token"];
				NSString *idToken      = jsonDict[@"id_token"];
				
				if ([refreshToken isKindOfClass:[NSString class]] && [idToken isKindOfClass:[NSString class]])
				{
					result = [[Auth0LoginResult alloc] initWithRefreshToken:refreshToken idToken:idToken];
				}
			}
		}

		if (result)
		{
			Succeed(result);
		}
		else if (error)
		{
			Fail(error);
		}
		else
		{
			NSInteger statusCode = response.httpStatusCode;
			error = [self errorWithStatusCode:statusCode description:@"Invalid response from server"];
			
			Fail(error);
		}
	}];

	[task resume];

}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Create User
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)createUserWithEmail:(NSString *)email
                   username:(NSString *)username
                   password:(NSString *)password
            auth0Connection:(NSString *)auth0Connection
            completionQueue:(nullable dispatch_queue_t)inCompletionQueue
            completionBlock:(void (^)(NSString *auth0ID, NSError *error))completionBlock
{
#ifndef NS_BLOCK_ASSERTIONS
	NSParameterAssert(email != nil);
	NSParameterAssert(username != nil);
	NSParameterAssert(password != nil);
	NSParameterAssert(auth0Connection != nil);
	NSParameterAssert(completionBlock != nil);
#else
	if (completionBlock == nil) return;
#endif
	
	dispatch_queue_t completionQueue = inCompletionQueue ?: dispatch_get_main_queue();

	void (^Fail)(NSError*) = ^(NSError *error){
		
		NSParameterAssert(error != nil);
		
		dispatch_async(completionQueue, ^{ @autoreleasepool {
			completionBlock(nil, error);
		}});
	};
	
	void (^Succeed)(NSString*) = ^(NSString *auth0ID){
		
		NSParameterAssert(auth0ID != nil);
		
		dispatch_async(completionQueue, ^{ @autoreleasepool {
			completionBlock(auth0ID, nil);
		}});
	};

	NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
	NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];

	NSURLComponents *urlComponents = [[NSURLComponents alloc] init];
	urlComponents.scheme = @"https";
	urlComponents.host = kAuth04thADomain;
	urlComponents.path = @"/dbconnections/signup";

	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithCapacity:8];
	jsonDict[A0ParameterClientID]   = kAuth04thA_AppClientID;
	jsonDict[A0ParameterEmail]      = email;
	jsonDict[A0ParameterUsername]   = username;
	jsonDict[A0ParameterPassword]   = password;
	jsonDict[A0ParameterGrantType]  = @"password";
	jsonDict[A0ParameterScope]      = @"openid offline_access";
#if TRACK_DEVICE
	jsonDict[A0ParameterDevice]     = [self deviceName];
#endif
	jsonDict[A0ParameterConnection] = auth0Connection;

	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];

	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[urlComponents URL]];
	request.HTTPMethod = @"POST";
	request.HTTPBody = jsonData;

	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

	NSURLSessionDataTask *task =
	  [session dataTaskWithRequest: request
	             completionHandler:^(NSData *responseObject, NSURLResponse *response, NSError *error)
	{
		if (error)
		{
			Fail(error);
			return;
		}
		  
		NSDictionary *jsonDict = nil;
		NSString *auth0ID = nil;

		if ([responseObject isKindOfClass:[NSData class]]
		 && (responseObject.length > 0))
		{
			jsonDict = [NSJSONSerialization JSONObjectWithData:(NSData *)responseObject options:0 error:&error];
			
			if (![jsonDict isKindOfClass:[NSDictionary class]]) {
				jsonDict = nil;
			}
		}

		if (jsonDict)
		{
			NSString *code = jsonDict[@"code"];
			if (code)
			{
				// {
				//   code = "user_exists";
				//   description = "The user already exists.";
				//   name = BadRequestError;
				//   statusCode = 400;
				// }

				NSString *description = jsonDict[@"description"];
				
				if ([description isKindOfClass:[NSString class]]) {
					error = [self errorWithDescription:description a0Code:code];
				}
			}
			else
			{
				NSString *rawID = jsonDict[@"_id"];
				
				if ([rawID isKindOfClass:[NSString class]]) {
					auth0ID = [NSString stringWithFormat:@"auth0|%@", rawID];
				}
			}
		}

		if (!error && !auth0ID)
		{
			NSInteger statusCode = response.httpStatusCode;
			
			error = [self errorWithStatusCode: statusCode
			                      description: @"Invalid response from server"];
		}

		if (error)
		{
			Fail(error);
		}
		else
		{
			Succeed(auth0ID);
		}
	}];

	[task resume];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Get User Profile
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)getUserProfileWithAccessToken:(NSString *)accessToken
                           requestKey:(NSString *)requestKey
{
	__weak typeof(self) weakSelf = self;
	
	void (^Fail)(NSError*) = ^(NSError *error){
		
		NSParameterAssert(error != nil);
		
		__strong typeof(self) strongSelf = weakSelf;
		if (!strongSelf) return;
		
		NSArray<dispatch_queue_t> * completionQueues = nil;
		NSArray<id>               * completionBlocks = nil;
		[strongSelf->pendingRequests popCompletionQueues: &completionQueues
		                                completionBlocks: &completionBlocks
		                                          forKey: requestKey];

		for (NSUInteger i = 0; i < completionBlocks.count; i++)
		{
			dispatch_queue_t completionQueue = completionQueues[i];
			void (^completionBlock)(A0UserProfile *a0Profile, NSError *error) = completionBlocks[i];

			dispatch_async(completionQueue, ^{ @autoreleasepool {

				completionBlock(nil, error);
			}});
		}
	};
	
	void (^Succeed)(A0UserProfile*) = ^(A0UserProfile *profile){
		
		NSParameterAssert(profile != nil);
		
		__strong typeof(self) strongSelf = weakSelf;
		if (!strongSelf) return;
		
		NSArray<dispatch_queue_t> * completionQueues = nil;
		NSArray<id>               * completionBlocks = nil;
		[strongSelf->pendingRequests popCompletionQueues: &completionQueues
		                                completionBlocks: &completionBlocks
		                                          forKey: requestKey];

		for (NSUInteger i = 0; i < completionBlocks.count; i++)
		{
			dispatch_queue_t completionQueue = completionQueues[i];
			void (^completionBlock)(A0UserProfile *a0Profile, NSError *error) = completionBlocks[i];

			dispatch_async(completionQueue, ^{ @autoreleasepool {

				completionBlock(profile, nil);
			}});
		}
	};

	NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
	NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];

	NSURLComponents *urlComponents = [[NSURLComponents alloc] init];
	urlComponents.scheme = @"https";
	urlComponents.host = kAuth04thADomain;
	urlComponents.path = @"/userinfo";
	
	NSMutableArray<NSURLQueryItem *> *queryItems = [NSMutableArray arrayWithCapacity:1];
	[queryItems addObject:[NSURLQueryItem queryItemWithName:@"access_token" value:accessToken]];

	urlComponents.queryItems = queryItems;

	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[urlComponents URL]];
	request.HTTPMethod = @"GET";

	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

	NSURLSessionDataTask *task =
	  [session dataTaskWithRequest: request
	             completionHandler:^(NSData *responseObject, NSURLResponse *response, NSError *error)
	{
		if (error)
		{
			Fail(error);
			return;
		}
		  
		NSDictionary *jsonDict = nil;
		A0UserProfile* profile = nil;
		
		if ([responseObject isKindOfClass:[NSData class]])
		{
			jsonDict = [NSJSONSerialization JSONObjectWithData:(NSData *)responseObject options:0 error:&error];
			
			if (![jsonDict isKindOfClass:[NSDictionary class]]) {
				jsonDict = nil;
			}
		}
		  
		if (jsonDict)
		{
			if (jsonDict[@"error"])
			{
				NSString *description  = jsonDict[@"error_description"];
				error = [self errorWithDescription:description];
			}
			else
			{
				profile = [[A0UserProfile alloc] initWithDictionary:jsonDict];
			}
		}
		  
		if (profile)
		{
			Succeed(profile);
		}
		else if (error)
		{
			Fail(error);
		}
		else
		{
			error = [self errorWithStatusCode: response.httpStatusCode
			                      description: @"Invalid response from server"];
			Fail(error);
		}
	}];

	[task resume];
}

- (void)getUserProfileWithAccessToken:(NSString *)accessToken
                      completionQueue:(nullable dispatch_queue_t)completionQueue
                      completionBlock:(void (^)(A0UserProfile *_Nullable a0Profile,
                                                NSError *_Nullable error))completionBlock
{
#ifndef NS_BLOCK_ASSERTIONS
	NSParameterAssert(accessToken);
	NSParameterAssert(completionBlock);
#else
	if (completionBlock == nil) return;
#endif

	NSString *requestKey = [NSString stringWithFormat:@"%@-%@", NSStringFromSelector(_cmd), accessToken];

	NSUInteger requestCount =
	  [pendingRequests pushCompletionQueue: completionQueue
	                       completionBlock: completionBlock
	                                forKey: requestKey];

	if (requestCount > 1)
	{
		// There's a previous request currently in-flight.
		// The <completionQueue, completionBlock> have been added to the existing request's list.
		return;
	}

	[self getUserProfileWithAccessToken: accessToken
	                         requestKey: requestKey];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Get Access Token
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)getAccessTokenWithRefreshToken:(NSString *)refreshToken
                            requestKey:(NSString *)requestKey
{
	__weak typeof(self) weakSelf = self;
	
	void (^Fail)(NSError*) = ^(NSError *error){
		
		NSParameterAssert(error != nil);
		
		__strong typeof(self) strongSelf = weakSelf;
		if (!strongSelf) return;
		
		NSArray<dispatch_queue_t> * completionQueues = nil;
		NSArray<id>               * completionBlocks = nil;
		[strongSelf->pendingRequests popCompletionQueues: &completionQueues
		                                completionBlocks: &completionBlocks
		                                          forKey: requestKey];

		for (NSUInteger i = 0; i < completionBlocks.count; i++)
		{
			dispatch_queue_t completionQueue = completionQueues[i];
			void (^completionBlock)(NSString *accessToken, NSError *error) = completionBlocks[i];

			dispatch_async(completionQueue, ^{ @autoreleasepool {

				completionBlock(nil, error);
			}});
		}
	};
	
	void (^Succeed)(NSString*) = ^(NSString *accessToken){
		
		NSParameterAssert(accessToken != nil);
		
		__strong typeof(self) strongSelf = weakSelf;
		if (!strongSelf) return;
		
		NSArray<dispatch_queue_t> * completionQueues = nil;
		NSArray<id>               * completionBlocks = nil;
		[strongSelf->pendingRequests popCompletionQueues: &completionQueues
		                                completionBlocks: &completionBlocks
		                                          forKey: requestKey];

		for (NSUInteger i = 0; i < completionBlocks.count; i++)
		{
			dispatch_queue_t completionQueue = completionQueues[i];
			void (^completionBlock)(NSString *accessToken, NSError *error) = completionBlocks[i];

			dispatch_async(completionQueue, ^{ @autoreleasepool {

				completionBlock(accessToken, nil);
			}});
		}
	};

	NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
	NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];

	NSURLComponents *urlComponents = [[NSURLComponents alloc] init];
	urlComponents.scheme = @"https";
	urlComponents.host = kAuth04thADomain;
	urlComponents.path = @"/oauth/token";

	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithCapacity:4];
	jsonDict[A0ParameterClientID]     = kAuth04thA_AppClientID;
	jsonDict[A0ParameterGrantType]    = @"refresh_token";
	jsonDict[A0ParameterRefreshToken] = refreshToken;
	jsonDict[A0ParameterScope]        = @"profile";

	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];

	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[urlComponents URL]];
	request.HTTPMethod = @"POST";
	request.HTTPBody = jsonData;

	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

	NSURLSessionDataTask *task =
	  [session dataTaskWithRequest: request
	             completionHandler:^(NSData *responseObject, NSURLResponse *response, NSError *error)
	{
		if (error)
		{
			Fail(error);
			return;
		}

		NSInteger statusCode = response.httpStatusCode;
		if ((statusCode != 200) &&
		    (statusCode != 401) &&
		    (statusCode != 403))
		{
			error = [self errorWithStatusCode:statusCode description:@"Bad Status response"];
			
			Fail(error);
			return;
		}
		  
		NSDictionary *jsonDict = nil;
		NSString *accessToken = nil;

		if ([responseObject isKindOfClass:[NSData class]] && (responseObject.length > 0))
		{
			jsonDict = [NSJSONSerialization JSONObjectWithData:(NSData *)responseObject options:0 error:&error];
			
			if (![jsonDict isKindOfClass:[NSDictionary class]]) {
				jsonDict = nil;
			}
		}

		if (jsonDict)
		{
			NSString *error_code = jsonDict[@"error"];
			if (error_code)
			{
				NSString *error_description = jsonDict[@"error_description"];
				
				error = [self errorWithDescription:error_description a0Code:error_code];
			}
			else
			{
				accessToken = jsonDict[@"access_token"];
				
				if (![accessToken isKindOfClass:[NSString class]]) {
					accessToken = nil;
				}
			}
		}
		  
		if (accessToken)
		{
			Succeed(accessToken);
		}
		else
		{
			Fail(error ?: [self errorWithStatusCode:500 description:@"Invalid response from server"]);
		}
	}];

	[task resume];
}

- (void)getAccessTokenWithRefreshToken:(NSString *)auth0_refreshToken
                       completionQueue:(nullable dispatch_queue_t)completionQueue
                       completionBlock:(void (^)(NSString *_Nullable auth0_accessToken,
                                                 NSError *_Nullable error))completionBlock
{
#ifndef NS_BLOCK_ASSERTIONS
	NSParameterAssert(auth0_refreshToken);
	NSParameterAssert(completionBlock);
#else
	if (completionBlock == nil) return;
#endif

	NSString *requestKey = [NSString stringWithFormat:@"%@-%@", NSStringFromSelector(_cmd), auth0_refreshToken];

	NSUInteger requestCount =
	  [pendingRequests pushCompletionQueue: completionQueue
	                       completionBlock: completionBlock
	                                forKey: requestKey];

	if (requestCount > 1)
	{
		// There's a previous request currently in-flight.
		// The <completionQueue, completionBlock> have been added to the existing request's list.
		return;
	}

	[self getAccessTokenWithRefreshToken: auth0_refreshToken
	                          requestKey: requestKey];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Get Access Token
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)getIDTokenWithRefreshToken:(NSString *)refreshToken
                        requestKey:(NSString *)requestKey
{
	__weak typeof(self) weakSelf = self;
	
	void (^Fail)(NSError*) = ^(NSError *error){
		
		NSParameterAssert(error != nil);
		
		__strong typeof(self) strongSelf = weakSelf;
		if (!strongSelf) return;
		
		NSArray<dispatch_queue_t> * completionQueues = nil;
		NSArray<id>               * completionBlocks = nil;
		[strongSelf->pendingRequests popCompletionQueues: &completionQueues
		                                completionBlocks: &completionBlocks
		                                          forKey: requestKey];

		for (NSUInteger i = 0; i < completionBlocks.count; i++)
		{
			dispatch_queue_t completionQueue = completionQueues[i];
			void (^completionBlock)(NSString *accessToken, NSError *error) = completionBlocks[i];

			dispatch_async(completionQueue, ^{ @autoreleasepool {

				completionBlock(nil, error);
			}});
		}
	};
	
	void (^Succeed)(NSString*) = ^(NSString *idToken){
		
		NSParameterAssert(idToken != nil);
		
		__strong typeof(self) strongSelf = weakSelf;
		if (!strongSelf) return;
		
		NSArray<dispatch_queue_t> * completionQueues = nil;
		NSArray<id>               * completionBlocks = nil;
		[strongSelf->pendingRequests popCompletionQueues: &completionQueues
		                                completionBlocks: &completionBlocks
		                                          forKey: requestKey];

		for (NSUInteger i = 0; i < completionBlocks.count; i++)
		{
			dispatch_queue_t completionQueue = completionQueues[i];
			void (^completionBlock)(NSString *accessToken, NSError *error) = completionBlocks[i];

			dispatch_async(completionQueue, ^{ @autoreleasepool {

				completionBlock(idToken, nil);
			}});
		}
	};
	
	NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
	NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];

	NSURLComponents *urlComponents = [[NSURLComponents alloc] init];
	urlComponents.scheme = @"https";
	urlComponents.host = kAuth04thADomain;
	urlComponents.path = @"/oauth/token";

	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithCapacity:4];
	jsonDict[A0ParameterClientID]     = kAuth04thA_AppClientID;
	jsonDict[A0ParameterGrantType]    = @"refresh_token";
	jsonDict[A0ParameterRefreshToken] = refreshToken;
	jsonDict[A0ParameterScope]        = @"openid";

	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];

	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[urlComponents URL]];
	request.HTTPMethod = @"POST";
	request.HTTPBody = jsonData;

	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	
	NSURLSessionDataTask *task =
	  [session dataTaskWithRequest: request
	             completionHandler:^(NSData *responseObject, NSURLResponse *response, NSError *error)
	{
		if (error)
		{
			Fail(error);
			return;
		}

		NSInteger statusCode = response.httpStatusCode;
		if ((statusCode != 200) &&
		    (statusCode != 401) &&
		    (statusCode != 403))
		{
			error = [self errorWithStatusCode:statusCode description:@"Bad Status response"];
			
			Fail(error);
			return;
		}
		  
		NSDictionary *jsonDict = nil;
		NSString *idToken = nil;

		if ([responseObject isKindOfClass:[NSData class]] && (responseObject.length > 0))
		{
			jsonDict = [NSJSONSerialization JSONObjectWithData:(NSData *)responseObject options:0 error:&error];
			
			if (![jsonDict isKindOfClass:[NSDictionary class]]) {
				jsonDict = nil;
			}
		}

		if (jsonDict)
		{
			NSString *error_code = jsonDict[@"error"];
			if (error_code)
			{
				NSString *error_description = jsonDict[@"error_description"];
				
				error = [self errorWithDescription:error_description a0Code:error_code];
			}
			else
			{
				idToken = jsonDict[@"id_token"];
				
				if (![idToken isKindOfClass:[NSString class]]) {
					idToken = nil;
				}
			}
		}
		  
		if (idToken)
		{
			Succeed(idToken);
		}
		else
		{
			Fail(error ?: [self errorWithStatusCode:500 description:@"Invalid response from server"]);
		}
	}];

	[task resume];
}

- (void)getIDTokenWithRefreshToken:(NSString *)auth0_refreshToken
                   completionQueue:(nullable dispatch_queue_t)completionQueue
                   completionBlock:(void (^)(NSString * _Nullable auth0_idToken,
                                             NSError *_Nullable error))completionBlock
{
	#ifndef NS_BLOCK_ASSERTIONS
	NSParameterAssert(auth0_refreshToken);
	NSParameterAssert(completionBlock);
#else
	if (completionBlock == nil) return;
#endif

	NSString *requestKey = [NSString stringWithFormat:@"%@-%@", NSStringFromSelector(_cmd), auth0_refreshToken];

	NSUInteger requestCount =
	  [pendingRequests pushCompletionQueue: completionQueue
	                       completionBlock: completionBlock
	                                forKey: requestKey];

	if (requestCount > 1)
	{
		// There's a previous request currently in-flight.
		// The <completionQueue, completionBlock> have been added to the existing request's list.
		return;
	}

	[self getIDTokenWithRefreshToken: auth0_refreshToken
	                      requestKey: requestKey];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Get AWS Credentials
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)getAWSCredentialsWithRefreshToken:(NSString *)refreshToken
                               requestKey:(NSString *)requestKey
{
	__weak typeof(self) weakSelf = self;
	
	void (^Fail)(NSError*) = ^(NSError *error){
		
		NSParameterAssert(error != nil);
		
		__strong typeof(self) strongSelf = weakSelf;
		if (!strongSelf) return;
		
		NSArray<dispatch_queue_t> * completionQueues = nil;
		NSArray<id>               * completionBlocks = nil;
		[strongSelf->pendingRequests popCompletionQueues: &completionQueues
		                                completionBlocks: &completionBlocks
		                                          forKey: requestKey];

		for (NSUInteger i = 0; i < completionBlocks.count; i++)
		{
			dispatch_queue_t completionQueue = completionQueues[i];
			void (^completionBlock)(NSDictionary *delegationToken, NSError *error) = completionBlocks[i];

			dispatch_async(completionQueue, ^{ @autoreleasepool {

				completionBlock(nil, error);
			}});
		}
	};
	
	void (^Succeed)(NSDictionary*) = ^(NSDictionary *delegation){
		
		NSParameterAssert(delegation != nil);
		
		__strong typeof(self) strongSelf = weakSelf;
		if (!strongSelf) return;
		
		NSArray<dispatch_queue_t> * completionQueues = nil;
		NSArray<id>               * completionBlocks = nil;
		[strongSelf->pendingRequests popCompletionQueues: &completionQueues
		                                completionBlocks: &completionBlocks
		                                          forKey: requestKey];

		for (NSUInteger i = 0; i < completionBlocks.count; i++)
		{
			dispatch_queue_t completionQueue = completionQueues[i];
			void (^completionBlock)(NSDictionary *delegationToken, NSError *error) = completionBlocks[i];

			dispatch_async(completionQueue, ^{ @autoreleasepool {

				completionBlock(delegation, nil);
			}});
		}
	};
	
	NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
	NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];

	NSURLComponents *urlComponents = [[NSURLComponents alloc] init];
	urlComponents.scheme = @"https";
	urlComponents.host = kAuth04thADomain;
	urlComponents.path = @"/delegation";

	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithCapacity:5];
	jsonDict[A0ParameterClientID]     = kAuth04thA_AppClientID;
	jsonDict[A0ParameterGrantType]    = @"urn:ietf:params:oauth:grant-type:jwt-bearer";
	jsonDict[A0ParameterScope]        = @"openid offline_access";
	jsonDict[A0ParameterAPIType]      = @"aws";
	jsonDict[A0ParameterRefreshToken] = refreshToken;

	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];

	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[urlComponents URL]];
	request.HTTPMethod = @"POST";
	request.HTTPBody = jsonData;

	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

	NSURLSessionDataTask *task =
	  [session dataTaskWithRequest: request
	             completionHandler:^(NSData *responseObject, NSURLResponse *response, NSError *error)
	{
		if (error)
		{
			Fail(error);
			return;
		}

		NSInteger statusCode = response.httpStatusCode;
		if ((statusCode != 200) &&
		    (statusCode != 401) &&
		    (statusCode != 403) &&
		    (statusCode != 429))
		{
			error = [self errorWithStatusCode:statusCode description:@"Bad Status response"];
			
			Fail(error);
			return;
		}
		  
		NSDictionary *jsonDict = nil;
		NSDictionary *delegation = nil;
		
		if ([responseObject isKindOfClass:[NSData class]] && (responseObject.length > 0))
		{
			jsonDict = [NSJSONSerialization JSONObjectWithData:(NSData *)responseObject options:0 error:&error];
			
			if (![jsonDict isKindOfClass:[NSDictionary class]]) {
				jsonDict = nil;
			}
		}

		if (jsonDict)
		{
			NSString *error_code = jsonDict[@"error"];
			if (error_code)
			{
				NSString *error_description = jsonDict[@"error_description"];
				error = [self errorWithDescription:error_description a0Code:error_code];
			}
			else
			{
				delegation = jsonDict;
			}
		}

		if (delegation)
		{
			Succeed(delegation);
		}
		else if (error)
		{
			Fail(error);
		}
		else
		{
			error = [self errorWithStatusCode:statusCode description:@"Invalid response from server"];
			Fail(error);
		}
	}];

	[task resume];
}

- (void)getAWSCredentialsWithRefreshToken:(NSString *)refreshToken
                          completionQueue:(nullable dispatch_queue_t)completionQueue
                          completionBlock:(void (^)(NSDictionary * _Nullable delegationToken,
                                                    NSError *_Nullable error))completionBlock
{
#ifndef NS_BLOCK_ASSERTIONS
	NSParameterAssert(refreshToken);
	NSParameterAssert(completionBlock);
#else
	if (completionBlock == nil) return;
#endif

	NSString *requestKey = [NSString stringWithFormat:@"%@-%@", NSStringFromSelector(_cmd), refreshToken];

	NSUInteger requestCount =
	  [pendingRequests pushCompletionQueue: completionQueue
	                       completionBlock: completionBlock
	                                forKey: requestKey];

	if (requestCount > 1)
	{
		// There's a previous request currently in-flight.
		// The <completionQueue, completionBlock> have been added to the existing request's list.
		return;
	}

	[self getAWSCredentialsWithRefreshToken: refreshToken
	                             requestKey: requestKey];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark  - Auth0 Get Social media login tools
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSString *)callbackURLscheme
{
	return [[NSString stringWithFormat:@"a0%@", kAuth04thA_AppClientID] lowercaseString];
}

-(NSURL*) socialQueryURLforStrategyName:(NSString*)strategyName
					  callBackURLScheme:(NSString*)callBackURLScheme
							  CSRFState:(NSString*)CSRFState
{
	NSParameterAssert(strategyName != nil);

	static NSString* const kCallbackURLString =  @"%@://%@.auth0.com/authorize";

	NSString *callbackURLString = [NSString stringWithFormat:kCallbackURLString,
								   callBackURLScheme,
								   strategyName].lowercaseString;

	NSURL* callbackURL = [NSURL URLWithString:callbackURLString];

	NSURLComponents *urlComponents = [[NSURLComponents alloc] init];
	urlComponents.scheme = @"https";
	urlComponents.host = kAuth04thADomain;
	urlComponents.path = @"/authorize";

	NSMutableArray<NSURLQueryItem *> *queryItems = [NSMutableArray arrayWithCapacity:8];
	
	[queryItems addObject:[NSURLQueryItem queryItemWithName:A0ParameterClientID     value:kAuth04thA_AppClientID]];
	[queryItems addObject:[NSURLQueryItem queryItemWithName:A0ParameterScope        value:@"offline_access"]];
	[queryItems addObject:[NSURLQueryItem queryItemWithName:A0ParameterResponseType value:@"token"]];
	[queryItems addObject:[NSURLQueryItem queryItemWithName:A0ParameterRedirectURI  value:callbackURL.absoluteString]];
	[queryItems addObject:[NSURLQueryItem queryItemWithName:A0ParameterConnection   value:strategyName]];
#if TRACK_DEVICE
	[queryItems addObject:[NSURLQueryItem queryItemWithName:A0ParameterDevice       value:[self deviceName]]];
#endif
	if (CSRFState) {
		[queryItems addObject:[NSURLQueryItem queryItemWithName:A0ParameterState value:CSRFState]];
	}
	
	urlComponents.queryItems = queryItems;

	return urlComponents.URL;
}


-(BOOL) decodeSocialQueryString:(NSString*)queryString
						a0Token:(A0Token * _Nullable*) a0TokenOut
						CSRFState:(NSString * _Nullable*) CSRFStateOut
						  error:(NSError ** _Nullable)errorOut
{
	BOOL success = NO;

	NSError * error = nil;
	A0Token* a0Token = nil;
	NSString* stateStr = nil;

	NSString *urlStr;
	if ([queryString hasPrefix:@"?"]) {
		urlStr = [NSString stringWithFormat:@"http://www.apple.com%@", queryString];
	}
	else {
		urlStr = [NSString stringWithFormat:@"http://www.apple.com?%@", queryString];
	}
	
	NSURLComponents *components = [NSURLComponents componentsWithString:urlStr];
	NSArray<NSURLQueryItem *> *queryItems = components.queryItems;

	NSURLQueryItem *item_error = nil;
	NSURLQueryItem *item_error_description = nil;
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:queryItems.count];
	
	for (NSURLQueryItem *item in queryItems)
	{
		if ([item.name isEqualToString:@"error"])
		{
			item_error = item;
		}
		else if ([item.name isEqualToString:@"error_description"])
		{
			item_error_description = item;
		}
		
		dict[item.name] = item.value ?: @"";
	}
	
	if (item_error)
	{
		NSString *description = item_error_description.value ?: item_error.value;
		error = [self errorWithDescription:description];
	}
	else
	{
		a0Token = [A0Token tokenFromDictionary:dict];
		if (a0Token) {
			success = YES;
		}
		
		stateStr = dict[A0ParameterState];
	}

	if (CSRFStateOut) *CSRFStateOut = stateStr;
	if (a0TokenOut) *a0TokenOut = a0Token;
	if (errorOut) *errorOut = error;
	
	return success;
}

@end