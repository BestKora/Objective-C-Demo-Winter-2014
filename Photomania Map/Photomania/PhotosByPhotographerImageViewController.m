//
//  PhotosByPhotographerImageViewController.m
//  Photomania
//
//  Created by CS193p Instructor.
//  Copyright (c) 2013 Stanford University. All rights reserved.
//

#import "PhotosByPhotographerImageViewController.h"
#import "PhotosByPhotographerMapViewController.h"

@interface PhotosByPhotographerImageViewController ()
// the embedded PhotosByPhotographerMapViewController
@property (nonatomic, strong) PhotosByPhotographerMapViewController *mapvc;
@end

@implementation PhotosByPhotographerImageViewController

- (void)setPhotographer:(Photographer *)photographer
{
    _photographer = photographer;
    self.title = photographer.name;
    // set the embedded PhotosByPhotographerMapViewController's Model
    // (in case our Model, the photographer, is set AFTER embedding happens)
    self.mapvc.photographer = self.photographer;
}

// embed segues are normal segues in that they must be prepared

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[PhotosByPhotographerMapViewController class]]) {
        PhotosByPhotographerMapViewController *pbpmapvc =
            (PhotosByPhotographerMapViewController *)segue.destinationViewController;
        // set the embedded PhotosByPhotographerMapViewController's Model
        pbpmapvc.photographer = self.photographer;
        // hold onto the embedded PhotosByPhotographerMapViewController
        // in case our Model is nil right now
        // and then set it later when our Model gets set by the photographer property's setter
        self.mapvc = pbpmapvc;
    } else {
        // not embedding, let our superclass do any segues it can do
        [super prepareForSegue:segue sender:sender];
    }
}

@end
