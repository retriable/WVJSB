//
//  WVJSBScriptMessageHandler.m
//  WVJSB
//
//  Created by retriable on 2019/3/21.
//  Copyright © 2019 retriable. All rights reserved.
//

#import "WVJSBScriptMessageHandler.h"
#import "WVJSBServer+Private.h"

@interface WVJSBScriptMessageHandler()

@end

@implementation WVJSBScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    [[WVJSBServer serverWithWebView:message.webView namespace:message.name flag:NO] handleMessage:message.body];
}

@end
