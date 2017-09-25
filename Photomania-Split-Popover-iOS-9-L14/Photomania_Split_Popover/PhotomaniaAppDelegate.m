//
//  PhotomaniaAppDelegate.m
//  Photomania
//
//  Created by CS193p Instructor.
//  Copyright (c) 2013 Stanford University. All rights reserved.
//

#import "PhotomaniaAppDelegate.h"
#import "PhotomaniaAppDelegate+MOC.h"
#import "FlickrFetcher.h"
#import "Photo+Flickr.h"
#import "PhotoDatabaseAvailability.h"
#import "ImageViewController.h"
#import "PhotosByPhotographerCDTVC.h"

@interface PhotomaniaAppDelegate () <UISplitViewControllerDelegate, NSURLSessionDownloadDelegate>

@property (copy, nonatomic) void (^flickrDownloadBackgroundURLSessionCompletionHandler)(void);
@property (strong, nonatomic) NSURLSession *flickrDownloadSession;
@property (strong, nonatomic) NSTimer *flickrForegroundFetchTimer;
@property (strong, nonatomic) NSManagedObjectContext *photoDatabaseContext;
@end


// имя background download сессии для загруки данных с Flickr
#define FLICKR_FETCH @"Flickr Just Uploaded Fetch"

// как часто (в секундах) мы выбираем новые фотографии,
// когда мы в активном режиме (n the foreground)
#define FOREGROUND_FLICKR_FETCH_INTERVAL (20*60)

// как долго мы будем ждать выборки из Flickr чтобы вернуться (return),
// когда мы в фоновом режиме (in the background)
#define BACKGROUND_FLICKR_FETCH_TIMEOUT (10)

@implementation PhotomaniaAppDelegate

#pragma mark - UIApplicationDelegate

// это вызывается как только ваш storyboard прочитан и мы готовы стартовать
// но все равно это еще в самом начале игры (UI еще не на экране, например)

- (BOOL)application:(UIApplication *)application
                               didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    UISplitViewController *splitViewController =
                                     (UISplitViewController *)self.window.rootViewController;
    UINavigationController *navigationController =
                                            [splitViewController.viewControllers lastObject];
    navigationController.topViewController.navigationItem.leftBarButtonItem =
                                                   splitViewController.displayModeButtonItem;
    navigationController.topViewController.navigationItem.leftItemsSupplementBackButton = YES;
    
    splitViewController.preferredDisplayMode =  UISplitViewControllerDisplayModeAllVisible;
    
    // splitViewController.preferredPrimaryColumnWidthFraction = 0.5;
    // splitViewController.maximumPrimaryColumnWidth = 512;
    
    splitViewController.delegate = self;

  /*  UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
    navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
    splitViewController.delegate = self;*/

    // когда мы в фоновом режиме (in the background), производим выборку как можно чаще
    // (что на самом деле не будет часто)
    // забыл включить эту строку во время демонстрации на лекции,
    // но вы не забудьте включить ее в ваше приложение!
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];

    // мы получаем managed object контекст, самостоятельно создавая его в категории PhotomaniaAppDelegate
    // но в Домашней работе вы должны получить контекст из UIManagedDocument
    // ( то есть вам не нужно использовать этот метод createMainQueueManagedObjectContext,
    // или используйте этот подход)
    self.photoDatabaseContext = [self createMainQueueManagedObjectContext];
   
    // мы запускаем выборку из Flickr каждый раз при старте (почему нет?)
    [self startFlickrFetch];
    
    
    // это возвращаемое значение должно что-то делать с обработкой URLs из других приложений
    // сейчас не беспокойтесь об этом, просто возвращайте YES
    return YES;
}

