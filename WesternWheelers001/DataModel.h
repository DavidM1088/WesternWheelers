#import <Foundation/Foundation.h>
#import "Ride.h"

extern int RIDESET_ALL;
extern int RIDESET_LEVEL;
extern int RIDESET_SEARCH;

@interface DataModel : NSObject {
    NSMutableArray *_rideList;
    NSMutableArray *_eventLog;
}

+(DataModel *) getInstance;
+(NSString*) decodeHtml: (NSString*) in;
+(NSString *) getStringBoundedBy:(NSString*) instr start:(NSString*) startStr end:(NSString*) endStr;
+(NSString*) xmlTagData:(NSString*) tag data:(NSString*) inData offset:(int) offset;

-(NSArray *) getEventLog;
- (void) addEvent:(NSObject*) event;
- (NSArray*) getRides:(int) type tag:(NSString*) tag error:(NSError **)outError;
- (void) getRideDetails:(NSString*) rideId;

@property (nonatomic, strong) NSMutableArray *rideList;
@property int currentRideSetType;
@property (nonatomic, strong) NSString *currentRideSetTag;


@end
