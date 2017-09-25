//
//  ImageViewController.m
//  Imaginarium
//
//  Created by CS193p Instructor.
//  Copyright (c) 2013 Stanford University. All rights reserved.
//

#import "ImageViewController.h"
#import "URLViewController.h"

@interface ImageViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImage *image;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@end

@implementation ImageViewController

#pragma mark - View Controller Lifecycle

// добавляем UIImageView к MVC's View

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.scrollView addSubview:self.imageView];

}

// для эффективности мы будем действительно загружать image с Flickr.com
// только тогда, когда мы уже собираемся выйти на экран
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (self.image == nil) {
       [self startDownloadingImage];
    }
}

#pragma mark - Properties

// lazy instantiation (отложенное получение экземпляра класса)

- (UIImageView *)imageView
{
    if (!_imageView) _imageView = [[UIImageView alloc] init];
    return _imageView;
}

// свойство image не использует переменную экземпляра класса _image,
// вместо этого она просто получает/устанавливает image в свойстве imageView
// поэтому нет необходимости в @synthesize
// даже когда реализуют оба: и setter, и getter

- (UIImage *)image
{
    return self.imageView.image;
}

- (void)setImage:(UIImage *)image
{
    self.imageView.image = image; // не изменяет frame UIImageView

    // нужно добавить две строки кода в Shutterbug для исправления ошибки
    // при повторном использовании ("reusing") ImageViewController's MVC
    self.scrollView.zoomScale = 1.0;
    self.imageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    
    // self.scrollView будет равен nil на следующей строке кода,
    // если установка outlet еще не произошла
    self.scrollView.contentSize = self.image ? self.image.size : CGSizeZero;

    // в портретной ориентации на iPad в split view,
    //   к сожалению, master может быть доступен при открытом Popover
    //   (поэтому удаляем URL, если кто-то изменил image и мы попадаем в этот setter)
    //---iOS 8 и iOS 9----
    
    if (self.presentedViewController) {
          [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
    
    [self.spinner stopAnimating];
}

- (void)setScrollView:(UIScrollView *)scrollView
{
    _scrollView = scrollView;
    
    // следующие три строки необходимы для изменения масштаба (zooming)
    _scrollView.minimumZoomScale = 0.2;
    _scrollView.maximumZoomScale = 2.0;
    _scrollView.delegate = self;

    // следующая строка необходима в случае, если self.image устанавливается
    // перед установкой self.scrollView, например, вызывается
    // prepareForSegue:sender: перед фазой установки outlets
    self.scrollView.contentSize = self.image ? self.image.size : CGSizeZero;
}

#pragma mark - UIScrollViewDelegate

// обязательный zooming метод в UIScrollViewDelegate protocol
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

#pragma mark - Navigation

// показываем наш imageURL в popover

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[URLViewController class]]) {
        URLViewController *urlvc =
                              (URLViewController *)segue.destinationViewController;
        urlvc.url = self.imageURL;
    }
}

// не показывайте URL, если imageURL равно nil

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"Show URL"]) {
          return self.imageURL ? YES : NO;
    } else {
        return [super shouldPerformSegueWithIdentifier:identifier sender:sender];
    }
}

#pragma mark - Setting the Image from the Image's URL

- (void)setImageURL:(NSURL *)imageURL
{
    _imageURL = imageURL;
    [self startDownloadingImage];
}

- (void)startDownloadingImage
{
    self.image = nil;

    if (self.imageURL)
    {
        [self.spinner startAnimating];

        NSURLRequest *request = [NSURLRequest requestWithURL:self.imageURL];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];

        NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request
            completionHandler:^(NSURL *localfile, NSURLResponse *response, NSError *error) {
                // этот обработчик не исполняется на main queue,
                // так что мы не можем изменять UI здесь напрямую
                if (!error) {
                    if ([request.URL isEqual:self.imageURL]) {
                        // UIImage является исключением к тому, что "нельзя здесь изменять UI"
                        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:localfile]];
                        // но вызов "self.image =" определенно не является этим исключением!
                        // так что мы должны вернуться назад в main queue
                        dispatch_async(dispatch_get_main_queue(), ^{ self.image = image; });
                    }
                }
        }];
        [task resume]; // не забывайте, что все задания NSURLSession стартуют как suspended!
    }
}

@end
