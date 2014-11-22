#import "DataModel.h"
#import "Ride.h"
#import <CoreLocation/CoreLocation.h>

int RIDESET_ALL=0;
int RIDESET_LEVEL=1;
int RIDESET_SEARCH=2;

NSTimeInterval oneDay = 24 * 60 * 60;
int testMode=0;
int firstLoad=1;
NSError *httpError=nil;
//NSDate *lastLoadDate=nil;

@implementation DataModel

@synthesize rideList=_rideList;

+ (DataModel*) getInstance {
    static DataModel *single = nil;
    @synchronized(self) {
        if (!single) {
            single = [[self alloc] init];
        }
    }
    return single;
}

- (DataModel*)init {
    self = [super init];
    _eventLog = [[NSMutableArray alloc] init];
    _rideList = [[NSMutableArray alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifiedOfAppIsActive) name:@"AppIsActive" object:nil];
    return self;
}

- (void) notifiedOfAppIsActive {
    //NSDate *nowDate = [[NSDate alloc] init];
    //if (lastLoadDate) {
    //    NSTimeInterval diff = [nowDate timeIntervalSinceDate:lastLoadDate];
    //    long waitSeconds = 30 /* minutes */ * 60;
    //    if (diff < waitSeconds) return; //only load if enough time passed since the last load. The list may have been updated
    //}
    [NSThread detachNewThreadSelector:@selector(loadRides) toTarget:self withObject:nil];
}

- (NSArray*) getEventLog {
    return _eventLog;
}

- (void) loadRides {
    /* this thread is suspended if the app goes to backgroud (but not exited). When the user brings the app back
     active this thread will resume and immediately load the data fresh. If the app just stays active the data
     will be refreshed periodically as per the refresh minutes below*/
    int done=0;
    //int afterSuccessRefreshMins = 30; //this also becomes the maximum time the data can be out of sync from the web site when the app stays active
    //int afterFailRefreshMins = 1; //don't wait too long with the user unable to see any data.
    //int loop=0;
    int lastError=0;
    while (!done) {
        //[self loadAllFromWebPages];
        [self loadAllFromRSSPage];
        if (httpError.code == 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RidesLoaded" object:self];
            //[NSThread sleepForTimeInterval:afterSuccessRefreshMins * 60];
            //[NSThread sleepForTimeInterval:20];
        }
        else {
            //[NSThread sleepForTimeInterval:afterFailRefreshMins * 60];
            //[NSThread sleepForTimeInterval:20];
        }
        lastError=httpError.code;
        done=1; //dont keep thread alive..
    }
    firstLoad=0;
}

- (void) getRideDetails:(NSString*) rideId {
    for (Ride *ride in self.rideList) {
        if ([ride.rideid isEqualToString:rideId])  {
            if (!ride.allDetailsLoaded) {
                [self loadDetailFromRidePage:ride];
                ride.allDetailsLoaded=YES;
            }
        }
    }
}

+ (NSString*) xmlTagData:(NSString*) tag data:(NSString*) inData offset:(int) offset {
    NSString *startTag = [NSString stringWithFormat:@"<%@>", tag];
    NSString *endTag = [NSString stringWithFormat:@"</%@>", tag];
    
    NSRange startRng, endRng;
    startRng.location=offset;
    startRng.length=inData.length-offset;
    startRng = [inData rangeOfString:startTag options:0 range:startRng];
    if (startRng.location == NSNotFound) return nil;
    endRng.location=startRng.location+startTag.length;
    endRng.length=inData.length-endRng.location;
    endRng = [inData rangeOfString:endTag options:0 range:endRng];
    if (endRng.location == NSNotFound) return nil;
    
    //strip the start and end tag
    NSRange rng;
    rng.location = startRng.location + tag.length+2;
    rng.length= endRng.location - rng.location;
    
    NSString *res = [inData substringWithRange:rng];
    return res;
    
}

+(NSString *)getStringBoundedBy:(NSString*) instr start:(NSString*) startStr end:(NSString*) endStr;
{
    NSRange rngScan;
    if (startStr!= nil) {
        rngScan = [instr rangeOfString:startStr];
        if (rngScan.location == NSNotFound) return nil;
    }
    else {
        rngScan.location = 0;
    }
    rngScan.length= instr.length - rngScan.location;
    NSRange endScan;
    if (endStr != nil) {
        endScan = [instr rangeOfString:endStr options:0 range:rngScan];
        if (endScan.location == NSNotFound) return nil;
    }
    else {
        endScan.location=instr.length;
    }
    
    rngScan.location += startStr.length;
    rngScan.length = endScan.location - rngScan.location;
    NSString *res = [instr substringWithRange:rngScan];
    return res;
}

