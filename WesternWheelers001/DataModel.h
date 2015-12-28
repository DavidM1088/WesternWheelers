#import <Foundation/Foundation.h>
#import "Ride.h"

extern int RIDESET_ALL;
extern int RIDESET_LEVEL;
extern int RIDESET_SEARCH;

@interface DataModel : NSObject {
    NSMutableArray *_rideList;
    NSMutableArray *_eventLog;
    NSMutableArray *_statsLeaders;
    NSMutableArray *_statsRiders;
}

+(DataModel *) getInstance;
+(NSString*) decodeHtml: (NSString*) in;
+(NSString *) getStringBoundedBy:(NSString*) instr start:(NSString*) startStr end:(NSString*) endStr;
+(NSString*) xmlTagData:(NSString*) tag data:(NSString*) inData offset:(int) offset;

-(NSArray *) getEventLog;
- (void) addEvent:(NSObject*) event;
- (NSArray*) getRides:(int) type tag:(NSString*) tag error:(NSError **)outError;
- (NSArray*) getStatsLeaders;
- (NSArray*) getStatsRiders;
- (void) getRideDetails:(NSString*) rideId rideDate:(NSDate*) rideDate;

@property (nonatomic, strong) NSMutableArray *rideList;
@property (nonatomic, strong) NSMutableArray *statsLeaders;
@property (nonatomic, strong) NSMutableArray *statsRiders;

@property int currentRideSetType;
@property (nonatomic, strong) NSString *currentRideSetTag;


@end
