//
//  Pomelo.m
//  iOS client for Pomelo
//
//  Created by Johnny on 12-12-11.
//  Copyright (c) 2012 netease pomelo team. All rights reserved.
//

#import "NTYPomelo.h"
#import "NTYPomeloProtocol.h"
#import "NTYSocketIOJSONSerialization.h"
#import "NTYSocketIOPacket.h"
#import "NTYSocketIO.h"

static NSString const *_connectCallback = @"__connectCallback__";
static NSString const *_disconnectCallback = @"__disconnectCallback__";

@interface NTYPomelo (Private)
- (void)sendMessageWithReqId:(NSInteger)reqId andRoute:(NSString *)route andMsg:(NSDictionary *)msg;
- (void)processMessage:(NSDictionary *)msg;
- (void)processMessageBatch:(NSArray *)msgs;
@end

@interface NTYPomelo () <NTYSocketIODelegate>
{
    __unsafe_unretained id<NTYPomeloDelegate> _delegate;
    
    NSMutableDictionary *_callbacks;
    NSInteger _reqId;
    NTYSocketIO *socketIO;
}

@end

@implementation NTYPomelo

- (id)initWithDelegate:(id<NTYPomeloDelegate>)delegate
{
    self = [super init];
    if (self) {
        _delegate = delegate;
        _reqId = 0;
        _callbacks = [[NSMutableDictionary alloc] init];
        socketIO = [[NTYSocketIO alloc] initWithDelegate:self];
    }
    return self;
    
}

- (void)connectToHost:(NSString *)host onPort:(NSInteger)port
{
    [socketIO connectToHost:host onPort:port];
}
- (void)connectToHost:(NSString *)host onPort:(NSInteger)port withCallback:(NTYPomeloCallback)callback;
{
    if (callback) {
        [_callbacks setObject:callback forKey:_connectCallback];
    }
    [socketIO connectToHost:host onPort:port];
}
- (void)connectToHost:(NSString *)host onPort:(NSInteger)port withParams:(NSDictionary *)params
{
    [socketIO connectToHost:host onPort:port withParams:params];
}
- (void)disconnect
{
    [socketIO disconnect];
}

- (void)disconnectWithCallback:(NTYPomeloCallback)callback
{
    if (callback) {
        [_callbacks setObject:callback forKey:_disconnectCallback];
    }
    [socketIO disconnect];
}
# pragma mark -
# pragma mark implement SocketIODelegate

- (void) socketIODidConnect:(NTYSocketIO *)socket
{
    NTYPomeloCallback callback = [_callbacks objectForKey:_connectCallback];
    if (callback != nil) {
        callback(self);
        [_callbacks removeObjectForKey:_connectCallback];
    }
    if ([_delegate respondsToSelector:@selector(PomeloDidConnect:)]) {
        [_delegate PomeloDidConnect:self];
    }
}

- (void) socketIODidDisconnect:(NTYSocketIO *)socket disconnectedWithError:(NSError *)error
{
    NTYPomeloCallback callback = [_callbacks objectForKey:_disconnectCallback];
    if (callback != nil) {
        callback(self);
        [_callbacks removeObjectForKey:_disconnectCallback];
    }
    if ([_delegate respondsToSelector:@selector(PomeloDidDisconnect:withError:)]) {
        [_delegate PomeloDidDisconnect:self withError:error];
    }
}

- (void)socketIO:(NTYSocketIO *)socket didReceiveMessage:(NTYSocketIOPacket *)packet
{
    id data = [packet dataAsJSON];
    if ([_delegate respondsToSelector:@selector(Pomelo:didReceiveMessage:)]) {
        [_delegate Pomelo:self didReceiveMessage:data];
    }
    
    if ([data isKindOfClass:[NSArray class]]) {
        [self processMessageBatch:data];
    } else if ([data isKindOfClass:[NSDictionary class]]) {
        [self processMessage:data];
    }
}

# pragma mark -
# pragma mark main api

- (void)notifyWithRoute:(NSString *)route andParams:(NSDictionary *)params
{
    [self sendMessageWithReqId:0 andRoute:route andMsg:params];
}

- (void)requestWithRoute:(NSString *)route andParams:(NSDictionary *)params andCallback:(NTYPomeloCallback)callback
{
    if (callback) {
        ++_reqId;
        NSString *key = [NSString stringWithFormat:@"%ld", (long)_reqId];
        [_callbacks setObject:[callback copy] forKey:key];
        [self sendMessageWithReqId:_reqId andRoute:route andMsg:params];
    } else {
        [self notifyWithRoute:route andParams:params];
    }

}

- (void)onRoute:(NSString *)route withCallback:(NTYPomeloCallback)callback
{
    id array = [_callbacks objectForKey:route];
    if (array == nil) {
        array = [NSMutableArray arrayWithCapacity:1];
        [_callbacks setObject:array forKey:route];
    }
    [array addObject:[callback copy]];
}

- (void)offRoute:(NSString *)route
{
    [_callbacks removeObjectForKey:route];
}

# pragma mark -
# pragma mark private methods

- (void)sendMessageWithReqId:(NSInteger)reqId andRoute:(NSString *)route andMsg:(NSDictionary *)msg
{
    NSString *msgStr = [NTYSocketIOJSONSerialization JSONStringFromObject:msg error:nil];
    [socketIO sendMessage:[NTYPomeloProtocol encodeWithId:reqId andRoute:route andBody:msgStr]];
}

- (void)processMessage:(NSDictionary *)msg
{
    id msgId =  [msg objectForKey:@"id"];
    if (msgId && msgId > 0){
        NSString *key = [NSString stringWithFormat:@"%@", msgId];
        NTYPomeloCallback callback = [_callbacks objectForKey:key];
        if (callback != nil) {
            callback([msg objectForKey:@"body"]);
            [_callbacks removeObjectForKey:key];
        }
    } else {
        NSMutableArray *callbacks = [_callbacks objectForKey:[msg objectForKey:@"route"]];
        if (callbacks != nil) {
            for (NTYPomeloCallback cb in callbacks)  {
                cb(msg);
            }
        }
        
    }
}

- (void)processMessageBatch:(NSArray *)msgs
{
    for (id msg in msgs) {
        [self processMessage:msg];
    }
}

# pragma mark -

- (void)dealloc
{
    socketIO = nil;
    _callbacks = nil;
    _delegate = nil;
}
@end