- (NSArray*) getRides:(int) type tag:(NSString*) tag error:(NSError **)outError;
{
    if (self.rideList.count==0 && httpError != nil) {
        //if we already have rides return them even if they have not been updated from the web page recently
        *outError = httpError;
        return nil;
    }
    NSMutableArray *rides = [[NSMutableArray alloc] init];
    self.currentRideSetTag =  tag;
    self.currentRideSetType = type;
    
    for (Ride *ride in self.rideList) {
        if (self.currentRideSetType == RIDESET_ALL) {
            [rides addObject:ride];
        }
        if (self.currentRideSetType == RIDESET_LEVEL) {
            if ([ride isOfLevel:self.currentRideSetTag]) {
                [rides addObject:ride];
            }
        }
        if (self.currentRideSetType == RIDESET_SEARCH) {
            if ([ride matchesTag:self.currentRideSetTag]) {
                [rides addObject:ride];
            }
        }
    }
    return rides;
}

NSMutableData *responseData;

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"URL error %@", error);
}

- (void) parsePageContents_unused:(NSString*) data date:(NSDate*) startDate {
    
    //loop thru data looking for rows
    int firstDateRow=1;
    int done=0;
    NSString *eventToken = @"<td class=\"EventListCalendarItem";
    NSRange eventRng;
    eventRng.location=0;
    eventRng.length=data.length;
    int ctr=0;
    int column=0;
    while (!done) {
        eventRng = [data rangeOfString:eventToken options:0 range:eventRng];
        if (eventRng.location == NSNotFound) break;
        eventRng.length= data.length - eventRng.location;
        NSString *event = [data substringWithRange:eventRng];
        event = [DataModel getStringBoundedBy:event start:nil end:@"</td>"];
        NSRange rng = [event rangeOfString:@"eventId"];
        int isaRide = rng.location != NSNotFound;
        
        if (isaRide) {
            Ride *newRide= [[Ride alloc] initFromEvent:event rideDate:startDate];
            //check if we have it already since the next month page also lists some of this months rides
            int found=0;
            for (Ride *r in self.rideList) {
                if ([r.rideid isEqualToString:newRide.rideid]) {
                    found=1;
                    break;
                }
            }
            if (found==0) {
                [self.rideList addObject:newRide /*forKey:newRide.rideid*/];
            }
        }
        
        ctr++;
        if (column == 0 /*|| !isaRide*/) {
            //look for the next week in the calendar
            NSRange typeRng = [event rangeOfString:@"calendarDate"];
            if (typeRng.location != NSNotFound) {
                if (firstDateRow==0) {
                    startDate = [startDate dateByAddingTimeInterval:7*oneDay];
                }
                firstDateRow=0;
            }
        }
        if (column == 6) {
            column=0;
            startDate = [startDate  dateByAddingTimeInterval:0-6*oneDay];
        }
        else {
            column++;
            startDate = [startDate  dateByAddingTimeInterval:oneDay];
        }
        eventRng.location += event.length;
        eventRng.length= data.length - eventRng.location;
        if (eventRng.location + eventRng.length > data.length) break;
    }
}

- (NSString*) fmtDate:(NSDate*) dt {
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    [f setDateFormat:@"MMM dd, yyy HH:mm"];
    NSString *ds = [f stringFromDate:dt];
    return ds;
}


