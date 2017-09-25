//
//  AddPhotoViewController.h
//  Photomania
//
//  Created by CS193p Instructor.
//  Copyright (c) 2013 Stanford University. All rights reserved.
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
