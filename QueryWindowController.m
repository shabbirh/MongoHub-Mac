//
//  QueryWindowController.m
//  MongoHub
//
//  Created by Syd on 10-4-28.
//  Copyright 2010 ThePeppersStudio.COM. All rights reserved.
//

#import "Configure.h"
#import "NSProgressIndicator+Extras.h"
#import "QueryWindowController.h"
#import "DatabasesArrayController.h"
#import "ResultsOutlineViewController.h"
#import "Connection.h"
#import "NSString+Extras.h"
#import "JsonWindowController.h"
#import "MODServer.h"
#import "MODCollection.h"
#import "MODDatabase.h"
#import "MODHelper.h"
#import "MODJsonParser.h"

@implementation QueryWindowController

@synthesize managedObjectContext;
@synthesize databasesArrayController;
@synthesize findResultsViewController;
@synthesize mongoCollection;
@synthesize conn;

@synthesize criticalTextField;
@synthesize fieldsTextField;
@synthesize skipTextField;
@synthesize limitTextField;
@synthesize sortTextField;
@synthesize totalResultsTextField;
@synthesize findQueryTextField;
@synthesize findResultsOutlineView;
@synthesize findQueryLoaderIndicator;

@synthesize updateCriticalTextField;
@synthesize updateSetTextField;
@synthesize upsetCheckBox;
@synthesize updateResultsTextField;
@synthesize updateQueryTextField;
@synthesize updateQueryLoaderIndicator;

@synthesize removeCriticalTextField;
@synthesize removeResultsTextField;
@synthesize removeQueryTextField;
@synthesize removeQueryLoaderIndicator;

@synthesize insertDataTextView;
@synthesize insertResultsTextField;
@synthesize insertLoaderIndicator;

@synthesize indexTextField;
@synthesize indexesOutlineViewController;
@synthesize indexLoaderIndicator;

@synthesize mapFunctionTextView;
@synthesize reduceFunctionTextView;
@synthesize mrcriticalTextField;
@synthesize mroutputTextField;
@synthesize mrOutlineViewController;
@synthesize mrLoaderIndicator;

@synthesize expCriticalTextField;
@synthesize expFieldsTextField;
@synthesize expSkipTextField;
@synthesize expLimitTextField;
@synthesize expSortTextField;
@synthesize expResultsTextField;
@synthesize expPathTextField;
@synthesize expTypePopUpButton;
@synthesize expQueryTextField;
@synthesize expJsonArrayCheckBox;
@synthesize expProgressIndicator;

@synthesize impIgnoreBlanksCheckBox;
@synthesize impDropCheckBox;
@synthesize impHeaderlineCheckBox;
@synthesize impFieldsTextField;
@synthesize impResultsTextField;
@synthesize impPathTextField;
@synthesize impTypePopUpButton;
@synthesize impJsonArrayCheckBox;
@synthesize impStopOnErrorCheckBox;
@synthesize impProgressIndicator;


- (id)init {
    self = [super initWithWindowNibName:@"QueryWindow"];
    return self;
}

