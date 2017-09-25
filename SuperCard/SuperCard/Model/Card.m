//
//  Card.m
//  Matchismo
//
//  Created by Tatiana Kornilova on 11/2/13.
//  Copyright (c) 2013 Tatiana Kornilova. All rights reserved.
//

#import "Card.h"

@interface Card ()

@end
@implementation Card


-(int)match:(NSArray *)otherCards
{
    int score =0;
    
    for (Card *card in otherCards) {
        if ([card.contents isEqualToString:self.contents]) {
            score = 1;
        }
    }
    
    return score;
}
 -(NSString *)description
{
    return self.contents;
}
@end
