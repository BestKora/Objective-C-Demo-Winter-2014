//
//  URLViewController.m
//  Photomania
//
//  Created by CS193p Instructor.
//  Copyright (c) 2013 Stanford University. All rights reserved.
//

#import "URLViewController.h"

@interface URLViewController ()<UIPopoverPresentationControllerDelegate>
@property (weak, nonatomic) IBOutlet UITextView *urlTextView;
@end

@implementation URLViewController

-(void)awakeFromNib {
    [super awakeFromNib];
    self.modalPresentationStyle = UIModalPresentationPopover;
    self.popoverPresentationController.delegate = self;
}

- (void)setUrl:(NSURL *)url
{
    _url = url;
    [self updateUI];
}

// updateUI работает здесь, если свойство url
// устанавливается перед загрузкой outlets
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self updateUI];
}

- (void)updateUI
{
    self.urlTextView.text = [self.url absoluteString];
}

-(CGSize)preferredContentSize {
    
    if (self.urlTextView != nil && self.presentingViewController != nil ) {
        
        return [self.urlTextView
                 sizeThatFits:self.presentingViewController.view.bounds.size];
    }
        else {
            return super.preferredContentSize;
        }
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
                                                               traitCollection:(UITraitCollection *)traitCollection
{
    return UIModalPresentationNone;
}


@end
