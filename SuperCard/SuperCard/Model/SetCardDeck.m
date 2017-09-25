//
//  SetCardDeck.m
//  Matchismo3
//
//  Created by Tatiana Kornilova on 11/12/13.
//  Copyright (c) 2013 Tatiana Kornilova. All rights reserved.
//

#import "SetCardDeck.h"
#import "SetCard.h"

@implementation SetCardDeck
-(id)init
{
    self = [super init];
    if (self) {
        for (NSString *symbol in [[SetCard class] validSymbols]) {
            
            for (NSUInteger number=1; number<=3; number++) {
                
                for (NSString *color in [[SetCard class] validColors]) {
                    
                    for (NSString *shading in [[SetCard class] validShadings]) {
                        SetCard *card =[[SetCard alloc] init];
                        card.number =number;
                        card.symbol =symbol;
                        card.color =color;
                        card.shading =shading;
                      //  NSLog(@"%@",card);
                        [self addCard:card atTop:YES];
                    }
                    
                }
            }
        }
    }
    return self;
}

@end
