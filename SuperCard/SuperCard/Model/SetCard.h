//
//  SetCard.h
//  Matchismo3
//
//  Created by Tatiana Kornilova on 11/12/13.
//  Copyright (c) 2013 Tatiana Kornilova. All rights reserved.
//

#import "Card.h"

// Each card in Set has:

// number   - 1, 2, 3
// symbol   - diamond, squiggle, oval
// shading  - solid, striped, open
// color    - red, green, purple

@interface SetCard : Card

@property (nonatomic) NSUInteger number;
@property (nonatomic,strong) NSString *symbol;
@property (nonatomic,strong) NSString *shading;
@property (nonatomic,strong) NSString *color;

+(NSArray *)validSymbols;
+(NSArray *)validShadings;
+(NSArray *)validColors;

@end
