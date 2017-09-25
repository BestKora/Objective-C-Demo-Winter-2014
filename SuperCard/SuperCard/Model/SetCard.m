//
//  SetCard.m
//  Matchismo3
//
//  Created by Tatiana Kornilova on 11/12/13.
//  Copyright (c) 2013 Tatiana Kornilova. All rights reserved.
//

#import "SetCard.h"

// Each card in Set has:

// number   - 1, 2, 3
// symbol   - diamond, squiggle, oval
// shading  - solid, striped, open
// color    - red, green, purple

@implementation SetCard

+ (NSArray *)validSymbols
{
    return @[@"diamond", @"squiggle", @"oval"];
}

+ (NSArray *)validShadings
{
    return @[@"solid", @"striped", @"open"];
}

+ (NSArray *)validColors
{
    return @[@"red", @"green", @"purple"];
}

-(void)setSymbol:(NSString *)symbol
{
    if ([[SetCard validSymbols] containsObject:symbol]) {
        _symbol =symbol;
    }
}

-(void)setShading:(NSString *)shading
{
    if ([[SetCard validShadings] containsObject:shading]) {
        _shading =shading;
    }
}

-(void)setColor:(NSString *)color
{
    if ([[SetCard validColors] containsObject:color]) {
        _color =color;
    }
}
- (int)match:(NSArray *)otherCards
{
    int score = 0;
    int symbolSum  = 0;
    int numberSum  = 0;
    int shadingSum = 0;
    int colorSum   = 0; 
    
    if (otherCards.count==3) {
        
        for (SetCard *otherCard in otherCards) {
            symbolSum+= [[SetCard validSymbols] indexOfObject:otherCard.symbol]+1; //otherCard.symbol;
            numberSum+= otherCard.number;
            shadingSum+= [[SetCard validShadings] indexOfObject:otherCard.shading]+1; //otherCard.shading;
            colorSum+= [[SetCard validColors] indexOfObject:otherCard.color]+1; //otherCard.color;
        }

        if ((symbolSum%3==0)&&(numberSum%3==0)&&(shadingSum%3==0)&&(colorSum%3==0))
        {
           // NSLog(@"совпали %@ %@ %@",self,otherCards[0],otherCards[1]);
            score = 1;
        }
    }
    return score;
}


- (NSString *) contents
{
    NSDictionary *symbolPallette = @{@"diamond":@"▲",@"squiggle":@"■",@"oval":@"●"};
    NSString *text      =  [@"" stringByPaddingToLength:self.number
                                                      withString:symbolPallette[self.symbol]
                                                 startingAtIndex:0];
    return text;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@ %@ %@ ", self.contents, self.color,self.shading];
}

@end
