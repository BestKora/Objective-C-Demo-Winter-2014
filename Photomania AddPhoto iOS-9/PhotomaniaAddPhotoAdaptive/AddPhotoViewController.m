//
//  AddPhotoViewController.m
//  Photomania
//

#import "AddPhotoViewController.h"
#import "Photo.h"
#import <CoreLocation/CoreLocation.h>
#import <MobileCoreServices/MobileCoreServices.h>   // kUTTypeImage
#import "UIImage+CS193p.h"                          // thumbnail и методы фильтрации

@interface AddPhotoViewController ()<UITextFieldDelegate, CLLocationManagerDelegate,
                    UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet UITextField *subtitleTextField;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) UIImage *image;
@property (strong, nonatomic) CLLocation *location;
@property (strong, nonatomic) NSURL *imageURL;
@property (strong, nonatomic) NSURL *thumbnailURL;
@property (strong, nonatomic, readwrite) Photo *addedPhoto;
@property (strong, nonatomic) CLLocationManager *locationManager;

@property (nonatomic) NSInteger locationErrorCode;

@end

@implementation AddPhotoViewController
#pragma mark - Capabilities

// возможно он должен быть public
// потому что presenters могли бы вначале проверять, стоит ли это делать

+ (BOOL)canAddPhoto
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        if ([availableMediaTypes containsObject:(NSString *)kUTTypeImage]) {
            if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusRestricted) {
                return YES;
            }
        }
    }
    return NO;
}

#pragma mark - Target/Action

- (IBAction)cancel
{
    self.image = nil; // чистим временные файлы
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)takePhoto
{
    UIImagePickerController *uiipc = [[UIImagePickerController alloc] init];
    uiipc.delegate = self;
    uiipc.mediaTypes = @[(NSString *)kUTTypeImage];
    uiipc.sourceType = UIImagePickerControllerSourceTypeCamera;
    uiipc.allowsEditing = YES;
    [self presentViewController:uiipc animated:YES completion:NULL];
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker
                           didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerEditedImage];
    if (!image) image = info[UIImagePickerControllerOriginalImage];
    self.image = image;
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - View Controller Lifecycle

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
       if (![[self class] canAddPhoto]) {
        [self fatalAlert:@"Sorry, this device cannot add a photo."];
    } else {
        [self.locationManager startUpdatingLocation];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // это все равно произойдет, когда вы покинете "кучу",
    // но просто для уверенности ...
    [self.locationManager stopUpdatingLocation];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.image = [UIImage imageNamed:@"flower.jpg"];
}

#pragma mark - Location

- (CLLocationManager *)locationManager
{
    if (!_locationManager) {
        CLLocationManager *locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        // -------добавлено для iOS 9-----
        if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
        {
            [locationManager requestWhenInUseAuthorization];
        }
        // -------------------------------
        
        _locationManager = locationManager;
    }
    return _locationManager;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    self.location = [locations lastObject];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    self.locationErrorCode = error.code;
}



#pragma mark - Navigation

#define UNWIND_SEGUE_IDENTIFIER @"Do Add Photo"

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:UNWIND_SEGUE_IDENTIFIER])
    {
        NSManagedObjectContext *context =
                            self.photographerTakingPhoto.managedObjectContext;
        if (context) {
            Photo *photo = [NSEntityDescription
                            insertNewObjectForEntityForName:@"Photo"
                                     inManagedObjectContext:context];
            photo.title = self.titleTextField.text;
            photo.subtitle = self.subtitleTextField.text;
            photo.whoTook = self.photographerTakingPhoto;
            
            photo.latitude = @(self.location.coordinate.latitude);
            photo.longitude = @(self.location.coordinate.longitude);
            photo.imageURL = [self.imageURL absoluteString];
            photo.thumbnailURL = [self.thumbnailURL absoluteString];
            
            self.addedPhoto = photo;
            
            self.imageURL = nil; // эти URL уже были использованы
            self.thumbnailURL = nil;

          }
    }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:UNWIND_SEGUE_IDENTIFIER]) {
        if (!self.image) {
            [self alert:@"No photo taken!"];
            return NO;
        } else if (![self.titleTextField.text length]) {
            [self alert:@"Title required!"];
            return NO;
        }  else if (!self.location) {
            switch (self.locationErrorCode) {
                case kCLErrorLocationUnknown:
                    [self alert:@"Couldn't figure out where this photo was taken (yet)."];
                     break;
                case kCLErrorDenied:
                    [self alert:@"Location Services disabled under Privacy in Settings application."];
                     break;
                case kCLErrorNetwork:
                    [self alert:@"Can't figure out where this photo is being taken. Verify your connection to the network."];
                    break;
                default:
                    [self alert:@"Cant figure out where this photo is being taken, sorry."];
                    break;
            }
            return NO;
        }else {
            return YES;
        }
    } else { // следует проверить также location & imageURL, чтобы убедиться,
        // что мы могли бы писать в файл
        return [super shouldPerformSegueWithIdentifier:identifier sender:sender];
    }
}

