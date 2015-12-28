#import <UIKit/UIKit.h>
#import "RideDetailViewController.h"
#import "RideListViewController.h"
#import "InfoView.h"

@interface RideLevelViewController : UITableViewController <UISearchBarDelegate, UITableViewDelegate> {
}

@property (strong, nonatomic) RideListViewController *detailViewController;
@property (strong, nonatomic) Ride* ride;
@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) UISearchBar *infoBar;
@property (strong, nonatomic) InfoView *infoView;
@property (strong, nonatomic) UILabel *statsTitle;
@property (strong, nonatomic) UITextView *statsMsg1;
@property (strong, nonatomic) UITextView *statsMsg2;
@end
