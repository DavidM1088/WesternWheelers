#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

@interface Ride : NSObject

- (Ride*)initFromEvent:(NSString*) anchor rideDate:(NSDate*) date;
- (BOOL) isOfLevel:(NSString*) level;
- (BOOL) matchesTag:(NSString*) tag;
- (BOOL) isSameRide:(NSString*) rideEventNumber date:(NSDate*) rideDate;
//- (BOOL) isSameRide:(Ride*) anotherRide;

@property (strong, nonatomic) NSString* rideEventNumber;
@property (strong, nonatomic) NSString* anchorData; //data from html tag
@property (strong, nonatomic) NSString* rssData;
@property (strong, nonatomic) NSString* htmlLink;
@property (strong, nonatomic) NSString* title;
@property (strong, nonatomic) NSString* rideLevel;
@property (strong, nonatomic) NSDate* rideDate;
@property (strong, nonatomic) NSString* dayOfWeek;
@property (strong, nonatomic) NSString* locationDescription;
@property BOOL allDetailsLoaded;
@property BOOL isImpromtu;
@property (nonatomic) CLLocationCoordinate2D locationPoint;
@property (strong, nonatomic) NSString* startTime;

@end
