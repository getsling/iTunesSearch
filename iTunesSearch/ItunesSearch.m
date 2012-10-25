//
//  ItunesSearch.m
//  iTunesSearch
//
//  Created by Piers Biddlestone on 28/09/12.
//  Copyright (c) 2012 Gangverk. All rights reserved.
//

#import "ItunesSearch.h"

#define API_URL @"http://itunes.apple.com/"

@interface ItunesSearch ()
@property (nonatomic, strong) NSOperationQueue *queue;
@end

@implementation ItunesSearch

#pragma mark - Initialization

+ (ItunesSearch *)sharedInstance {
    static dispatch_once_t pred;
    static ItunesSearch *sharedInstance = nil;
    dispatch_once(&pred, ^{ sharedInstance = [[self alloc] init]; });
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        self.partnerId = @"";
        self.tradeDoublerId = @"";
        self.queue = [[NSOperationQueue alloc] init];
    }
    return self;
}

#pragma mark - Private methods

- (NSString*)urlEscapeString:(id)unencodedString {
    if ([unencodedString isKindOfClass:[NSString class]]) {
        CFStringRef originalStringRef = (__bridge_retained CFStringRef)unencodedString;
        NSString *s = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,originalStringRef, NULL, NULL,kCFStringEncodingUTF8);
        CFRelease(originalStringRef);
        return s;
    }
    return unencodedString;
}

- (NSString *)forceString:(NSString *)value {
    if (!value) return @"";
    return value;
}

- (void)performApiCallForMethod:(NSString*)method
                     withParams:(NSDictionary *)params
                     andFilters:(NSDictionary *)filters
                 successHandler:(ItunesSearchReturnBlockWithObject)successHandler
                 failureHandler:(ItunesSearchReturnBlockWithError)failureHandler {

    NSBlockOperation *op = [[NSBlockOperation alloc] init];
    [op addExecutionBlock:^{
        // Add the short link affiliation token
        NSMutableDictionary *newParams = [params mutableCopy];
        
        // Add affiliate identifiers if supplied
        if (self.partnerId && self.partnerId.length > 0)
            [newParams setObject:self.partnerId forKey:@"partnerId"];
        if (self.tradeDoublerId && self.tradeDoublerId.length > 0)
            [newParams setObject:self.tradeDoublerId forKey:@"tduid"];

        // Set the user's country to get the correct price
        [newParams setObject:[[NSLocale currentLocale] objectForKey: NSLocaleCountryCode]
                      forKey:@"country"];

        // Convert the dict of params into an array of key=value strings
        NSMutableArray *paramsArray = [NSMutableArray arrayWithCapacity:[newParams count]];
        [newParams enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [paramsArray addObject:[NSString stringWithFormat:@"%@=%@", [self urlEscapeString:key], [self urlEscapeString:obj]]];
        }];

        // Set up the http request
        NSString *url = [NSString stringWithFormat:@"%@%@?%@", API_URL, method, [paramsArray componentsJoinedByString:@"&"]];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
        [request setHTTPMethod:@"GET"];
        
        NSURLResponse *response;
        NSError *error;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

        // Check for NSURLConnection errors
        if (error) {
            if (failureHandler) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    failureHandler(error);
                }];
            }
            return;
        }
        
        // Deserialise the raw data into a JSON object
        id jsonData = [NSJSONSerialization JSONObjectWithData:data
                                                      options:0
                                                        error:&error];
        
        // Check for data serialization errors
        if (error) {
            if (failureHandler) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    failureHandler(error);
                }];
            }
            return;
        }
        
        // Ensure the JSON is valid
        if (![NSJSONSerialization isValidJSONObject:jsonData]) {
            if (failureHandler) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    // Build an error describing the failure
                    NSMutableDictionary* details = [NSMutableDictionary dictionary];
                    [details setValue:@"Invalid JSON returned"
                               forKey:NSLocalizedDescriptionKey];
                    NSError *invalidJSONError = [NSError errorWithDomain:@"ItunesSearch"
                                                                    code:100
                                                                userInfo:details];
                    
                    // Execute the failure handler
                    failureHandler(invalidJSONError);
                }];
            }
            return;
        }
        
        // Ensure a dictionary was received
        if (![jsonData isKindOfClass:[NSDictionary class]]) {
            if (failureHandler) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    // Build an error describing the failure
                    NSMutableDictionary* details = [NSMutableDictionary dictionary];
                    [details setValue:@"Expected a dictionary as the top level object"
                               forKey:NSLocalizedDescriptionKey];
                    NSError *invalidTopLevel = [NSError errorWithDomain:@"ItunesSearch"
                                                                   code:101
                                                               userInfo:details];
                    
                    // Execute the failure handler
                    failureHandler(invalidTopLevel);
                }];
            }
            
            return;
        }
        
        // Extract the results from the returned data
        NSArray *filteredResults = nil;
        if (jsonData && [jsonData count] > 0) {
            // Pull out the results object
            NSArray *results = [jsonData objectForKey:@"results"];
            
            // Sanity check the results
            if (results) {
                // Apply filters to the results if supplied
                if (filters && [filters count] > 0) {
                    NSMutableArray *predicates = [NSMutableArray array];
                    // Construct a case-insensitive predicate for each filter
                    for (id key in [filters allKeys]) {
                        [predicates addObject:[NSPredicate predicateWithFormat:
                                               @"%K ==[c] %@",
                                               key,
                                               [filters valueForKey:key]]];
                    }
                    
                    // Apply the predicates
                    filteredResults = [results filteredArrayUsingPredicate:
                                       [NSCompoundPredicate andPredicateWithSubpredicates:predicates]];
                } else {
                    // No filtering necessary
                    filteredResults = results;
                }
            }
        }
        
        // Send the results to the success handler
        if (successHandler) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                successHandler(filteredResults);
            }];
        }
    }];
    
    [self.queue addOperation:op];
}

