//
//  PhotosByPhotographerMapViewController.m
//  Photomania
//
//  Created by CS193p Instructor.
//  Copyright (c) 2013 Stanford University. All rights reserved.
//

#import "PhotosByPhotographerMapViewController.h"
#import <MapKit/MapKit.h>
#import "Photo+Annotation.h"
#import "ImageViewController.h"
#import "Photographer+Create.h"
#import "AddPhotoViewController.h"

@interface PhotosByPhotographerMapViewController () <MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) NSArray *photosByPhotographer; // of Photo
@property (nonatomic, strong) ImageViewController *imageViewController; // can be nil
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addPhotoBarButtonItem;
@end

@implementation PhotosByPhotographerMapViewController

#pragma mark - Properties

// lazily fetch the photos by our photographer from Core Data

- (NSArray *)photosByPhotographer
{
    if (!_photosByPhotographer) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
        request.predicate = [NSPredicate predicateWithFormat:@"whoTook = %@", self.photographer];
        _photosByPhotographer = [self.photographer.managedObjectContext executeFetchRequest:request
                                                                                      error:NULL];
    }
    return _photosByPhotographer;
}

// when our photographer changes, clear out our photosByPhotographer
// and update the map (if self.mapView is even set at this point)

- (void)setPhotographer:(Photographer *)photographer
{
    _photographer = photographer;
    self.title = photographer.name;
    self.photosByPhotographer = nil;
    [self updateMapViewAnnotations];
    [self updateAddPhotoBarButtonItem]; // show "camera" button only if self.photographer.isUser
}

- (void)updateAddPhotoBarButtonItem
{
    if (self.addPhotoBarButtonItem) {
        BOOL canAddPhoto = self.photographer.isUser;
        NSMutableArray *rightBarButtonItems = [self.navigationItem.rightBarButtonItems mutableCopy];
        if (!rightBarButtonItems) rightBarButtonItems = [[NSMutableArray alloc] init];
        NSUInteger addPhotoBarButtonItemIndex = [rightBarButtonItems indexOfObject:self.addPhotoBarButtonItem];
        if (addPhotoBarButtonItemIndex == NSNotFound) {
            if (canAddPhoto) [rightBarButtonItems addObject:self.addPhotoBarButtonItem];
        } else {
            if (!canAddPhoto) [rightBarButtonItems removeObjectAtIndex:addPhotoBarButtonItemIndex];
        }
        self.navigationItem.rightBarButtonItems = rightBarButtonItems;
    }
}

// when the mapView outlet gets set, set its delegate to ourself
// also, update the annotations to be our photosByPhotographer (if set yet)

- (void)setMapView:(MKMapView *)mapView
{
    _mapView = mapView;
    self.mapView.delegate = self;
    [self updateMapViewAnnotations];
}

// remove all existing annotations from the map
// and add all of our photosByPhotographer to the map
// zoom the map to show them all
// if we are capable of showing a photo immediately
//   (i.e. self.imageViewController is not nil)
//   then pick one of the photos at random and show it

- (void)updateMapViewAnnotations
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView addAnnotations:self.photosByPhotographer];
    [self.mapView showAnnotations:self.photosByPhotographer animated:YES];
    if (self.imageViewController) {
        Photo *autoselectedPhoto = [self.photosByPhotographer firstObject];
        if (autoselectedPhoto) {
            [self.mapView selectAnnotation:autoselectedPhoto animated:YES];
            [self prepareViewController:self.imageViewController
                               forSegue:nil
                       toShowAnnotation:autoselectedPhoto];
        }
    }
}

// see if we can find an ImageViewController to show the selected annotation's image
// currently we look at the detail of a split view we are in (if any)

- (ImageViewController *)imageViewController
{
    id detailvc = [self.splitViewController.viewControllers lastObject];
    if ([detailvc isKindOfClass:[UINavigationController class]]) {
        detailvc = [((UINavigationController *)detailvc).viewControllers firstObject];
    }
    return [detailvc isKindOfClass:[ImageViewController class]] ? detailvc : nil;
}

#pragma mark - MKMapViewDelegate

