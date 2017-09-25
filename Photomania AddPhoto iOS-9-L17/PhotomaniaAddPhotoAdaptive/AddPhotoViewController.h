//
//  AddPhotoViewController.h
//  Photomania
//

#import <UIKit/UIKit.h>
#import "Photographer.h"
#import "Photo.h"

@interface AddPhotoViewController : UIViewController

// in
@property (nonatomic, strong) Photographer *photographerTakingPhoto;

// out
@property (nonatomic, readonly) Photo *addedPhoto;

@end