- (void)loadAllFromRSSPage {
    NSURL *url = [NSURL URLWithString:@"http://westernwheelersbicycleclub.memberlodge.com/ride_calendar/RSS"];
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    NSURLResponse *resp =nil;
    NSError *err=nil;
    httpError=nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];
    int errNum = [err code];
    if (errNum != 0 ) {
        httpError = [err copy];
        [self addEvent:@"Unable to access internet"];
        return;
    }
    NSString *rssXml = [[NSString alloc] initWithData:responseData encoding: NSASCIIStringEncoding];
    
    //loop thru xml data looking for ride <items>

    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setTimeZone:[NSTimeZone systemTimeZone]];
    [dateFormat setLocale:[NSLocale currentLocale]];
    [dateFormat setFormatterBehavior:NSDateFormatterBehaviorDefault];
    //                          Tue, 01 Jul 2014 14:15:00 GMT
    [dateFormat setDateFormat:@"dd MMM yyyy"];
    int totRidesScanned=0;
    int totRidesAdded=0;
    
    //locate where to start scanning for <item>s
    NSRange startRng;
    startRng.location=0;
    startRng.length=rssXml.length;
    startRng = [rssXml rangeOfString:@"<item>" options:0 range:startRng];
    int offset = startRng.location;
    
    NSString* firstDate;
    NSString* lastDate;
    while (1) {
        NSString *event = [DataModel xmlTagData:@"item" data:rssXml offset:offset];
        if (event==nil) break;
        NSString *eventTitle = [DataModel xmlTagData:@"title" data:event offset:0];
        NSString *eventDateStr = [DataModel xmlTagData:@"pubDate" data:event offset:0];
        NSRange rng;
        rng.location = 5;
        rng.length = 11;
        eventDateStr = [eventDateStr substringWithRange:rng];
        
        NSDate *eventDate = [dateFormat dateFromString:eventDateStr];
        
        if (eventDate != nil) {
            int found=0;
            Ride *newRide= [[Ride alloc] initFromEvent:event rideDate:eventDate];
            //check if we have it already. Rides are loaded whenever the app goes active so we only want rides added since the last load.
            for (Ride *r in self.rideList) {
                if ([r.rideid isEqualToString:newRide.rideid]) {
                    found=1;
                    break;
                }
            }
            if (found==0) {
                [self.rideList addObject:newRide];
                totRidesAdded++;
            }
            
            totRidesScanned++;
            if (firstDate==nil) firstDate = eventDateStr;
            lastDate = eventDateStr;
        }
        else {
            NSLog(@"bad event date: %@ for ride:%@", eventDateStr, eventTitle);
        }

        offset += event.length + 13; //13 = length of start and end <item> tags which where not included the event data
        if (offset>rssXml.length) break;
    }
    NSString *log = [NSString stringWithFormat:@"%d website rides scanned from %@ to %@, %d new rides added to app", totRidesScanned, firstDate, lastDate, totRidesAdded];
    NSLog(@"%@", log);
    [self addEvent:log];
    
}

/* Load all the rides from the main site web page. 7/2/14 Unused since a Wild Apricot software release broke this fragile screen
 scaping code. Decision is to load from the RSS format instead. */
- (void)loadAllFromWebPages_unused {
     
    NSURL *url = [NSURL URLWithString:@"http://westernwheelersbicycleclub.memberlodge.com/ride_calendar"];
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    NSURLResponse *resp =nil;
    NSError *err=nil;
    httpError=nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];
    int errNum = [err code];
    if (errNum != 0 ) {
        httpError = [err copy];
        [self addEvent:@"Unable to access internet"];
        return;
    }
    NSString *body = [[NSString alloc] initWithData:responseData encoding: NSASCIIStringEncoding];
    
    // find the calendar starting month and year from system time then back to last Sunday of previous month
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *currentPageFirstDate = [NSDate date];
    NSDateComponents *comps = [cal components:(NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit) fromDate:currentPageFirstDate];
    [comps setDay:1];
    [comps setMonth:[comps month]];
    [comps setYear:[comps year]];
    [comps setHour:22]; // mark all rides for the current day in the future in view. e.g. evenings rides should show as not passed yet.
    currentPageFirstDate = [cal dateFromComponents:comps];
    //back up to previous Sunday
    comps = [cal components:(NSWeekdayCalendarUnit) fromDate:currentPageFirstDate];
    int weekDay = [comps weekday];
    comps = [[NSDateComponents alloc] init];
    comps.day=0-weekDay+1;
    currentPageFirstDate = [cal dateByAddingComponents:comps toDate:currentPageFirstDate options:0];
    
    self.rideList = [[NSMutableArray alloc] init];
    
    [self parsePageContents_unused:body date:currentPageFirstDate];
    int thisMonthCount = self.rideList.count;
    
    /* ----- load the following month ---- */
    
    comps = [[NSDateComponents alloc]init];
    comps.day=(7*7)-4; // Make a date that pushes us into 'next month'. 6 weeks to generate link date for next month
    NSDate *nextMonthlinkDate = [cal dateByAddingComponents:comps toDate:currentPageFirstDate options:0];
    comps = [cal components:(NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit) fromDate:nextMonthlinkDate];
    
    NSString *linkDateStr = [NSString stringWithFormat:@"%d/%d/%d", [comps month], [comps day] + 1, [comps year]];
    NSString *nextMonthUrl = [NSString stringWithFormat:@"http://westernwheelersbicycleclub.memberlodge.com/ride_calendar?EventViewMode=1&EventListViewMode=2&SelectedDate=%@&CalendarViewType=1", linkDateStr];
    url = [NSURL URLWithString:nextMonthUrl];
    req = [NSURLRequest requestWithURL:url];
    resp =nil;
    responseData = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];
    body = [[NSString alloc] initWithData:responseData encoding: NSASCIIStringEncoding];
    
    //calc the first date that did appear on the "next month's rides" page
    comps = [[NSDateComponents alloc]init];
    //comps.day=5*7; // 5 weeks - this is wrong.... gives 5/5
    comps = [cal components:(NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit) fromDate:nextMonthlinkDate];
    [comps setDay:1];
    [comps setMonth:[comps month]];
    [comps setYear:[comps year]];
    [comps setHour:22];
    NSDate* nextPageFirstDate = [cal dateFromComponents:comps];
    //back up to previous Sunday
    comps = [cal components:(NSWeekdayCalendarUnit) fromDate:nextPageFirstDate];
    weekDay = [comps weekday];
    comps = [[NSDateComponents alloc] init];
    comps.day=0-weekDay+1;
    //thisMonthStartDate = [cal dateByAddingComponents:comps toDate:thisMonthStartDate options:0];
    
    nextPageFirstDate = [cal dateByAddingComponents:comps toDate:nextPageFirstDate options:0];
    //comps = [cal components:(NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit) fromDate:nextPageFirstDate];
    [self parsePageContents_unused:body date:nextPageFirstDate];
    
    NSString *log = [NSString stringWithFormat:@"Rides loaded for this month:%d, next month:%lu\nFirstDateforCurrent:%@ FirstDateforNext:%@", thisMonthCount, (unsigned long)[self.rideList count] - thisMonthCount, [self fmtDate:currentPageFirstDate], [self fmtDate:nextPageFirstDate]];
    NSLog(@"%@", log);
    //NSString *event = [[NSString alloc] initWithFormat:@"Rides loaded for this month %d, next month %d, earliest: %@",   thisMonthCount, (int)[self.rideList count] - thisMonthCount , [self fmtDate:thisMonthStartDate]];
    [self addEvent:log];
    
    self.rideList = [[self.rideList sortedArrayUsingSelector:@selector(compareDates:)] copy];
}

