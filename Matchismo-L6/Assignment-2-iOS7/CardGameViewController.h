//
//  CardGameViewController.h
//  Assignment-2-iOS7
//
//  Created by Tatiana Kornilova on 7/12/14.
//  Copyright (c) 2014 Tatiana Kornilova. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Deck.h"

@interface CardGameViewController : UIViewController

// protected
// for subclasses
- (Deck *)createDeck; // abstract
@end
