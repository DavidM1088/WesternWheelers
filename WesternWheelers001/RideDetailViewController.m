#import "RideDetailViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "DataModel.h"
#import "WebPageViewController.h"

@interface RideDetailViewController ()

@end

@implementation RideDetailViewController

#pragma mark - Managing the detail item

-(void) setupDetails {
    self.lblLocationDescription.text = self.ride.locationDescription;
    self.lblStartTime.text = self.ride.startTime;
    if (self.ride.locationPoint.latitude == 0) {
        self.testMap.hidden=YES;
        self.lblMapStatus.text=@"Map not available for this location";
    }
    else {
        self.testMap.hidden=NO;
        MKCoordinateRegion region;
        region.center=self.ride.locationPoint;
        region.span.latitudeDelta=0.1;
        region.span.longitudeDelta=0.1;
        self.testMap.region=region;
        self.coordinate = self.ride.locationPoint;

        [self.testMap addAnnotation:self];
        self.lblMapStatus.text=@"approximate location only - see ride page for start location";
    }
    [self.view setNeedsDisplay];
    
}

-(void) notificationOfData:(NSNotification*) n {
    NSDictionary *d = n.userInfo;
    Ride* ride = [d objectForKey:@"ride"];
    if ([ride.rideid isEqual:self.ride.rideid]) {
        [self setupDetails];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.testMap.hidden=YES;
    self.lblLocationDescription.text = @"loading...";
    self.lblStartTime.text=@"";
    self.lblMapStatus.text=@"";

    if (self.ride.allDetailsLoaded) {
        [self setupDetails];
    }
    else {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationOfData:) name:@"RideLoaded" object:nil];
        [NSThread detachNewThreadSelector:@selector(loadRideDetails) toTarget:self withObject:nil];
    }
    
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    [fmt setDateStyle:NSDateFormatterFullStyle];
    self.lblRideDate.text =[fmt stringFromDate:self.ride.rideDate];
    self.lblTitle.text = self.ride.title;
    self.lblRideLevel.text = self.ride.rideLevel;
    self.title = self.ride.title; //View Controller title
}

- (void) loadRideDetails {
    //[NSThread sleepForTimeInterval:2];    
    [[DataModel getInstance] getRideDetails:self.ride.rideid];
}

- (IBAction)loadMapPressed {
    if (!self.webPageViewController) {
        self.webPageViewController = [[WebPageViewController alloc] initWithNibName:@"WebPageViewController" bundle:nil];
    }
    self.webPageViewController.ride = self.ride;
    [self.navigationController pushViewController:self.webPageViewController animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    self.webPageViewController=nil;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Ride Details", @"Ride Details");
    }
    return self;
}

- (void)viewDidUnload {
    [self setLblTitle:nil];
    [self setWebPageViewController:nil];
    [self setTestMap:nil];
    [self setLblLocationDescription:nil];
    [self setLblStartTime:nil];
    [self setLblMapStatus:nil];
    [super viewDidUnload];
}


@end
