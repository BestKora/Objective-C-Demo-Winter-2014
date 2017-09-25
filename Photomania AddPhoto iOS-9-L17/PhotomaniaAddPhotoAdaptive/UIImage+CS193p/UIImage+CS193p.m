//
//  UIImage+CS193p.m
//  Photomania
//
//  Created by CS193p Instructor.
//  Copyright (c) 2013 Stanford University. All rights reserved.
//

#import "UIImage+CS193p.h"

@implementation UIImage (CS193p)

- (UIImage *)imageByScalingToSize:(CGSize)size
{
    UIGraphicsBeginImageContextWithOptions(size, YES, 0.0);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resizedImage;
}

- (UIImage *)imageByApplyingFilterNamed:(NSString *)filterName
{
    UIImage *filteredImage = self;

    //Step 1: создаем CIImage объект
    CIImage *inputImage = [CIImage imageWithCGImage:[self CGImage]];
    if (inputImage) {
        //Step 2: получаем фильтр
        CIFilter *filter = [CIFilter filterWithName:filterName];
        //Step 3: снабжаем аргументами
        [filter setValue:inputImage forKey:kCIInputImageKey];
        //Step 4: получаем выходное изображение image
        CIImage *outputImage = [filter outputImage];
        if (outputImage) {
            filteredImage = [UIImage imageWithCIImage:outputImage];
            if (filteredImage) {
                //Step 5: рисуем его внутри нового image
                UIGraphicsBeginImageContextWithOptions(self.size, YES, 0.0);
                [filteredImage drawInRect:CGRectMake(0, 0, self.size.width, self.size.height)];
                filteredImage = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
            }
        }
    }
    
    return filteredImage;
}

@end
