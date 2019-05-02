//
//  WVJSBClient+Private.h
//  WVJSB
//
//  Created by retriable on 2019/04/09.
//  Copyright © 2018 retriable. All rights reserved.
//

#import "WVJSBServer.h"

NS_ASSUME_NONNULL_BEGIN

@interface WVJSBServer (Private)

+ (instancetype)serverWithWebView:(id)webView namespace:(NSString* _Nullable)ns flag:(BOOL)flag;

- (instancetype)initWithWebView:(id)webView ns:(NSString*)ns;

- (void)install;

- (void)query;

- (void)handleMessage:(id)message;

@end

NS_ASSUME_NONNULL_END
