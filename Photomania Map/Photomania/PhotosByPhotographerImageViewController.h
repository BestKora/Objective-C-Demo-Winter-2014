//
//  PhotosByPhotographerImageViewController.h
//  Photomania
//
//  Created by CS193p Instructor.
//  Copyright (c) 2013 Stanford University. All rights reserved.
//

#import "ImageViewController.h"
#import "Photographer.h"

@interface PhotosByPhotographerImageViewController : ImageViewController

// our Model
// passed through to our embedded controller
@property (nonatomic, strong) Photographer *photographer;

@end
