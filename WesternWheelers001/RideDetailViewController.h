#import "Ride.h"
#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "WebPageViewController.h"

@interface RideDetailViewController : UIViewController <MKAnnotation>
- (IBAction)loadMapPressed;

@property (strong, nonatomic) WebPageViewController *webPageViewController;

@property (strong, nonatomic) Ride* ride;

@property (weak, nonatomic) IBOutlet UILabel *lblRideDate;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UILabel *lblRideLevel;
@property (weak, nonatomic) IBOutlet UILabel *lblLocationDescription;
@property (weak, nonatomic) IBOutlet UILabel *lblStartTime;
@property (weak, nonatomic) IBOutlet UILabel *lblMapStatus;
@property (weak, nonatomic) IBOutlet MKMapView *testMap;

/* Map annotation */
@property (nonatomic) CLLocationCoordinate2D coordinate;
//@property (nonatomic, copy) NSString* title;

@end
