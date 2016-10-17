//
//  ViewController.m
//  SQLiteExample
//
//  Created by User on 10/16/16.
//  Copyright © 2016 User. All rights reserved.
//

#import "ViewController.h"
#import "DBTableViewController.h"



@interface ViewController ()

@end



@implementation ViewController


//more detailed and advanced tutorial on using SQLite3: http://www.appcoda.com/sqlite-database-ios-app-tutorial/


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.nameTextField.delegate = self;
    self.addressTextField.delegate = self;
    self.phoneTextField.delegate = self;
    
    //proper simple tutorial from: https://www.techotopia.com/index.php/An_Example_SQLite_based_iOS_7_Application
    /* create a file for database if it does not already exist */
    
    NSString* docsDirectory;
    NSArray* dirPaths;
    
    //store an array of paths to the specified location on disk
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    //set our path to use for default location of the db (in this case, we have appended the filename to the pathname)
    docsDirectory = [dirPaths objectAtIndex:0];
    self.databasePath = [[NSString alloc] initWithString:[docsDirectory stringByAppendingPathComponent:@"contacts.db"]];
    
    NSFileManager* filemgr = [NSFileManager defaultManager];
    
    if([filemgr fileExistsAtPath:self.databasePath] == NO)
    {
        //UTF8String is a pointer to a struct within a string (used specifically for SQLite)
        const char* dbPath = [self.databasePath UTF8String];
        
        //if the path to the specified file can be opened, proceed
        if(sqlite3_open(dbPath, &_contactDB) == SQLITE_OK)
        {
            //object to save errors
            char* errorMsg;
            
            //create the DB (this text apparently isn't just for notes sake, it looks like a script for SQLite)
            const char* sql_stmt = "CREATE TABLE IF NOT EXISTS CONTACTS (ID INTEGER PRIMARY KEY AUTOINCREMENT, NAME TEXT, ADDRESS TEXT, PHONE TEXT)";
            
            //show error if can't open table
            if( sqlite3_exec(self.contactDB, sql_stmt, NULL, NULL, &errorMsg) != SQLITE_OK)
            {
                self.outputLabel.text =[NSString stringWithFormat:@"Failed to create table. Error: %s", sqlite3_errmsg(_contactDB)];
            }
            sqlite3_close(self.contactDB);
            
        }
        else
        {
            self.outputLabel.text = @"Failed to open/create database.";
        }
        
    }
    
}



- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

/*save the current record into the database; this does not check for duplicates, so it simply ignores requests to add duplicate values */

- (IBAction)pressedSaveData:(id)sender
{
    //create sql statement
    sqlite3_stmt* statement;
    const char* dbPath = [self.databasePath UTF8String];
    
    //if the path can be opened
    if(sqlite3_open(dbPath, &_contactDB) == SQLITE_OK)
    {
        //backslashes i.e. '\' before quotes inside a string literal allows you to uses quotes within the string (its like a command similar to the \n for newline)
        //prepare a script to send SQLite db object
        NSString* insertSQL = [NSString stringWithFormat:@"INSERT INTO CONTACTS (name, address, phone) VALUES (\"%@\", \"%@\", \"%@\")", self.nameTextField.text, self.addressTextField.text, self.phoneTextField.text];
        NSLog(@"%@", insertSQL); //debug output optional
        
        //convert to format usable by SQLite
        const char* insert_stmt = [insertSQL UTF8String];
        
        //not sure what this does (no local documentation for it)
        sqlite3_prepare_v2(self.contactDB, insert_stmt, -1, &statement, NULL);
        
        //if the SQLite statment has been successfully executed
        if(sqlite3_step(statement) == SQLITE_DONE)
        {
            self.outputLabel.text = @"Contact saved.";
            self.nameTextField.text = @"";
            self.addressTextField.text = @"";
            self.phoneTextField.text = @"";
            
        }
        else
        {
            self.outputLabel.text = @"Failed to add contact.";
        }
        
        sqlite3_finalize(statement);
        sqlite3_close(self.contactDB);
    }
}

/* Search the database to retrieve data based off a key (the name in this case) */

