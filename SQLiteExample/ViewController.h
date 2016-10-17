//
//  ViewController.h
//  SQLiteExample
//
//  Created by User on 10/16/16.
//  Copyright © 2016 User. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sqlite3.h>


@interface ViewController : UIViewController <UITextFieldDelegate>
{
    
}


@property (strong, nonatomic) IBOutlet UITextField *nameTextField;
@property (strong, nonatomic) IBOutlet UITextField *addressTextField;
@property (strong, nonatomic) IBOutlet UITextField *phoneTextField;
@property (strong, nonatomic) IBOutlet UILabel *outputLabel;

//variable for database
@property (nonatomic) sqlite3* contactDB;
@property (strong, nonatomic) NSString* databasePath;

//specifically for one example for db
@property (nonatomic, strong) NSMutableArray *arrResults;
@property (nonatomic, strong) NSMutableArray *arrColumnNames;
- (void) runQuery:(const char*)query;


- (IBAction)pressedSaveData:(id)sender;
- (IBAction)pressedFindData:(id)sender;
- (IBAction)pressedDeleteData:(id)sender;



@end




