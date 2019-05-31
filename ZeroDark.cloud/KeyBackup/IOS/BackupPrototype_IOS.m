
/**
 * ZeroDark.cloud
 * <GitHub wiki link goes here>
 **/

#import "BackupPrototype_IOS.h"
#import <ZeroDarkCloud/ZeroDarkCloud.h>
#import "ZeroDarkCloudPrivate.h"
#import "ZDCConstantsPrivate.h"

// Categories
#import "OSImage+ZeroDark.h"

#import "ZDCLogging.h"


// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = DDLogLevelVerbose;
#else
static const int ddLogLevel = DDLogLevelWarning;
#endif
#pragma unused(ddLogLevel)



@implementation BackupPrototype_IOS
{
	UISwipeGestureRecognizer 				*swipeRight;
	YapDatabaseConnection *         databaseConnection;

}


@synthesize keyBackupVC = keyBackupVC;

- (void)viewDidLoad {
	[super viewDidLoad];

}


-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	databaseConnection = keyBackupVC.owner.databaseManager.uiDatabaseConnection;

	self.navigationItem.title = @"Backup as Text";

	UIImage* image = [[UIImage imageNamed:@"backarrow"
								 inBundle:[ZeroDarkCloud frameworkBundle]
			compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

	UIBarButtonItem* backItem = [[UIBarButtonItem alloc] initWithImage:image
																 style:UIBarButtonItemStylePlain
																target:self
																action:@selector(handleNavigationBack:)];

	self.navigationItem.leftBarButtonItem = backItem;


	swipeRight = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeRight:)];
 	[self.view addGestureRecognizer:swipeRight];


	[self refreshView];

}
-(void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[self.view removeGestureRecognizer:swipeRight]; swipeRight = nil;

	[[NSNotificationCenter defaultCenter]  removeObserver:self];
}


-(void)swipeRight:(UISwipeGestureRecognizer *)gesture
{
	[keyBackupVC pushVerifyText];
}

- (void)handleNavigationBack:(UIButton *)backButton
{
	[[self navigationController] popViewControllerAnimated:YES];
}



- (BOOL)canPopViewControllerViaPanGesture:(KeyBackupViewController_IOS *)sender
{
	return NO;

}


-(void) refreshView
{

}

@end
