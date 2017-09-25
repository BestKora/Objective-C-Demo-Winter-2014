//
//  PhotosByPhotographerImageViewController.m
//  Photomania
//
//

#import "PhotosByPhotographerImageViewController.h"
#import "PhotosByPhotographerMapViewController.h"

@interface PhotosByPhotographerImageViewController ()

// вставляемый PhotosByPhotographerMapViewController
@property (nonatomic, strong) PhotosByPhotographerMapViewController *mapvc;
@property (weak, nonatomic) IBOutlet UIView *containerView;

@end

@implementation PhotosByPhotographerImageViewController

- (void)setPhotographer:(Photographer *)photographer
{
    _photographer = photographer;
    self.title = photographer.name;
    
    // устанавливаем Model для вставляемого PhotosByPhotographerMapViewController
    // (на случай, если наша Model, photographer, устанавливается ПОСЛЕ того,
    //  как произошла вставка )
    self.mapvc.photographer = self.photographer;
}


// embed segues - это нормальные segues, которые мы должны быть подготовлены

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController
                     isKindOfClass:[PhotosByPhotographerMapViewController class]]) {
        PhotosByPhotographerMapViewController *pbpmapvc =
               (PhotosByPhotographerMapViewController *)segue.destinationViewController;
        
        // устанавливаем Model для вставляемого PhotosByPhotographerMapViewController
        
        pbpmapvc.photographer = self.photographer;
        
        // удерживаем вставляемый PhotosByPhotographerMapViewController
        // в случае, если наша Model равна nil прямо в данный момент
        // и устанавливаем его позже, когда наша Model установится с помощью
        // setter свойства photographer
        
        self.mapvc = pbpmapvc;
        
    } else {
        
        // нет вставки, позволим нашему superclass выполнить любые segues,
        // какие он может
        [super prepareForSegue:segue sender:sender];
    }
}
- (IBAction)hide:(UIBarButtonItem *)sender {
    if (!self.containerView.hidden) {
        self.containerView.hidden = YES;
        sender.title = @"ShowMap";
    } else {
        self.containerView.hidden = NO;
        sender.title = @"HideMap";
    }

}

@end
