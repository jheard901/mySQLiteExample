//
//  DBTableViewController.h
//  SQLiteExample
//
//  Created by User on 10/17/16.
//  Copyright © 2016 User. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface DBTableViewController : UITableViewController

//@property (nonatomic) sqlite3* contactDb;
@property (strong, nonatomic) NSString* databasePath;

@property (nonatomic, strong) NSMutableArray* contactsArray; //array of contacts based from the SQLite3 db file


- (id) init;

//specifically for getting data from the database created in the first view
- (void)loadData;

@end


