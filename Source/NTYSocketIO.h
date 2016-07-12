//
//  SocketIO.h
//  v0.3.0 ARC
//
//  based on 
//  socketio-cocoa https://github.com/fpotter/socketio-cocoa
//  by Fred Potter <fpotter@pieceable.com>
//
//  using
//  https://github.com/square/SocketRocket
//  https://github.com/stig/json-framework/
//
//  reusing some parts of
//  /socket.io/socket.io.js
//
//  Created by Philipp Kyeck http://beta-interactive.de
//
//  Updated by 
//    samlown   https://github.com/samlown
//    kayleg    https://github.com/kayleg
//    taiyangc  https://github.com/taiyangc
//

#import <Foundation/Foundation.h>

#import "NTYSocketIOTransport.h"

@class NTYSocketIO;
@class NTYSocketIOPacket;

typedef void(^NTYSocketIOCallback)(id argsData);

extern NSString* const NTYSocketIOError;

typedef enum {
    SocketIOServerRespondedWithInvalidConnectionData = -1,
    SocketIOServerRespondedWithDisconnect = -2,
    SocketIOHeartbeatTimeout = -3,
    SocketIOWebSocketClosed = -4,
    SocketIOTransportsNotSupported = -5,
    SocketIOHandshakeFailed = -6,
    SocketIODataCouldNotBeSend = -7
} NTYSocketIOErrorCodes;


@protocol NTYSocketIODelegate <NSObject>
@optional
- (void) socketIODidConnect:(NTYSocketIO *)socket;
- (void) socketIODidDisconnect:(NTYSocketIO *)socket disconnectedWithError:(NSError *)error;
- (void) socketIO:(NTYSocketIO *)socket didReceiveMessage:(NTYSocketIOPacket *)packet;
- (void) socketIO:(NTYSocketIO *)socket didReceiveJSON:(NTYSocketIOPacket *)packet;
- (void) socketIO:(NTYSocketIO *)socket didReceiveEvent:(NTYSocketIOPacket *)packet;
- (void) socketIO:(NTYSocketIO *)socket didSendMessage:(NTYSocketIOPacket *)packet;
- (void) socketIO:(NTYSocketIO *)socket onError:(NSError *)error;

// TODO: deprecated -> to be removed
- (void) socketIO:(NTYSocketIO *)socket failedToConnectWithError:(NSError *)error __attribute__((deprecated));
- (void) socketIOHandshakeFailed:(NTYSocketIO *)socket __attribute__((deprecated));
@end


@interface NTYSocketIO : NSObject <NSURLConnectionDelegate, NTYSocketIOTransportDelegate>
{
    NSString *_host;
    NSInteger _port;
    NSString *_sid;
    NSString *_endpoint;
    NSDictionary *_params;
    
    __unsafe_unretained id<NTYSocketIODelegate> _delegate;
    
    NSObject <NTYSocketIOTransport> *_transport;
    
    BOOL _isConnected;
    BOOL _isConnecting;
    BOOL _useSecure;
    
    // heartbeat
    NSTimeInterval _heartbeatTimeout;
    NSTimer *_timeout;
    
    NSMutableArray *_queue;
    
    // acknowledge
    NSMutableDictionary *_acks;
    NSInteger _ackCount;
    
    // http request
    NSMutableData *_httpRequestData;
}

@property (nonatomic, readonly) NSString *host;
@property (nonatomic, readonly) NSInteger port;
@property (nonatomic, readonly) NSString *sid;
@property (nonatomic, readonly) NSTimeInterval heartbeatTimeout;
@property (nonatomic) BOOL useSecure;
@property (nonatomic, readonly) BOOL isConnected, isConnecting;
@property (nonatomic, unsafe_unretained) id<NTYSocketIODelegate> delegate;

- (id) initWithDelegate:(id<NTYSocketIODelegate>)delegate;
- (void) connectToHost:(NSString *)host onPort:(NSInteger)port;
- (void) connectToHost:(NSString *)host onPort:(NSInteger)port withParams:(NSDictionary *)params;
- (void) connectToHost:(NSString *)host onPort:(NSInteger)port withParams:(NSDictionary *)params withNamespace:(NSString *)endpoint;
- (void) disconnect;

- (void) sendMessage:(NSString *)data;
- (void) sendMessage:(NSString *)data withAcknowledge:(NTYSocketIOCallback)function;
- (void) sendJSON:(NSDictionary *)data;
- (void) sendJSON:(NSDictionary *)data withAcknowledge:(NTYSocketIOCallback)function;
- (void) sendEvent:(NSString *)eventName withData:(id)data;
- (void) sendEvent:(NSString *)eventName withData:(id)data andAcknowledge:(NTYSocketIOCallback)function;
- (void) sendAcknowledgement:(NSString*)pId withArgs:(NSArray *)data;

@end