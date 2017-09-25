//
//  PhotosCDTVC.m
//  Photomania
//
//  Created by CS193p Instructor.
//  Copyright (c) 2013 Stanford University. All rights reserved.
//

#import "PhotosCDTVC.h"
#import "Photo.h"
#import "ImageViewController.h"

@implementation PhotosCDTVC

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView
                             cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView
                             dequeueReusableCellWithIdentifier:@"Photo Cell"];
    
    Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.textLabel.text = photo.title;
    cell.detailTextLabel.text = photo.subtitle;
    
    return cell;
}

#pragma mark - Navigation

- (void)prepareViewController:(id)vc
                     forSegue:(NSString *)segueIdentifer
                fromIndexPath:(NSIndexPath *)indexPath
{

    Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // заметьте, что мы не проверяем здесь идентификатор segue
    // легко представить два различных segue от этого класса к
    // ImageViewController, но в данный момент у нас единственный segue,
    // так что нам не надо проверять его идентификатор
    
    id ivc = vc;
    
    if ([vc isKindOfClass:[UINavigationController class]]) {
        ivc = [(UINavigationController  *)vc topViewController] ;
    }
    
    if ([ivc isKindOfClass:[ImageViewController class]]) {
        ((ImageViewController *)ivc).imageURL = [NSURL URLWithString:photo.imageURL];
        ((ImageViewController *)ivc).title = photo.title;
        
         ((ImageViewController *)ivc).navigationItem.leftBarButtonItem =
                                          self.splitViewController.displayModeButtonItem;
         ((ImageViewController *)ivc).navigationItem.leftItemsSupplementBackButton = YES;
    }
}

// boilerplate
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = nil;
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        indexPath = [self.tableView indexPathForCell:sender];
    }
    [self prepareViewController:segue.destinationViewController
                       forSegue:segue.identifier
                  fromIndexPath:indexPath];
}

// boilerplate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id detailvc = [self.splitViewController.viewControllers lastObject];
    if ([detailvc isKindOfClass:[UINavigationController class]]) {
        detailvc = [((UINavigationController *)detailvc).viewControllers firstObject];
        [self prepareViewController:detailvc
                           forSegue:nil
                      fromIndexPath:indexPath];
    }
}

@end
