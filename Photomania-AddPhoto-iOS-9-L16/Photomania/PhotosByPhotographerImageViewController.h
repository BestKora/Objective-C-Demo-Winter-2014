//
//  PhotosByPhotographerImageViewController.h
//  Photomania
//
//

#import "ImageViewController.h"
#import "Photographer.h"

@interface PhotosByPhotographerImageViewController : ImageViewController

// наша Model
// передается насквозь в наш embedded controller
@property (nonatomic, strong) Photographer *photographer;

@end