#pragma mark - Album methods

- (void)getTracksForAlbums:(NSArray *)albumIds limitOrNil:(NSNumber *)limit sucessHandler:(ItunesSearchReturnBlockWithArray)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler {
    // Set up the request parameters
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:[albumIds componentsJoinedByString:@","] forKey:@"id"];
    [params setObject:@"song" forKey:@"entity"];
    
    // Add the limit if supplied
    if (limit && limit > 0) {
        [params setObject:limit forKey:@"limit"];
    }
    
    [self performApiCallForMethod:@"lookup"
                       withParams:params
                       andFilters:nil
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

#pragma mark - Artist methods

- (void)getAlbumsForArtist:(NSNumber *)artistId limitOrNil:(NSNumber *)limit successHandler:(ItunesSearchReturnBlockWithArray)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler {
    // Set up the request paramters
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:[self forceString:[artistId stringValue]] forKey:@"id"];
    [params setObject:@"music" forKey:@"media"];
    [params setObject:@"album" forKey:@"entity"];
    
    // Set up the results filter
    NSDictionary *filters = @{
        @"wrapperType": @"collection",
        @"collectionType": @"album"
    };
    
    // Add the limit if supplied
    if (limit && limit > 0) {
        [params setObject:limit forKey:@"limit"];
    }
    
    [self performApiCallForMethod:@"lookup"
                       withParams:params
                          andFilters:filters
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)getAlbumWithArtist:(NSString *)artistName andName:(NSString *)albumName limitOrNil:(NSNumber *)limit successHandler:(ItunesSearchReturnBlockWithArray)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler {
    // Set up the request paramters
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:[self forceString:artistName] forKey:@"term"];
    [params setObject:@"music" forKey:@"media"];
    [params setObject:@"album" forKey:@"entity"];
    [params setObject:@"artistTerm" forKey:@"attribute"];
     
    // Set up the results filter
    NSDictionary *filters = @{
        @"wrapperType": @"collection",
        @"collectionType": @"album",
        @"collectionName": albumName
    };
    
    // Add the limit if supplied
    if (limit && limit > 0) {
        [params setObject:limit forKey:@"limit"];
    }
    
    [self performApiCallForMethod:@"search"
                       withParams:params
                       andFilters:filters
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

- (void)getIdForArtist:(NSString *)artist successHandler:(ItunesSearchReturnBlockWithArray)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler {
    // Set up the request paramters
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:[self forceString:artist] forKey:@"term"];
    [params setObject:@"music" forKey:@"media"];
    [params setObject:@"musicArtist" forKey:@"entity"];
    [params setObject:@"artistTerm" forKey:@"attribute"];
    
    // Set up the results filter
    NSDictionary *filters = @{
        @"artistName": artist
    };
    
    [self performApiCallForMethod:@"search"
                       withParams:params
                       andFilters:filters
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

@end