- (IBAction)pressedFindData:(id)sender
{
    sqlite3_stmt* statement;
    const char* dbPath = [self.databasePath UTF8String];
    
    //open the db
    if(sqlite3_open(dbPath, &_contactDB) == SQLITE_OK)
    {
        //create the SQL statement to retrieve the data
        NSString* querySQL = [NSString stringWithFormat:@"SELECT address, phone FROM contacts WHERE name=\"%@\"", self.nameTextField.text];
        const char* query_stmt = [querySQL UTF8String];
        
        //prepare the query
        if(sqlite3_prepare_v2(self.contactDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            //if query was ok, we must have a row if the data was there
            if(sqlite3_step(statement) == SQLITE_ROW)
            {
                //parse the SQL column text to retrieve the address
                NSString* addressField = [[NSString alloc] initWithUTF8String:(const char*)sqlite3_column_text(statement, 0)];
                self.addressTextField.text = addressField;
                
                //parse the SQL column text to retreive the phone
                NSString* phoneField = [[NSString alloc] initWithUTF8String:(const char*)sqlite3_column_text(statement, 1)];
                self.phoneTextField.text = phoneField;
                
                self.outputLabel.text = @"Match Found.";
            }
            else
            {
                //if there is not a row, the data is not found
                self.outputLabel.text = @"Match not found.";
                self.addressTextField.text = @"";
                self.phoneTextField.text = @"";
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(self.contactDB);
    }
}

/* Search the database to delete data based off a key (the name in this case) */

- (IBAction)pressedDeleteData:(id)sender
{
    //create the statement
    sqlite3_stmt* statement;
    const char* dbPath = [self.databasePath UTF8String];
    
    //open the db | note we can use "contactDB" without writing it as "self.contactDB" because it is a private variable
    if(sqlite3_open(dbPath, &_contactDB) == SQLITE_OK)
    {
        //create the SQL statement to delete the data | info from: https://www.tutorialspoint.com/sqlite/sqlite_delete_query.htm
        //NSString* querySQL = [NSString stringWithFormat:@"DELETE FROM CONTACTS WHERE name IS '%@'", self.nameTextField.text]; //original MAC tut code; buggy
        NSString* querySQL = [NSString stringWithFormat:@"DELETE FROM CONTACTS WHERE name = \"%@\"", self.nameTextField.text];
        const char* query_stmt = [querySQL UTF8String];
        
        //prepare the query | fix for deleting: http://stackoverflow.com/questions/4300613/cant-delete-row-from-sqlite-database-yet-no-errors-are-issued
        if(sqlite3_prepare_v2(self.contactDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            //execute the query on success
            sqlite3_step(statement);
            
            //output to notify user it happened
            self.addressTextField.text = @"";
            self.phoneTextField.text = @"";
            self.outputLabel.text = @"Record deleted.";
        }
        else
        {
            //if there is not a row, then the data is not found
            self.outputLabel.text = @"Record not found.";
            self.addressTextField.text = @"";
            self.phoneTextField.text = @"";
        }
        
        sqlite3_finalize(statement);
        sqlite3_close(self.contactDB); //remember to close the database if it has been successfully opened
    }
}

//gets data from table | based off the function in this tut: http://www.appcoda.com/sqlite-database-ios-app-tutorial/
- (void)runQuery:(const char *)query
{
    //this is the query specifically being used with this function
    //NSString* query = @"select * from CONTACTS";
    
    
    // Initialize the results array.
    if (self.arrResults != nil)
    {
        [self.arrResults removeAllObjects];
        self.arrResults = nil;
    }
    self.arrResults = [[NSMutableArray alloc] init];
    
    // Initialize the column names array.
    if (self.arrColumnNames != nil)
    {
        [self.arrColumnNames removeAllObjects];
        self.arrColumnNames = nil;
    }
    self.arrColumnNames = [[NSMutableArray alloc] init];
    
    
    
    // Open the database.
    sqlite3_stmt* statement;
    const char* dbPath = [self.databasePath UTF8String];
    
    //open the db
    if(sqlite3_open(dbPath, &_contactDB) == SQLITE_OK)
    {
        
        //create the SQL statement to retrieve the data
        const char* query_stmt = query;
        
        //prepare the query
        if(sqlite3_prepare_v2(self.contactDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            
            // Declare an array to keep the data for each fetched row.
            NSMutableArray* arrDataRow;
            
            // Loop through the results and add them to the results array row by row.
            while(sqlite3_step(statement) == SQLITE_ROW)
            {
                
                // Initialize the mutable array that will contain the data of a fetched row.
                arrDataRow = [[NSMutableArray alloc] init];
                
                // Get the total number of columns.
                int totalColumns = sqlite3_column_count(statement);
                
                
                // Go through all columns and fetch each column data.
                for (int i = 0; i < totalColumns; i++)
                {
                    // Convert the column data to text (characters).
                    char *dbDataAsChars = (char *)sqlite3_column_text(statement, i);
                    
                    // If there are contents in the currenct column (field) then add them to the current row array.
                    if (dbDataAsChars != NULL)
                    {
                        // Convert the characters to string.
                        [arrDataRow addObject:[NSString  stringWithUTF8String:dbDataAsChars]];
                    }
                    
                    // Keep the current column name.
                    if (self.arrColumnNames.count != totalColumns)
                    {
                        dbDataAsChars = (char *)sqlite3_column_name(statement, i);
                        [self.arrColumnNames addObject:[NSString stringWithUTF8String:dbDataAsChars]];
                    }
                }
                
                // Store each fetched data row in the results array, but first check if there is actually data.
                if (arrDataRow.count > 0)
                {
                    [self.arrResults addObject:arrDataRow];
                }
            }
        }
        sqlite3_finalize(statement);
    }
    sqlite3_close(self.contactDB);
}




-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"dbTableSegue"])
    {
        /* pass an array of data (the contacts) to the new view */
        
        DBTableViewController* dbTableViewController = (DBTableViewController*)segue.destinationViewController;
        
        /* get data from database */
        
        //make the query
        NSString* query = @"select * from CONTACTS";
        
        //this function fills arrResults with values
        [self runQuery: [query UTF8String]];
        
        //passes data to the table view (forgot to set the view controller in storyboard to use the proper class, problem solved now)
//        dbTableViewController.contactsArray = [[NSMutableArray alloc] init];
//        for(int i = 0; i < [self.arrResults count]; i++)
//        {
//            [dbTableViewController.contactsArray insertObject:[self.arrResults objectAtIndex:i] atIndex:i];
//            
//        }
        
        dbTableViewController.contactsArray = [[NSMutableArray alloc] initWithArray:(NSArray*)self.arrResults];
        
    }
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}





@end