- (void) addEvent:(NSObject*) event {
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    [fmt setDateFormat:@"MMM dd, HH:mm:ss"];
    NSString *ts = [fmt stringFromDate:[[NSDate alloc] init]];
    
    NSString *line = [[NSString alloc] initWithFormat:@"%@: %@", ts, event ];
    [_eventLog addObject:line];
    if (_eventLog.count > 50) {
        [_eventLog removeObjectAtIndex:0];
    }
}

Ride* geoRide;

- (void) geoLocate :(NSString*) address {
    CLGeocoder *coder = [[CLGeocoder alloc] init];
    //NSString *addr = @"shoup park, palo alto, california";
    CLLocationCoordinate2D center; center.latitude=37.42; center.longitude=-122.16;//stanford
    CLRegion *region = [[CLRegion alloc] initCircularRegionWithCenter:center radius:1000*300 identifier:@"id"];
    [coder geocodeAddressString:address inRegion:region completionHandler:^(NSArray *placemarks, NSError *error)
     {
         CLLocationCoordinate2D point; point.latitude=0; point.longitude=0;
         if (error){
             NSLog(@"Geocode failed with error: %@ for address:%@", error, address);
         }
         else {
             CLPlacemark *mark = [placemarks objectAtIndex:0];
             CLLocation *location = mark.location;
             point = location.coordinate;
         }
         geoRide.locationPoint = point;
         NSDictionary *data = [NSDictionary dictionaryWithObject:geoRide forKey:@"ride"];
         [[NSNotificationCenter defaultCenter] postNotificationName:@"RideLoaded" object:nil userInfo:data];
     }];
}

/* Load ride details from the ride's specific web page */

- (void)loadDetailFromRidePage:(Ride*) ride {
    NSString *link = ride.htmlLink;
    NSURL *url = [[NSURL alloc] initWithString:link];
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    NSURLResponse *resp =nil;
    NSError *err;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];
    NSString *body = [[NSString alloc] initWithData:responseData encoding: NSASCIIStringEncoding];
    
    NSString *tag = @"<label>Location</label>";
    NSString *location = [DataModel getStringBoundedBy:body start:tag end:@"</span"];
    location = [DataModel getStringBoundedBy:location start:@"<span>" end:nil];
    ride.locationDescription=[DataModel decodeHtml:location];
    
    tag = @"<label>When</label>";
    NSString *startTime = [DataModel getStringBoundedBy:body start:tag end:@"</span"];
    startTime = [DataModel getStringBoundedBy:startTime start:@"<span>" end:nil];
    ride.startTime=startTime;

    //asynch call..
    geoRide = ride;
    [self geoLocate:location];
}

+ (NSString*) decodeHtml: (NSString*) in {
    if (in==nil) return nil;
    NSRange rng;
    rng.location=0;
    rng.length=in.length;
    
    NSString *result = [in  stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
    result = [result  stringByReplacingOccurrencesOfString:@"&#39;" withString:@"'"];
    result = [result  stringByReplacingOccurrencesOfString:@"â" withString:@"-"];
    
    return result;
}

@end
