//
//  ItunesSearch.m
//  lastfmlocalplayback
//
//  Created by Piers Biddlestone on 28/09/12.
//  Copyright (c) 2012 Gangverk. All rights reserved.
//

#import "ItunesSearch.h"
#import <AFJSONRequestOperation.h>

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
                 successHandler:(ItunesSearchReturnBlockWithObject)successHandler
                 failureHandler:(ItunesSearchReturnBlockWithError)failureHandler {
    
    // Add the short link affiliation token
    NSMutableDictionary *newParams = [params mutableCopy];
    // TODO: Get the correct tduid
    [newParams setObject:self.partnerId forKey:@"partnerId"];
    [newParams setObject:self.tradeDoublerId forKey:@"tduid"];

    // Set the user's country to get the correct price
    [newParams setObject:[[NSLocale currentLocale] objectForKey:NSLocaleCountryCode]
                  forKey:@"country"];

    // Convert the dict of params into an array of key=value strings
    NSMutableArray *paramsArray = [NSMutableArray arrayWithCapacity:[newParams count]];
    [newParams enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [paramsArray addObject:[NSString stringWithFormat:@"%@=%@", [self urlEscapeString:key], [self urlEscapeString:obj]]];
    }];

    // Set up the http request
    NSString *url = [NSString stringWithFormat:@"%@%@?%@", API_URL, method, [paramsArray componentsJoinedByString:@"&"]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            if (![JSON isKindOfClass:[NSDictionary class]]) {
                if (failureHandler) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        //TODO: error indicating invalid format for response
                        failureHandler(nil);
                    }];
                }
                
                return;
            }
            
            // Extract the results from the returned data
            NSDictionary *data = JSON;
            NSArray *results = nil;
            if (data && [data count] > 0) {
                results = [data objectForKey:@"results"];
            }
            
            // Send the results to the success handler
            if (successHandler) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    successHandler(results);
                }];
            }
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            // Execute the failure handler if supplied
            if (failureHandler) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    failureHandler(error);
                }];
            }
            
            return;
        }];
    
    [self.queue addOperation:operation];
}

#pragma mark - Artist methods

- (void)getAlbumsForArtist:(NSString *)artist limitOrNil:(NSNumber *)limit successHandler:(ItunesSearchReturnBlockWithArray)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler {
    // Set up the request paramters
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:[self forceString:artist] forKey:@"term"];
    [params setObject:@"album" forKey:@"entity"];
    
    // Add the limit if supplied
    if (limit && limit > 0) {
        [params setObject:limit forKey:@"limit"];
    }
    
    [self performApiCallForMethod:@"search"
                       withParams:params
                   successHandler:successHandler
                   failureHandler:failureHandler];
}

@end
