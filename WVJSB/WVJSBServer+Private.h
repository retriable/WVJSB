//
//  WVJSBClient+Private.h
//  WVJSB
//
//  Created by retriable on 2019/04/09.
//  Copyright © 2018 retriable. All rights reserved.
//

#import "WVJSBServer.h"

NS_ASSUME_NONNULL_BEGIN

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"

static BOOL WVJSBIsStringEmpty(NSString *v){
    return ![v isKindOfClass:NSString.class]||v.length==0;
}

static NSString *WVJSBCorrectedJSString(NSString *v){
    v = [v stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    v = [v stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    v = [v stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
    v = [v stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    v = [v stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    v = [v stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
    v = [v stringByReplacingOccurrencesOfString:@"\b" withString:@"\\b"];
    v = [v stringByReplacingOccurrencesOfString:@"\t" withString:@"\\t"];
    v = [v stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
    v = [v stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
    return v;
}
#pragma clang diagnostic pop


@interface WVJSBServer (Private)

+ (instancetype)serverWithWebView:(id)webView namespace:(NSString* _Nullable)ns flag:(BOOL)flag;

- (instancetype)initWithWebView:(id)webView ns:(NSString*)ns;

- (void)install;

- (void)query;

- (void)handleMessage:(id)message;

@end

NS_ASSUME_NONNULL_END