// вызывается системой случайно, КОГДА МЫ НЕ ЯВЛЯЕМСЯ FOREGROUND APPLICATION
// в действительности, система ЗАПУСТИТ НАС, если необходимо вызвать этот метод
// у системы очень много разумных причин когда это сделать, но для нас это абсолютно непрозрачно

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    // на лекции мы положились на background flickrDownloadSession,
    // чтобы выполнить выборку путем вызова[self startFlickrFetch]
    // это легко кодировать, но очень слабо в том смысле, как часто эта выборка будет реально
    // происходить (может быть почти никогда)
    // это потому, что нет гарантий, что нам разрешат стартовать такого слишком своенравного выборщика,
    // который работает, когда мы находимся в фоновом режиме
    // так что давайте просто сделаем здесь несвоенравную, не background-session выборку
    // мы не хотим, чтобы она занимала слишком много времени, потому что система начнет терять доверие к нам
    // из-за background выборщика и перестанет нас часто вызывать
    // поэтому мы ограничим время выборки в BACKGROUND_FETCH_TIMEOUT секунд
    // (а также мы не будем использовать дорогостоящую сотовую передачу данных )

    if (self.photoDatabaseContext) {
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        sessionConfig.allowsCellularAccess = NO;
        
        // хотим быть добропорядочными гражданами фонового режима (background citizen)!
        sessionConfig.timeoutIntervalForRequest = BACKGROUND_FLICKR_FETCH_TIMEOUT;
        NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[FlickrFetcher URLforRecentGeoreferencedPhotos]];
        NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request
            completionHandler:^(NSURL *localFile, NSURLResponse *response, NSError *error) {
                if (error) {
                    NSLog(@"Flickr background fetch failed: %@", error.localizedDescription);
                    completionHandler(UIBackgroundFetchResultNoData);
                } else {
                    [self loadFlickrPhotosFromLocalURL:localFile
                                           intoContext:self.photoDatabaseContext
                                   andThenExecuteBlock:^{
                                       completionHandler(UIBackgroundFetchResultNewData);
                                   }
                     ];
                }
            }];
        [task resume];
    } else {
        // не делаем обновления в переключателе приложений app-switcher, если нет database!
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

// это вызывается тогда, когда URL, который мы запросили в background сессии, возвращается,
// а мы в фоновом режиме (in the background)
// и он по существу "будит нас от спячки", чтобы обработать результаты URL
// если мы в активном режиме (in the foreground), iOS просто вызывает наши методы делегата и
// не беспокоит нас этим совсем

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler
{
    // когда вызывается этот completionHandler, то осуществляется перерисовка нашего UI
    // в переключателе приложений (app switcher),
    // но не следует вызывать этот обработчик до тех пор, пока мы не завершили обработку URL,
    // результаты которого теперь доступны
    // поэтому мы припрячем этот completionHandler в специальном свойстве до тех пор,
    // пока мы не будем готовы его вызвать
    // (смотри flickrDownloadTasksMightBeComplete, в котором он действительно вызывается)

    self.flickrDownloadBackgroundURLSessionCompletionHandler = completionHandler;
}

#pragma mark - Split view Controller

- (UIViewController *)splitViewController:(UISplitViewController *)splitViewController
                      separateSecondaryViewControllerFromPrimaryViewController:
                                          (UIViewController *)primaryViewController {
    
    if ([primaryViewController isKindOfClass:[UINavigationController class]]) {
        if ( [[(UINavigationController *)primaryViewController topViewController]
              isKindOfClass:[PhotosByPhotographerCDTVC class]]) {
            //--------Выбираем autoselectedPhoto----
            PhotosByPhotographerCDTVC *masterView = (PhotosByPhotographerCDTVC *)
            [(UINavigationController *)primaryViewController topViewController];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            
            Photo *autoselectedPhoto = (Photo *)
            [masterView.fetchedResultsController objectAtIndexPath:indexPath];
            //-------------------------------
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            UINavigationController *detailView =
            [storyboard instantiateViewControllerWithIdentifier:@"detailNavigation"];
            
            // Обеспечиваем появление обратной кнопки
            UIViewController *controller = [detailView visibleViewController];
            controller.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
            controller.navigationItem.leftItemsSupplementBackButton = YES;
            
            //---устанавливаем фотографию для autoselectedPhoto в качестве Модели----
            if ([controller isKindOfClass:[ImageViewController class]]) {
                
                if (autoselectedPhoto) {
                    [masterView.tableView  selectRowAtIndexPath:indexPath animated:YES scrollPosition:0];
                    ((ImageViewController *)controller).imageURL =
                                                        [NSURL URLWithString:autoselectedPhoto.imageURL];
                    ((ImageViewController *)controller).title = autoselectedPhoto.title;
                }
            }
            //------
            
            return detailView;
        }
    }
    return  nil;
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController
                         collapseSecondaryViewController:(UIViewController *)secondaryViewController
                               ontoPrimaryViewController:(UIViewController *)primaryViewController {
    
    if ([secondaryViewController isKindOfClass:[UINavigationController class]]) {
        
      if ( [[(UINavigationController *)secondaryViewController topViewController]
                                                       isKindOfClass:[ImageViewController class]]) {
        
       if( ([(ImageViewController *)[(UINavigationController *)secondaryViewController
                                                             topViewController] imageURL] == nil)) {
        
        // Возвращаем YES, чтобы показать, что мы сами будем управлять Detail для collapsed интерфейса
        //  и ничего не делаем;  следовательно Detail будет отвергнуто.
        return YES;
        }
          if ([primaryViewController isKindOfClass:[UINavigationController class]]) {
              [ (UINavigationController *)primaryViewController
                                                       setNavigationBarHidden:false animated:false];
          }

      }
    }
        return NO;
}

#pragma mark - Database Context

// мы можем что-то делать с базой данных, если контекст базы данных фотографий доступен
// мы запускаем foreground таймер NSTimer, чтобы мы могли делать выборку
// каждый раз в определенное время в активном режиме (in the foreground)
// мы посылаем уведомление (notification), давая знать другим, что контекст доступен
- (void)setPhotoDatabaseContext:(NSManagedObjectContext *)photoDatabaseContext
{
    _photoDatabaseContext = photoDatabaseContext;
    
    // каждый раз при изменении контекста, мы заново стартуем наш таймер,
    // убивая (invalidate) текущий таймер
    // (к сожалению, мы не получили эту строку кода в лекции!)
    [self.flickrForegroundFetchTimer invalidate];
    self.flickrForegroundFetchTimer = nil;
    
    if (self.photoDatabaseContext)
    {
         // этот таймер будет запускаться только когда мы в активном режиме (in the foreground)
        self.flickrForegroundFetchTimer = [NSTimer scheduledTimerWithTimeInterval:FOREGROUND_FLICKR_FETCH_INTERVAL
                                         target:self
                                       selector:@selector(startFlickrFetch:)
                                       userInfo:nil
                                        repeats:YES];
    }
    
    // позволяем всем, кто интересуется, узнать, что этот контекст доступен
    // Это происходит очень рано, при старте нашего приложения
    // Возможно, что НЕ ИМЕЕТ СМЫСЛА слушать эту радиостанцию в тех View Controller, на которые, например,
    // "переезжают" (segued to) (но это вполне естественно, потому что View Controller на которые "переезжают",
    // предположительно "подготавливаются" путем передачи им контекста для работы)
    NSDictionary *userInfo = self.photoDatabaseContext ? @{ PhotoDatabaseAvailabilityContext : self.photoDatabaseContext } : nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:PhotoDatabaseAvailabilityNotification
                                                        object:self
                                                      userInfo:userInfo];
}

#pragma mark - Flickr Fetching

// Это, возможно, не будет работать (task = nil), если мы находимся в background, но это нормально
// (мы выполняем выборку в фоновом режиме в performFetchWithCompletionHandler:)
// она всегда работает, когда мы является foreground (активным) приложением

- (void)startFlickrFetch
{
    // getTasksWithCompletionHandler: является ASYNCHRONOUS (асихронной)
    // и это нормально, потому что не ожидаем, что startFlickrFetch будет делать синхронно в любом случае
       [self.flickrDownloadSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
           // давайте посмотрим, может быть выборки уже работают ...
        if (![downloadTasks count]) {
              // ... выборки не работают и мы запускаем одну
            NSURLSessionDownloadTask *task = [self.flickrDownloadSession downloadTaskWithURL:[FlickrFetcher URLforRecentGeoreferencedPhotos]];
            task.taskDescription = FLICKR_FETCH;
            [task resume];
        } else {
            // ... выборки уже работают (давайте убедимся, она (они) работает(ют), когда мы находимся здесь)
            for (NSURLSessionDownloadTask *task in downloadTasks) [task resume];
        }
    }];
}

