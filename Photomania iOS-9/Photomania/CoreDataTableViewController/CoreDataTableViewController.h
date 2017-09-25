//
//  CoreDataTableViewController.h
//
//  Created for Stanford CS193p Fall 2013.
//  Copyright 2013 Stanford University. All rights reserved.
//
// Этот класс практически полностью копирует код из документации NSFetchedResultsController
//   в subclass of UITableViewController.
//
// Просто создайте subclass этого и установите this and set the fetchedResultsController.
// Единственный метод из методов UITableViewDataSource, который вы ДОЛЖНЫ реализовать - tableView:cellForRowAtIndexPath:.
// Для того, чтобы это сделать, используйте метод objectAtIndexPath:  класса NSFetchedResultsController.
//
// Помните, что создав NSFetchedResultsController, вы НЕ МОЖЕТЕ исменять его @propertys.
// Если вы хотите новые параметры для выборки (предикаты, сортировка и т.д.),
// создайте НОВЫЙ NSFetchedResultsController и установите заново свойство (@property) этого класса.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface CoreDataTableViewController : UITableViewController <NSFetchedResultsControllerDelegate>

// Это Сontroller (этот класс не выберет ничего, если вы это не установите).
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

// Заставляет fetchedResultsController обновлять данные.
// Вам практически никогда не нужно его вызывать.
// NSFetchedResultsController класс отслеживает context
//  (так что, если объекты в context меняются, вам нет необходимости вызывать performFetch
//   так как NSFetchedResultsController заметит изменения и обновит таблицу автоматически).
// Это также будет автоматически вызываться, если вы изменили fetchedResultsController @property.
- (void)performFetch;

// Установите в YES для получения дополнительной информации на консоле при отладке.
@property BOOL debug;

@end
