## What is MongoHub
**[MongoHub](http://mongohub.todayclose.com/)** is a **[mongodb](http://mongodb.org)** GUI application.
This repository is a fork of [MongoHub](https://github.com/bububa/MongoHub-Mac).

## System Requirements

Mac OS X(10.6.x or 10.7.x), intel(64bit/32bit) based.

## Installation

You can either download the compiled executable file from [here](https://github.com/downloads/fotonauts/MongoHub-Mac/MongoHub.zip) 
or clone the source code and compile it on your own system.

## Build

Just build it, it should work (but let me know if you have an errors or warnings).

## Current Status

This project is very new. Any issues or bug reports are welcome. And I still don't have time to write a **usage guide**.

** Known bugs **
    
    - Canot modify indexes in the "Index" tab
    - Don't trust the grey default value in textfields
    - Most of errors are not handled correctly
    - Simple quote is not supported yet for json
    - Key should always be with double quotes

** To do list **
    
    - Should manage a list of database/user/password for each connections
    - Should save the password into the keychain
    - Create a document editor to edit using an outline view (like the plist editor in Xcode)
    - Need a better UI to replace the tabs in a collection window
    
** Current **

    - Fix to parse { "toto" : [ { "1" : 2 }, { "2" : 3 } ] }
    - Display errors (if any) when inserting a document
    - Display errors (if any) when removing a document
    - Fix to remove a document
    
## History

** 2.4.2(76) - 15/10/11 **

    - Crash fixed when using an authenticated database
    - Show all the databases when using authentication
    - Use "admin" database when there is no database set for the authentication
    - Crash fixed when searching for mongo document with "{ "$oid" : "4E40C5111F85DD1BE9FAF825" }"
    - Adding the error message when the search criteria is invalid
    - Trying to be nice to complete your criteria. To search for an id, you can either type: 
            * 123
            * "abc"
            * "$oid" : "123"
            * {"$oid" : "123"}
    - Adding Command-R in the index view to reload the index list


** [Update 2.4.1(75)] **
    
    - Can do export and import (mysql)

** [Update 2.3.2] **
	
	- Fixed a bug in jsoneditor related to Date() object;
	- Add import/export to JSON/CSV functions;
	- Add support for ssh access use public key;
	- Add a function to remove single record in find query window;
	- Fixed a bug to create collection in a database which doesn't have collection;
	
** [Update 2.3.1] **
	
	- Fixed a bug in jsoneditor related to Date() object;
	- Add execution time in find panel;
	- Add reconnect support;
	- Fixed a bug in remove function.

** [2.3.0] **
	
	- Add mongo stat monitor;
	- Add replica set connection support;
	- Add reconnect support;
	- Add an JSON editor for found results with syntax highlight;
	- More flexible query style in find window;
	- Fixed long long int value overflow;
	- Fixed application crash during open/close connection window.

** [2.2.0] **
	
	- SSH Tunnel connection support;
	- Fixed a bug in display ObjectID type fields;
	- Fixed some UI bugs;
	- Fixed some memory leaks and random crashes;
	- Add confirm panel before drop database or collection;
	- Run queries in a seperate thread so that won't block the UI;
	- Fixed a bug to install on some 10.6.x(64bit) system.

** [2.1.0] **
	
	- Auto expand and collaspe finding results;
	- Display Date_t or Timestamp as GMT time format;
	- Fixed a bug in display ObjectIds in Array element;
	- Import data from mysql database to mongodb;
	- Export data from mongodb to mysql database.

** [2.0.9] **
	
	- Add support for mongohq.com;
	- Changed update behavior;
	- Fixed a bug to detect NumberLong type of BSONElement;
	- Fixed a bug in Array type of BSONElement.

** [2.0.8] **
	
	- Fix several UI bugs in Query Window;
	- Fix bugs in Find Query and Update Query;
	- Fix bugs related to ObjectId;
	- Fix copy&paste bugs.

** [2.0.7] **
	
	- Add sparkle framework to check application updates.

** [2.0.6] **
	
	- fixed some UI bugs;
	- add admin auth support.

## Contribute

I'd love to include your contributions, friend.

Then [send me a pull request](https://github.com/fotonauts/MongoHub-Mac/pull/new/master)!
