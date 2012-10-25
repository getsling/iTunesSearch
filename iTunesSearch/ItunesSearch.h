//
//  ItunesSearch.h
//  iTunesSearch
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
- (void)performApiCallForMethod:(NSString*)method withParams:(NSDictionary *)params andFilters:(NSDictionary *)filters successHandler:(ItunesSearchReturnBlockWithObject)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler;

#pragma mark - Album methods

- (void)getTracksForAlbums:(NSArray *)albumIds limitOrNil:(NSNumber *)limit sucessHandler:(ItunesSearchReturnBlockWithArray)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler;

#pragma mark - Artist methods

- (void)getAlbumsForArtist:(NSNumber *)artistId limitOrNil:(NSNumber *)limit successHandler:(ItunesSearchReturnBlockWithArray)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler;
- (void)getAlbumWithArtist:(NSString *)artistName andName:(NSString *)albumName limitOrNil:(NSNumber *)limit successHandler:(ItunesSearchReturnBlockWithArray)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler;
- (void)getIdForArtist:(NSString *)artist successHandler:(ItunesSearchReturnBlockWithArray)successHandler failureHandler:(ItunesSearchReturnBlockWithError)failureHandler;

@end