// NSTimer target/action всегда использует NSTimer как аргумент
- (void)startFlickrFetch:(NSTimer *)timer
{
    [self startFlickrFetch];
}


// getter для свойства flickrDownloadSession
// эту NSURLSession мы будем использовать для выборки Flickr данных в background
- (NSURLSession *)flickrDownloadSession
{
    if (!_flickrDownloadSession) {
         // dispatch_once обеспечивает однократный запуск блока (синглтон)
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            
            // заметьте, что конфигурация здесь "backgroundSessionConfiguration:"
            // что означает, что мы получим в конце концов результаты,
            // даже если мы не foreground приложение,
            // даже если приложение закончится аварийно, оно будет перезапушено (в конце концов)
            // для обработки URL результатов!

            NSURLSessionConfiguration *urlSessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:FLICKR_FETCH];

            // ДОЛЖЕН быть делегат для background configurations, следовательно  delegate:self
            // nil для delegateQueue означает "случайная, не main queue очередь"
            _flickrDownloadSession = [NSURLSession sessionWithConfiguration:urlSessionConfig
                                                                   delegate:self
                                                              delegateQueue:nil];
        });
    }
    return _flickrDownloadSession;
}

// стандартный код для "получаем информацию о фотографиях с Flickr URL"
- (NSArray *)flickrPhotosAtURL:(NSURL *)url
{
    NSDictionary *flickrPropertyList;
    NSData *flickrJSONData = [NSData dataWithContentsOfURL:url];   // будет блокировка, если url - не локальный!
    if (flickrJSONData) {
        flickrPropertyList = [NSJSONSerialization JSONObjectWithData:flickrJSONData
                                                                           options:0
                                                                             error:NULL];
    }
    return [flickrPropertyList valueForKeyPath:FLICKR_RESULTS_PHOTOS];
}

