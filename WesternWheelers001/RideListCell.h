#import <Foundation/Foundation.h>

@interface RideListCell : UITableViewCell

+ (NSString *)reuseIdentifier;

@property (weak, nonatomic) IBOutlet UILabel *lblDate;

@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UILabel *lblId;

@property (weak, nonatomic) IBOutlet UILabel *lblLevel;

@property (weak, nonatomic) IBOutlet UILabel *lblImpromtu;
@end
