//
//  CardMatchingGame.m
//  Matchismo

#import "CardMatchingGame.h"

@interface CardMatchingGame()

@property (nonatomic, readwrite) NSInteger score;
@property (nonatomic, strong) NSMutableArray *cards; // of Card
@property (nonatomic,strong) NSMutableArray *faceUpCards; // of Card
@property (readwrite,nonatomic) NSInteger lastFlipPoints;

@end

@implementation CardMatchingGame

- (NSMutableArray *)cards {
    if (!_cards) {
        _cards = [[NSMutableArray alloc] init];
    }
    return _cards;
}

- (void)setNumberOfMatches:(NSUInteger)numberOfMatches
{
    _numberOfMatches = numberOfMatches >= 2 ? numberOfMatches :2;
}

- (instancetype)initWithCardCount:(NSUInteger)count
                        usingDeck:(Deck *)deck
{
    self = [super init];
    
    if (self) {
        for (int i = 0; i < count; i++) {
            Card *card = [deck drawRandomCard];
            if (card) {
                [self.cards addObject:card];
            } else {
                self = nil;
                break;
            }
        }
    }
    
    return self;
}

static const int MISMATCH_PENALTY = 2;
static const int MATCH_BONUS = 4;
static const int COST_TO_CHOOSE = 1;

-(void)chooseCardAtIndex:(NSUInteger)index
{
    Card *card = [self cardAtIndex:index];
    if (!card.isMatched) {
        if (card.isChosen) {
            card.chosen =NO;
        } else {
            // match against another cards
            self.faceUpCards= [[NSMutableArray alloc] initWithArray:@[card]];
            self.lastFlipPoints = 0;
            for (Card *otherCard in self.cards) {
                if (otherCard.isChosen && !otherCard.isMatched) {
                    [self.faceUpCards insertObject:otherCard atIndex:0];
                    // decision on match
                    if ([self.faceUpCards count] == (self.numberOfMatches)) {
                        
                        int matchScore = [card match:self.faceUpCards];
                        if (matchScore) {
                            self.lastFlipPoints = matchScore * MATCH_BONUS;
                            for (Card *faceUpCard in self.faceUpCards) {
                                faceUpCard.matched =YES;
                            }
                            
                        } else {
                            self.lastFlipPoints = - MISMATCH_PENALTY;
                            for (Card *faceUpCard in self.faceUpCards) {
                                if (faceUpCard != card) faceUpCard.chosen =NO;
                            }
                        }
                        self.matchedCards =[self.faceUpCards copy];
                        break;
                    }
                    // decision on match
                }
            }
            self.score+= self.lastFlipPoints - COST_TO_CHOOSE;
            self.matchedCards =[self.faceUpCards copy];
            card.chosen = YES;
        }
    }
}


- (Card *)cardAtIndex:(NSUInteger)index
{
    return (index < [self.cards count]) ? self.cards[index] : nil;
}

@end
