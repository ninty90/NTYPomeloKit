//
//  Pomelo.h
//  iOS client for Pomelo
//
//  Created by Johnny on 12-12-11.
//  Copyright (c) 2012 netease pomelo team. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^NTYPomeloCallback)(id callback);

@class NTYPomelo;

@protocol NTYPomeloDelegate <NSObject>
@optional
- (void)PomeloDidConnect:(NTYPomelo *)pomelo;
- (void)PomeloDidDisconnect:(NTYPomelo *)pomelo withError:(NSError *)error;
- (void)Pomelo:(NTYPomelo *)pomelo didReceiveMessage:(NSArray *)message;
@end

@interface NTYPomelo : NSObject

- (id)initWithDelegate:(id<NTYPomeloDelegate>)delegate;
- (void)connectToHost:(NSString *)host onPort:(NSInteger)port;
- (void)connectToHost:(NSString *)host onPort:(NSInteger)port withCallback:(NTYPomeloCallback)callback;
- (void)connectToHost:(NSString *)host onPort:(NSInteger)port withParams:(NSDictionary *)params;
- (void)disconnect;
- (void)disconnectWithCallback:(NTYPomeloCallback)callback;

- (void)requestWithRoute:(NSString *)route andParams:(NSDictionary *)params andCallback:(NTYPomeloCallback)callback;
- (void)notifyWithRoute:(NSString *)route andParams:(NSDictionary *)params;
- (void)onRoute:(NSString *)route withCallback:(NTYPomeloCallback)callback;
- (void)offRoute:(NSString *)route;

@end
