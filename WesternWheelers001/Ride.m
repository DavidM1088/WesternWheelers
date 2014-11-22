#import "Ride.h"
#import "DataModel.h"

@implementation Ride

static int loadNumber=0;

- (Ride*) init {
    self.htmlLink=@"html";
    self.title =@"desc";
    self.rideid=@"no id";
    self.loadnum = [NSNumber numberWithInt:loadNumber++];
    self.allDetailsLoaded=NO;
    return self;
}

- (Ride*)initFromEvent:(NSString*) data rideDate: (NSDate*) date {
    self.loadnum = [NSNumber numberWithInt:loadNumber++];
    //self.anchor=data;
    self.rssData=data;
    self.rideDate=nil;
    self.allDetailsLoaded=NO;
    self.rideDate=date;
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comps = [cal components:(NSWeekdayCalendarUnit) fromDate:date];
    int weekday = [comps weekday];
    if (weekday == 1) self.dayOfWeek = @"Sunday";
    if (weekday == 2) self.dayOfWeek = @"Monday";
    if (weekday == 3) self.dayOfWeek = @"Tuesday";
    if (weekday == 4) self.dayOfWeek = @"Wednesday";
    if (weekday == 5) self.dayOfWeek = @"Thursday";
    if (weekday == 6) self.dayOfWeek = @"Friday";
    if (weekday == 7) self.dayOfWeek = @"Saturday";

    //[self parseHtmlAnchor_unused];
    [self parseRss];
    return self;
}

- (NSComparisonResult) compareDates:(Ride *)other {
    if ([self.rideDate compare:other.rideDate]==NSOrderedSame) {
        return [self.rideLevel compare:other.rideLevel];
    }
    else {
        return [self.rideDate compare:other.rideDate];
    }
}

- (BOOL) isOfLevel:(NSString*) level {
    if (self.rideLevel==nil) return NO;
    NSRange rng = [self.rideLevel rangeOfString:level ];
    return (rng.location != NSNotFound);
}

- (BOOL) matchesTag:(NSString*) tag {
    if ([self.title rangeOfString:tag options:NSCaseInsensitiveSearch].location != NSNotFound) return YES;
    if ([self.dayOfWeek rangeOfString:tag options:NSCaseInsensitiveSearch].location != NSNotFound) return YES;
    //if ([self.locationDescription rangeOfString:tag options:NSCaseInsensitiveSearch].location != NSNotFound) return YES;
    return NO;
}

- (void) parseRss {
    self.htmlLink = [DataModel xmlTagData:@"link" data:self.rssData offset:0];
    self.title = [DataModel xmlTagData:@"title" data:self.rssData offset:0];
    self.rideid = [DataModel getStringBoundedBy:self.htmlLink start:@"event-" end:nil];
    //self.locationDescription=@"loc desc?"; this is not avaialble in the rss xml but was available in the html parse version
    
    //strip the date out of the title. Ssearch backwards for begnning of date in parenthesis (date)
    int i;
    for (i=[self.title length]-1; i>0; i--) {
        unichar ch = [self.title characterAtIndex:i];
        if (ch == '(') {
            NSRange rng;
            rng.location = 0;
            rng.length = i;
            self.title = [self.title substringWithRange:rng];
            break;
        }
    }    //NSString *res = [self.title substringWithRange:rngScan];
    [self buildRideData];

    
}

- (void) parseHtmlAnchor_unused {
    self.htmlLink = [DataModel getStringBoundedBy:self.anchorData start:@"href=\"" end:@"&"];
    self.locationDescription = [DataModel getStringBoundedBy:self.anchorData start:@"title=\"" end:@"\">"];
    self.rideid = [DataModel getStringBoundedBy:self.anchorData start:@"eventId=" end:@"&"];
    self.title = [DataModel getStringBoundedBy:self.anchorData start:@">" end:nil];
    self.title = [DataModel getStringBoundedBy:self.title start:@">" end:nil]; //skip tabs..
    self.title = [DataModel getStringBoundedBy:self.title start:@">" end:@"<"];
    [self buildRideData];
}

- (void) buildRideData {
    NSRange rng = [self.title rangeOfString:@"Impromptu"];
    if (rng.location != NSNotFound) {
        self.isImpromtu=YES;
        self.title = [DataModel getStringBoundedBy:self.title start:@" " end:nil];
    }
    else {
        self.isImpromtu=NO;
    }
    NSRange rngScan = [self.title rangeOfString:@"LDT"];
    self.title = [self.title stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];

    if (rngScan.location==NSNotFound) {
        self.rideLevel = [DataModel getStringBoundedBy:self.title start:nil end:@" "];
        //strip out the ride level from the title
        self.title = [DataModel getStringBoundedBy:self.title start:self.rideLevel end:nil];
        rngScan = [self.title rangeOfString:@" - "];
        if (rngScan.location != NSNotFound) {
            self.title = [DataModel getStringBoundedBy:self.title start:@" - " end:nil];
        }
    }
    else {
        //LDTs have inconsistent ride level syntax, even with each other :( "eg if level is BCD/2-3(2000) it is parsed as null. 
        self.rideLevel = [DataModel getStringBoundedBy:self.title start:@"B/" end:nil];
        self.rideLevel = [NSString stringWithFormat:@"B/%@", self.rideLevel];
        NSString *kept = self.title;
        self.title = [DataModel getStringBoundedBy:self.title start:nil end:self.rideLevel];
        self.title = [self.title stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
        if (self.title.length==0) {
            self.title = kept; //give up parsing it..
        }

    }
    self.title = [self.title stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
    self.title = [DataModel decodeHtml:self.title];
    self.rideLevel = [DataModel decodeHtml:self.rideLevel];
    self.locationDescription = [DataModel decodeHtml:self.locationDescription];
}


@end
