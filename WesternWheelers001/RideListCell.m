#import "RideListCell.h"

@implementation RideListCell

// see http://agilewarrior.wordpress.com/2012/05/19/how-to-add-a-custom-uitableviewcell-to-a-xib-file-objective-c/

+ (NSString *)reuseIdentifier {
    return @"CustomCellIdentifier";
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    return self;
}

@end
