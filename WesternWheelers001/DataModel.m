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

@implementation DataModel

@synthesize rideList=_rideList;
@synthesize statsLeaders=_statsLeaders;
@synthesize statsRiders=_statsRiders;

+ (DataModel*) getInstance {
    static DataModel *single = nil;
    @synchronized(self) {
        if (!single) {
            single = [[self alloc] init];
        }
    }
    return single;
}

- (DataModel*) init {
    self = [super init];
    _eventLog = [[NSMutableArray alloc] init];
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *appLog = [NSString stringWithFormat:@"App version %@", appVersion];

    NSLog(@"%@", appLog);
    [self addEvent:appLog];

    _rideList = [[NSMutableArray alloc] init];
    _statsLeaders = [[NSMutableArray alloc] init];
    _statsRiders = [[NSMutableArray alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifiedOfAppIsActive) name:@"AppIsActive" object:nil];
    return self;
}

- (void) notifiedOfAppIsActive {
    [NSThread detachNewThreadSelector:@selector(loadRides) toTarget:self withObject:nil];
    [NSThread detachNewThreadSelector:@selector(loadStats) toTarget:self withObject:nil];
}

- (NSArray*) getEventLog {
    return _eventLog;
}

- (void) loadRides {
    /* this thread is suspended if the app goes to backgroud (but not exited). When the user brings the app back
     active this thread will resume and immediately load the data fresh. If the app just stays active the data
     will be refreshed periodically as per the refresh minutes below*/
    int done=0;
    //NSInteger lastError=0;
    while (!done) {
        [self loadAllFromRSSPage];
        if (httpError.code == 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"AllRidesLoaded" object:nil];
            //[NSThread sleepForTimeInterval:afterSuccessRefreshMins * 60];
        }
        else {
            //[NSThread sleepForTimeInterval:afterFailRefreshMins * 60];
        }
        //lastError=httpError.code;
        done=1; //dont keep thread alive..
    }
    firstLoad=0;
}

- (NSMutableArray *) findInTag:(NSString *) inString
                      startTag:(NSString *)startTag
                        endTag:(NSString *)endTag
{
    NSMutableArray *list = [[NSMutableArray alloc] init];
    NSInteger startIndex = 0;
    while (true) {
        NSRange searchRange = NSMakeRange(startIndex, inString.length - startIndex);
        NSRange rangeStart = [inString rangeOfString:startTag options:NSCaseInsensitiveSearch range:searchRange];
        if (rangeStart.location == NSNotFound) {
            break;
        }
        searchRange = NSMakeRange(rangeStart.location+rangeStart.length, inString.length - rangeStart.location - rangeStart.length);
        NSRange rangeEnd = [inString rangeOfString:endTag options:NSCaseInsensitiveSearch range:searchRange];
        if (rangeEnd.location == NSNotFound) {
            break;
        }
        NSRange range;
        range.location = rangeStart.location + rangeStart.length;
        range.length = rangeEnd.location - range.location;
        NSString *res = [inString substringWithRange:range];
        [list addObject:res];
        startIndex = rangeEnd.location + rangeEnd.length;
    }
    return list;
}

