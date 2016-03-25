#import <UIKit/UIKit.h>
#import "RideListCell.h"

@class RideListViewController;

@interface RideListViewController : UITableViewController

-(void) assignRideSet:(int) setType level:(NSString*) rideSet ;

@property (strong, nonatomic) RideDetailViewController *detailViewController;
@property (strong, nonatomic) NSString* rideSet;
@property int rideSetType;

@property (strong, nonatomic) IBOutlet RideListCell *rideListCell;
//@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *lblLoadNum;
@property int firstAppearance;

@end
