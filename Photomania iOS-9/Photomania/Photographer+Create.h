//
//  Photographer+Create.h
//  Photomania8
//
//  Created by Tatiana Kornilova on 6/25/15.
//  Copyright (c) 2015 Tatiana Kornilova. All rights reserved.
//

#import "Photographer.h"

@interface Photographer (Create)

+ (Photographer *)photographerWithName:(NSString *)name
                inManagedObjectContext:(NSManagedObjectContext *)context;
@end
