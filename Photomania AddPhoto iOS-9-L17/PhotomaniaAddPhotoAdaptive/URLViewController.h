//
//  URLViewController.h
//  Photomania
//
//  Created by CS193p Instructor.
//  Copyright (c) 2013 Stanford University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface URLViewController : UIViewController

// показывает url
// это специализированный popover класс
// он будет работать в любой среде
// (например, для push в navigation controller)

@property (nonatomic, strong) NSURL *url;

@end
