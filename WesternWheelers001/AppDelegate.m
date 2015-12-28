#import "StartScreenViewController.h"
#import <QuartzCore/QuartzCore.h>

#import "AppDelegate.h"

#import "RideLevelViewController.h"
#import "DataModel.h"

@implementation AppDelegate
StartScreenViewController *start = nil;;

int dataLoaded=0;

-(void) notifiedOfDataLoaded {
    //Once the data is loaded take down the start status screen
    dataLoaded=1;
    /* any attempt to modify UIKIt views from this thread fails. Dont know why... UIKit can only be  modified from main thread*/
    //[start.view setHidden:YES];
}

-(void) timeoutNetworkLoad {
    for (int i=0; i<8; i++) {
        if (dataLoaded==1) break;
        [NSThread sleepForTimeInterval:1];
    }
    /* any attempt to display a UIKit view (e.g. dialog) in this thread crashes. So if the timeout fires just take down the start screen status window.
     The user will be shown the specific error when a view controller accesses the data model to get the ride list. This method is required
     only to stop the status window being shown forever.
     */
    //if (![start.view isHidden]) {
        start.view.layer.hidden=YES; //for some unknown reason this works from this thread but not the notification thread
    //}
}

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    //UIButton *b = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    //[self.window addSubview:b];
    
    RideLevelViewController *masterViewController = [[RideLevelViewController alloc] initWithNibName:@"RideLevelViewController" bundle:nil];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:masterViewController];
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];

    [DataModel getInstance]; //force init here
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifiedOfDataLoaded) name:@"AllRidesLoaded" object:nil];

    start = [[StartScreenViewController alloc] initWithNibName:@"StartScreenViewController" bundle:nil];
    start.view.layer.borderWidth=2;
    start.view.layer.cornerRadius=24;
    [NSThread detachNewThreadSelector:@selector(timeoutNetworkLoad) toTarget:self withObject:nil];
    [self.window addSubview:[start view]];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AppIsActive" object:nil];
    CGRect rect = CGRectMake(50, 120, 200, 70);
    start.view.frame = rect;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