- (void)dealloc {
    [managedObjectContext release];
    [databasesArrayController release];
    [findResultsViewController release];
    [conn release];
    [mongoCollection release];
    
    [criticalTextField release];
    [fieldsTextField release];
    [skipTextField release];
    [limitTextField release];
    [sortTextField release];
    [totalResultsTextField release];
    [findQueryTextField release];
    [findResultsOutlineView release];
    [findQueryLoaderIndicator release];
    
    [updateCriticalTextField release];
    [updateSetTextField release];
    [upsetCheckBox release];
    [updateResultsTextField release];
    [updateQueryTextField release];
    [updateQueryLoaderIndicator release];
    
    [removeCriticalTextField release];
    [removeResultsTextField release];
    [removeQueryTextField release];
    [removeQueryLoaderIndicator release];
    
    [insertDataTextView release];
    [insertResultsTextField release];
    [insertLoaderIndicator release];
    
    [indexTextField release];
    [indexesOutlineViewController release];
    [indexLoaderIndicator release];
    
    [mapFunctionTextView release];
    [reduceFunctionTextView release];
    [mrcriticalTextField release];
    [mroutputTextField release];
    [mrOutlineViewController release];
    [mrLoaderIndicator release];
    
    [expCriticalTextField release];
    [expFieldsTextField release];
    [expSkipTextField release];
    [expLimitTextField release];
    [expSortTextField release];
    [expResultsTextField release];
    [expPathTextField release];
    [expTypePopUpButton release];
    [expQueryTextField release];
    [expJsonArrayCheckBox release];
    [expProgressIndicator release];
    
    [impIgnoreBlanksCheckBox release];
    [impDropCheckBox release];
    [impHeaderlineCheckBox release];
    [impFieldsTextField release];
    [impResultsTextField release];
    [impPathTextField release];
    [impTypePopUpButton release];
    [impJsonArrayCheckBox release];
    [impStopOnErrorCheckBox release];
    [impProgressIndicator release];
    
    [super dealloc];
}

