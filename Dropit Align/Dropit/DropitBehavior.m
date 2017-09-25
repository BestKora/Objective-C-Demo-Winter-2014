//
//  DropitBehavior.m
//  Dropit
//
//  Created by CS193p Instructor.
//  Copyright (c) 2013 Stanford University. All rights reserved.
//

#import "DropitBehavior.h"

@interface DropitBehavior() <UICollisionBehaviorDelegate>
@property (strong, nonatomic) UIGravityBehavior *gravity;
@property (strong, nonatomic) UICollisionBehavior *collider;
@property (strong, nonatomic) UIDynamicItemBehavior *animationOptions;
@end

@implementation DropitBehavior

- (UIGravityBehavior *)gravity
{
    if (!_gravity) {
        _gravity = [[UIGravityBehavior alloc] init];
        _gravity.magnitude = 0.9;
    }
    return _gravity;
}

- (UICollisionBehavior *)collider
{
    if (!_collider) {
        _collider = [[UICollisionBehavior alloc] init];
        _collider.translatesReferenceBoundsIntoBoundary = YES;
        _collider.collisionDelegate = self;
    }
    return _collider;
}

- (void)collisionBehavior:(UICollisionBehavior *)behavior
      endedContactForItem:(id<UIDynamicItem>)item1
                 withItem:(id<UIDynamicItem>)item2
{
    [self alignItem:item1];
    [self alignItem:item2];
}

#define CLOSE_TO_ALIGNMENT 4.0

- (void)alignItem:(id <UIDynamicItem>)item
{
    [UIView animateWithDuration:0.3 animations:^{
        CGFloat currentItemWidth = item.bounds.size.width;
        CGFloat currentItemLeftEdge = (item.center.x - currentItemWidth / 2);
        CGFloat newItemLeftEdge = round(currentItemLeftEdge / currentItemWidth) * currentItemWidth;
        if (ABS(currentItemLeftEdge - newItemLeftEdge) > CLOSE_TO_ALIGNMENT) {
            if ([self.animationOptions linearVelocityForItem:item].x > 0) {
                newItemLeftEdge = floorf((currentItemLeftEdge + currentItemWidth) /currentItemWidth) * currentItemWidth;
            } else if ([self.animationOptions linearVelocityForItem:item].x < 0) {
                newItemLeftEdge = floorf(currentItemLeftEdge / currentItemWidth) * currentItemWidth;
            }
        }
        if (newItemLeftEdge > self.dynamicAnimator.referenceView.bounds.size.width - currentItemWidth) {
            newItemLeftEdge -= currentItemWidth;
        }
        if (newItemLeftEdge < 0) {
            newItemLeftEdge += currentItemWidth;
        }
        if (newItemLeftEdge != currentItemLeftEdge) {
            item.center = CGPointMake(newItemLeftEdge + currentItemWidth / 2, item.center.y);
            [self.dynamicAnimator updateItemUsingCurrentState:item];
        }
    }];
}


- (UIDynamicItemBehavior *)animationOptions
{
    if (!_animationOptions) {
        _animationOptions = [[UIDynamicItemBehavior alloc] init];
        _animationOptions.allowsRotation = NO;
    }
    return _animationOptions;
}

- (void)addItem:(id <UIDynamicItem>)item
{
    [self.gravity addItem:item];
    [self.collider addItem:item];
    [self.animationOptions addItem:item];
}

- (void)removeItem:(id <UIDynamicItem>)item;
{
    [self.gravity removeItem:item];
    [self.collider removeItem:item];
    [self.animationOptions removeItem:item];
}

- (instancetype)init
{
    self = [super init];
    [self addChildBehavior:self.gravity];
    [self addChildBehavior:self.collider];
    [self addChildBehavior:self.animationOptions];
    return self;
}

@end