- (void) loadStats {
    self.statsLeaders = [[NSMutableArray alloc] init];
    self.statsRiders = [[NSMutableArray alloc] init];
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:[NSDate date]];
    NSInteger year = [components year];
    
    /* ride leaders */
    NSString *url = [NSString stringWithFormat:@"http://www.westernwheelers.org/main/stats/%d/wwstat%dleader1.htm", year, year-2000];
    NSURLRequest * urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSURLResponse * response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    if ([error code] != 0 ) {
        httpError = [error copy];
        //NSString *error = [NSString stringWithFormat:@"Cannot access stats : %@ %@", httpError, url];
        NSString *error = @"Unable to access internet for ride leaders";
        [self addEvent:error];
        return;
    }
    NSString* html = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSMutableArray *rows = [self findInTag:html startTag:@"<tr>" endTag:@"</tr>"];
    for (NSString *row in rows) {
        NSMutableArray *cells = [self findInTag:row startTag:@"<td>" endTag:@"</td>"];
        NSMutableArray *cellsn = [self findInTag:row startTag:@"<td class=\"numeric\">" endTag:@"</td>"];
        if (cells.count > 0 && cellsn.count >0) {
            NSString *line = [NSString stringWithFormat:@"Congratulate %@ %@ who led %@ rides this year", cells[0], cells[1], cellsn[3]];
            [self.statsLeaders addObject:line];
        }
    }

    /* riders */

    url = [NSString stringWithFormat:@"http://www.westernwheelers.org/main/stats/%d/wwstat%d.htm", year, year-2000];
    urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    response = nil;
    error = nil;
    data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    if ([error code] != 0 ) {
        httpError = [error copy];
        //NSString *error = [NSString stringWithFormat:@"Cannot access stats : %@ %@", httpError, url];
        NSString *error = @"Unable to access internet for riders";
        [self addEvent:error];
        return;
    }
    html = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSMutableArray *tables = [self findInTag:html startTag:@"<table" endTag:@"</table>"];
    int table_count = 0;
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    
    for (NSString *table in tables) {
        if (table_count == 1) {
            rows = [self findInTag:table startTag:@"<tr>" endTag:@"</tr>"];
            for (NSString *row in rows) {
                NSMutableArray *cells = [self findInTag:row startTag:@"<td>" endTag:@"</td>"];
                NSMutableArray *cellsn = [self findInTag:row startTag:@"<td class=\"numeric\">" endTag:@"</td>"];
                if (cells.count > 0 && cellsn.count > 0) {
                    NSInteger feetClimbed = [cellsn[3] integerValue];
                    NSString *feetClimbedStr = [formatter stringFromNumber:@(feetClimbed)];
                    NSString *line = [NSString stringWithFormat:@"Congratulate %@ %@ who rode %@ miles on %@ rides this year", cells[0], cells[1], cellsn[1], cellsn[2]];
                    if (feetClimbed > 0){
                        line = [NSString stringWithFormat:@"%@ and climbed %@ feet", line, feetClimbedStr];
                    }
                    [self.statsRiders addObject:line];
                }
            }
        }
        table_count += 1;
    }
    
    NSString *log = [NSString stringWithFormat:@"Load stats %lu leaders, %lu riders", (unsigned long)self.statsLeaders.count, (unsigned long)self.statsRiders.count];
    NSLog(@"%@", log);
    [self addEvent:log];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"StatsLoaded" object:nil];
}

