//
//  ItunesSearch.h
//  lastfmlocalplayback
//
//  Created by Piers Biddlestone on 28/09/12.
//  Copyright (c) 2012 Gangverk. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ItunesSearchReturnBlockWithObject)(id result);
typedef void (^ItunesSearchReturnBlockWithArray)(NSArray *result);
typedef void (^ItunesSearchReturnBlockWithError)(NSError *error);

@interface ItunesSearch : NSObject

@property (strong, nonatomic) NSString *partnerId;
@property (strong, nonatomic) NSString *tradeDoublerId;

+ (ItunesSearch *)sharedInstance;
- (void)performApiCallForMethod:(NSString*)method withParams:(NSDictionary *)params successHandler:(ItunesSearchReturnBlockWithObject)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler;

#pragma mark - Artist methods

- (void)getAlbumsForArtist:(NSString *)artist limitOrNil:(NSNumber *)limit successHandler:(ItunesSearchReturnBlockWithArray)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler;

@end
