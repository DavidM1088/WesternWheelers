#import "DataModel.h"
#import "RideLevelViewController.h"
#import "RideListViewController.h"
#import "StartScreenViewController.h"

@interface RideLevelViewController () {
    NSMutableArray *_objects;
}
@end

DataModel *dataModel=nil;
NSThread *latestStatsViewThread = nil;

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
    //add observer here to make sure its added before stats loaded notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationOfStats:) name:@"StatsLoaded" object:nil];
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
    //self.infoView.backgroundColor = [UIColor lightGrayColor];
    CGRect rect;
    rect.size.width=100;
    rect.size.height=140;
    rect.origin.x=0;
    rect.origin.y=0;
    [self.infoView setFrame:rect];
    
    //lay out components in the statistics view
    NSInteger row = 10;
    NSInteger margin = 10;
    NSInteger height = 18;
    NSInteger width = 400;

    UILabel *line=[[UILabel alloc]initWithFrame:CGRectMake(0, row, width, height/8)];
    [line setBackgroundColor:[UIColor lightGrayColor]];
    [self.infoView addSubview:line];

    row += height/4;
    self.statsTitle=[[UILabel alloc]initWithFrame:CGRectMake(margin, row, width, height)];
    [self.statsTitle setTextColor:[UIColor blueColor]];
    [self.infoView addSubview:self.statsTitle];
    
    row += height;
    self.statsMsg1 =[[UITextView alloc]initWithFrame:CGRectMake(margin, row, (width*2)/3, height*2)];
    [self.statsMsg1 setEditable:false];
    [self.infoView addSubview:self.statsMsg1];
    
    row += 2 *height;
    self.statsMsg2=[[UITextView alloc]initWithFrame:CGRectMake(margin, row, (width*2)/3, height*3)];
    [self.statsMsg2 setEditable:false];
    [self.infoView addSubview:self.statsMsg2];

    row += 3 * height;
    UIButton *infoBtn =[UIButton buttonWithType:UIButtonTypeInfoLight];
    //UIButton *infoBtn =[UIButton buttonWithType:UIButtonTypeRoundedRect];
    //[infoBtn setTitle:@"Ride Info" forState:UIControlStateNormal];
    [infoBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    infoBtn.frame = CGRectMake(0, row, 40, height);
    [infoBtn addTarget:self action:@selector(showInfo) forControlEvents:UIControlEventTouchDown];
    [self.infoView addSubview:infoBtn];
    
    [self.tableView setTableFooterView:self.infoView];
    //[NSThread detachNewThreadSelector:@selector(notificationOfStats) toTarget:self withObject:nil];
}

- (void) showRandomStats {
    DataModel *m = [DataModel getInstance];
    NSArray *leaders = m.getStatsLeaders;
    if (leaders.count > 0) {
        [self.statsTitle setText:@"Hall of Fame"];
        int index = arc4random() %(leaders.count);
        NSString *line = leaders[index];
        [self.statsMsg1 setText:line];
        [self.statsMsg1 setNeedsDisplay];
    }
    NSArray *riders = m.getStatsRiders;
    if (riders.count > 0) {
        [self.statsTitle setText:@"Hall of Fame"];
        int index = arc4random() %(riders.count);
        NSString *line = riders[index];
        [self.statsMsg2 setText:line];
        [self.statsMsg2 setNeedsDisplay];
    }
}

-(void) notificationOfStats:(NSNotification*) n {
    //NSLog(@"---> stats thread START old:%@ new:%@", latestStatsViewThread, [NSThread currentThread]);
    latestStatsViewThread = [NSThread currentThread];
    while (1) {
        NSThread *thisThread = [NSThread currentThread];
        if (thisThread != latestStatsViewThread) {
            //NSLog(@"---> stats thread EXIT :%@", thisThread);
            break;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showRandomStats];
        });
        [NSThread sleepForTimeInterval:20]; //seconds
    }
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
