//
//   Copyright 2012 Square Inc.
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.
//

#import <Foundation/Foundation.h>
#import <Security/SecCertificate.h>

typedef enum {
    NTY_CONNECTING   = 0,
    NTY_OPEN         = 1,
    NTY_CLOSING      = 2,
    NTY_CLOSED       = 3,
} NTYReadyState;

typedef enum NTYStatusCode : NSInteger {
    NTYStatusCodeNormal = 1000,
    NTYStatusCodeGoingAway = 1001,
    NTYStatusCodeProtocolError = 1002,
    NTYStatusCodeUnhandledType = 1003,
    // 1004 reserved.
    NTYStatusNoStatusReceived = 1005,
    // 1004-1006 reserved.
    NTYStatusCodeInvalidUTF8 = 1007,
    NTYStatusCodePolicyViolated = 1008,
    NTYStatusCodeMessageTooBig = 1009,
} NTYStatusCode;

@class NTYWebSocket;

extern NSString *const NTYWebSocketErrorDomain;
extern NSString *const NTYHTTPResponseErrorKey;

#pragma mark - NTYWebSocketDelegate

@protocol NTYWebSocketDelegate;

#pragma mark - NTYWebSocket

@interface NTYWebSocket : NSObject <NSStreamDelegate>

@property (nonatomic, weak) id <NTYWebSocketDelegate> delegate;

@property (nonatomic, readonly) NTYReadyState readyState;
@property (nonatomic, readonly, retain) NSURL *url;

// This returns the negotiated protocol.
// It will be nil until after the handshake completes.
@property (nonatomic, readonly, copy) NSString *protocol;

// Protocols should be an array of strings that turn into Sec-WebSocket-Protocol.
- (id)initWithURLRequest:(NSURLRequest *)request protocols:(NSArray *)protocols;
- (id)initWithURLRequest:(NSURLRequest *)request;

// Some helper constructors.
- (id)initWithURL:(NSURL *)url protocols:(NSArray *)protocols;
- (id)initWithURL:(NSURL *)url;

// Delegate queue will be dispatch_main_queue by default.
// You cannot set both OperationQueue and dispatch_queue.
- (void)setDelegateOperationQueue:(NSOperationQueue*) queue;
- (void)setDelegateDispatchQueue:(dispatch_queue_t) queue;

// By default, it will schedule itself on +[NNTYunLoop NTY_networkRunLoop] using defaultModes.
- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode;
- (void)unscheduleFromRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode;

// NTYWebSockets are intended for one-time-use only.  Open should be called once and only once.
- (void)open;

- (void)close;
- (void)closeWithCode:(NSInteger)code reason:(NSString *)reason;

// Send a UTF8 String or Data.
- (void)send:(id)data;

@end

#pragma mark - NTYWebSocketDelegate

@protocol NTYWebSocketDelegate <NSObject>

// message will either be an NSString if the server is using text
// or NSData if the server is using binary.
- (void)webSocket:(NTYWebSocket *)webSocket didReceiveMessage:(id)message;

@optional

- (void)webSocketDidOpen:(NTYWebSocket *)webSocket;
- (void)webSocket:(NTYWebSocket *)webSocket didFailWithError:(NSError *)error;
- (void)webSocket:(NTYWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;

@end

#pragma mark - NSURLRequest (CertificateAdditions)

@interface NSURLRequest (NTYCertificateAdditions)

@property (nonatomic, retain, readonly) NSArray *NTY_SSLPinnedCertificates;

@end

#pragma mark - NSMutableURLRequest (CertificateAdditions)

@interface NSMutableURLRequest (NTYCertificateAdditions)

@property (nonatomic, retain) NSArray *NTY_SSLPinnedCertificates;

@end

#pragma mark - NSRunLoop (NTYWebSocket)

@interface NSRunLoop (NTYWebSocket)

+ (NSRunLoop *)NTY_networkRunLoop;

@end
