//
//  SocketIOTransportWebsocket.m
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

#import "NTYSocketIOTransportWebsocket.h"
#import "NTYSocketIO.h"

#define DEBUG_LOGS 0

#if DEBUG_LOGS
#define DEBUGLOG(...) NSLog(__VA_ARGS__)
#else
#define DEBUGLOG(...)
#endif

static NSString* kInsecureSocketURL = @"ws://%@/socket.io/1/websocket/%@";
static NSString* kSecureSocketURL = @"wss://%@/socket.io/1/websocket/%@";
static NSString* kInsecureSocketPortURL = @"ws://%@:%d/socket.io/1/websocket/%@";
static NSString* kSecureSocketPortURL = @"wss://%@:%d/socket.io/1/websocket/%@";

@implementation NTYSocketIOTransportWebsocket

@synthesize delegate;

- (id) initWithDelegate:(id<NTYSocketIOTransportDelegate>)delegate_
{
    self = [super init];
    if (self) {
        self.delegate = delegate_;
    }
    return self;
}

- (BOOL) isReady
{
    return _webSocket.readyState == NTY_OPEN;
}

- (void) open
{
    NSString *urlStr;
    NSString *format;
    if (delegate.port) {
        format = delegate.useSecure ? kSecureSocketPortURL : kInsecureSocketPortURL;
        urlStr = [NSString stringWithFormat:format, delegate.host, delegate.port, delegate.sid];
    }
    else {
        format = delegate.useSecure ? kSecureSocketURL : kInsecureSocketURL;
        urlStr = [NSString stringWithFormat:format, delegate.host, delegate.sid];
    }
    NSURL *url = [NSURL URLWithString:urlStr];
    
    _webSocket = nil;
    
    _webSocket = [[NTYWebSocket alloc] initWithURL:url];
    _webSocket.delegate = self;
    DEBUGLOG(@"Opening %@", url);
    [_webSocket open];
}

- (void) close
{
    [_webSocket close];
}

- (void) send:(NSString*)request
{
    [_webSocket send:request];
}



# pragma mark -
# pragma mark WebSocket Delegate Methods

- (void) webSocket:(NTYWebSocket *)webSocket didReceiveMessage:(id)message
{
    [delegate onData:message];
}

- (void) webSocketDidOpen:(NTYWebSocket *)webSocket
{
    DEBUGLOG(@"Socket opened.");
}

- (void) webSocket:(NTYWebSocket *)webSocket didFailWithError:(NSError *)error
{
    DEBUGLOG(@"Socket failed with error ... %@", [error localizedDescription]);
    // Assuming this resulted in a disconnect
    [delegate onDisconnect:error];
}

- (void) webSocket:(NTYWebSocket *)webSocket
  didCloseWithCode:(NSInteger)code
            reason:(NSString *)reason
          wasClean:(BOOL)wasClean
{
    DEBUGLOG(@"Socket closed. %@", reason);
    [delegate onDisconnect:[NSError errorWithDomain:NTYSocketIOError
                                               code:SocketIOWebSocketClosed
                                           userInfo:nil]];
}

@end
