//
//  WVJSBClient.h
//  WVJSB
//
//  Created by retriable on 2019/04/09.
//  Copyright © 2018 retriable. All rights reserved.
//

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#endif
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@class WVJSBHandler;
@class WVJSBServer;
@class WVJSBConnection;
@class WVJSBOperation;

typedef void (^WVJSBOnCancelBlock)(id _Nullable context);
typedef void (^WVJSBOperationAckBlock)(WVJSBOperation *operation, id _Nullable result, NSError * _Nullable error);
typedef void (^WVJSBAckBlock)(id _Nullable result, NSError *_Nullable error);
typedef id _Nullable (^WVJSBOnEventBlock)(WVJSBConnection *connection, id _Nullable parameter, WVJSBAckBlock(^done)(void));

@interface WVJSBServer : NSObject

@property (readonly) NSDictionary<NSString*,WVJSBConnection*> *connections;

+ (instancetype)serverWithWebView:(id)webView namespace:(NSString* _Nullable)ns NS_SWIFT_NAME(init(webView:ns:));

+ (BOOL)canHandleWithWebView:(id)webView request:(NSURLRequest*)request NS_SWIFT_NAME(canHandle(webView:request:));

- (WVJSBHandler*)on:(NSString*)type;

@end

NS_ASSUME_NONNULL_END
