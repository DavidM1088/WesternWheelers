#import "DataModel.h"
#import "RideLevelViewController.h"
#import "RideListViewController.h"
#import "RideDetailViewController.h"
#import "Ride.h"

@interface RideListViewController () {
    NSMutableArray *_objects;
}
@end


@implementation RideListViewController

@synthesize rideListCell = _rideListCell;

/* -------------------------- http ------------------------*/

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Rides List", @"Rides List");
    }
    _objects = [[NSMutableArray alloc] init];
    return self;
}

-(void) assignRideSet:(int) setType level:(NSString*) rideSet {
    //called once at view creation
    self.rideSet=rideSet;
    self.rideSetType=setType;
    self.title = [NSString stringWithFormat:@"%@ Rides", self.rideSet];
    DataModel *dataModel = [DataModel getInstance];
    NSError *err;
    NSArray *rides = [dataModel getRides:setType tag:self.rideSet error:&err];
    if (err.code != 0) {
        UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Cannot load rides" message:[err localizedDescription] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [a show];
    }
    for (Ride *ride in rides) {
        [self insertNewObject:ride];
    }
    self.firstAppearance=1;
}

- (void)notificationOfData:(NSNotification*) n {
    NSDictionary *d = [n userInfo];
    Ride *newRide = [d objectForKey:@"ride"];
    int exists=0;
    int row;
    for (int i=0; i<_objects.count; i++) {
        Ride *ride = [_objects objectAtIndex:i];
        if ([newRide isSameRide:ride.rideEventNumber date:ride.rideDate]) {
            [_objects setObject:newRide atIndexedSubscript:i];
            exists=1;
            row=i;
            break;
        }
    }
    if (exists) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        //[self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    else {
        [self insertNewObject:newRide];
    }
}

- (void)insertNewObject:(Ride*) newRide
{
    if (newRide==nil) return;
    [_objects addObject:newRide];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_objects.count-1 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void) insertUsersRide {
    [self insertNewObject:[[Ride alloc] init ]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80.f;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.rowHeight=100.f;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationOfData:) name:@"AllRidesLoaded" object:nil];
}

- (void) setCurrentRide {
    NSDate *now = [NSDate date];
    for (int i =0; i<[_objects count]; i++) {
        Ride *ride = [_objects objectAtIndex:i];
        if ([ride.rideDate compare:now] != NSOrderedAscending) {
            if (i>0) {
                NSIndexPath *p = [NSIndexPath indexPathForRow:i-1 inSection:0];
                [self.tableView scrollToRowAtIndexPath:p atScrollPosition:UITableViewScrollPositionTop animated:YES];
            }
            break;
        }
    }
}

- (void) viewDidAppear:(BOOL)animated {
    if (self.firstAppearance) {
        [self setCurrentRide];
        self.firstAppearance=0;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    self.detailViewController=nil;
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
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RideListCell *cell = (RideListCell*) [tableView dequeueReusableCellWithIdentifier:[RideListCell reuseIdentifier]];
    if (cell==nil) {
        [[NSBundle mainBundle] loadNibNamed:@"RideListCell" owner:self options:nil];
        cell = _rideListCell;
        _rideListCell=nil;
    }
    Ride *ride = _objects[indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.lblTitle.text = ride.title;

    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    [fmt setDateStyle:NSDateFormatterFullStyle];
    cell.lblDate.text= [fmt stringFromDate:ride.rideDate];
    /*
    NSDate *now = [[NSDate alloc] init]; //gray out rides in the past
    if ([ride.rideDate compare:now] != NSOrderedDescending) {
        cell.lblDate.textColor = [UIColor grayColor];
        cell.lblTitle.textColor = [UIColor grayColor];
        cell.lblLevel.textColor = [UIColor grayColor];
        cell.lblImpromtu.textColor = [UIColor grayColor];
    }*/
    cell.lblId.text= @"";
    cell.lblLevel.text=ride.rideLevel;
    if (ride.isImpromtu) cell.lblImpromtu.text = @"Impromptu"; else cell.lblImpromtu.text=@"";
    return cell;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPathOld:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"tablecell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    Ride *ride = _objects[indexPath.row];
    cell.textLabel.text  = ride.title;
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

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //[super dealloc];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.detailViewController) {
        self.detailViewController = [[RideDetailViewController alloc] initWithNibName:@"RideDetailViewController" bundle:nil];
    }
    Ride *ride =[_objects objectAtIndex:indexPath.row];
    self.detailViewController.ride = ride;
    [self.navigationController pushViewController:self.detailViewController animated:YES];
}

@end
