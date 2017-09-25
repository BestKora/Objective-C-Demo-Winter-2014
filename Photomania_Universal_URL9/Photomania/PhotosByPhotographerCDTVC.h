//
//  PhotosByPhotographerCDTVC.h
//  Photomania
//
//  Created by CS193p Instructor.
//  Copyright (c) 2013 Stanford University. All rights reserved.
//PhotosCDTVC

#import "PhotosCDTVC.h"
#import "Photographer.h"

// этот класс наследует способность показывать Photo в своих строках
// и способность к навигации для показа изображения Photo
// от своего superclass PhotosCDTVC

@interface PhotosByPhotographerCDTVC :PhotosCDTVC

@property (nonatomic, strong) Photographer *photographer;

@end