#pragma mark - Alerts

- (void)alert:(NSString *)msg
{
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"Add Photo"
                                        message:msg
                                 preferredStyle:UIAlertControllerStyleAlert ];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
   [self presentViewController:alert animated:YES completion:nil];
}

- (void)fatalAlert:(NSString *)msg
{
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"Add Photo"
                                        message:msg
                                 preferredStyle:UIAlertControllerStyleAlert ];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                                                
                                            }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}


#pragma mark - Image Properties

- (NSURL *)uniqueDocumentURL
{
    NSArray *documentDirectories =
     [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                            inDomains:NSUserDomainMask];
    NSString *unique = [NSString
                        stringWithFormat:@"%.0f",
                                 floor([NSDate timeIntervalSinceReferenceDate])];
    return [[documentDirectories firstObject] URLByAppendingPathComponent:unique];
}

- (NSURL *)imageURL
{
    if (!_imageURL && self.image) {
        NSURL *url = [self uniqueDocumentURL];
        if (url) {
            NSData *imageData = UIImageJPEGRepresentation(self.image, 1.0);
            if ([imageData writeToURL:url atomically:YES]) {
                _imageURL = url;
            }
        }
    }
    return _imageURL;
}

- (NSURL *)thumbnailURL
{
    NSURL *url = [self.imageURL URLByAppendingPathExtension:@"thumbnail"];
    if (![_thumbnailURL isEqual:url]) {
        _thumbnailURL = nil;
        if (url) {
            UIImage *thumbnail = [self.image imageByScalingToSize:CGSizeMake(75, 75)];
            NSData *imageData = UIImageJPEGRepresentation(thumbnail, 0.5);
            if ([imageData writeToURL:url atomically:YES]) {
                _thumbnailURL = url;
            }
        }
    }
    return _thumbnailURL;
}

- (void)setImage:(UIImage *)image
{
    self.imageView.image = image;
    
    // если image изменился, мы должны удалить файлы, которые мы создали
    // (если они уже существуют)
    [[NSFileManager defaultManager] removeItemAtURL:_imageURL error:NULL];
    [[NSFileManager defaultManager] removeItemAtURL:_thumbnailURL error:NULL];
    self.imageURL = nil;
    self.thumbnailURL = nil;
    
}

- (UIImage *)image
{
    return self.imageView.image;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
     // заставляет "return" клавишу скрывать клавиатуру
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Filter Image

- (IBAction)filterImage:(UIButton *)sender {
    if (!self.image) {
        [self alert:@"You must take a photo first!"];
    } else {
        UIAlertController *alert = [UIAlertController
                                    alertControllerWithTitle:@"Filter Image"
                                    message:@"Choose filter."
                                    preferredStyle:UIAlertControllerStyleActionSheet];
        for (NSString *filter in [self filters]) {
            UIAlertAction *filterAction = [UIAlertAction
                                           actionWithTitle:filter
                                           style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction * action) {
           self.image = [self.image imageByApplyingFilterNamed:self.filters[action.title]];
           NSLog(@"You pressed button %@", self.filters[action.title]);
                                           }];
            [alert addAction:filterAction];
        }
        UIAlertAction *cancelAction = [UIAlertAction
                                       actionWithTitle:@"Cancel"
                                       style:UIAlertActionStyleCancel
                                       handler:^(UIAlertAction * action) {
                                           NSLog(@"You pressed button Cancel");
                                       }];
        [alert addAction:cancelAction];
        
        alert.modalPresentationStyle = UIModalPresentationPopover; //  for iPad
        UIPopoverPresentationController *ppc = alert.popoverPresentationController; //  for iPad
        if (ppc)
        {
            ppc.sourceView = sender;
            ppc.sourceRect = sender.bounds;
            ppc.permittedArrowDirections = UIPopoverArrowDirectionAny;
        }
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (NSDictionary *)filters
{
    return @{ @"Chrome" : @"CIPhotoEffectChrome",
              @"Blur"   : @"CIGaussianBlur",
              @"Noir"   : @"CIPhotoEffectNoir",
              @"Fade"   : @"CIPhotoEffectFade" };
}


@end
