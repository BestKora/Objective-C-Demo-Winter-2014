//
//  Photo+Annotation.m
//  Photomania
//

#import "Photo+Annotation.h"

@implementation Photo (Annotation)

- (CLLocationCoordinate2D)coordinate
{
    CLLocationCoordinate2D coordinate;
    
    coordinate.latitude = (self.latitude).doubleValue;
    coordinate.longitude = (self.longitude).doubleValue;
    
    return coordinate;
}


@end