- (void) getRideDetails:(NSString*) rideEventNumber rideDate:(NSDate*) rideDate {
    for (Ride *ride in self.rideList) {
        if ([ride isSameRide:rideEventNumber date:rideDate])  {
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
        if (outError != nil)
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

- (NSArray*) getStatsLeaders {
    return self.statsLeaders;
}

- (NSArray*) getStatsRiders {
    return self.statsRiders;
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

- (NSString*) fmtDate:(NSDate*) dt {
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    [f setDateFormat:@"MMM dd, yyy HH:mm"];
    NSString *ds = [f stringFromDate:dt];
    return ds;
}

/*- (NSString*) getCellContents:(NSString*) htmlIn tagName:(NSString *)tagName {
    NSString *tag = [NSString stringWithFormat:@"<td>%@</td>", tagName];
    return @"X";
}*/


- (void)loadAllFromRSSPage {
    NSURL *url = [NSURL URLWithString:@"http://westernwheelersbicycleclub.memberlodge.com/ride_calendar/RSS"];
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    NSURLResponse *resp =nil;
    NSError *err=nil;
    httpError=nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];
    NSInteger errNum = [err code];
    if (errNum != 0 ) {
        httpError = [err copy];
        [self addEvent:@"Unable to access internet"];
        return;
    }
    NSString *rssXml = [[NSString alloc] initWithData:responseData encoding: NSUTF8StringEncoding];
    
    //loop thru xml data looking for ride <items>

    //Dates are in GMT time zone in the RSS feed but need to displayed in PST on the app
    //They are not necessarily displayed in the users loca time zone.
    //e.g. even if the user is visiting Europe the ride schedule should still show PDT time
    NSDateFormatter *dateFormatGMT = [[NSDateFormatter alloc] init];
    [dateFormatGMT setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [dateFormatGMT setLocale:[NSLocale currentLocale]];
    [dateFormatGMT setFormatterBehavior:NSDateFormatterBehaviorDefault];
    [dateFormatGMT setDateFormat:@"dd MMM yyyy HH:mm:ss"];

    //NSTimeZone *timezonePDT = [NSTimeZone systemTimeZone];
    //NSLog(@"%@", [NSTimeZone knownTimeZoneNames]);
    NSTimeZone* timezonePDT = [NSTimeZone timeZoneWithName:@"America/Los_Angeles"];

    int totRidesScanned=0;
    int totRidesAdded=0;
    
    //locate where to start scanning for <item>s
    NSRange startRng;
    startRng.location=0;
    startRng.length=rssXml.length;
    startRng = [rssXml rangeOfString:@"<item>" options:0 range:startRng];
    NSInteger offset = startRng.location;
    
    NSString* firstDate;
    NSString* lastDate;
    //rides in a series have the same rideid for each ride in the series. So within a single invocation of this
    //method the list may see the same rideid and so we also need to check for ride date to detect duplicate rides.
    //
    //12/24/2016 : decided to empty the ride list every time. This corrects the situation where a ride was previoulsy loaded
    //but then deleted from the web site. It also means when rides are appended to the list after the list already has rides the list then doesnt
    //need to be sorted (by date) so the newly added rides sort correctly relative to the existing ride list rides.
    self.rideList = [[NSMutableArray alloc] init];
    
    while (1) {
        NSString *event = [DataModel xmlTagData:@"item" data:rssXml offset:(int) offset];
        if (event==nil) break;
        NSString *eventTitle = [DataModel xmlTagData:@"title" data:event offset:0];
        NSString *eventDateStr = [DataModel xmlTagData:@"pubDate" data:event offset:0];
        NSRange rng;
        rng.location = 5;
        rng.length = 11;
        rng.length = 20;
        eventDateStr = [eventDateStr substringWithRange:rng];
        
        NSDate *eventDateGMT = [dateFormatGMT dateFromString:eventDateStr];
        
        if (eventDateGMT != nil) {
            int found=0;
            float offsetSeconds = [timezonePDT secondsFromGMTForDate:eventDateGMT];
            NSDate *eventDatePDT = [eventDateGMT dateByAddingTimeInterval:offsetSeconds];
            //NSLog(@"----> %@ [%@] [%@] %@",eventDateStr, eventDateGMT, eventDatePDT, eventTitle);
            Ride *newRide= [[Ride alloc] initFromEvent:event rideDate:eventDatePDT];
            if (true) {
                //check if we have it already from a previous load.
                //Rides are loaded whenever the app goes active so we only want rides added to the site since the last load.
                for (Ride *r in self.rideList) {
                    if ([newRide isSameRide:r.rideEventNumber date:r.rideDate]) {
                        found=1;
                        break;
                    }
                }
                if (found==0) {
                    [self.rideList addObject:newRide];
                    totRidesAdded++;
                }
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
    NSString *log = [NSString stringWithFormat:@"Load rides : %d website rides scanned from %@ to %@, %d new rides added to app", totRidesScanned, firstDate, lastDate, totRidesAdded];
    NSLog(@"%@", log);
    [self addEvent:log];
    
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
         [[NSNotificationCenter defaultCenter] postNotificationName:@"RideGeoLocated" object:nil userInfo:data];
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
    
    NSString *result = [in stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
    //result = [result  stringByReplacingOccurrencesOfString:@"&#39;" withString:@"'"];
    //result = [result  stringByReplacingOccurrencesOfString:@"â" withString:@"-"];
    return result;
}


@end
