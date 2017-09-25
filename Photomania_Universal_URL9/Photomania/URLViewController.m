//
//  URLViewController.m
//  Photomania
//
//  Created by CS193p Instructor.
//  Copyright (c) 2013 Stanford University. All rights reserved.
//

#import "URLViewController.h"

@interface URLViewController ()
@property (weak, nonatomic) IBOutlet UITextView *urlTextView;
@end

@implementation URLViewController

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
/*
-(CGSize)preferredContentSize {
    if (self.urlTextView != nil && self.presentingViewController != nil ) {
        return [self.urlTextView sizeThatFits:self.presentingViewController.view.bounds.size];
    }
        else {
            return super.preferredContentSize;
        }
}
*/
@end
