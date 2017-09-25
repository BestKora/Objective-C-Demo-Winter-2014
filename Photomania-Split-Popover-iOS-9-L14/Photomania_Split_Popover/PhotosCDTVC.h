//
//  PhotosCDTVC.h
//  Photomania
//
//  Created by CS193p Instructor.
//  Copyright (c) 2013 Stanford University. All rights reserved.
//

#import "CoreDataTableViewController.h"

@interface PhotosCDTVC : CoreDataTableViewController

// generic, показывающий Photo  CDTVC
// подцепляется fetchedResultsController к любому Photo fзапросу
// используйте @"Photo Cell" как cell's reuse id для вашей table view
// "переезжает" на ImageViewController для показа изображения 

@end
