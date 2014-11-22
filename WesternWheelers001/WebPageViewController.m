#import "WebPageViewController.h"

@interface WebPageViewController ()

@end

@implementation WebPageViewController

- (void) didRotate:(NSNotification*) notif
{
    CGRect newSize = self.view.bounds;
    [self.rideWebView setFrame:newSize];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    CGRect rect = [self.view bounds];
    self.rideWebView = [[UIWebView alloc] initWithFrame:rect];
    self.title = self.ride.title;
    [self.view addSubview:self.rideWebView];

    [self.rideWebView setDelegate:self];
    NSURL *url = [NSURL URLWithString:self.ride.htmlLink];
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    [self.rideWebView loadRequest:req];
    self.rideWebView.scalesPageToFit=YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];

}

- (void)viewDidUnload {
    [self setRideWebView:nil];
    [super viewDidUnload];
}
@end