// получаем словари с Flickr фотографиями из url и размещаем в Core Data
// после лекции это переместили сюда, чтобы дать вам пример, как декларировать метод, аргументом которого является блок,
// и потому что этот метод вызываеися дважды как в части обработчика делегата background session,
// так и в случае, когда происходит background fetch

- (void)loadFlickrPhotosFromLocalURL:(NSURL *)localFile
                         intoContext:(NSManagedObjectContext *)context
                 andThenExecuteBlock:(void(^)(void))whenDone
{
    if (context) {
        NSArray *photos = [self flickrPhotosAtURL:localFile];
        [context performBlock:^{
            [Photo loadPhotosFromFlickrArray:photos intoManagedObjectContext:context];
            [context save:NULL]; // НЕТ НЕОБХОДИМОСТИ, если у вас контекст базы данных от UIManagedDocument
            if (whenDone) whenDone();
        }];
    } else {
        if (whenDone) whenDone();
    }
}

#pragma mark - NSURLSessionDownloadDelegate

// обязательный метод протокола
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)localFile
{
    // нам не следует предполагать, что мы единственные осуществляем загрузку в данный момент ...
    if ([downloadTask.taskDescription isEqualToString:FLICKR_FETCH]) {
        // ... но если это Flickr выборка, то обрабатываем возвращенные данные
        [self loadFlickrPhotosFromLocalURL:localFile
                               intoContext:self.photoDatabaseContext
                       andThenExecuteBlock:^{
                           [self flickrDownloadTasksMightBeComplete];
                       }
         ];
    }
}

// обязательный метод протокола
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
    // мы не будем поддерживать возобновление прерванного задания загрузки
}

// обязательный метод протокола
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
       // мы не будем отображать процесс загрузки на нашем UI, но это действительно крутой метод
}

// не требуется протоколом, но здесь следует ловить ошибки
// чтобы избежать аварийного завершения
// и также мы можем обнаружить, что задачи загрузки закончены (могут быть закончены)
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error && (session == self.flickrDownloadSession)) {
        NSLog(@"Flickr background download session failed: %@", error.localizedDescription);
        [self flickrDownloadTasksMightBeComplete];
    }
}

// этот "может быть" на случай, если когда-то у нас будет много загрузок одновременно

- (void)flickrDownloadTasksMightBeComplete
{
    if (self.flickrDownloadBackgroundURLSessionCompletionHandler) {
        [self.flickrDownloadSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
            
            // мы делаем эту проверку для других загрузок, чтобы чисто теоретически "быть корректными"
            // но в действительности мы в ней не нуждаемся, (так как мы запускаем  только одну загрузку за раз)
            // дополнительно заметим, что getTasksWithCompletionHandler: является ASYNCHRONOUS
            // так что мы должны во время выполнения блока опять проверить, не установлен ли обработчик в nil
            //  (другой поток может уже послать его при multiple-tasks-at-once реализации)
            if (![downloadTasks count]) {  // остались ли еще какие-нибудь Flickr загрузки?
                // нет, тогда вовлекаем flickrDownloadBackgroundURLSessionCompletionHandler (если он все еще не nil)
                void (^completionHandler)(void) = self.flickrDownloadBackgroundURLSessionCompletionHandler;
                self.flickrDownloadBackgroundURLSessionCompletionHandler = nil;
                if (completionHandler) {
                    completionHandler();
                }
            }// иначе другие загрузки продолжаются, так что позволим им вызвать этот метод, когда они финишируют
        }];
    }
}


@end
