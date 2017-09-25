//
//  PhotosByPhotographerMapViewController.m
//  Photomania
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
@property (nonatomic, strong) ImageViewController *imageViewController; // может быть nil
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addPhotoBarButtonItem;

@end

@implementation PhotosByPhotographerMapViewController

// Смотрим, можем ли мы найти ImageViewController
// чтобы показать изображение выбранного annotation,
// мы смотрим на detail того split view, в котором мы находимся
// (если действительно находимся)

- (ImageViewController *)imageViewController
{
    id detailvc = (self.splitViewController.viewControllers).lastObject;
    if ([detailvc isKindOfClass:[UINavigationController class]]) {
        detailvc = (((UINavigationController *)detailvc).viewControllers).firstObject;
    }
    return [detailvc isKindOfClass:[ImageViewController class]] ? detailvc : nil;
}

#pragma mark - Properties
// lazily выборка photos by our photographer из Core Data

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

// когда устанавливается outlet mapView, устанавливаем его делегатом этот VC

- (void)setMapView:(MKMapView *)mapView
{
    _mapView = mapView;
    self.mapView.delegate = self;
    [self updateMapViewAnnotations];
}


// убирает все существующие annotations с карты
// и добавляет все наши photosByPhotographer на карту
// изменяет масштаб карты для показа их всех
// если мы способны показывать фото незамедлительно
//   (например, в случае, если self.imageViewController не равен nil)
//   тогда случайно выбираем одну из фотографий и показываем ее

- (void)updateMapViewAnnotations
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView addAnnotations:self.photosByPhotographer];
    [self.mapView showAnnotations:self.photosByPhotographer animated:YES];
    if (self.imageViewController) {
        Photo *autoselectedPhoto = (self.photosByPhotographer).firstObject;
        if (autoselectedPhoto) {
            [self.mapView selectAnnotation:autoselectedPhoto animated:YES];
            [self prepareViewController:self.imageViewController
                               forSegue:nil
                       toShowAnnotation:autoselectedPhoto];
        }
    }
}

- (void)setPhotographer:(Photographer *)photographer
{
    _photographer = photographer;
    self.title = photographer.name;
    self.photosByPhotographer = nil;
    [self updateMapViewAnnotations];
    
    // показываем кнопку "camera" только если self.photographer.isUser
    [self updateAddPhotoBarButtonItem];

}

- (void)updateAddPhotoBarButtonItem
{
    if (self.addPhotoBarButtonItem) {
        BOOL canAddPhoto = self.photographer.isUser;
        NSMutableArray *rightBarButtonItems = [self.navigationItem.rightBarButtonItems mutableCopy];
        if (!rightBarButtonItems) rightBarButtonItems = [[NSMutableArray alloc] init];
        NSUInteger addPhotoBarButtonItemIndex =
                                    [rightBarButtonItems indexOfObject:self.addPhotoBarButtonItem];
        if (addPhotoBarButtonItemIndex == NSNotFound) {
            if (canAddPhoto) [rightBarButtonItems addObject:self.addPhotoBarButtonItem];
        } else {
            if (!canAddPhoto) [rightBarButtonItems removeObjectAtIndex:addPhotoBarButtonItemIndex];
        }
        self.navigationItem.rightBarButtonItems = rightBarButtonItems;
    }
}


#pragma mark - MKMapViewDelegate

// улучшаем нашу выноску (callout), чтобы у нее были левое (UIImageView)
// и правое (UIButton) вспомогательные views
// делаем это только, если нам нужно "перезжать" на другой VC, чтобы показать фотографию
//  (потому что, если нет (например, self.imageViewController не равно nil),
// и фотография уже находится на экране, то нет причины показывать ее миниатюру
// и заставлять пользователя опять кликать на кнопке disclosure)

- (MKAnnotationView *)mapView:(MKMapView *)mapView
            viewForAnnotation:(id<MKAnnotation>)annotation
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
            [disclosureButton setBackgroundImage:[UIImage imageNamed:@"disclosure"]
                                        forState:UIControlStateNormal];
            [disclosureButton sizeToFit];
            view.rightCalloutAccessoryView = disclosureButton;
        }
    }
    view.annotation = annotation;
    return view;
}


// вызывается, когда мы кликаем на MKAnnotationView ("булавке")
// либо обновляет левое вспомогательное view  (UIImageView)
// или показывает Photo annotation в in self.imageViewController (если он есть)

- (void)mapView:(MKMapView *)mapView
                            didSelectAnnotationView:(MKAnnotationView *)view
{
    
    if (self.imageViewController) {
        [self prepareViewController:self.imageViewController
                           forSegue:nil
                   toShowAnnotation:view.annotation];
    
    } else {
        [self updateLeftCalloutAccessoryViewInAnnotationView:view];
    }
}

// делаем проверку, чтобы убедиться, что левый view в callout, это UIImageView,
// если это так, и если annotation является Photo, тогда показываем миниатюру,
// для получения которой нам следует делать выборку в другом потоке,
// но, когда миниатюра возвращается, было бы хорошо проверить annotationView,
// чтобы убедиться, что все еще показывается тот же annotation, для которого мы делали выборку
// (потому что MKAnnotationViews, как и UITableViewCells, являются повторно используемыми)

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
            imageView.image = [UIImage imageWithData:
                    [NSData dataWithContentsOfURL:[NSURL URLWithString:photo.thumbnailURL]]];
        }
    }
}

// вызывается, когда "тапаем" по right callout accessory view
// (это единственный accessory view, который у нас наследует от UIControl)
// это "обрушит" приложение, если у этого View Controller не будет
//  @"Show Photo" segue на storyboard

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view
                                      calloutAccessoryControlTapped:(UIControl *)control
{
   
    [self performSegueWithIdentifier:@"Show Photo" sender:view];
}

#pragma mark - Navigation

// Если annotation, это Photo, то vc передается
// его imageURL(если vc это ImageViewController)

- (void)prepareViewController:(id)vc
                     forSegue:(NSString *)segueIdentifier
             toShowAnnotation:(id <MKAnnotation>)annotation
{
    Photo *photo = nil;
    if ([annotation isKindOfClass:[Photo class]]) {
        photo = (Photo *)annotation;
    }
    if (photo) {
        if (!segueIdentifier.length || [segueIdentifier isEqualToString:@"Show Photo"])
        {
            if ([vc isKindOfClass:[ImageViewController class]]) {
                ImageViewController *ivc = (ImageViewController *)vc;
                ivc.imageURL = [NSURL URLWithString:photo.imageURL];
                ivc.title = photo.title;
            }
        }
    }
}

// этот метод вызывается, когда AddPhotoViewController отсоединяется назад к нам

- (IBAction)addedPhoto:(UIStoryboardSegue *)segue
{
    if ([segue.sourceViewController isKindOfClass:[AddPhotoViewController class]]) {
        AddPhotoViewController *apvc =
                               (AddPhotoViewController *)segue.sourceViewController;
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


// Если sender -это  MKAnnotationView, а это так и есть,
// то вызывается prepareViewController:forSegue:toShowAnnotation:

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[AddPhotoViewController class]]) {
        AddPhotoViewController *apvc =
                               (AddPhotoViewController *)segue.destinationViewController;
        apvc.photographerTakingPhoto = self.photographer;
        
    } else if ([sender isKindOfClass:[MKAnnotationView class]]) {
        [self prepareViewController:segue.destinationViewController
                           forSegue:segue.identifier
                   toShowAnnotation:((MKAnnotationView *)sender).annotation];
    }
}

@end