- (NSString *)formatedQueryWithReplace:(BOOL)replace
{
    NSString *query = @"";
    NSString *value;
    
    value = [[criticalTextField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([value length] > 0) {
        if ([value hasPrefix:@"{"]) {
            NSString *innerValue;
            
            innerValue = [[value substringFromIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([innerValue hasPrefix:@"\"$oid\""] || [innerValue hasPrefix:@"'$iod'"]) {
                query = [NSString stringWithFormat:@"{\"_id\": %@ }",value];
            } else {
                query = value;
            }
        } else if ([value hasPrefix:@"\"$oid\""] || [value hasPrefix:@"'$iod'"]) {
            query = [NSString stringWithFormat:@"{\"_id\": {%@}}",value];
        } else {
            query = [NSString stringWithFormat:@"{\"_id\": %@}",value];
        }
    }
    if (replace) {
        [criticalTextField setStringValue:query];
    }
    return query;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    NSString *title = [[NSString alloc] initWithFormat:@"Query in %@", mongoCollection.absoluteCollectionName];
    [self.window setTitle:title];
    [title release];
}

- (void)windowWillClose:(NSNotification *)notification {
    [self release];
}

- (IBAction)findQuery:(id)sender
{
    int limit = [limitTextField intValue];
    NSMutableArray *fields;
    NSString *criteria;
    
    if (limit <= 0) {
        limit = 30;
    }
    criteria = [self formatedQueryWithReplace:YES];
    fields = [[NSMutableArray alloc] init];
    for (NSString *field in [[fieldsTextField stringValue] componentsSeparatedByString:@","]) {
        field = [field stringByTrimmingWhitespace];
        if ([field length] > 0) {
            [fields addObject:field];
        }
    }
    [findQueryLoaderIndicator start];
    [mongoCollection findWithCriteria:criteria fields:fields skip:[skipTextField intValue] limit:limit sort:[sortTextField stringValue] callback:^(NSArray *documents, MODQuery *mongoQuery) {
        if (mongoQuery.error) {
            [findQueryLoaderIndicator stop];
            NSRunAlertPanel(@"Error", [mongoQuery.error localizedDescription], @"OK", nil, nil);
        } else {
            [findResultsViewController.results removeAllObjects];
            [findResultsViewController.results addObjectsFromArray:[MODHelper convertForOutlineWithObjects:documents]];
            [findResultsViewController.myOutlineView reloadData];
            [mongoCollection countWithCriteria:criteria callback:^(int64_t count, MODQuery *mongoQuery) {
                [findQueryLoaderIndicator stop];
                [totalResultsTextField setStringValue:[NSString stringWithFormat:@"Total Results: %lld (%0.2fs)", count, [[mongoQuery.userInfo objectForKey:@"timequery"] duration]]];
            }];
        }
    }];
    [fields release];
}

- (IBAction)expandFindResults:(id)sender
{
    [findResultsOutlineView expandItem:nil expandChildren:YES];
}

- (IBAction)collapseFindResults:(id)sender
{
    [findResultsOutlineView collapseItem:nil collapseChildren:YES];
}

- (IBAction)updateQuery:(id)sender
{
    NSString *criteria = [updateCriticalTextField stringValue];
    
    [updateQueryLoaderIndicator start];
    [mongoCollection countWithCriteria:criteria callback:^(int64_t count, MODQuery *mongoQuery) {
        [updateResultsTextField setStringValue:[NSString stringWithFormat:@"Affected Rows: %lld", count]];
    }];
    [mongoCollection updateWithCriteria:criteria update:[updateSetTextField stringValue] upsert:[upsetCheckBox state] multiUpdate:YES callback:^(MODQuery *mongoQuery) {
        [updateQueryLoaderIndicator stop];
    }];
}

- (IBAction)removeQuery:(id)sender
{
    [removeQueryLoaderIndicator start];
    NSString *criteria = [removeCriticalTextField stringValue];
    
    [mongoCollection countWithCriteria:criteria callback:^(int64_t count, MODQuery *mongoQuery) {
        [updateResultsTextField setStringValue:[NSString stringWithFormat:@"Affected Rows: %lld", count]];
    }];
    [mongoCollection removeWithCriteria:criteria callback:^(MODQuery *mongoQuery) {
        [removeQueryLoaderIndicator stop];
    }];
}

- (IBAction) insertQuery:(id)sender
{
    id objects;
    NSError *error;
    
    [insertLoaderIndicator start];
    objects = [MODJsonToObjectParser objectsFromJson:[insertDataTextView string] error:&error];
    if (error) {
        NSRunAlertPanel(@"Error", [error localizedDescription], @"OK", nil, nil);
    } else {
        if ([objects isKindOfClass:[NSDictionary class]]) {
            objects = [NSArray arrayWithObject:objects];
        }
        [mongoCollection insertWithDocuments:objects callback:^(MODQuery *mongoQuery) {
            [insertLoaderIndicator stop];
            if (mongoQuery.error) {
                NSRunAlertPanel(@"Error", [mongoQuery.error localizedDescription], @"OK", nil, nil);
                [insertResultsTextField setStringValue:@"Error!"];
            } else {
                [insertResultsTextField setStringValue:@"Completed!"];
            }
        }];
    }
}

- (IBAction) indexQuery:(id)sender
{
    [mongoCollection indexListWithcallback:^(NSArray *indexes, MODQuery *mongoQuery) {
        if (mongoQuery.error) {
            NSRunAlertPanel(@"Error", [mongoQuery.error localizedDescription], @"OK", nil, nil);
        }
        [indexesOutlineViewController.results removeAllObjects];
        [indexesOutlineViewController.results addObjectsFromArray:[MODHelper convertForOutlineWithObjects:indexes]];
        [indexesOutlineViewController.myOutlineView reloadData];
    }];
}

- (IBAction) ensureIndex:(id)sender
{
    [indexLoaderIndicator start];
    [mongoCollection createIndex:[indexTextField stringValue] name:nil options:0 callback:^(MODQuery *mongoQuery) {
        if (mongoQuery.error) {
            NSRunAlertPanel(@"Error", [mongoQuery.error localizedDescription], @"OK", nil, nil);
        } else {
            [indexTextField setStringValue:@""];
        }
        [indexLoaderIndicator stop];
        [self indexQuery:nil];
    }];
}


- (IBAction) reIndex:(id)sender
{
    [indexLoaderIndicator start];
    [mongoCollection reIndexWithCallback:^(MODQuery *mongoQuery) {
        if (mongoQuery.error) {
            NSRunAlertPanel(@"Error", [mongoQuery.error localizedDescription], @"OK", nil, nil);
        } else {
            [indexTextField setStringValue:@""];
        }
        [indexLoaderIndicator stop];
    }];
}

- (IBAction) dropIndex:(id)sender
{
    [indexLoaderIndicator start];
    [mongoCollection dropIndex:[[indexesOutlineViewController.selectedDocument objectForKey:@"objectvalue"] objectForKey:@"key"] callback:^(MODQuery *mongoQuery) {
        if (mongoQuery.error) {
            NSRunAlertPanel(@"Error", [mongoQuery.error localizedDescription], @"OK", nil, nil);
        }
        [indexLoaderIndicator stop];
        [self indexQuery:nil];
    }];
}

- (IBAction) mapReduce:(id)sender
{
    [mongoCollection mapReduceWithMapFunction:[mapFunctionTextView string] reduceFunction:[reduceFunctionTextView string] query:[mrcriticalTextField stringValue] sort:nil limit:-1 output:[mroutputTextField stringValue] keepTemp:NO finalizeFunction:nil scope:nil jsmode:NO verbose:NO callback:^(MODQuery *mongoQuery) {
        if (mongoQuery.error) {
            NSRunAlertPanel(@"Error", [mongoQuery.error localizedDescription], @"OK", nil, nil);
        }
    }];
}

- (IBAction)removeRecord:(id)sender
{
    if ([findResultsViewController.myOutlineView selectedRow] != -1)
    {
        NSDictionary *criteria;
        id currentItem = [findResultsViewController.myOutlineView itemAtRow:[findResultsViewController.myOutlineView selectedRow]];
        //NSLog(@"%@", [findResultsViewController rootForItem:currentItem]);
        [removeQueryLoaderIndicator start];
        
        criteria = [[NSDictionary alloc] initWithObjectsAndKeys:[currentItem objectForKey:@"objectvalueid"], @"_id", nil];
        [mongoCollection removeWithCriteria:criteria callback:^(MODQuery *mongoQuery) {
            if (mongoQuery.error) {
                NSRunAlertPanel(@"Error", [mongoQuery.error localizedDescription], @"OK", nil, nil);
            }
            [removeQueryLoaderIndicator stop];
            [self findQuery:nil];
        }];
        [criteria release];
    }
}

- (void)controlTextDidChange:(NSNotification *)nd
{
	NSTextField *ed = [nd object];
    
	if (ed == criticalTextField || ed == fieldsTextField || ed == sortTextField || ed == skipTextField || ed == limitTextField) {
        [self findQueryComposer:nil];
    } else if (ed == updateCriticalTextField || ed == updateSetTextField) {
        [self updateQueryComposer:nil];
    } else if (ed == removeCriticalTextField) {
        [self removeQueryComposer:nil];
    } else if (ed == expCriticalTextField || ed == expFieldsTextField || ed == expSortTextField || ed == expSkipTextField || ed == expLimitTextField) {
        [self exportQueryComposer:nil];
    }

}

- (IBAction) findQueryComposer:(id)sender
{
    NSString *critical;
    critical = [self formatedQueryWithReplace:NO];
    
    NSString *jsFields;
    if ([[fieldsTextField stringValue] length] > 0) {
        NSArray *keys = [[NSArray alloc] initWithArray:[[fieldsTextField stringValue] componentsSeparatedByString:@","]];
        NSMutableArray *tmpstr = [[NSMutableArray alloc] initWithCapacity:[keys count]];
        for (NSString *str in keys) {
            [tmpstr addObject:[NSString stringWithFormat:@"%@:1", str]];
        }
        jsFields = [[NSString alloc] initWithFormat:@", {%@}", [tmpstr componentsJoinedByString:@","] ];
        [keys release];
        [tmpstr release];
    }else {
        jsFields = [[NSString alloc] initWithString:@""];
    }
    
    NSString *sort;
    if ([[sortTextField stringValue] length] > 0) {
        sort = [[NSString alloc] initWithFormat:@".sort(%@)", [sortTextField stringValue]];
    }else {
        sort = [[NSString alloc] initWithString:@""];
    }
    
    NSString *skip = [[NSString alloc] initWithFormat:@".skip(%d)", [skipTextField intValue]];
    NSString *limit = [[NSString alloc] initWithFormat:@".limit(%d)", [limitTextField intValue]];
    NSString *col = [NSString stringWithFormat:@"%@.%@", mongoCollection.databaseName, mongoCollection.collectionName];
    
    NSString *query = [NSString stringWithFormat:@"db.%@.find(%@%@)%@%@%@", col, critical, jsFields, sort, skip, limit];
    [jsFields release];
    [sort release];
    [skip release];
    [limit release];
    [findQueryTextField setStringValue:query];
}

- (IBAction)updateQueryComposer:(id)sender
{
    NSString *col = [NSString stringWithFormat:@"%@.%@", mongoCollection.databaseName, mongoCollection.collectionName];
    NSString *critical;
    if ([[updateCriticalTextField stringValue] length] > 0) {
        critical = [[NSString alloc] initWithString:[updateCriticalTextField stringValue]];
    }else {
        critical = [[NSString alloc] initWithString:@""];
    }
    NSString *sets;
    if ([[updateSetTextField stringValue] length] > 0) {
        //sets = [[NSString alloc] initWithFormat:@", {$set:%@}", [updateSetTextField stringValue]];
        sets = [[NSString alloc] initWithFormat:@", %@", [updateSetTextField stringValue]];
    }else {
        sets = [[NSString alloc] initWithString:@""];
    }
    NSString *upset;
    if ([upsetCheckBox state] == 1) {
        upset = [[NSString alloc] initWithString:@", true"];
    }else {
        upset = [[NSString alloc] initWithString:@", false"];
    }

    NSString *query = [NSString stringWithFormat:@"db.%@.update(%@%@%@)", col, critical, sets, upset];
    [critical release];
    [sets release];
    [upset release];
    [updateQueryTextField setStringValue:query];
}

- (IBAction)removeQueryComposer:(id)sender
{
    NSString *col = [NSString stringWithFormat:@"%@.%@", mongoCollection.databaseName, mongoCollection.collectionName];
    NSString *critical;
    if ([[removeCriticalTextField stringValue] length] > 0) {
        critical = [[NSString alloc] initWithString:[removeCriticalTextField stringValue]];
    }else {
        critical = [[NSString alloc] initWithString:@""];
    }
    NSString *query = [NSString stringWithFormat:@"db.%@.remove(%@)", col, critical];
    [critical release];
    [removeQueryTextField setStringValue:query];
}

- (IBAction) exportQueryComposer:(id)sender
{
    NSString *critical;
    if ([[expCriticalTextField stringValue] length] > 0) {
        critical = [[NSString alloc] initWithString:[expCriticalTextField stringValue]];
    }else {
        critical = [[NSString alloc] initWithString:@""];
    }
    
    NSString *jsFields;
    if ([[expFieldsTextField stringValue] length] > 0) {
        NSArray *keys = [[NSArray alloc] initWithArray:[[expFieldsTextField stringValue] componentsSeparatedByString:@","]];
        NSMutableArray *tmpstr = [[NSMutableArray alloc] initWithCapacity:[keys count]];
        for (NSString *str in keys) {
            [tmpstr addObject:[NSString stringWithFormat:@"%@:1", str]];
        }
        jsFields = [[NSString alloc] initWithFormat:@", {%@}", [tmpstr componentsJoinedByString:@","] ];
        [keys release];
        [tmpstr release];
    }else {
        jsFields = [[NSString alloc] initWithString:@""];
    }
    
    NSString *sort;
    if ([[expSortTextField stringValue] length] > 0) {
        sort = [[NSString alloc] initWithFormat:@".sort(%@)"];
    }else {
        sort = [[NSString alloc] initWithString:@""];
    }
    
    NSString *skip = [[NSString alloc] initWithFormat:@".skip(%d)", [expSkipTextField intValue]];
    NSString *limit = [[NSString alloc] initWithFormat:@".limit(%d)", [expLimitTextField intValue]];
    NSString *col = [NSString stringWithFormat:@"%@.%@", mongoCollection.databaseName, mongoCollection.collectionName];
    
    NSString *query = [NSString stringWithFormat:@"db.%@.find(%@%@)%@%@%@", col, critical, jsFields, sort, skip, limit];
    [critical release];
    [jsFields release];
    [sort release];
    [skip release];
    [limit release];
    [expQueryTextField setStringValue:query];
}

- (void)showEditWindow:(id)sender
{
    switch([findResultsViewController.myOutlineView selectedRow])
	{
		case -1:
			break;
		default:{
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(findQuery:) name:kJsonWindowSaved object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(jsonWindowWillClose:) name:kJsonWindowWillClose object:nil];
            id currentItem = [findResultsViewController.myOutlineView itemAtRow:[findResultsViewController.myOutlineView selectedRow]];
            //NSLog(@"%@", [findResultsViewController rootForItem:currentItem]);
            JsonWindowController *jsonWindowController = [[JsonWindowController alloc] init];
            jsonWindowController.managedObjectContext = self.managedObjectContext;
            jsonWindowController.conn = conn;
            jsonWindowController.mongoCollection = mongoCollection;
            jsonWindowController.jsonDict = [findResultsViewController rootForItem:currentItem];
            [jsonWindowController showWindow:sender];
			break;
        }
	}
}

- (void)jsonWindowWillClose:(id)sender
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)chooseExportPath:(id)sender
{
    NSSavePanel *tvarNSSavePanelObj	= [NSSavePanel savePanel];
    int tvarInt	= [tvarNSSavePanelObj runModal];
    if(tvarInt == NSOKButton){
     	NSLog(@"doSaveAs we have an OK button");
        //NSString * tvarDirectory = [tvarNSSavePanelObj directory];
        //NSLog(@"doSaveAs directory = %@",tvarDirectory);
        NSString * tvarFilename = [[tvarNSSavePanelObj URL] path];
        NSLog(@"doSaveAs filename = %@",tvarFilename);
        [expPathTextField setStringValue:tvarFilename];
    } else if(tvarInt == NSCancelButton) {
     	NSLog(@"doSaveAs we have a Cancel button");
     	return;
    } else {
     	NSLog(@"doSaveAs tvarInt not equal 1 or zero = %3d",tvarInt);
     	return;
    } // end if
}

- (IBAction)chooseImportPath:(id)sender
{
    NSOpenPanel *tvarNSOpenPanelObj	= [NSOpenPanel openPanel];
    NSInteger tvarNSInteger	= [tvarNSOpenPanelObj runModal];
    if(tvarNSInteger == NSOKButton){
     	NSLog(@"doOpen we have an OK button");
        //NSString * tvarDirectory = [tvarNSOpenPanelObj directory];
        //NSLog(@"doOpen directory = %@",tvarDirectory);
        NSString * tvarFilename = [[tvarNSOpenPanelObj URL] path];
        NSLog(@"doOpen filename = %@",tvarFilename);
        [impPathTextField setStringValue:tvarFilename];
    } else if(tvarNSInteger == NSCancelButton) {
     	NSLog(@"doOpen we have a Cancel button");
     	return;
    } else {
     	NSLog(@"doOpen tvarInt not equal 1 or zero = %ld",(long int)tvarNSInteger);
     	return;
    } // end if
}

//- (mongo::BSONObj)parseCSVLine:(char *) line type:(int)_type sep:(const char *)_sep headerLine:(bool)_headerLine ignoreBlanks:(bool)_ignoreBlanks fields:(std::vector<std::string>&)_fields
//{
//    if ( _type == 0 ) {
//        char * end = ( line + strlen( line ) ) - 1;
//        while ( std::isspace(*end) ) {
//            *end = 0;
//            end--;
//        }
//        return mongo::fromjson( line );
//    }
//    mongo::BSONObjBuilder b;
//    
//    unsigned int pos=0;
//    while ( line[0] ) {
//        std::string name;
//        if ( pos < _fields.size() ) {
//            name = _fields[pos];
//        }else {
//            std::stringstream ss;
//            ss << "field" << pos;
//            name = ss.str();
//        }
//        pos++;
//        
//        bool done = false;
//        std::string data;
//        char * end;
//        if ( _type == 1 && line[0] == '"' ) {
//            line++; //skip first '"'
//            
//            while (true) {
//                end = strchr( line , '"' );NSLog(@"%s", line);
//                if (!end) {
//                    data += line;
//                    done = true;
//                    break;
//                } else if (end[1] == '"') {
//                    // two '"'s get appended as one
//                    data.append(line, end-line+1); //include '"'
//                    line = end+2; //skip both '"'s
//                } else if (end[-1] == '\\') {
//                    // "\\\"" gets appended as '"'
//                    data.append(line, end-line-1); //exclude '\\'
//                    data.append("\"");
//                    line = end+1; //skip the '"'
//                } else {
//                    data.append(line, end-line);
//                    line = end+2; //skip '"' and ','
//                    break;
//                }
//            }
//        } else {
//            end = strstr( line , _sep );NSLog(@"end: %s", end);
//            if ( ! end ) {
//                done = true;
//                data = std::string( line );
//            } else {
//                data = std::string( line , end - line );
//                line = end+1;
//            }
//        }
//        
//        if ( _headerLine ) {
//            while ( std::isspace( data[0] ) )
//                data = data.substr( 1 );
//            _fields.push_back( data );
//        }else{
//            if ( !b.appendAsNumber( name , data ) && !(_ignoreBlanks && data.size() == 0) ){
//                b.append( name , data );
//            }
//        }
//        
//        if ( done )
//            break;
//    }
//    return b.obj();
//}

- (IBAction)segmentedControlAction:(id)sender
{
    NSString *identifier;
    
    identifier = [[NSString alloc] initWithFormat:@"%ld", [segmentedControl selectedSegment]];
    [tabView selectTabViewItemWithIdentifier:identifier];
    [identifier release];
}

@end

@implementation QueryWindowController(MODCollectionDelegate)

- (void)mongoCollection:(MODCollection *)collection queryResultFetched:(NSArray *)result withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage
{
    [findQueryLoaderIndicator stop];
    if (collection == mongoCollection) {
        if (errorMessage) {
            NSRunAlertPanel(@"Error", errorMessage, @"OK", nil, nil);
        } else {
            [findResultsViewController.results removeAllObjects];
            [findResultsViewController.results addObjectsFromArray:result];
            [findResultsViewController.myOutlineView reloadData];
        }
    }
}

- (void)mongoCollection:(MODCollection *)collection queryCountWithValue:(long long)value withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage
{
    if (collection == mongoCollection) {
        if ([mongoQuery.userInfo objectForKey:@"title"]) {
            if ([mongoQuery.userInfo objectForKey:@"timequery"]) {
                [[mongoQuery.userInfo objectForKey:@"textfield"] setStringValue:[NSString stringWithFormat:[mongoQuery.userInfo objectForKey:@"title"], value, [[mongoQuery.userInfo objectForKey:@"timequery"] duration]]];
            } else {
                [[mongoQuery.userInfo objectForKey:@"textfield"] setStringValue:[NSString stringWithFormat:[mongoQuery.userInfo objectForKey:@"title"], value]];
            }
        }
    }
}

- (void)mongoCollection:(MODCollection *)collection updateDonwWithMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage
{
    if (collection == mongoCollection) {
        [findQueryLoaderIndicator stop];
        if (errorMessage) {
            NSRunAlertPanel(@"Error", errorMessage, @"OK", nil, nil);
        }
    }
}

@end
