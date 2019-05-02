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

#import "WVJSBDefine.h"

NS_ASSUME_NONNULL_BEGIN


@interface WVJSBServer : NSObject

+ (instancetype)serverWithWebView:(id)webView namespace:(NSString* _Nullable)ns NS_SWIFT_NAME(init(webView:ns:));

+ (BOOL)canHandleWithWebView:(id)webView URLString:(NSString*_Nullable)URLString NS_SWIFT_NAME(canHandle(webView:URLString:));

- (id<WVJSBHandler>)on:(NSString*)type;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