// enhances our callout to have left (UIImageView) and right (UIButton) accessory views
// only does this if we are going to need to segue to a different VC to show a photo
//  (because, if not (i.e. self.imageViewController is not nil), the photo will already be on screen
//   so there is no reason to show its thumbnail or make the user click again on disclosure button)

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    static NSString *reuseId = @"PhotosByPhotographerMapViewController";
    MKAnnotationView *view = [mapView dequeueReusableAnnotationViewWithIdentifier:reuseId];
    if (!view) {
        view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                               reuseIdentifier:reuseId];
        view.canShowCallout = YES;
        if (!self.imageViewController) {
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 46, 46)];
            view.leftCalloutAccessoryView = imageView;
            UIButton *disclosureButton = [[UIButton alloc] init];
            [disclosureButton setBackgroundImage:[UIImage imageNamed:@"disclosure"] forState:UIControlStateNormal];
            [disclosureButton sizeToFit];
            view.rightCalloutAccessoryView = disclosureButton;
        }
    }
    
    view.annotation = annotation;
    
    return view;
}

// called when the MKAnnotationView (the pin) is clicked on
// either updates the left callout accessory (UIImageView)
// or shows the Photo annotation in self.imageViewController (if available)

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    if (self.imageViewController) {
        [self prepareViewController:self.imageViewController
                           forSegue:nil
                   toShowAnnotation:view.annotation];
    } else {
        [self updateLeftCalloutAccessoryViewInAnnotationView:view];
    }
}

// checks to be sure that the annotationView's left callout is a UIImageView
// if it is and if the annotation is a Photo, then shows the thumbnail
// this should do that fetch in another thread
// but when the thumbnail image came back, it would need to double check the annotationView
// to be sure it is still displaying the annotation for which we fetched
// (because MKAnnotationViews, like UITableViewCells, are reused)

- (void)updateLeftCalloutAccessoryViewInAnnotationView:(MKAnnotationView *)annotationView
{
    UIImageView *imageView = nil;
    if ([annotationView.leftCalloutAccessoryView isKindOfClass:[UIImageView class]]) {
        imageView = (UIImageView *)annotationView.leftCalloutAccessoryView;
    }
    if (imageView) {
        Photo *photo = nil;
        if ([annotationView.annotation isKindOfClass:[Photo class]]) {
            photo = (Photo *)annotationView.annotation;
        }
        if (photo) {
#warning Blocking main queue!
            imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:photo.thumbnailURL]]];
        }
    }
}

// called when the right callout accessory view is tapped
// (it is the only accessory view we have that inherits from UIControl)
// will crash the program if this View Controller does not have a @"Show Photo" segue
// in the storyboard

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    [self performSegueWithIdentifier:@"Show Photo" sender:view];
}

#pragma mark - Navigation

// if the annotation is a Photo, this passes its imageURL to vc (if vc is an ImageViewController)

- (void)prepareViewController:(id)vc
                     forSegue:(NSString *)segueIdentifier
             toShowAnnotation:(id <MKAnnotation>)annotation
{
    Photo *photo = nil;
    if ([annotation isKindOfClass:[Photo class]]) {
        photo = (Photo *)annotation;
    }
    if (photo) {
        if (![segueIdentifier length] || [segueIdentifier isEqualToString:@"Show Photo"]) {
            if ([vc isKindOfClass:[ImageViewController class]]) {
                ImageViewController *ivc = (ImageViewController *)vc;
                ivc.imageURL = [NSURL URLWithString:photo.imageURL];
                ivc.title = photo.title;
            }
        }
    }
}

// this is called when AddPhotoViewController unwinds back to us

- (IBAction)addedPhoto:(UIStoryboardSegue *)segue
{
    if ([segue.sourceViewController isKindOfClass:[AddPhotoViewController class]]) {
        AddPhotoViewController *apvc = (AddPhotoViewController *)segue.sourceViewController;
        Photo *addedPhoto = apvc.addedPhoto;
        if (addedPhoto) {
            [self.mapView addAnnotation:addedPhoto];
            [self.mapView showAnnotations:@[addedPhoto] animated:YES];
            self.photosByPhotographer = nil;
        } else {
            NSLog(@"AddPhotoViewController unexpectedly did not add a photo!");
        }
    }
}

// if sender is an MKAnnotationView, this calls prepareViewController:forSegue:toShowAnnotation:

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[AddPhotoViewController class]]) {
        AddPhotoViewController *apvc = (AddPhotoViewController *)segue.destinationViewController;
        apvc.photographerTakingPhoto = self.photographer;
    } else if ([sender isKindOfClass:[MKAnnotationView class]]) {
        [self prepareViewController:segue.destinationViewController
                           forSegue:segue.identifier
                   toShowAnnotation:((MKAnnotationView *)sender).annotation];
    }
}

@end
