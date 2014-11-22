#import "Ride.h"
#import <UIKit/UIKit.h>

@interface WebPageViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString* title;
@property (strong, nonatomic) IBOutlet UIWebView *rideWebView;
@property (strong, nonatomic) Ride *ride;

@end
