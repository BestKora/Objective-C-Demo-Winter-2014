//
//  PhotosByPhotographerMapViewController.h
//  Photomania
//
//  Created by CS193p Instructor.
//  Copyright (c) 2013 Stanford University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Photographer.h"

@interface PhotosByPhotographerMapViewController : UIViewController

// our Model
// we will show all photos by this photographer on a map
@property (nonatomic, strong) Photographer *photographer;

@end
