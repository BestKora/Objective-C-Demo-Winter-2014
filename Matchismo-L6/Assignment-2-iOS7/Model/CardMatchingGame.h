//
//  CardMatchingGame.h
//  Matchismo

#import <Foundation/Foundation.h>
#import "Deck.h"

@interface CardMatchingGame : NSObject

// designated initializer
- (instancetype)initWithCardCount:(NSUInteger)count
                        usingDeck:(Deck *)deck;

- (void)chooseCardAtIndex:(NSUInteger)index;
- (Card *)cardAtIndex:(NSUInteger)index;

@property (nonatomic, readonly) NSInteger score;
@property (nonatomic) NSUInteger numberOfMatches;
@property (strong,nonatomic) NSArray *matchedCards;
@property (readonly,nonatomic) NSInteger lastFlipPoints;

@end
