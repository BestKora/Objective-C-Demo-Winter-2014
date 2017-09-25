//
//  PlayingCardGameViewController.m
//  MatchismoL6
//
//  Created by Tatiana Kornilova on 11/20/14.
//  Copyright (c) 2014 Tatiana Kornilova. All rights reserved.
//

#import "PlayingCardGameViewController.h"
#import "PlayingCardDeck.h"


@implementation PlayingCardGameViewController
- (Deck *)createDeck
{
    return [[PlayingCardDeck alloc] init];
}


@end
