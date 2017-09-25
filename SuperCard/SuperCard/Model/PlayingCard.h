//
//  PlayingCard.h
//  Matchismo
//
//  Created by Tatiana Kornilova on 11/3/13.
//  Copyright (c) 2013 Tatiana Kornilova. All rights reserved.
//

#import "Card.h"

@interface PlayingCard : Card

@property (strong, nonatomic) NSString *suit;
@property (nonatomic) NSUInteger rank;

+ (NSArray *)validSuits;
+ (NSUInteger)maxRank;


@end
