#import "Ride.h"
#import "DataModel.h"

@implementation Ride

- (Ride*) init {
    self.htmlLink=@"";
    self.title =@"";
    self.rideEventNumber=@"";
    self.allDetailsLoaded=NO;
    return self;
}

- (Ride*)initFromEvent:(NSString*) data rideDate: (NSDate*) date {
    self.rssData=data;
    self.rideDate=nil;
    self.allDetailsLoaded=NO;
    self.rideDate=date;
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comps = [cal components:(NSWeekdayCalendarUnit) fromDate:date];
    int weekday = (int) [comps weekday];
    if (weekday == 1) self.dayOfWeek = @"Sunday";
    if (weekday == 2) self.dayOfWeek = @"Monday";
    if (weekday == 3) self.dayOfWeek = @"Tuesday";
    if (weekday == 4) self.dayOfWeek = @"Wednesday";
    if (weekday == 5) self.dayOfWeek = @"Thursday";
    if (weekday == 6) self.dayOfWeek = @"Friday";
    if (weekday == 7) self.dayOfWeek = @"Saturday";

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

- (BOOL) isSameRide:(NSString*) rideEventNumber date:(NSDate*) rideDate {
    //More than one ride in a series may have the same identifier. Therefore to know its the exact same ride check ride id and ride date.
    return ([rideEventNumber isEqualToString:self.rideEventNumber] && [rideDate compare:self.rideDate] == NSOrderedSame);
}

/*- (BOOL) isSameRide:(Ride*) anotherRide {
    //More than one ride in a series may have the same identifier. Therefore to know its the exact same ride check ride id and ride date.
    return ([self isEqual:anotherRide.rideEventNumber date:anotherRide.rideDate]);
}*/

- (BOOL) matchesTag:(NSString*) tag {
    if ([self.title rangeOfString:tag options:NSCaseInsensitiveSearch].location != NSNotFound) return YES;
    if ([self.dayOfWeek rangeOfString:tag options:NSCaseInsensitiveSearch].location != NSNotFound) return YES;
    //if ([self.locationDescription rangeOfString:tag options:NSCaseInsensitiveSearch].location != NSNotFound) return YES;
    return NO;
}

- (void) parseRss {
    self.htmlLink = [DataModel xmlTagData:@"link" data:self.rssData offset:0];
    self.title = [DataModel xmlTagData:@"title" data:self.rssData offset:0];
    self.rideEventNumber = [DataModel getStringBoundedBy:self.htmlLink start:@"event-" end:nil];
    
    //strip the date out of the title. Search backwards for begnning of date in parenthesis (date)
    unsigned long i;
    for (i=[self.title length]-1; i>0; i--) {
        unichar ch = [self.title characterAtIndex:i];
        if (ch == '(') {
            NSRange rng;
            rng.location = 0;
            rng.length = i;
            self.title = [self.title substringWithRange:rng];
            break;
        }
    }
    //NSString *res = [self.title substringWithRange:rngScan];
    [self buildRideData];
}

- (void) buildRideData {
    //self.title = @"***IMPROMPTU** C/4 (3,798')/41 PAGE MILL (Sat, December 12, 2015) fails parse 12/10/2015";
    //self.title = @"LDT SUNDAY RIDE: HEALDSBURG TO SWEETWATER SPRINGS  BC/2(1500’)/30; CD/3!(2300’)/37";
    //self.title = @"LDT RIDE: SHORELINE  B/1/(600’)/33; C/1.5(1600’)/37; D/2(2000’)/44; E/2(3000’)/52";
    
    self.title = [self.title stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
    self.title = [DataModel decodeHtml:self.title];
    
    NSRange rngTemp = [self.title rangeOfString:@"Pedaling" options:NSCaseInsensitiveSearch];
    if (rngTemp.location != NSNotFound) {
        rngTemp = rngTemp;
    }

    NSRange rng = [self.title rangeOfString:@"Impromptu" options:NSCaseInsensitiveSearch];
    if (rng.location != NSNotFound) {
        self.isImpromtu=YES;
        //self.title = [DataModel getStringBoundedBy:self.title start:@" " end:nil];
    }
    else {
        self.isImpromtu=NO;
    }
    
    //parse out words with "/" as representing the ride meta data, all others as ride title
    NSString *metadata = @"";
    NSString *rideTitle = @"";
    NSMutableArray *words = [NSMutableArray arrayWithArray:[self.title componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
    [words removeObjectIdenticalTo:@""];
    for (NSString* word in words) {
        NSString *wordTrimmed = [word stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
        NSRange rngScan = [wordTrimmed rangeOfString:@"/"];
        if (rngScan.location!=NSNotFound) {
            metadata = [metadata stringByAppendingString:wordTrimmed];
            metadata = [metadata stringByAppendingString:@" "];
        }
        else {
            if (!([wordTrimmed isEqualToString:@"***IMPROMPTU**"])) {
                rideTitle = [rideTitle stringByAppendingString:wordTrimmed];
                rideTitle = [rideTitle stringByAppendingString:@" "];
            }
        }
    }
    
    self.title = rideTitle;
    self.rideLevel = [DataModel decodeHtml:metadata];
    self.locationDescription = [DataModel decodeHtml:self.locationDescription];
    //NSLog(@"Level:%@ title:%@", self.rideLevel, self.title);
}

@end
