//
//  ImageViewController.h
//  Imaginarium
//
//  Created by CS193p Instructor.
//  Copyright (c) 2013 Stanford University. All rights reserved.
//

#import <UIKit/UIKit.h>

// будет передавать свой imageURL при "переезде" на URLViewController
// (это показывается в popover)

@interface ImageViewController : UIViewController

// Модель для этого MVC ... URL изображения image для показа на экране
@property (nonatomic, strong) NSURL *imageURL;

@end
