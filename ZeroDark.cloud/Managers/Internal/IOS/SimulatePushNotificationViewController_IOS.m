/**
 * ZeroDark.cloud Framework
 * 
 * Homepage      : https://www.zerodark.cloud
 * GitHub        : https://github.com/4th-ATechnologies/ZeroDark.cloud
 * Documentation : https://zerodarkcloud.readthedocs.io/en/latest/
 * API Reference : https://apis.zerodark.cloud
 **/

#import "SimulatePushNotificationViewController_IOS.h"
#import "ZeroDarkCloud.h"
#import "ZeroDarkCloudPrivate.h"

#import "ZDCLogging.h"

// Categories

// Log Levels: off, error, warning, info, verbose
// Log Flags : trace
#if DEBUG
static const int zdcLogLevel = ZDCLogLevelWarning;
#else
static const int zdcLogLevel = ZDCLogLevelWarning;
#endif

@implementation SimulatePushNotificationViewController_IOS
{
	
	IBOutlet __weak UIButton                		*_btnSimPush;
	IBOutlet __weak UIActivityIndicatorView  		*_actPush;
	
	ZeroDarkCloud*                     owner;
}


- (instancetype)initWithOwner:(ZeroDarkCloud*)inOwner
{
	
	self = [super initWithNibName:@"SimulatePushNotificationViewController_IOS"
								  bundle:[ZeroDarkCloud frameworkBundle]];
 	if (self)
	{
		owner = inOwner;
 	}
	return self;
	
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:	animated];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
														  selector:@selector(pullStarted:)
																name:ZDCPullStartedNotification
															 object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
														  selector:@selector(pullStopped:)
																name:ZDCPullStoppedNotification
															 object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self
														  selector:@selector(pushStarted:)
																name:ZDCPushStartedNotification
															 object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self
														  selector:@selector(pushStopped:)
																name:ZDCPushStoppedNotification
															 object:nil];

}

-(void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Pull/Push
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



- (void)pullStarted:(NSNotification *)notification
{
	ZDCLogAutoTrace();

	if(!_actPush.isAnimating){
		[_actPush startAnimating];
		_btnSimPush.enabled = NO;
  	}

}

- (void)pullStopped:(NSNotification *)notification
{
	ZDCLogAutoTrace();
	
	if(_actPush.isAnimating){
		[_actPush stopAnimating];
		_btnSimPush.enabled = YES;
	}

}

- (void)pushStarted:(NSNotification *)notification
{
	ZDCLogAutoTrace();
	
	if(!_actPush.isAnimating){
		[_actPush startAnimating];
		_btnSimPush.enabled = NO;
	}

}

- (void)pushStopped:(NSNotification *)notification
{
	ZDCLogAutoTrace();

	if(_actPush.isAnimating){
		[_actPush stopAnimating];
		 _btnSimPush.enabled = YES;
		 }

}

- (IBAction)didHitSimulatePush:(id)sender
{
	[owner.syncManager pullChangesForAllLocalUsers];
}
 
 
@end