#import "DataModel.h"
#import "RideLevelViewController.h"
#import "RideListViewController.h"
#import "StartScreenViewController.h"

@interface RideLevelViewController () {
    NSMutableArray *_objects;
}
@end

DataModel *dataModel=nil;

@implementation RideLevelViewController
/* -------------------------- http ------------------------*/

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Ride Levels", @"Ride Levels");
    }
    _objects = [[NSMutableArray alloc] init];
    [_objects addObject:@"A Rides"];
    [_objects addObject:@"B Rides"];
    [_objects addObject:@"C Rides"];
    [_objects addObject:@"D Rides"];
    [_objects addObject:@"E Rides"];
    [_objects addObject:@"All Rides"];
    dataModel = [DataModel getInstance];
    return self;
}
							
- (void)startSearch: (id) object
{
    self.tableView.tableHeaderView=self.searchBar;
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self.searchBar resignFirstResponder];
    self.detailViewController = [[RideListViewController alloc] initWithNibName:@"RideListViewController" bundle:nil];
    [self.detailViewController assignRideSet:RIDESET_SEARCH level:self.searchBar.text];
    [self.navigationController pushViewController:self.detailViewController animated:YES];
}

- (void) searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.searchBar resignFirstResponder];
    self.searchBar.text=nil;
}

- (void)startSplash {
    // start screen
    StartScreenViewController *start = [[StartScreenViewController alloc] initWithNibName:@"StartScreenViewController" bundle:nil];
    [self presentViewController:start animated:NO completion:nil];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate=self;
    
    /* Search bar */
    
    //UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    //self.navigationItem.rightBarButtonItem = addButton;
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.placeholder = @"Type a search term";
    self.searchBar.delegate = self;
    [self.searchBar sizeToFit];
    self.searchBar.showsCancelButton=YES;
    self.tableView.tableHeaderView=self.searchBar;
    
    self.infoBar =[[UISearchBar alloc] init];
    self.infoBar.placeholder = @"Type a search term";
    self.infoBar.delegate = self;
    [self.infoBar sizeToFit];
    self.infoBar.showsCancelButton=YES;


    /* info view footer */
    self.infoView = [[InfoView alloc] init];
    self.infoView.backgroundColor = [UIColor lightGrayColor];
    CGRect rect;
    rect.size.width=100;
    rect.size.height=40;
    rect.origin.x=0;
    rect.origin.y=0;
    [self.infoView setFrame:rect];
    
    UIButton *footerBtn =[UIButton buttonWithType:UIButtonTypeInfoLight];
    CGRect fr = footerBtn.frame;
    fr.origin.y += 10;
    fr.origin.x += 10;
    footerBtn.frame = fr;
    [footerBtn addTarget:self action:@selector(showInfo) forControlEvents:UIControlEventTouchDown];
    [footerBtn setTitle:@"info" forState:UIControlStateNormal];
    [self.infoView addSubview:footerBtn];
    [self.tableView setTableFooterView:self.infoView];
    
}

-(void) showInfo {
    DataModel *m = [DataModel getInstance];
    NSString *events = [[NSString alloc] initWithFormat:@""];
    for (NSString *event in [m getEventLog]) {
        events = [[NSString alloc] initWithFormat:@"%@\n%@\n", events, event];
    }
    UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Ride Info" message:events delegate:self cancelButtonTitle:@"Cancel"otherButtonTitles: nil];
    [a show];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender
{
    if (!_objects) {
        _objects = [[NSMutableArray alloc] init];
    }
    [_objects insertObject:(NSString*)sender atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _objects.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }


    NSDate *object = _objects[indexPath.row];
    cell.textLabel.text = [object description];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *rideLevel = _objects[indexPath.row];
    self.detailViewController = [[RideListViewController alloc] initWithNibName:@"RideListViewController" bundle:nil];
    if ([rideLevel isEqualToString:@"All Rides"]) {
        [self.detailViewController assignRideSet:RIDESET_ALL level: @"All"];
    }
    else {
        rideLevel = [rideLevel substringToIndex:1];
        [self.detailViewController assignRideSet:RIDESET_LEVEL level:rideLevel];
    }
    [self.navigationController pushViewController:self.detailViewController animated:YES];
}

@end
