//
//  UIImage+CS193p.h
//  Photomania
//
//  Created by CS193p Instructor.
//  Copyright (c) 2013 Stanford University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (CS193p)

// создает копию другого размера
- (UIImage *)imageByScalingToSize:(CGSize)size;

// применяет фильтры, которые обсуждались на секции в Пятницу
- (UIImage *)imageByApplyingFilterNamed:(NSString *)filterName;

@end
