//
//  Photo+Flickr.h
//  Photomania8
//
//

#import "Photo.h"

@interface Photo (Flickr)

+(Photo *)photoWithFlickrInfo: (NSDictionary *)photoDictionary
       inManagedObjectContext: (NSManagedObjectContext *)context;

+(void)loadPhotosFromFlickrArray: (NSArray *)photos // of Flickr NSDictionary
          intoManagedObjectContext: (NSManagedObjectContext *)context;

@end
